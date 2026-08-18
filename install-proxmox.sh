#!/usr/bin/env bash
# Instala el entorno de scripts y dotfiles de este repositorio en un host Proxmox VE.
# Uso: ./install-proxmox.sh

set -Eeuo pipefail

REPO_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
TARGET_HOME=${HOME:?No se pudo determinar HOME}
STAMP=$(date +%Y%m%d-%H%M%S)

log() { printf '\033[1;32m[proxmox-install]\033[0m %s\n' "$*"; }
die() { printf '\033[1;31mError:\033[0m %s\n' "$*" >&2; exit 1; }

[[ -f /etc/pve/.version ]] || command -v pveversion >/dev/null 2>&1 \
  || die "Este instalador es exclusivo para un host Proxmox VE."

if (( EUID == 0 )); then
  [[ -n "${SUDO_USER:-}" && "$SUDO_USER" != root ]] \
    || die "Ejecuta este script como tu usuario normal usando sudo cuando sea necesario, no como root."
  TARGET_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
fi
ZSH_DIR="$TARGET_HOME/.zsh"
TARGET_USER=${SUDO_USER:-$(id -un)}
TARGET_GROUP=$(id -gn "$TARGET_USER")

if command -v sudo >/dev/null 2>&1; then
  SUDO=(sudo)
elif (( EUID == 0 )); then
  SUDO=()
else
  die "Se necesita sudo para instalar dependencias."
fi

backup_if_needed() {
  local destination=$1
  if [[ -e "$destination" || -L "$destination" ]]; then
    mv -- "$destination" "${destination}.backup-${STAMP}"
    log "Respaldo creado: ${destination}.backup-${STAMP}"
  fi
}

link_repo_file() {
  local source=$1 destination=$2
  [[ -f "$source" ]] || die "Falta el archivo del repositorio: $source"
  if [[ -L "$destination" && "$(readlink -f "$destination")" == "$source" ]]; then
    return
  fi
  backup_if_needed "$destination"
  ln -s -- "$source" "$destination"
}

clone_or_update() {
  local url=$1 destination=$2
  if [[ -d "$destination/.git" ]]; then
    git -C "$destination" pull --ff-only --quiet || log "No se pudo actualizar $destination; se conserva la versión local."
  elif [[ -e "$destination" ]]; then
    die "La ruta existe pero no es un repositorio Git: $destination"
  else
    git clone --depth=1 --quiet "$url" "$destination"
  fi
}

log "Verificando dependencias del host Proxmox..."
"${SUDO[@]}" apt-get update -qq
"${SUDO[@]}" apt-get install -y --no-install-recommends \
  git zsh curl nano less lsd fzf bat tree tmux openssh-client \
  iproute2 iputils-ping procps util-linux hostname debianutils \
  gawk sed grep coreutils timeshift

mkdir -p "$ZSH_DIR/plugins"
clone_or_update https://github.com/romkatv/powerlevel10k.git "$ZSH_DIR/powerlevel10k"
clone_or_update https://github.com/zsh-users/zsh-autosuggestions.git "$ZSH_DIR/plugins/zsh-autosuggestions"
clone_or_update https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_DIR/plugins/zsh-syntax-highlighting"
clone_or_update https://github.com/zsh-users/zsh-completions.git "$ZSH_DIR/plugins/zsh-completions"

link_repo_file "$REPO_DIR/.zshrc" "$TARGET_HOME/.zshrc"
link_repo_file "$REPO_DIR/.p10k.zsh" "$TARGET_HOME/.p10k.zsh"
link_repo_file "$REPO_DIR/.nanorc" "$TARGET_HOME/.nanorc"

chown -h "$TARGET_USER:$TARGET_GROUP" \
  "$TARGET_HOME/.zshrc" "$TARGET_HOME/.p10k.zsh" "$TARGET_HOME/.nanorc" 2>/dev/null || true

log "Instalación completada."
log "Repositorio usado: $REPO_DIR"
log "Abre una nueva sesión Zsh o ejecuta: exec zsh"
log "Tus archivos anteriores quedaron como *.backup-$STAMP"
