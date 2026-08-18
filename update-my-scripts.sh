#!/usr/bin/env bash
# Descarga cambios del repositorio sin sobrescribir modificaciones locales.

set -Eeuo pipefail

REPO_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
BRANCH="${PULL_BRANCH:-main}"
REMOTE="${PULL_REMOTE:-origin}"

if [[ -t 1 ]]; then
  GREEN=$'\033[1;32m'; CYAN=$'\033[1;36m'; YELLOW=$'\033[1;33m'; RESET=$'\033[0m'
else
  GREEN=''; CYAN=''; YELLOW=''; RESET=''
fi

cd "$REPO_DIR"
[[ -d .git ]] || { printf '%s❌ No es un repositorio Git: %s%s\n' "$YELLOW" "$REPO_DIR" "$RESET"; exit 1; }

if [[ -n "$(git status --porcelain)" ]]; then
  printf '%s⚠ Hay cambios locales pendientes en el repositorio.%s\n' "$YELLOW" "$RESET"
  git status --short
  printf '%sNo se descargó nada para evitar sobrescribirlos.%s\n' "$YELLOW" "$RESET"
  exit 1
fi

printf '%s🔄 Buscando cambios en %s/%s...%s\n' "$CYAN" "$REMOTE" "$BRANCH" "$RESET"
BEFORE=$(git rev-parse HEAD)
if ! git pull --ff-only "$REMOTE" "$BRANCH"; then
  printf '%s❌ No se pudo actualizar con fast-forward. Revisa el estado manualmente.%s\n' "$YELLOW" "$RESET"
  exit 1
fi
AFTER=$(git rev-parse HEAD)

if [[ "$BEFORE" == "$AFTER" ]]; then
  printf '%s✅ Ya estaba actualizado.%s\n' "$GREEN" "$RESET"
else
  printf '%s✅ Actualización completada.%s\n' "$GREEN" "$RESET"
  git --no-pager log --oneline --decorate "$BEFORE..$AFTER"
  printf '%sRecarga Zsh con: exec zsh%s\n' "$CYAN" "$RESET"
fi
