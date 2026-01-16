#!/usr/bin/env sh
# backup_cipriano_shell_dotfiles_sh.sh
# Respalda todos los dotfiles de Bash y Zsh de cipriano
# Compatible con sh y bash

USER_HOME="/home/cipriano/MyScriptsBashs"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="$USER_HOME/dotfiles_backup_$DATE"

# Crear directorio de backup
mkdir -p "$BACKUP_DIR"

echo "📦 Respaldando dotfiles de Bash y Zsh de $USER_HOME..."

# Respaldar todos los archivos .bash* y .zsh* (archivos y directorios)
for file in "$USER_HOME"/.bash* "$USER_HOME"/.zsh*; do
    # Verificar que exista realmente
    if [ -e "$file" ]; then
        BASENAME=$(basename "$file")
        if [ -d "$file" ]; then
            cp -rp "$file" "$BACKUP_DIR/"
        else
            cp -p "$file" "$BACKUP_DIR/"
        fi
        echo "✅ Respaldado: $BASENAME"
    fi
done

echo "🎉 Respaldo completo en: $BACKUP_DIR"
