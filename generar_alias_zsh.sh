#!/bin/bash
# Generar alias automáticamente para todos los scripts en ~/MyScriptsBashs (para Zsh)
# Limpia duplicados manteniendo la última definición

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

    # Elimina alias viejo si existe en .zshrc
    sed -i "/^alias $nombre=/d" "$ZSHRC"

    # Agrega alias nuevo
    echo "$alias_cmd" >> "$ZSHRC"
    echo "✅ Alias creado: $nombre → $script"
done

# Alias maestro para listar tus scripts, elimina duplicados primero
sed -i '/^alias miscripts=/d' "$ZSHRC"
echo "alias miscripts='grep \"^alias \" $ZSHRC'" >> "$ZSHRC"

# Limpiar duplicados de todos los aliases, manteniendo la última definición
grep '^alias ' "$ZSHRC" | tac | awk '!seen[$0]++' | tac > "$ZSHRC.aliases.tmp"
grep -v '^alias ' "$ZSHRC" > "$ZSHRC.noalias.tmp"
cat "$ZSHRC.noalias.tmp" "$ZSHRC.aliases.tmp" > "$ZSHRC.cleaned"
mv "$ZSHRC.cleaned" "$ZSHRC"
rm "$ZSHRC.noalias.tmp" "$ZSHRC.aliases.tmp"

echo
echo "⚡ Listo. Recarga Zsh con: source ~/.zshrc"
