typeset -U PATH path
path=("$HOME/.local/bin" "$HOME/.npm-global/bin" "/usr/lib/ccache/bin", "$path[@]")
export PATH

#export QT_AUTO_SCREEN_SCALE_FACTOR=0
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1

export TERMINAL="alacritty --config-file ~/.config/alacritty/`hostname`.yml"
export BROWSER="firefox"

export TASKRC=~/.config/taskwarrior/config

export BC_ENV_ARGS="$HOME/.config/bc"
export QT_QPA_PLATFORMTHEME="qt5ct"

export DISABLE_AUTO_UPDATE=true

export HOSTNAME=$HOST

EDITOR="vim"
if type nvim &> /dev/null; then
  EDITOR="nvim"
fi
export EDITOR
export DIFFPROG="$EDITOR -d"

export BEMENU_OPTS="-il 15 -p '> ' --fn 'sans-serif 14' --scrollbar autohide"

if [ -f ~/."$HOST"_env ]; then
  source ~/."$HOST"_env
fi

if [ -f ~/.zshsecret ]; then
  source ~/.zshsecret
fi
