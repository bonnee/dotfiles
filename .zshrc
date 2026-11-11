zstyle ':completion:*' list-colors ''
zstyle ':completion:*' menu select
zstyle ':completion:*' select-prompt %SScrolling active: current selection at %p%s
zstyle :compinstall filename '/home/bonnee/.zshrc'
zstyle ':completion::complete:*' gain-privileges 1
zstyle ':completion:*' completer _expand_alias _complete _ignored

zmodload zsh/complist

setopt autocd extendedglob nomatch notify no_share_history

export HISTSIZE=100000
export SAVEHIST=100000
mkdir -p "$XDG_STATE_HOME"

# Use vim keys in tab complete menu:
bindkey -M menuselect 'h' vi-backward-char
bindkey -M menuselect 'k' vi-up-line-or-history
bindkey -M menuselect 'l' vi-forward-char
bindkey -M menuselect 'j' vi-down-line-or-history
bindkey -v '^?' backward-delete-char

# Finally, make sure the terminal is in application mode, when zle is
# active. Only then are the values from $terminfo valid.
if (( ${+terminfo[smkx]} && ${+terminfo[rmkx]} )); then
	autoload -Uz add-zle-hook-widget
	function zle_application_mode_start {
		echoti smkx
	}
	function zle_application_mode_stop {
		echoti rmkx
	}
	add-zle-hook-widget -Uz zle-line-init zle_application_mode_start
	add-zle-hook-widget -Uz zle-line-finish zle_application_mode_stop
fi

autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search

[[ -n "${key[Up]}"   ]] && bindkey -- "${key[Up]}"   up-line-or-beginning-search
[[ -n "${key[Down]}" ]] && bindkey -- "${key[Down]}" down-line-or-beginning-search

# Rehash on USR1
catch_signal_usr1() {
  trap catch_signal_usr1 USR1
  rehash
}
trap catch_signal_usr1 USR1

# Use nearcolor if not on a 24bit terminal
[[ "$COLORTERM" == (24bit|truecolor) || "${terminfo[colors]}" -eq '16777216' ]] || zmodload zsh/nearcolor

if [ -d /usr/share/oh-my-zsh ]; then
  export ZSH=/usr/share/oh-my-zsh
elif [ -d ~/.oh-my-zsh ]; then
  export ZSH=~/.oh-my-zsh
fi

plugins=(git-prompt common-aliases colorize colored-man-pages command-not-found fzf-tab zsh-autosuggestions zsh-syntax-highlighting vi-mode)

ZSH_CACHE_DIR=$XDG_CACHE_HOME/oh-my-zsh
if [[ ! -d $ZSH_CACHE_DIR ]]; then
  mkdir $ZSH_CACHE_DIR
fi

# Keep the completion dump in the XDG cache dir (xdg-ninja). Set it before
# sourcing oh-my-zsh: oh-my-zsh runs compinit itself, so this must be the only
# compinit and the only dump file.
mkdir -p "$XDG_CACHE_HOME/zsh"
ZSH_COMPDUMP="$XDG_CACHE_HOME/zsh/zcompdump-${HOST%%.*}-$ZSH_VERSION"

if [ -n "${ZSH}" ]; then
  source "$ZSH/oh-my-zsh.sh"
fi

# The interactive plugins (fzf-tab, zsh-autosuggestions, zsh-syntax-highlighting)
# are loaded eagerly, here in plugins=(). Deferring them with zsh-defer was tried
# on 2026-11-11 and produced input stalls: a pty key->echo test (baseline 2 ms)
# showed 150-350 ms freezes aligned with the deferred sources, and none with
# eager loading. Later runs of the same deferred config did not always reproduce
# them, but eager loading never stalled - the ~0.1 s of extra start-up is the
# better trade, so keep them in this list.

ZSH_THEME_GIT_PROMPT_PREFIX="["
ZSH_THEME_GIT_PROMPT_SUFFIX="] "

hcolor="blue"
if [[ ${SSH_TTY} ]] ; then
  hcolor="green"
fi
PROMPT='%F{$hcolor}%m%f %F{yellow}%4~%f '

if type git_super_status &> /dev/null; then
  RPROMPT='$(git_super_status)'
fi
RPROMPT="${RPROMPT}[%F{green}%?%f]"

# ALIASES

# compinit already ran in oh-my-zsh (with $ZSH_COMPDUMP above); running it again
# here only added a second dump file and ~20 ms to every shell.
# promptinit is gone too: the prompt is set by hand below, no theme is loaded.

# https://unix.stackexchange.com/a/583743
# don't expand aliases _before_ completion has finished
#   like: git comm-[tab]
unsetopt completealiases
unsetopt complete_aliases

alias wget=wget --hsts-file="$XDG_DATA_HOME/wget-hsts"

# https://medium.com/@alexcg1/using-sudo-with-user-dotfiles-and-aliases-db76813007e
alias sudo='nocorrect sudo -E '

# https://github.com/rushsteve1/trash-d
if command -v trash > /dev/null; then
  alias rm='trash'
fi

alias vim="$EDITOR -p"
alias v="$EDITOR -p"

if command -v git > /dev/null; then
    _dots="git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME"
    alias dots=$_dots
    compdef '$_dots'=git
fi

if command -v paru > /dev/null; then
    alias yay="paru"
    compdef yay=paru

    alias yeet='paru -Rsn'
    compdef yeet=paru
fi

alias s=systemctl
compdef s=systemctl

if type docker > /dev/null 2>&1; then
  alias d="docker"

  # Probe the compose CLI plugin on disk instead of running `docker compose`,
  # which cost ~60 ms of every shell startup.
  _compose_plugin=""
  for _f in "$HOME/.docker/cli-plugins/docker-compose" \
            /usr/lib/docker/cli-plugins/docker-compose \
            /usr/local/lib/docker/cli-plugins/docker-compose; do
    [[ -x $_f ]] && { _compose_plugin=1; break }
  done
  unset _f

  if [[ -n $_compose_plugin ]]; then
    alias dc="docker compose"
    alias dcup="docker compose pull; docker compose up -d"
  elif type docker-compose > /dev/null 2>&1; then
    alias dc="docker-compose"
    alias dcup="docker-compose pull; docker-compose up -d"
  fi
  unset _compose_plugin
fi

alias ts=tailscale
alias ll='ls -lh'

# pywal
if [ -d ~/.cache/wal ]; then
  if [ -f ~/.config/wpg/sequences ]; then
    (cat ~/.config/wpg/sequences &)
  else
    (cat ~/.cache/wal/sequences &)
  fi

  source ~/.cache/wal/colors-tty.sh
  source ~/.cache/wal/colors.sh
fi

