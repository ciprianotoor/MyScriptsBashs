#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

### 1. Actualizar, almacenamiento y modo silencioso de login
apt update -y
apt upgrade -y
termux-setup-storage
touch "$HOME/.hushlogin"

### 2. Instalaciones base
pkg install -y git micro zsh bat lsd curl

### 3. Instalar Oh My Zsh
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)" "" --unattended
fi

### 4. Instalar Powerlevel10k
if [ ! -d "$HOME/powerlevel10k" ]; then
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$HOME/powerlevel10k"
fi

if ! grep -q "powerlevel10k.zsh-theme" "$HOME/.zshrc"; then
  echo 'source ~/powerlevel10k/powerlevel10k.zsh-theme' >> "$HOME/.zshrc"
fi

### 5. Zsh autosuggestions
mkdir -p "$HOME/.plugins/zsh-autosuggestions"
if [ ! -d "$HOME/.plugins/zsh-autosuggestions/.git" ]; then
  git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions.git \
    "$HOME/.plugins/zsh-autosuggestions"
fi

if ! grep -q "zsh-autosuggestions.zsh" "$HOME/.zshrc"; then
  echo 'source ~/.plugins/zsh-autosuggestions/zsh-autosuggestions.zsh' >> "$HOME/.zshrc"
fi

### 6. Zsh syntax highlighting
mkdir -p "$HOME/.plugins/zsh-syntax-highlighting"
if [ ! -d "$HOME/.plugins/zsh-syntax-highlighting/.git" ]; then
  git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git \
    "$HOME/.plugins/zsh-syntax-highlighting"
fi

if ! grep -q "zsh-syntax-highlighting.zsh" "$HOME/.zshrc"; then
  echo 'source ~/.plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh' >> "$HOME/.zshrc"
fi

### 7. Extra keys (termux.properties)
mkdir -p "$HOME/.termux"

cat > "$HOME/.termux/termux.properties" << 'EOF'
extra-keys = [
 ['ESC','|','-', {key: HOME, display: 'INC'},'UP',{key: END, display: 'FIN'}, 'APOSTROPHE', {macro: "clear ENTER", display: '×'}],
 ['TAB','CTRL','BACKSLASH','LEFT','DOWN','RIGHT','KEYBOARD','DEL']
]
EOF

### 8. Colores (colors.properties)
cat > "$HOME/.termux/colors.properties" << 'EOF'
color0=#303030
color1=#a87139
color2=#6AEB36
color3=#71a839
color4=#7139a8
color5=#a83971
color6=#3971a8
color7=#8a8a8a
color8=#494949
color9=#EE146F
color10=#3bb076
color11=#76b03b
color12=#6F6FFC
color13=#b03b76
color14=#3b76b0
color15=#cfcfcf
background=#1A1A1E
foreground=#d9e6f2
cursor=#d9e6f2
EOF

### 9. Recargar configuración de Termux
termux-reload-settings

echo "Instalación completada."
echo "Abra una nueva terminal para ejecutar: p10k configure"
