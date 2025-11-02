#!/bin/bash
# Generar alias automáticamente para todos los scripts en ~/MyScriptsBashs

SCRIPTS_DIR="$HOME/MyScriptsBashs"
BASHRC="$HOME/.bashrc"

echo "🔄 Generando alias en $BASHRC ..."

# Recorre todos los scripts en la carpeta
for script in "$SCRIPTS_DIR"/*.sh; do
    nombre=$(basename "$script" .sh)   # nombre sin extensión
    alias_cmd="alias $nombre='$script'"

    # Elimina alias viejo si existe en .bashrc
    sed -i "/alias $nombre=/d" "$BASHRC"

    # Agrega alias nuevo
    echo "$alias_cmd" >> "$BASHRC"
    echo "✅ Alias creado: $nombre → $script"
done

echo
echo "⚡ Recarga tu bashrc con: source ~/.bashrc"
