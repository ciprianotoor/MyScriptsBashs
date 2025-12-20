#!/bin/bash
# Generar alias automáticamente para todos los scripts en ~/MyScriptsBashs (para Zsh)
# Solo agrega/actualiza los alias de scripts, sin tocar otros aliases

SCRIPTS_DIR="$HOME/MyScriptsBashs"
ZSHRC="$HOME/.zshrc"

echo "🔄 Generando alias en $ZSHRC ..."

# Asegurarse que la carpeta existe
if [ ! -d "$SCRIPTS_DIR" ]; then
    echo "❌ Carpeta $SCRIPTS_DIR no encontrada. Crea la carpeta y agrega tus scripts."
    exit 1
fi

# Recorre todos los scripts .sh en la carpeta
for script in "$SCRIPTS_DIR"/*.sh; do
    [ -e "$script" ] || continue  # Salta si no hay scripts
    nombre=$(basename "$script" .sh)   # nombre sin extensión
    alias_cmd="alias $nombre='$script'"

    # Elimina alias viejo solo para este script
    sed -i "/^alias $nombre=/d" "$ZSHRC"

    # Agrega alias nuevo al final del archivo
    echo "$alias_cmd" >> "$ZSHRC"
    echo "✅ Alias creado: $nombre → $script"
done

# Actualiza alias maestro para listar solo los alias de scripts
# Primero eliminar línea vieja
sed -i '/^alias miscripts=/d' "$ZSHRC"
# Luego agregar línea nueva
echo "alias miscripts='grep \"^alias \" $ZSHRC | grep \"$SCRIPTS_DIR\"'" >> "$ZSHRC"

echo
echo "⚡ Listo. Recarga Zsh con: source ~/.zshrc"
