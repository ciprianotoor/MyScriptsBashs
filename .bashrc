# ===================================================================
#  .bashrc PERSONALIZADO PARA PROXMOX VE (BASH PURO)
# ===================================================================

# ==============================
# COLORES
# ==============================
ORANGE="\[\e[38;5;208m\]"
WHITE="\[\e[1;37m\]"
GRAY="\[\e[0;37m\]"
CYAN="\[\e[1;36m\]"
GREEN="\[\e[1;32m\]"
RED="\[\e[1;31m\]"
RESET="\[\e[0m\]"

# ==============================
# CONFIGURACIÓN DE RED
# ==============================
MY_IP="TU_IP_AQUI"
MY_PORT="TU_PUERTO_AQUI"

alias mi_ip='echo $MY_IP'
alias ssh_root='ssh root@$MY_IP -p $MY_PORT'
alias red_ip='ip -4 addr show'
alias puertos='ss -tuln'
alias conexiones='ss -tunap'

# ==============================
# ALIAS BÁSICOS
# ==============================
alias cls='clear'
alias recargar='source ~/.bashrc'
alias editarbash='nano ~/.bashrc'
alias apagar='poweroff'
alias reiniciar='reboot'
alias actualizar='apt update && apt full-upgrade -y && apt autoremove -y'
alias limpiar='apt clean && apt autoremove -y'
alias version='pveversion'
alias kernel='uname -r'
alias fecha='date "+%Y-%m-%d %H:%M:%S"'
alias tiempo='uptime -p'

# ==============================
# FUNCIONES PROXMOX
# ==============================
_get_proxmox_version() {
    command -v pveversion >/dev/null 2>&1 && \
    pveversion | awk -F'/' '{print $2}' | awk '{print $1}'
}

_get_lan_ip() {
    ip route get 8.8.8.8 2>/dev/null \
    | awk '/src/ {print $7; exit}'
}

# ==============================
# PROMPT DINÁMICO
# ==============================
_update_prompt() {
    local PVE_VER="$(_get_proxmox_version)"
    local IP="$(_get_lan_ip)"
    local DATE="$(date '+%d/%m/%Y %H:%M:%S')"

    PS1="\n${ORANGE}╭─${WHITE}{${ORANGE}PROXMOX:${GRAY}${PVE_VER}${WHITE}}\
${ORANGE}--${WHITE}{${CYAN}\u@\h${WHITE}}\
${ORANGE}--${WHITE}{${GREEN}\w${WHITE}}\
${ORANGE}--${WHITE}{${CYAN}${IP}${WHITE}}\
${ORANGE}--${WHITE}{${GRAY}${DATE}${WHITE}}\
\n${ORANGE}╰─>${RESET} "
}

PROMPT_COMMAND=_update_prompt

# ==============================
# HISTORIAL
# ==============================
HISTCONTROL=ignoreboth
HISTSIZE=5000
HISTFILESIZE=10000
shopt -s histappend

# ==============================
# AUTOCOMPLETADO
# ==============================
bind 'set show-all-if-ambiguous on'
bind 'set completion-ignore-case on'
bind 'TAB:menu-complete'

# Bash completion
if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
fi

# ==============================
# ENTORNO
# ==============================
export EDITOR=nano
export LANG=es_NI.UTF-8
export LANGUAGE=es_NI.UTF-8

# Colores en ls
if command -v dircolors >/dev/null 2>&1; then
    eval "$(dircolors -b)"
    alias ls='ls --color=auto'
fi