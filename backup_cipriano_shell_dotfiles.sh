#!/usr/bin/env bash
# backup_cipriano_shell_dotfiles.sh
# Respalda todos los dotfiles de Bash y Zsh de cipriano

set -euo pipefail

USER_HOME="/home/cipriano"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="$USER_HOME/dotfiles_backup_$DATE"

# Crear directorio de backup
mkdir -p "$BACKUP_DIR"

echo "📦 Respaldando dotfiles de Bash y Zsh de $USER_HOME..."

# Buscar todos los archivos .bash* y .zsh* (archivos y directorios)
DOTFILES=($(find "$USER_HOME" -maxdepth 1 -name ".bash*" -o -name ".zsh*"))

# Copiar cada uno al backup
for file in "${DOTFILES[@]}"; do
    BASENAME=$(basename "$file")
    if [ -e "$file" ]; then
        if [ -d "$file" ]; then
            cp -rp "$file" "$BACKUP_DIR/"
        else
            cp -p "$file" "$BACKUP_DIR/"
        fi
        echo "✅ Respaldado: $BASENAME"
    fi
done

echo "🎉 Respaldo completo en: $BACKUP_DIR"
