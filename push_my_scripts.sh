#!/usr/bin/env bash
# push_my_scripts.sh - Sincroniza MyScriptsBashs con GitHub automáticamente
# Mejoras: detección automática de ssh-agent, manejo de errores, mensajes claros

set -euo pipefail

REPO_DIR="/home/cipriano/MyScriptsBashs"
KEY="/home/cipriano/.ssh/id_ed25519"
REMOTE="git@github.com:ciprianotoor/MyScriptsBashs.git"
BRANCH="main"

# ------------------------------
# Función: activar ssh-agent y agregar clave
# ------------------------------
function ensure_ssh_agent() {
    if [ -z "${SSH_AUTH_SOCK:-}" ] || ! pgrep -u "$USER" ssh-agent >/dev/null 2>&1; then
        eval "$(ssh-agent -s)" >/dev/null
    fi

    if ! ssh-add -l | grep -q "$(ssh-keygen -lf "$KEY" | awk '{print $2}')" 2>/dev/null; then
        ssh-add "$KEY" >/dev/null 2>&1 || true
    fi
}

# ------------------------------
# Función: inicializar repositorio si no existe
# ------------------------------
function ensure_repo() {
    cd "$REPO_DIR"
    if [ ! -d .git ]; then
        git init
        git checkout -B "$BRANCH"
        git remote add origin "$REMOTE"
    fi

    git config user.name "cipriano"
    git config user.email "cipriano@users.noreply.github.com"
}

# ------------------------------
# Función: sincronizar cambios
# ------------------------------
function sync_changes() {
    git add --all

    if ! git diff --cached --quiet; then
        TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
        git commit -m "Auto-commit: cambios locales ($TIMESTAMP)"

        # Rebase para evitar conflictos simples
        if git pull --rebase origin "$BRANCH" 2>/dev/null; then
            echo "[INFO] Rebase exitoso"
        else
            echo "[WARN] No se pudo hacer rebase, continuar con push"
        fi

        git push -u origin "$BRANCH"
        echo "✅ Cambios sincronizados con GitHub a las $TIMESTAMP"
    else
        echo "🟢 No hay cambios para enviar."
    fi
}

# ------------------------------
# Ejecución
# ------------------------------
ensure_ssh_agent
ensure_repo
sync_changes
