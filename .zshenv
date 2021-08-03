typeset -U PATH path
path=("$HOME/.local/bin/" "$HOME/.npm-global/bin/" "$path[@]")
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
compinit
promptinit

alias dots="git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME"
compdef dots "git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME"

alias yeet='paru -Rsn'
compdef yeet paru

alias yay="paru"
compdef yay paru

alias v="$EDITOR"
compdef v "$EDITOR"

alias s="systemctl"
compdef s systemctl

alias d="docker"
compdef d docker

alias dc="docker-compose"
compdef dc docker-compose

alias dcup="docker-compose pull; docker-compose up"

export BEMENU_OPTS="-il 15 -p '> ' --fn 'sans-serif 14' --scrollbar autohide"

if [ -f ~/."$HOST"_env ]; then
  source ~/."$HOST"_env
fi

if [ -f ~/.zshsecret ]; then
  source ~/.zshsecret
fi
