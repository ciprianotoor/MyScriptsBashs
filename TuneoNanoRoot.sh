#!/usr/bin/env bash
# Copia la configuración tuneada de Nano al usuario root.

set -Eeuo pipefail

REPO_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
SOURCE="$REPO_DIR/.nanorc"
TARGET=/root/.nanorc
STAMP=$(date +%Y%m%d-%H%M%S)

[[ -f "$SOURCE" ]] || { echo "❌ No existe la configuración: $SOURCE" >&2; exit 1; }
sudo -v

if sudo test -e "$TARGET" || sudo test -L "$TARGET"; then
  BACKUP="${TARGET}.backup-${STAMP}"
  sudo mv -- "$TARGET" "$BACKUP"
  echo "📦 Respaldo creado: $BACKUP"
fi

sudo install -o root -g root -m 600 "$SOURCE" "$TARGET"
echo "✅ Configuración de Nano copiada a $TARGET"
echo 'ℹ Para comprobarla: sudo nano /root/.nanorc'
