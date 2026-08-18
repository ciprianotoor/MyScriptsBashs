# ==========================================
# 🔥 ALIASES PRO - CIPRIANO (LSD FIXED)
# ==========================================
##########################Inteligencia artificial################
ai() {
  if [ -z "$*" ]; then
    echo "Uso: ai <consulta>"
    return 1
  fi
  command -v curl >/dev/null 2>&1 || { echo "Falta curl."; return 127; }
  command -v less >/dev/null 2>&1 || { echo "Falta less."; return 127; }
  query=$(echo "$*" | tr ' ' '+')
  curl -s "https://cheat.sh/$query?lang=es" | less -R
}
################################################################
SCRIPTS_DIR="${DOTFILES_REPO:-$HOME/MyScriptsBashs}"

# ========================
# AUTO ALIASES SCRIPTS
# ========================
typeset -ga DOTFILE_SCRIPT_ALIASES
if (( ${#DOTFILE_SCRIPT_ALIASES[@]} )); then
  unalias -- $DOTFILE_SCRIPT_ALIASES 2>/dev/null
fi
DOTFILE_SCRIPT_ALIASES=()
for script in "$SCRIPTS_DIR"/*.sh(N); do
    script_name=$(basename "$script" .sh)
    if [ "$script_name" != "aliases" ]; then
        # Ejecutar mediante Bash también permite usar scripts sin bit ejecutable.
        alias "$script_name"="bash '$script'"
        DOTFILE_SCRIPT_ALIASES+=("$script_name")
    fi
done
# ========================
# Alias de ssh windows 11
# ========================
alias w11root='ssh w11root'
alias w11cipriano='ssh w11cipriano'
alias encenderw11ltsc_proxmox='sudo qm start 101'
alias apagarw11ltsc_proxmox='sudo qm shutdown 101'
# ======================================
########################################
# Administracion
# Editar configuración de Timeshift
alias edit-timeshift='sudo nano /etc/timeshift/timeshift.json'
alias timeshift-list='sudo timeshift --list'
alias timeshift-create='sudo timeshift --create'
alias timeshift-restore='sudo timeshift --restore'
alias timeshift-delete='sudo timeshift --delete'
alias timeshift-delete-all='sudo timeshift --delete-all'
alias timeshift-help='timeshift --help'
# ========================
# Alias de apt
# ========================
alias instalar='sudo apt install'
alias desinstalar='sudo apt remove'
alias desintalar='desinstalar'  # Compatibilidad con el nombre anterior.

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
if command -v tree >/dev/null 2>&1; then
  alias tree='tree -C'
else
  alias tree='find . -maxdepth 2 -print'
fi
########################## alias ordenados ##########################
aliases() {
    command -v fzf >/dev/null 2>&1 || {
        echo "Falta fzf. Instálalo con: sudo apt install fzf"
        return 127
    }
    {
        printf "%-20s %s\n" "ALIAS" "DESCRIPCIÓN"
        alias |
        sed 's/^alias //' |
        awk -F"[=']" '{printf "%-20s %s\n", $1, $3}'
    } |
    fzf \
        --header-lines=1 \
        --layout=reverse \
        --border=rounded \
        --height=80% \
        --prompt="Aliases > "
}

# Ayuda rápida con nombres descriptivos. `aliases` sigue disponible para buscar
# cualquier alias mediante fzf; `aliashelp` explica los más importantes.
aliashelp() {
  cat <<'HELP'
=== AYUDA DE ALIASES PROXMOX ===

Sistema       cpu_info, memoria, discos, espacio_disco, info_sistema
Procesos      procesos, procesos_memoria, procesos_cpu, kill9
Red           ip_local, ruta_red, puertos_escucha, conexiones_red
              probar_internet
VM Proxmox    listar_vms, vm_iniciar, vm_detener, vm_reiniciar
              vm_configurar
LXC           listar_lxc, lxc_iniciar, lxc_detener, lxc_reiniciar
              lxc_configurar
Cluster       almacenamiento_estado, nodos_cluster, estado_cluster
ZFS           zfs_backup_v1, zfs_backup_v2
Terminal      recargar_zsh, aliasesrc, reload_alias
Tmux          tmux_iniciar, tmux_entrar, tmux_listar, tmux_cerrar
Git           gs, ga, gaa, gc, gp, gpl
Scripts       montar, r, disk_health, backup-promox-config
              install-proxmox, update-my-scripts, push_my_scripts

Los nombres cortos anteriores (vms, vmstart, cts, pvev, etc.) se conservan
como compatibilidad, pero los nombres descriptivos son los recomendados.
HELP
}
#==================================================================
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
alias cpu_info='lscpu'
alias memoria='free -h'
alias discos='lsblk -f'
alias espacio_disco='df -h'
alias montajes='mount | column -t'
alias version_kernel='uname -r'
alias info_sistema='hostnamectl'

# ========================
# PROCESOS
# ========================
alias psa='ps aux'
alias psg='ps aux | grep -i'
alias psmem='ps aux --sort=-%mem | head'
alias pscpu='ps aux --sort=-%cpu | head'
alias kill9='kill -9'
alias procesos='ps aux'
alias procesos_memoria='ps aux --sort=-%mem | head'
alias procesos_cpu='ps aux --sort=-%cpu | head'

# ========================
# RED
# ========================
alias mip='ip -4 addr'
alias puerta='ip route'
alias puertos='ss -tuln'
alias conexiones='ss -tunap'
alias pingg='ping 8.8.8.8'
alias ip_local='ip -4 addr'
alias ruta_red='ip route'
alias puertos_escucha='ss -tuln'
alias conexiones_red='ss -tunap'
alias probar_internet='ping 8.8.8.8'

# ========================
# PROXMOX
# ========================
alias pvev='pveversion'
alias proxmox_version='pveversion'
alias vms='sudo qm list'
alias listar_vms='sudo qm list'
alias vmstart='sudo qm start'
alias vm_iniciar='sudo qm start'
alias vmstop='sudo qm stop'
alias vm_detener='sudo qm stop'
alias vmreboot='sudo qm reboot'
alias vm_reiniciar='sudo qm reboot'
alias vmconfig='sudo qm config'
alias vm_configurar='sudo qm config'

alias cts='sudo pct list'
alias listar_lxc='sudo pct list'
alias ctstart='sudo pct start'
alias lxc_iniciar='sudo pct start'
alias ctstop='sudo pct stop'
alias lxc_detener='sudo pct stop'
alias ctreboot='sudo pct reboot'
alias lxc_reiniciar='sudo pct reboot'
alias ctconfig='sudo pct config'
alias lxc_configurar='sudo pct config'

alias storages='sudo pvesm status'
alias almacenamiento_estado='sudo pvesm status'
alias nodes='sudo pvecm nodes'
alias nodos_cluster='sudo pvecm nodes'
alias cluster='sudo pvecm status'
alias estado_cluster='sudo pvecm status'

# ========================
# APT
# ========================
alias actualizar='sudo apt update && sudo apt upgrade -y '
alias actualizardistro='sudo apt full-upgrade -y'
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
alias rebote='source ~/.zshrc'
alias recargar_zsh='source ~/.zshrc'
alias reload_alias="source '$SCRIPTS_DIR/aliases.sh'"
alias now='date "+%Y-%m-%d %H:%M:%S"'
alias perfil='nano ~/.zshrc'

# Edita aliases.sh y recarga los cambios solo si el editor termina correctamente.
unalias aliasesrc 2>/dev/null || true
aliasesrc() {
  local editor=${EDITOR:-nano}
  if [[ ! -f "$SCRIPTS_DIR/aliases.sh" ]]; then
    print -u2 "❌ No existe $SCRIPTS_DIR/aliases.sh"
    return 1
  fi
  "$editor" "$SCRIPTS_DIR/aliases.sh" || return
  source "$SCRIPTS_DIR/aliases.sh"
  print "✅ Aliases recargados desde $SCRIPTS_DIR/aliases.sh"
}

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
alias tmux_iniciar='tmux new-session -A -s trabajo'
alias tmux_entrar='tmux attach-session -t trabajo'
alias tmux_listar='tmux list-sessions'
alias tmux_cerrar='tmux kill-session -t trabajo'
# Nombres anteriores conservados por compatibilidad.
alias tmux_nuevo='tmux_iniciar'
alias tmux_conectar='tmux_entrar'
alias tmux_sesiones='tmux_listar'

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
###############snapshots
alias v1_pzfsb="sudo bash '$SCRIPTS_DIR/managerzfsproxmox.sh'"
alias v2_pzfsb="sudo bash '$SCRIPTS_DIR/managerzfsproxmoxv2.sh'"
alias zfs_backup_v1="sudo bash '$SCRIPTS_DIR/managerzfsproxmox.sh'"
alias zfs_backup_v2="sudo bash '$SCRIPTS_DIR/managerzfsproxmoxv2.sh'"
##########################Certificados
