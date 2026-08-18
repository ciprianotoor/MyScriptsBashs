#!/usr/bin/env bash
# Copia el .bashrc Proxmox tuneado al usuario root.

set -Eeuo pipefail

REPO_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
SOURCE="$REPO_DIR/.bashrc"
TARGET=/root/.bashrc
STAMP=$(date +%Y%m%d-%H%M%S)

[[ -f "$SOURCE" ]] || { echo "❌ No existe la configuración: $SOURCE" >&2; exit 1; }
bash -n "$SOURCE" || { echo '❌ El .bashrc no supera la validación de Bash.' >&2; exit 1; }
sudo -v

if sudo test -e "$TARGET" || sudo test -L "$TARGET"; then
  BACKUP="${TARGET}.backup-${STAMP}"
  sudo mv -- "$TARGET" "$BACKUP"
  echo "📦 Respaldo creado: $BACKUP"
fi

sudo install -o root -g root -m 600 "$SOURCE" "$TARGET"
echo "✅ Configuración de Bash copiada a $TARGET"
echo 'ℹ Para aplicarla en una sesión root: sudo -i'
