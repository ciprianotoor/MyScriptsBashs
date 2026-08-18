#!/usr/bin/env bash
# Copia la configuración tuneada de Nano al usuario actual (no root).
set -Eeuo pipefail
(( EUID != 0 )) || { echo '❌ Ejecuta este script con el usuario normal, no como root.' >&2; exit 1; }
REPO_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
SOURCE="$REPO_DIR/.nanorc"; TARGET="$HOME/.nanorc"; STAMP=$(date +%Y%m%d-%H%M%S)
[[ -f "$SOURCE" ]] || { echo "❌ No existe la configuración: $SOURCE" >&2; exit 1; }
if [[ -e "$TARGET" || -L "$TARGET" ]]; then mv -- "$TARGET" "${TARGET}.backup-${STAMP}"; echo "📦 Respaldo creado: ${TARGET}.backup-${STAMP}"; fi
install -m 600 "$SOURCE" "$TARGET"
echo "✅ Configuración de Nano aplicada a $TARGET"
