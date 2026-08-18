#!/usr/bin/env bash
# Copia el .bashrc Proxmox tuneado al usuario actual (no root).
set -Eeuo pipefail
(( EUID != 0 )) || { echo '❌ Ejecuta este script con el usuario normal, no como root.' >&2; exit 1; }
REPO_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
SOURCE="$REPO_DIR/.bashrc"; TARGET="$HOME/.bashrc"; STAMP=$(date +%Y%m%d-%H%M%S)
[[ -f "$SOURCE" ]] || { echo "❌ No existe la configuración: $SOURCE" >&2; exit 1; }
bash -n "$SOURCE" || { echo '❌ El .bashrc no supera la validación de Bash.' >&2; exit 1; }
if [[ -e "$TARGET" || -L "$TARGET" ]]; then mv -- "$TARGET" "${TARGET}.backup-${STAMP}"; echo "📦 Respaldo creado: ${TARGET}.backup-${STAMP}"; fi
install -m 600 "$SOURCE" "$TARGET"
echo "✅ Configuración de Bash aplicada a $TARGET"
echo 'ℹ Abre una nueva sesión Bash o ejecuta: source ~/.bashrc'
