#!/usr/bin/env bash
# push_my_scripts.sh
# Automatiza commit y push de MyScriptsBashs a GitHub desde Proxmox.

set -euo pipefail

REPO_DIR="/home/cipriano/MyScriptsBashs"
KEY="/home/cipriano/.ssh/id_ed25519"
REMOTE="git@github.com:ciprianotoor/MyScriptsBashs.git"
BRANCH="main"

# Activar ssh-agent y agregar clave si no está cargada
if ! pgrep -u "$USER" ssh-agent >/dev/null 2>&1; then
  eval "$(ssh-agent -s)" >/dev/null
fi

if ! ssh-add -l | grep -q "$(ssh-keygen -lf "$KEY" | awk '{print $2}')" 2>/dev/null; then
  ssh-add "$KEY" >/dev/null 2>&1 || true
fi

cd "$REPO_DIR"

# Inicializar repo si faltara
if [ ! -d .git ]; then
  git init
  git checkout -B "$BRANCH"
  git remote add origin "$REMOTE"
fi

git config user.name "cipriano"
git config user.email "cipriano@users.noreply.github.com"

# Agregar y hacer commit solo si hay cambios
git add --all
if ! git diff --cached --quiet; then
  TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  git commit -m "Auto-commit: cambios locales ($TIMESTAMP)"
  git pull --rebase origin "$BRANCH" 2>/dev/null || true
  git push -u origin "$BRANCH"
  echo "✅ Cambios sincronizados con GitHub a las $TIMESTAMP"
else
  echo "🟢 No hay cambios para enviar."
fi
