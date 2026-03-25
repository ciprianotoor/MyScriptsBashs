# ==========================================
# 🔥 ALIASES PRO - CIPRIANO (LIMPIO ZSH)
# ==========================================
#   Instalar
# ==========================================
#sudo apt update && sudo apt install -y \
#zsh git curl wget htop tree iproute2 net-tools dnsutils traceroute lsof \
#bat fzf lsd nala tmux neovim ncdu btop ripgrep fd-find
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
# LISTADO
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
alias update='sudo apt update'
alias upgrade='sudo apt full-upgrade -y'
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
alias editar_alias='nano ~/MyScriptsBashs/aliases.sh'
alias reload_alias='source ~/MyScriptsBashs/aliases.sh'
alias now='date "+%Y-%m-%d %H:%M:%S"'

# ========================
# BATCAT
# ========================
alias cat='batcat'

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
