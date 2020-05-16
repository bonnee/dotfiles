typeset -U PATH path
path=("$HOME/bin/" "$HOME/.local/bin/" "$HOME/.npm-global/bin/" "$path[@]")
export PATH

export QT_AUTO_SCREEN_SCALE_FACTOR=1
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1

export EDITOR=vim
export BC_ENV_ARGS="$HOME/.bc"
export QT_QPA_PLATFORMTHEME=qt5ct

export DISABLE_AUTO_UPDATE=true

export HOSTNAME=$HOST

source .cache/wal/colors.sh
source ~/."$HOST"_env
