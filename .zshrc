# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ===== COMPLETIONS =====
if [[ -d ~/.zsh/plugins/zsh-completions/src ]]; then
  fpath+=~/.zsh/plugins/zsh-completions/src
fi
autoload -Uz compinit && compinit
# ==============================
# 📜 ALIASES EXTERNOS
# ==============================
DOTFILES_REPO=${DOTFILES_REPO:-${${(%):-%N}:A:h}}
export DOTFILES_REPO
[[ -f "$DOTFILES_REPO/aliases.sh" ]] && source "$DOTFILES_REPO/aliases.sh"
# ===== HISTORIAL =====
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000

setopt APPEND_HISTORY
setopt SHARE_HISTORY
setopt INC_APPEND_HISTORY

setopt HIST_IGNORE_ALL_DUPS
setopt HIST_REDUCE_BLANKS

# ===== NAVEGACIÓN =====
setopt AUTO_CD
setopt CORRECT

# ===== RESUMEN PROXMOX =====
consumo() {
  local load cores
  read -r load _ < /proc/loadavg
  cores=$(getconf _NPROCESSORS_ONLN 2>/dev/null)
  [[ $cores == <-> ]] || cores=1

  print -P '%F{208}%BResumen de consumo del nodo%b%f'
  print -P "%F{117}󰍛 CPU%f  carga: %B${load}/${cores}%b"
  free -h | awk 'NR == 2 {printf "󰍛 RAM  usada: %s / %s (%s disponible)\n", $3, $2, $7}'
  df -hP / | awk 'NR == 2 {printf "󰋊 Disco /  usado: %s / %s (%s)\n", $3, $2, $5}'
}

# ===== PLUGINS =====
source ~/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
# ===== Powerlevel10k =====
source ~/.zsh/powerlevel10k/powerlevel10k.zsh-theme
# SIEMPRE ÚLTIMO
source ~/.zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh


# ===== PROMPT =====
PROMPT='%n@%m:%~ %# '

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
export PATH="$HOME/MyScriptsBashs:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"
export PATH="$HOME/.local/npm/bin:$PATH"
