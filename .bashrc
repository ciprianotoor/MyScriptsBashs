# ===================================================================
#  .bashrc PERSONALIZADO PARA PROXMOX VE (root)
#  Idioma: Español
# ===================================================================

# ==============================
# CONFIGURACIÓN DE RED
# ==============================
MY_IP="TU_IP_AQUI"
MY_PORT="TU_PUERTO_AQUI"

alias mi_ip="echo $MY_IP"
alias ssh_root="ssh root@$MY_IP -p $MY_PORT"
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
alias reiniciar='reboot now'

# ==============================
# FUNCIONES PROXMOX
# ==============================
_get_proxmox_version() {
    if command -v pveversion >/dev/null 2>&1; then
        pveversion | head -n1 | awk -F'/' '{print $2}' | awk '{print $1}'
    elif [ -f /etc/pve/.version ]; then
        tr -d ' \n' </etc/pve/.version
    else
        echo "N/A"
    fi
}

_get_lan_ip() {
    ip route get 8.8.8.8 2>/dev/null \
    | sed -n 's/.*src \([0-9.]\+\).*/\1/p' | head -n1
}

_update_prompt_vars() {
    PVE_VER=$(_get_proxmox_version)
    PROMPT_IP=$(_get_lan_ip)
    PROMPT_DATE=$(date '+%d/%m/%Y')
    PROMPT_TIME=$(date '+%I:%M:%S %p')
    LAST_CMD=$(fc -ln -1 2>/dev/null | sed 's/^[ \t]*//' | head -n1)
    [ -z "$LAST_CMD" ] && LAST_CMD="Ninguno"
    UPDATES=$(apt list --upgradable 2>/dev/null | grep -c '/')
    PS1="\n${ORANGE}╭─${WHITE}{${ORANGE}PROXMOX:${GRAY}${PVE_VER}${WHITE}}${ORANGE}--${WHITE}{${CYAN}\u@${CYAN}\h${WHITE}}${ORANGE}--${WHITE}{${GREEN}\w${WHITE}}${ORANGE}--${WHITE}{${CYAN}${PROMPT_IP}${WHITE}}${ORANGE}--${WHITE}{${GRAY}${PROMPT_DATE} ${PROMPT_TIME}${WHITE}}${ORANGE}--${WHITE}{${GREEN}${LAST_CMD}${WHITE}}${ORANGE}--${WHITE}{${CYAN}UPD:${UPDATES}${WHITE}}\n${ORANGE}╰─>${RESET} "
}

PROMPT_COMMAND=_update_prompt_vars

# ==============================
# COLORES (Proxmox)
# ==============================
ORANGE="\[\e[38;5;208m\]"
WHITE="\[\e[1;37m\]"
GRAY="\[\e[0;37m\]"
CYAN="\[\e[1;36m\]"
GREEN="\[\e[1;32m\]"
RESET="\[\e[0m\]"

# ==============================
# PROMPT
# ==============================
# PS1 se asigna dinámicamente en _update_prompt_vars

# ==============================
# ALIAS ÚTILES
# ==============================
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
alias usuario_actual='whoami'

# ==============================
# CONFIGURACIÓN GENERAL
# ==============================
HISTCONTROL=ignoreboth
HISTSIZE=5000
HISTFILESIZE=10000
shopt -s histappend

# Autocompletado mejorado
bind 'set show-all-if-ambiguous on'
bind 'set completion-ignore-case on'
bind 'TAB:menu-complete'

export EDITOR=nano
export LANG=es_NI.UTF-8
export LANGUAGE=es_NI.UTF-8

if [ -x /usr/bin/dircolors ]; then
    eval "$(dircolors -b)"
    alias ls='ls --color=auto'
fi

# Integración de herramientas modernas
# lsd: Reemplazo moderno para ls
if command -v lsd >/dev/null 2>&1; then
    alias ls='lsd'
fi

# bat: Reemplazo para cat con syntax highlighting
if command -v bat >/dev/null 2>&1; then
    alias cat='bat --plain'
fi

# fzf: Fuzzy finder
if command -v fzf >/dev/null 2>&1; then
    # Fuzzy history search con Ctrl+R
    bind '"\C-r": "\C-x\C-r"'
    __fzf_history__() {
        local output
        output=$(history | fzf --tac --query="$READLINE_LINE" | sed 's/ *[0-9]* *//')
        READLINE_LINE="$output"
        READLINE_POINT=${#output}
    }
    bind -x '"\C-x\C-r": __fzf_history__'

    # Fuzzy file search con Ctrl+T (si key-bindings está disponible)
    if [ -f /usr/share/fzf/key-bindings.bash ]; then
        source /usr/share/fzf/key-bindings.bash
    fi
fi

if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
fi
