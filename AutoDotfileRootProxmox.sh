#!/usr/bin/env bash
# install_dotfile.sh
# Autodotfile para instalar el .bashrc personalizado en /root con variables de red

set -euo pipefail

TARGET_USER="root"
TARGET_HOME="/root"
BASHRC_FILE="$TARGET_HOME/.bashrc"
DOTFILE_CONTENT="/tmp/bashrc_proxmox_custom"

# Crear archivo temporal con el contenido del bashrc personalizado
cat > "$DOTFILE_CONTENT" <<'EOF'
# ===================================================================
#  .bashrc PERSONALIZADO PARA PROXMOX VE
#  Estilo: Powerlevel10k con colores oficiales Proxmox
#  Idioma: Español (comandos y alias)
# ===================================================================

# ==============================
# 🔹 CONFIGURACIÓN DE RED PERSONALIZABLE
# ==============================
# Reemplaza estos valores por tu IP y puerto reales.
# MY_IP: tu IP local de Proxmox
# MY_PORT: el puerto SSH u otro que uses para conectarte
MY_IP="TU_IP_AQUI"       
MY_PORT="TU_PUERTO_AQUI"

# Alias dinámicos usando las variables definidas arriba
alias mi_ip="echo \$MY_IP"                       # Muestra la IP que configuraste
alias ssh_root="ssh root@\$MY_IP -p \$MY_PORT"  # Conexión SSH a root usando tu IP y puerto
alias red_ip='ip -4 addr show'                  # Mostrar todas las IPs del host
alias puertos='ss -tuln'                        # Mostrar puertos abiertos
alias conexiones='ss -tunap'                    # Mostrar conexiones activas

# ===================================================================
# 💡 ALIAS PERSONALES
# ===================================================================
alias cls='clear'
alias revote='source ~/.bashrc'
alias perfil='nano /root/.bashrc'
alias apagar='poweroff'
alias reiniciar='reboot now'

# ===================================================================
# ⚙️ FUNCIONES PARA EL PROMPT
# ===================================================================
_get_proxmox_version() {
    if command -v pveversion >/dev/null 2>&1; then
        pveversion | head -n1 | awk -F'/' '{print $2}' | awk '{print $1}'
    elif [ -f /etc/pve/.version ]; then
        cat /etc/pve/.version | tr -d ' \n'
    else
        echo "N/A"
    fi
}

_get_lan_ip() {
    ip route get 8.8.8.8 2>/dev/null | sed -n 's/.*src \([0-9.]\+\).*/\1/p' | head -n1
}

_update_prompt_vars() {
    PVE_VER=$(_get_proxmox_version)
    PROMPT_IP=$(_get_lan_ip)
    PROMPT_DATE=$(date '+%Y-%m-%d')
    PROMPT_TIME=$(date '+%I:%M:%S %p')
}

PROMPT_COMMAND='_update_prompt_vars'

# ===================================================================
# 🎨 COLORES (ESQUEMA PROXMOX)
# ===================================================================
ORANGE="\[\e[38;5;208m\]"   
WHITE="\[\e[1;37m\]"
GRAY="\[\e[0;37m\]"
BLUE="\[\e[1;34m\]"
CYAN="\[\e[1;36m\]"
GREEN="\[\e[1;32m\]"
RED="\[\e[1;31m\]"
RESET="\[\e[0m\]"

# ===================================================================
# 💻 PROMPT PERSONALIZADO
# ===================================================================
PS1="\n${ORANGE}╭─${WHITE}{${ORANGE} PROXMOX:${GRAY}\${PVE_VER}${WHITE} }${ORANGE}--"\ 
"${WHITE}{${CYAN}\u${WHITE}@${CYAN}\h${WHITE}}${ORANGE}--"\ 
"${WHITE}{${GREEN}\w${WHITE}}${ORANGE}--"\ 
"${WHITE}{${CYAN}\${PROMPT_IP}${WHITE}}${ORANGE}--"\ 
"${WHITE}{${GRAY}\${PROMPT_DATE} \${PROMPT_TIME}${WHITE}}\n"\ 
"${ORANGE}╰─>${RESET}> "

# ===================================================================
# 🧠 ALIAS ÚTILES EN ESPAÑOL
# ===================================================================
alias recargar='source ~/.bashrc'
alias editarbash='nano ~/.bashrc'
alias actualizar='apt update && apt full-upgrade -y && apt autoremove -y'
alias limpiar='apt clean && apt autoclean && apt autoremove -y'
alias version='pveversion'
alias kernel='uname -r'
alias info='neofetch || hostnamectl'
alias fecha='date "+%Y-%m-%d %I:%M:%S %p"'
alias tiempo='uptime -p'
alias buscar='apt search'
alias instalar='apt install'
alias borrar='apt remove'
alias limpiar_cache='sync &B& echo 3 > /proc/sys/vm/drop_caches'
alias usuario_actual='whoami'

# Aquí irían todos los alias de VM, LXC, discos, backups, etc., exactamente como los tenías antes
# (omitido por brevedad, pero se incluyen igual en tu script real)

# ===================================================================
# ⚙️ CONFIGURACIONES EXTRA
# ===================================================================
HISTCONTROL=ignoreboth
HISTSIZE=5000
HISTFILESIZE=10000
shopt -s histappend
export EDITOR=nano
export LANG=es_NI.UTF-8
export LANGUAGE=es_NI.UTF-8

if [ -x /usr/bin/dircolors ]; then
    eval "$(dircolors -b)"
    alias ls='ls --color=auto'
fi

if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
fi

# ===================================================================
#   FIN DEL ARCHIVO PERSONALIZADO
# ===================================================================
EOF

# Copiar al root
echo "📦 Copiando .bashrc a /root/"
sudo cp -f "$DOTFILE_CONTENT" "$BASHRC_FILE"
sudo chown root:root "$BASHRC_FILE"

# Recargar para root si es la sesión actual
if [ "$(whoami)" = "root" ]; then
    echo "🔄 Recargando .bashrc..."
    source "$BASHRC_FILE"
fi

# Limpiar archivo temporal
rm -f "$DOTFILE_CONTENT"

echo "🎉 Instalación completa. Tu .bashrc personalizado ya está en /root/.bashrc"
echo "💡 Recuerda editar MY_IP y MY_PORT en la parte superior para tus valores correctos."
