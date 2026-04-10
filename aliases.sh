# ==========================================
# 🔥 ALIASES PRO - CIPRIANO (LSD FIXED)
# ==========================================
##########################Inteligencia artificial################
ai() {
  if [ -z "$*" ]; then
    echo "Uso: ai <consulta>"
    return 1
  fi
  query=$(echo "$*" | tr ' ' '+')
  curl -s "https://cheat.sh/$query?lang=es" | less -R
}
################################################################
SCRIPTS_DIR="/home/cipriano/MyScriptsBashs"

# ========================
# AUTO ALIASES SCRIPTS
# ========================
for script in "$SCRIPTS_DIR"/*.sh; do
    script_name=$(basename "$script" .sh)
    if [ "$script_name" != "aliases" ]; then
        alias "$script_name"="$script"
    fi
done

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
# LISTADO (LSD CORRECTO)
# ========================
if command -v lsd >/dev/null 2>&1; then
  alias ls='lsd --icon always --group-dirs=first --color=always'
  alias ll='lsd -lh --icon always --group-dirs=first --color=always'
  alias la='lsd -lah --icon always --group-dirs=first --color=always'
  alias lt='lsd -lt --icon always --color=always'
else
  alias ls='ls --color=auto'
  alias ll='ls -lh --color=auto'
  alias la='ls -lah --color=auto'
  alias lt='ls -lht --color=auto'
fi

alias ltr='ls -lhtr'
alias lsize='du -sh * 2>/dev/null | sort -h'
alias tree='tree -C'

# ========================
# SISTEMA
# ========================
alias cpu='lscpu'
alias mem='free -h'
alias disk='lsblk -f'
alias dfh='df -h'
alias mounts='mount | column -t'
alias uptime='uptime -p'
alias kernel='uname -r'
alias osinfo='hostnamectl'

# ========================
# PROCESOS
# ========================
alias psa='ps aux'
alias psg='ps aux | grep -i'
alias psmem='ps aux --sort=-%mem | head'
alias pscpu='ps aux --sort=-%cpu | head'
alias kill9='kill -9'

# ========================
# RED
# ========================
alias miip='ip -4 addr'
alias gateway='ip route'
alias puertos='ss -tuln'
alias conexiones='ss -tunap'
alias pingg='ping 8.8.8.8'

# ========================
# PROXMOX
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
# APT
# ========================
alias actualiza='sudo apt update'
alias actualizar='sudo apt full-upgrade -y'
alias autoremove='sudo apt autoremove -y'
alias cleanapt='sudo apt clean'

# ========================
# LOGS
# ========================
alias logs='journalctl -xe'
alias logtoday='journalctl --since today'
alias logboot='journalctl -b'

# ========================
# GIT
# ========================
alias gs='git status'
alias ga='git add .'
alias gaa='git add -A'
alias gc='git commit -m'
alias gp='git push'
alias gpl='git pull'

# ========================
# UTILIDAD
# ========================
alias cls='clear'
alias recargar='source ~/.zshrc'
alias aliasesrc='nano ~/MyScriptsBashs/aliases.sh'
alias reload_alias='source ~/MyScriptsBashs/aliases.sh'
alias now='date "+%Y-%m-%d %H:%M:%S"'
alias perfil='nano ~/.zshrc'

# ========================
# BAT (CAT CON COLOR)
# ========================
if command -v batcat >/dev/null 2>&1; then
  alias cat='batcat'
elif command -v bat >/dev/null 2>&1; then
  alias cat='bat'
fi

# ========================
# FZF
# ========================
if command -v fzf >/dev/null 2>&1; then
  alias ff='fzf'
  alias fh='history | fzf'
fi

# ========================
# TMUX
# ========================
alias tn='tmux new -s trabajo'
alias ta='tmux attach -t trabajo'
alias tls='tmux ls'
alias tk='tmux kill-session -t trabajo'

# ========================
# SSH ADMIN
# ========================
alias ssh-status='systemctl status ssh'
alias ssh-active='systemctl is-active ssh'
alias ssh-restart='sudo systemctl restart ssh'
alias ssh-port='ss -tuln | grep ssh'

alias ssh-users='who'
alias ssh-connections='ss -tnp | grep ssh'
alias ssh-ps='ps aux | grep [s]shd'

alias ssh-pub='cat ~/.ssh/*.pub 2>/dev/null'
alias ssh-priv='ls -l ~/.ssh | grep id_'
alias ssh-auth='cat ~/.ssh/authorized_keys 2>/dev/null'
alias ssh-root-auth='sudo cat /root/.ssh/authorized_keys 2>/dev/null'

alias ssh-keygen-ed25519='ssh-keygen -t ed25519 -C "cipriano@$(hostname)"'
alias ssh-keygen-rsa='ssh-keygen -t rsa -b 4096 -C "cipriano@$(hostname)"'

alias ssh-copy='ssh-copy-id'

alias ssh-ls='ls -lah ~/.ssh'
alias ssh-perm='ls -l ~/.ssh'

alias ssh-log='journalctl -u ssh --no-pager | tail -n 50'
alias ssh-logf='journalctl -u ssh -f'
alias ssh-ok='journalctl -u ssh | grep "Accepted"'
alias ssh-fail='journalctl -u ssh | grep "Failed"'

alias ssh-conf='cat /etc/ssh/sshd_config'
alias ssh-edit='sudo nano /etc/ssh/sshd_config'

alias ssh-fp='ssh-keygen -lf ~/.ssh/id_ed25519.pub 2>/dev/null || ssh-keygen -lf ~/.ssh/id_rsa.pub'

# ========================
# POWER
# ========================
alias apagar='sudo poweroff'
alias reiniciar='sudo reboot now'

# ========================
# FUNCIÓN DEBUG SSH
# ========================
ssh-check() {
  echo "=== STATUS ==="
  systemctl is-active ssh

  echo "\n=== PUERTO ==="
  ss -tuln | grep ssh

  echo "\n=== USUARIOS ==="
  who

  echo "\n=== CLAVES ==="
  ls ~/.ssh
}
#------------------------------------Informacion de sesiones
alias informacion='run-parts /etc/update-motd.d/'
