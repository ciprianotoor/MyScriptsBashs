##############################################
# POWERLEVEL10K INSTANT PROMPT (DEBE IR ARRIBA)
##############################################
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

##############################################
# OH MY ZSH + PLUGINS
##############################################
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

plugins=(
  git
  zsh-autosuggestions
  zsh-syntax-highlighting
  history-substring-search
)

source $ZSH/oh-my-zsh.sh

##############################################
# POWERLEVEL10K CONFIG
##############################################
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

##############################################
# FUNCIONES
##############################################

# Backup rápido de archivo con timestamp
bkp() { sudo cp "$1" "$1.bkp_$(date +%F_%H-%M)"; }

# CAT moderno:
# - Usa batcat
# - Auto-sudo si no hay permisos
# - Paging deshabilitado por default
cat() {
  if [[ $# -eq 0 ]]; then
    command cat
    return
  fi

  if [[ -r "$1" ]]; then
    batcat --paging=never "$@"
  else
    sudo batcat --paging=never "$@"
  fi
}

##############################################
# RECARGA RÁPIDA DEL ZSHRC
##############################################
alias reload='source ~/.zshrc'

##############################################
# LISTADO DE ARCHIVOS (lsd)
##############################################
alias ls='lsd'
alias ll='lsd -lh'
alias la='lsd -a'
alias lla='lsd -lah'
alias tree='lsd --tree -L 2'
alias lt='lsd --tree'
alias lsdv='lsd -lh --group-directories-first'
alias lsa='sudo lsd'

##############################################
# LIMPIEZA DE PANTALLA
##############################################
alias cls='clear'
alias c='clear'

##############################################
# APAGADO Y REINICIO
##############################################
alias apagar='sudo poweroff'
alias reiniciar='sudo reboot now'

##############################################
# APT / GESTIÓN DE PAQUETES
##############################################
alias actualiza='sudo apt update && sudo apt upgrade -y'
alias instala='sudo apt install'
alias elimina='sudo apt remove'
alias limpia='sudo apt autoremove && sudo apt clean'
alias busca='apt search'
alias info='apt show'

# Atajos cortos
alias act='actualiza'
alias ins='instala'
alias eli='elimina'
alias lim='limpia'
alias bus='busca'

##############################################
# RED Y DIAGNÓSTICO
##############################################
alias ip4='ip -4 a'
alias ip6='ip -6 a'
alias ruta='ip route'
alias ports='sudo ss -tulnp'
alias puertos='sudo ss -tulnp'
alias pingg='ping -c 4 8.8.8.8'
alias scanlocal='sudo nmap -sn 192.168.1.0/24'
alias dnsflush='sudo systemd-resolve --flush-caches'

##############################################
# PROCESOS Y SISTEMA
##############################################
alias mem='free -h'
alias cpuuse='ps aux --sort=-%cpu | head -20'
alias memuse='ps aux --sort=-%mem | head -20'
alias kerna='uname -a'
alias hw='sudo lshw -short'

##############################################
# SYSTEMD / LOGS
##############################################
alias s-start='sudo systemctl start'
alias s-stop='sudo systemctl stop'
alias s-restart='sudo systemctl restart'
alias s-status='sudo systemctl status --no-pager'
alias bootlog='sudo journalctl -b'
alias bootlog1='sudo journalctl -b -1'

##############################################
# GIT
##############################################
alias gs='git status'
alias ga='git add .'
alias gc='git commit -m'
alias gpl='git pull'
alias gpo='git push'
alias gcl='git clone'

##############################################
# DISCO Y ARCHIVOS
##############################################
alias du1='du -h --max-depth=1'
alias dus='du -sh *'
alias mkdirp='mkdir -p'
alias cpv='rsync -ah --info=progress2'
alias mvv='mv -v'
alias rmrf='rm -rf'

##############################################
# BAT / VISUALIZACIÓN DE ARCHIVOS
##############################################
alias cata='batcat -A'
alias catn='batcat -n'
alias preview="batcat --pager='less -R'"

##############################################
# HISTORIAL
##############################################
alias hc='history -c'
alias hist10='history | tail -10'
alias hist50='history | tail -50'

##############################################
# FASTFETCH / BTOP
##############################################
alias sys='fastfetch'
alias fetch='fastfetch'
alias ff='fastfetch --logo auto'
alias ffc='fastfetch --cpu --gpu --os --memory'
alias ffl='fastfetch --logo small'

alias topv='btop'
alias bcpu='btop --preset cpu'
alias bram='btop --preset mem'
alias bfull='btop --utf-force'

##############################################
# TEMPERATURA CPU
##############################################
alias temp='sensors | grep -E "Tctl|Tdie|Package|Core"'
alias tempfull='sensors'

##############################################
# SSH
##############################################
alias sshconfig='nano ~/.ssh/config'
alias sshkeys='ls ~/.ssh'
alias sshperms='chmod 700 ~/.ssh && chmod 600 ~/.ssh/*'
alias ClavePublicaSSH='/bin/cat ~/.ssh/id_ed25519.pub'
##############################################
# SCRIPTS Y ALIAS DE PROXMOX Y MANTENIMIENTO
##############################################

# ===============================
# 1️⃣ Administración de contenedores LXC
# ===============================
alias lxc-list="lxc-ls -f"
alias lxc-start-all="for c in $(lxc-ls); do lxc-start -n $c; done"
alias lxc-stop-all="for c in $(lxc-ls); do lxc-stop -n $c; done"

# ===============================
# 2️⃣ Auditorías y reportes
# ===============================
alias prox-audit="sudo /root/proxmox_security_audit.sh"
alias prox-status="pveperf"

# ===============================
# 3️⃣ Backups y sincronización
# ===============================
alias prox-backup="vzdump --all --storage local-lvm"
alias sync-home="rsync -av /home/cipriano/ /mnt/backup/home_cipriano/"

# ===============================
# 4️⃣ Automatización y scripts útiles
# ===============================
alias update-all="apt update && apt upgrade -y"
alias clean-cache="apt autoremove -y && apt clean"

# ===============================
# 5️⃣ Almacenamiento y montaje
# ===============================
alias lvm-list="sudo lvs -a -o +devices"
alias mount-all="mount -a"

# ===============================
# 6️⃣ Servicios, CPU y rendimiento
# ===============================
alias cpu-info="lscpu"
alias mem-info="free -h"
alias pve-top="htop"

# ===============================
# 7️⃣ Red y VPN
# ===============================
alias ip-info="ip a"
alias restart-network="systemctl restart networking"

# ===============================
# 8️⃣ Samba
# ===============================
alias smb-status="systemctl status smbd"
alias smb-restart="systemctl restart smbd"

# Otras utilidades
alias dvd_manager='/home/cipriano/MyScriptsBashs/dvd_manager.sh.sh'

# Mostrar todos tus scripts / aliases
##############################################
# UTILIDADES Y EDICIÓN
##############################################
alias perfil='nano ~/.zshrc'      # Editar rápidamente el zshrc
alias revote='source ~/.zshrc'     # Recargar configuración
alias AuditoriaProxmoxVE='/home/cipriano/MyScriptsBashs/AuditoriaProxmoxVE.sh'
alias AutoDotfileRootProxmox='/home/cipriano/MyScriptsBashs/AutoDotfileRootProxmox.sh'
alias AutoScripts='/home/cipriano/MyScriptsBashs/AutoScripts.sh'
alias CuentaInvitadoSSH='/home/cipriano/MyScriptsBashs/CuentaInvitadoSSH.sh'
alias HelloWord='/home/cipriano/MyScriptsBashs/HelloWord.sh'
alias Info='/home/cipriano/MyScriptsBashs/Info.sh'
alias ParticionadorAlmecenamientos='/home/cipriano/MyScriptsBashs/ParticionadorAlmecenamientos.sh'
alias Proxmox-auto-update='/home/cipriano/MyScriptsBashs/Proxmox-auto-update.sh'
alias administrarVMLXC='/home/cipriano/MyScriptsBashs/administrarVMLXC.sh'
alias apt-auto-critical='/home/cipriano/MyScriptsBashs/apt-auto-critical.sh'
alias auto-clock='/home/cipriano/MyScriptsBashs/auto-clock.sh'
alias backup-promox-config='/home/cipriano/MyScriptsBashs/backup-promox-config.sh'
alias backup-proxmox-rsync='/home/cipriano/MyScriptsBashs/backup-proxmox-rsync.sh'
alias backup_cipriano_shell_dotfiles='/home/cipriano/MyScriptsBashs/backup_cipriano_shell_dotfiles.sh'
alias backup_samba='/home/cipriano/MyScriptsBashs/backup_samba.sh'
alias datosproxmox='/home/cipriano/MyScriptsBashs/datosproxmox.sh'
alias dvd_manager.sh='/home/cipriano/MyScriptsBashs/dvd_manager.sh.sh'
alias generar_alias='/home/cipriano/MyScriptsBashs/generar_alias.sh'
alias generar_alias_zsh='/home/cipriano/MyScriptsBashs/generar_alias_zsh.sh'
alias levantarTaiScale='/home/cipriano/MyScriptsBashs/levantarTaiScale.sh'
alias lxc-admin='/home/cipriano/MyScriptsBashs/lxc-admin.sh'
alias montar='/home/cipriano/MyScriptsBashs/montar.sh'
alias proxmox_security_audit='/home/cipriano/MyScriptsBashs/proxmox_security_audit.sh'
alias push_my_scripts='/home/cipriano/MyScriptsBashs/push_my_scripts.sh'
alias r='/home/cipriano/MyScriptsBashs/r.sh'
alias samba_admin='/home/cipriano/MyScriptsBashs/samba_admin.sh'
alias setup-cpu-autogovernor='/home/cipriano/MyScriptsBashs/setup-cpu-autogovernor.sh'
alias setup-termux='/home/cipriano/MyScriptsBashs/setup-termux.sh'
alias timeshift-menu='/home/cipriano/MyScriptsBashs/timeshift-menu.sh'
alias wifi-tools='/home/cipriano/MyScriptsBashs/wifi-tools.sh'
alias miscripts='grep "^alias " /home/cipriano/.zshrc | grep "/home/cipriano/MyScriptsBashs"'
