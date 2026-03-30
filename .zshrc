# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ===== COMPLETIONS =====
fpath+=~/.zsh/plugins/zsh-completions/src
autoload -Uz compinit && compinit
# ==============================
# 📜 ALIASES EXTERNOS
# ==============================
[ -f /home/cipriano/MyScriptsBashs/aliases.sh ] && source /home/cipriano/MyScriptsBashs/aliases.sh
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
