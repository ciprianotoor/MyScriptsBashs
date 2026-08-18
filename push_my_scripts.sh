#!/usr/bin/env bash
set -euo pipefail

# ==================================================
# Sincronización automática GitHub - Proxmox admin
# ==================================================

REPO_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
KEY="$HOME/.ssh/id_ed25519"
REMOTE="git@github.com:ciprianotoor/MyScriptsBashs.git"
BRANCH="main"
REPO_URL="https://github.com/ciprianotoor/MyScriptsBashs"

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
        echo "❌ No existe la clave SSH: $KEY"
        exit 1
    fi
}


# --------------------------------------------------
# Preparar repositorio
# --------------------------------------------------

ensure_repo() {

    if [ ! -d "$REPO_DIR" ]; then
        echo "❌ No existe $REPO_DIR"
        exit 1
    fi

    cd "$REPO_DIR"

    if [ ! -d ".git" ]; then
        echo "📦 Inicializando repositorio..."
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


        echo "📥 Actualizando remoto..."

        if ! git pull --rebase origin "$BRANCH"; then
            echo "❌ No se pudo actualizar desde el remoto; revisa el conflicto antes de continuar."
            exit 1
        fi


        echo "📤 Enviando cambios..."

        git push -u origin "$BRANCH"


        echo "✅ Sincronizado: $TIMESTAMP"

    else

        echo "🟢 Todo actualizado. Nada que enviar."

    fi
}


# --------------------------------------------------
# Mostrar repo
# --------------------------------------------------

show_repo() {

    echo "🌐 Repo:"
    echo "$REPO_URL"

}


# --------------------------------------------------
# Ejecución
# --------------------------------------------------

ensure_ssh_agent
ensure_repo
sync_changes
show_repo
