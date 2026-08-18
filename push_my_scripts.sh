#!/usr/bin/env bash
set -euo pipefail

# ==================================================
# Sincronización automática GitHub - Proxmox admin
# ==================================================

REPO_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
KEY="${PUSH_SSH_KEY:-$HOME/.ssh/id_ed25519}"
REMOTE="${PUSH_REMOTE:-git@github.com:ciprianotoor/MyScriptsBashs.git}"
BRANCH="${PUSH_BRANCH:-main}"
REPO_URL="${PUSH_REPO_URL:-https://github.com/ciprianotoor/MyScriptsBashs}"

if [[ -t 1 ]]; then
    GREEN=$'\033[1;32m'; CYAN=$'\033[1;36m'; YELLOW=$'\033[1;33m'; DIM=$'\033[2m'; RESET=$'\033[0m'
else
    GREEN=''; CYAN=''; YELLOW=''; DIM=''; RESET=''
fi

info() { printf '%s%s%s\n' "$CYAN" "$*" "$RESET"; }
ok() { printf '%s✅ %s%s\n' "$GREEN" "$*" "$RESET"; }
warn() { printf '%s⚠ %s%s\n' "$YELLOW" "$*" "$RESET"; }

# --------------------------------------------------
# SSH Agent
# --------------------------------------------------

ensure_ssh_agent() {

    CURRENT_USER=${USER:-$(id -un)}
    if [ -z "${SSH_AUTH_SOCK:-}" ] || ! pgrep -u "$CURRENT_USER" ssh-agent >/dev/null; then
        eval "$(ssh-agent -s)" >/dev/null
    fi

    if [ -f "$KEY" ]; then

        KEY_HASH=$(ssh-keygen -lf "$KEY" | awk '{print $2}')

        if ! ssh-add -l 2>/dev/null | grep -q "$KEY_HASH"; then
            ssh-add "$KEY" >/dev/null 2>&1
        fi

    else
            printf '%s❌ No existe la clave SSH: %s%s\n' "$YELLOW" "$KEY" "$RESET"
        exit 1
    fi
}


# --------------------------------------------------
# Preparar repositorio
# --------------------------------------------------

ensure_repo() {

    if [ ! -d "$REPO_DIR" ]; then
        printf '%s❌ No existe %s%s\n' "$YELLOW" "$REPO_DIR" "$RESET"
        exit 1
    fi

    cd "$REPO_DIR"

    if [ ! -d ".git" ]; then
        info '📦 Inicializando repositorio...'
        git init -q
        git remote add origin "$REMOTE"
    fi


    git config user.name "cipriano"
    git config user.email "cipriano@users.noreply.github.com"

}


# --------------------------------------------------
# Sincronizar
# --------------------------------------------------

sync_changes() {

    cd "$REPO_DIR"

    git add --all


    if ! git diff --cached --quiet; then

        TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

        git commit \
        -m "Auto-commit Proxmox admin: $TIMESTAMP" \
        -q


        info '📥 Actualizando remoto...'

        if ! git pull --rebase origin "$BRANCH"; then
            printf '%s❌ No se pudo actualizar desde el remoto; revisa el conflicto antes de continuar.%s\n' "$YELLOW" "$RESET"
            exit 1
        fi


        info '📤 Enviando cambios...'

        git push -u origin "$BRANCH"


        ok "Sincronizado: $TIMESTAMP"

    else

        ok 'Todo actualizado. Nada que enviar.'
        printf '%sPuedes abrir el repositorio aquí: %s%s\n' "$DIM" "$REPO_URL" "$RESET"
        printf '%sPara abrirlo desde la terminal: xdg-open %q%s\n' "$DIM" "$REPO_URL" "$RESET"

    fi
}


# --------------------------------------------------
# Mostrar repo
# --------------------------------------------------

show_repo() {

    printf '%s🌐 Repositorio: %s%s\n' "$CYAN" "$RESET" "$RESET"
    # OSC 8 crea un enlace clicable en terminales que lo soportan.
    printf '\033]8;;%s\a%s%s%s\033]8;;\a\n' "$REPO_URL" "$CYAN" "$REPO_URL" "$RESET"

}


# --------------------------------------------------
# Ejecución
# --------------------------------------------------

ensure_ssh_agent
ensure_repo
sync_changes
show_repo
