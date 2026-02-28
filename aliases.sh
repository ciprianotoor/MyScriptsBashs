#!/usr/bin/env bash
# ==========================================
# ALIASES PROFESIONALES - CIPRIANO
# ==========================================

# ===== Navegación =====
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias home='cd ~'

# ===== Listado =====
alias ls='ls --color=auto'
alias ll='ls -lh'
alias la='ls -lah'
alias lt='ls -lh --sort=time'
alias lsize='du -sh * | sort -h'

# ===== Sistema =====
alias cpu='lscpu'
alias mem='free -h'
alias disk='lsblk -f'
alias espacio='df -h'
alias uso='du -sh *'
alias uptime='uptime -p'
alias kernel='uname -r'

# ===== Red =====
alias puertos='ss -tuln'
alias conexiones='ss -tunap'
alias miip='ip -4 addr show'
alias gateway='ip route'
alias pingg='ping 8.8.8.8'

# ===== Procesos =====
alias psg='ps aux | grep -v grep | grep -i'
alias top10='ps aux --sort=-%mem | head'
alias kill9='kill -9'

# ===== Proxmox =====
alias pvev='pveversion'
alias vms='qm list'
alias cts='pct list'
alias reiniciarvm='qm reboot'
alias apagarvm='qm shutdown'
alias startvm='qm start'
alias stopvm='qm stop'

# ===== Actualización =====
alias actualizar='sudo apt update && sudo apt full-upgrade -y'
alias limpiar='sudo apt autoremove -y && sudo apt clean'

# ===== Seguridad =====
alias permisos='chmod +x'
alias propietario='chown'
alias puertos_abiertos='ss -tulwn'

# ===== Git =====
alias gs='git status'
alias ga='git add .'
alias gc='git commit -m'
alias gp='git push'
alias gl='git pull'
alias gb='git branch'

# ===== Utilidad =====
alias cls='clear'
alias recargar='source ~/.zshrc'
alias editar_alias='nano ~/MyScriptsBashs/aliases.sh'
alias reload_alias='source ~/MyScriptsBashs/aliases.sh'
