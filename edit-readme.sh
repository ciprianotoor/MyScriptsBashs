#!/usr/bin/env bash
# Editor seguro para el README del repositorio.

set -Eeuo pipefail

REPO_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
README_FILE="$REPO_DIR/README.md"
EDITOR_CMD="${EDITOR:-nano}"

[[ -f "$README_FILE" ]] || { echo "❌ No existe $README_FILE" >&2; exit 1; }
command -v "$EDITOR_CMD" >/dev/null 2>&1 || {
  echo "❌ No se encontró el editor: $EDITOR_CMD" >&2
  exit 1
}

"$EDITOR_CMD" "$README_FILE"

if grep -nE '^(<<<<<<<|=======|>>>>>>>)' "$README_FILE"; then
  echo '⚠ Se detectaron marcadores de conflicto en el README.'
  exit 1
fi

echo '✅ README revisado sin marcadores de conflicto.'
if git -C "$REPO_DIR" diff --quiet -- README.md; then
  echo '🟢 No hay cambios pendientes en README.md.'
else
  echo '📝 README.md tiene cambios pendientes.'
  git -C "$REPO_DIR" diff --stat -- README.md
  echo 'Para guardarlos en GitHub, ejecuta: push_my_scripts'
fi
