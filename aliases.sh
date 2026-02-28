#!/usr/bin/env bash
# ==========================================
# ALIASES PROFESIONALES - CIPRIANO
# ==========================================
alias perfil='nano ~/.zshrc'
alias perfilbash='nano ~/.bashrc'

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
#!/usr/bin/env bash
# ==========================================================
# ALIASES PRO - CIPRIANO (SYSADMIN / PROXMOX / SERVIDOR)
# ==========================================================

# ========================
# NAVEGACIÓN
# ========================
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias home='cd ~'
alias rootdir='cd /'
alias back='cd -'

# ========================
# LISTADO Y ARCHIVOS
# ========================
alias ls='ls --color=auto'
alias ll='ls -lh'
alias la='ls -lah'
alias lt='ls -lht'
alias ltr='ls -lhtr'
alias lsize='du -sh * 2>/dev/null | sort -h'
alias tree='tree -C'
alias mkdirp='mkdir -p'
alias rmf='rm -rf'
alias c='cat'
alias v='less'
alias h='head'
alias t='tail'
alias tf='tail -f'

# ========================
# SISTEMA
# ========================
alias cpu='lscpu'
alias mem='free -h'
alias disk='lsblk -f'
alias dfh='df -h'
alias mounts='mount | column -t'
alias espacio='du -sh /* 2>/dev/null'
alias uptime='uptime -p'
alias kernel='uname -r'
alias osinfo='hostnamectl'
alias rebootnow='sudo reboot'
alias shutdownnow='sudo poweroff'

# ========================
# PROCESOS
# ========================
alias psa='ps aux'
alias psg='ps aux | grep -i'
alias psmem='ps aux --sort=-%mem | head'
alias pscpu='ps aux --sort=-%cpu | head'
alias topmem='top -o %MEM'
alias topcpu='top -o %CPU'
alias kill9='kill -9'
alias portsused='lsof -i -P -n'

# ========================
# RED
# ========================
alias miip='ip -4 addr'
alias ipfull='ip a'
alias gateway='ip route'
alias puertos='ss -tuln'
alias conexiones='ss -tunap'
alias listening='ss -lntup'
alias pingg='ping 8.8.8.8'
alias tracer='traceroute 8.8.8.8'
alias dns='cat /etc/resolv.conf'

# ========================
# PROXMOX VE
# ========================
alias pvev='pveversion'
alias vms='qm list'
alias vmstart='qm start'
alias vmstop='qm stop'
alias vmreboot='qm reboot'
alias vmconfig='qm config'
alias cts='pct list'
alias ctstart='pct start'
alias ctstop='pct stop'
alias ctreboot='pct reboot'
alias ctconfig='pct config'
alias storages='pvesm status'
alias nodes='pvecm nodes'
alias cluster='pvecm status'

# ========================
# APT / PAQUETES
# ========================
alias update='sudo apt update'
alias upgrade='sudo apt full-upgrade -y'
alias install='sudo apt install'
alias remove='sudo apt remove'
alias purge='sudo apt purge'
alias autoremove='sudo apt autoremove -y'
alias cleanapt='sudo apt clean'
alias search='apt search'
alias policy='apt policy'

# ========================
# LOGS
# ========================
alias logs='journalctl -xe'
alias logtoday='journalctl --since today'
alias logboot='journalctl -b'
alias dmesglog='dmesg -T | less'
alias authlog='sudo journalctl -u ssh'
alias syslog='sudo tail -f /var/log/syslog'

# ========================
# SSH
# ========================
alias sshconfig='nano ~/.ssh/config'
alias knownhosts='nano ~/.ssh/known_hosts'
alias reloadssh='sudo systemctl restart ssh'
alias sshstatus='systemctl status ssh'

# ========================
# GIT
# ========================
alias gs='git status'
alias ga='git add .'
alias gaa='git add -A'
alias gc='git commit -m'
alias gca='git commit -am'
alias gp='git push'
alias gpl='git pull'
alias gb='git branch'
alias gl='git log --oneline --graph --decorate'

# ========================
# UTILIDADES
# ========================
alias cls='clear'
alias editar_alias='nano ~/MyScriptsBashs/aliases.sh'
alias reload_alias='source ~/MyScriptsBashs/aliases.sh'
alias reloadz='source ~/.zshrc'
alias path='echo $PATH | tr ":" "\n"'
alias now='date "+%Y-%m-%d %H:%M:%S"'
alias weather='curl wttr.in'
# ========================
# LSD (si existe)
# ========================
if command -v lsd >/dev/null 2>&1; then
  alias ls='lsd'
  alias ll='lsd -lh'
  alias la='lsd -lah'
  alias lt='lsd -lt'
else
  alias ls='ls --color=auto'
  alias ll='ls -lh --color=auto'
  alias la='ls -lah --color=auto'
  alias lt='ls -lht --color=auto'
fi

alias lsize='du -sh * 2>/dev/null | sort -h'
alias tree='tree -C'

# ========================
# BATCAT (FORZADO)
# ========================

alias cat='batcat'


# ========================
# FZF
# ========================
if command -v fzf >/dev/null 2>&1; then
  alias ff='fzf'
  alias fh='history | fzf'
  alias fd='find . -type f | fzf'
fi
