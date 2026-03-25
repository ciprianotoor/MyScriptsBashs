#!/usr/bin/env bash
set -euo pipefail

# --- Variables ---
REPO_DIR="/home/cipriano/MyScriptsBashs"
KEY="/home/cipriano/.ssh/id_ed25519"
REMOTE="git@github.com:ciprianotoor/MyScriptsBashs.git"
BRANCH="main"
REPO_URL="https://github.com/ciprianotoor/MyScriptsBashs"

function ensure_ssh_agent() {
    if [ -z "${SSH_AUTH_SOCK:-}" ] || ! pgrep -u "$USER" ssh-agent >/dev/null; then
        eval "$(ssh-agent -s)" >/dev/null
    fi
    # Añadir clave solo si no está presente
    ssh-add -l | grep -q "$(ssh-keygen -lf "$KEY" | awk '{print $2}')" 2>/dev/null || ssh-add "$KEY" >/dev/null 2>&1
}

function ensure_repo() {
    [ ! -d "$REPO_DIR" ] && echo "❌ Directorio no encontrado" && exit 1
    cd "$REPO_DIR"
    
    if [ ! -d .git ]; then
        git init -q
        git remote add origin "$REMOTE"
    fi
    git config user.name "cipriano"
    git config user.email "cipriano@users.noreply.github.com"
}

function sync_changes() {
    cd "$REPO_DIR"
    git add --all

    if ! git diff --cached --quiet; then
        TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
        git commit -m "Auto-commit: $TIMESTAMP" -q

        if git pull --rebase origin "$BRANCH" -q 2>/dev/null; then
            echo "📥 [INFO] Sincronizado con remoto (Rebase)"
        fi

        git push -u origin "$BRANCH" -q
        echo "✅ Cambios enviados a GitHub: $TIMESTAMP"
    else
        echo "🟢 Todo actualizado. Nada que enviar."
    fi
}

function open_github() {
    if [ -n "${SSH_CONNECTION:-}" ]; then
        echo "🌐 URL del repo: $REPO_URL"
    else
        if command -v microsoft-edge >/dev/null 2>&1; then
            microsoft-edge "$REPO_URL" >/dev/null 2>&1 &
            echo "🌐 Abriendo Edge..."
        else
            echo "🌐 URL: $REPO_URL"
        fi
    fi
}

ensure_ssh_agent
ensure_repo
sync_changes
open_github