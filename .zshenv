typeset -U PATH path
path=("$HOME/.local/bin" "$HOME/.npm-global/bin" "$path[@]")
export PATH

#export QT_AUTO_SCREEN_SCALE_FACTOR=0
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1

EDITOR="vim"
if type nvim &> /dev/null; then
  alias vim="nvim"
  EDITOR="nvim"
fi
export EDITOR
export DIFFPROG="$EDITOR -d"

export TERMINAL="alacritty --config-file ~/.config/alacritty/`hostname`.yml"
export BROWSER="firefox"

export TASKRC=~/.config/taskwarrior/config

export BC_ENV_ARGS="$HOME/.config/bc"
export QT_QPA_PLATFORMTHEME="qt5ct"

export DISABLE_AUTO_UPDATE=true

export HOSTNAME=$HOST

autoload -Uz compinit promptinit
promptinit
compinit

# https://unix.stackexchange.com/a/583743
unsetopt completealiases
unsetopt complete_aliases

if command -v git > /dev/null; then
    alias dots="git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME"
    compdef dots "git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME"
fi

if command -v paru > /dev/null; then
    alias yeet="paru -Rsn"
    alias yay="paru"
    compdef yay=paru
fi

alias v="$EDITOR"
compdef _vim v
compdef _vim nvim

alias s=systemctl
compdef s=systemctl

if command -v docker > /dev/null; then
  alias d="docker"
  compdef d=docker
  if command -v docker-compose > /dev/null; then
    alias dc="docker-compose"
    alias dcup="docker-compose pull; docker-compose up"
  fi
fi

alias -s txt="$EDITOR"
alias -s md="$EDITOR"
alias -s py="$EDITOR"
alias -s c="$EDITOR"
alias -s log="$EDITOR"

export BEMENU_OPTS="-il 15 -p '> ' --fn 'sans-serif 14' --scrollbar autohide"

if [ -f ~/."$HOST"_env ]; then
  source ~/."$HOST"_env
fi

if [ -f ~/.zshsecret ]; then
  source ~/.zshsecret
fi
