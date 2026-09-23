#!/usr/bin/env bash
set -euo pipefail

# Sincronización automática GitHub - Proxmox admin
REPO_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
KEY="${PUSH_SSH_KEY:-$HOME/.ssh/id_ed25519}"
REMOTE="${PUSH_REMOTE:-git@github.com:ciprianotoor/MyScriptsBashs.git}"
BRANCH="${PUSH_BRANCH:-main}"
REPO_URL="${PUSH_REPO_URL:-https://github.com/ciprianotoor/MyScriptsBashs}"
LOCK_FILE="${XDG_RUNTIME_DIR:-/tmp}/push_my_scripts.${UID:-$(id -u)}.lock"

if [[ -t 1 ]]; then
    GREEN=$'\033[1;32m'; CYAN=$'\033[1;36m'; YELLOW=$'\033[1;33m'; DIM=$'\033[2m'; RESET=$'\033[0m'
else
    GREEN=''; CYAN=''; YELLOW=''; DIM=''; RESET=''
fi

info() { printf '%s%s%s\n' "$CYAN" "$*" "$RESET"; }
ok() { printf '%s✅ %s%s\n' "$GREEN" "$*" "$RESET"; }
die() { printf '%s❌ %s%s\n' "$YELLOW" "$*" "$RESET" >&2; exit 1; }

acquire_lock() {
    command -v flock >/dev/null 2>&1 || die 'El comando flock no está instalado'
    exec 9>"$LOCK_FILE" || die "No se pudo crear el bloqueo: $LOCK_FILE"
    flock -n 9 || die 'Ya hay otra sincronización en curso'
}

ensure_ssh_agent() {
    local current_user key_hash
    current_user=${USER:-$(id -un)}
    if [[ -z "${SSH_AUTH_SOCK:-}" || ! -S "$SSH_AUTH_SOCK" ]] || \
       ! pgrep -u "$current_user" -x ssh-agent >/dev/null 2>&1; then
        eval "$(ssh-agent -s)" >/dev/null
    fi
    [[ -f "$KEY" ]] || die "No existe la clave SSH: $KEY"
    key_hash=$(ssh-keygen -lf "$KEY" -E sha256 | awk '{print $2}') || die 'No se pudo leer la clave SSH'
    if ! ssh-add -l 2>/dev/null | awk '{print $2}' | grep -Fxq "$key_hash"; then
        ssh-add "$KEY" >/dev/null 2>&1 || die "No se pudo cargar la clave SSH: $KEY"
    fi
}

ensure_repo() {
    [[ -d "$REPO_DIR" ]] || die "No existe $REPO_DIR"
    cd "$REPO_DIR"
    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        info '📦 Inicializando repositorio...'
        git init -q
    fi
    if git remote get-url origin >/dev/null 2>&1; then
        git remote set-url origin "$REMOTE"
    else
        git remote add origin "$REMOTE"
    fi
    git config user.name "${PUSH_GIT_USER_NAME:-cipriano}"
    git config user.email "${PUSH_GIT_USER_EMAIL:-cipriano@users.noreply.github.com}"
    if ! git show-ref --verify --quiet "refs/heads/$BRANCH"; then
        git switch -c "$BRANCH" || die "No se pudo crear la rama $BRANCH"
    elif [[ "$(git branch --show-current)" != "$BRANCH" ]]; then
        git switch "$BRANCH" || die "No se pudo cambiar a la rama $BRANCH"
    fi
}

sync_changes() {
    local rebase_merge rebase_apply timestamp commit_message comment remote_branch behind ahead
    cd "$REPO_DIR"
    rebase_merge=$(git rev-parse --git-path rebase-merge)
    rebase_apply=$(git rev-parse --git-path rebase-apply)
    if [[ -d "$rebase_merge" || -d "$rebase_apply" ]]; then
        if [[ -z "$(git diff --name-only --diff-filter=U)" ]]; then
            info '🔄 Finalizando un rebase interrumpido...'
            GIT_EDITOR=true git -c core.editor=true rebase --continue
        else
            die "Hay un rebase pendiente con conflictos. Resuélvelo y ejecuta el rebase antes de reintentar."
        fi
    fi

    # Actualiza referencias remotas incluso cuando no hay cambios locales.
    remote_branch=false
    if git ls-remote --exit-code --heads origin "$BRANCH" >/dev/null 2>&1; then
        remote_branch=true
        git fetch --quiet origin "$BRANCH" || die 'No se pudo consultar el remoto'
    fi

    git add --all
    if ! git diff --cached --quiet; then
        timestamp=$(date '+%Y-%m-%d %H:%M:%S')
        commit_message="Auto-commit Proxmox admin: $timestamp"
        printf '%s\n' '📝 Cambios detectados:'
        git diff --cached --stat
        comment=${PUSH_COMMIT_COMMENT:-}
        if [[ -z "$comment" && "${PUSH_ASK_COMMIT_COMMENT:-0}" == 1 && -t 0 ]]; then
            read -r -p '💬 Comentario opcional (Enter para continuar): ' comment
        fi
        [[ -n "$comment" ]] && commit_message="Auto-commit Proxmox admin: $comment"
        git commit -m "$commit_message" -q
    fi

    if [[ "$remote_branch" == true ]]; then
        if ! git rebase "origin/$BRANCH"; then
            printf '%sResuelve el conflicto y vuelve a ejecutar el script.%s\n' "$DIM" "$RESET"
            return 1
        fi
    fi

    if git rev-parse --verify HEAD >/dev/null 2>&1 && [[ "$remote_branch" == true ]]; then
        read -r behind ahead < <(git rev-list --left-right --count "origin/$BRANCH...HEAD")
        if [[ "$behind" == 0 && "$ahead" == 0 ]]; then
            ok 'Todo actualizado. Nada que enviar.'
            return
        fi
    fi
    info '📤 Enviando cambios...'
    git push -u origin "$BRANCH" || die 'No se pudieron enviar los cambios al repositorio'
    ok 'Sincronizado correctamente.'
}

show_repo() {
    if [[ -t 1 ]]; then
        printf '%s🌐 Repositorio: \033]8;;%s\a%s%s\033]8;;\a\n' "$CYAN" "$REPO_URL" "$REPO_URL" "$RESET"
    else
        printf '🌐 Repositorio: %s\n' "$REPO_URL"
    fi
}

acquire_lock
ensure_ssh_agent
ensure_repo
sync_changes
show_repo
