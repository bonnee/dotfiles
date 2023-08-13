typeset -U PATH path
path=("$HOME/.local/bin" "$HOME/.npm-global/bin" "/usr/lib/ccache/bin", "$path[@]")
export PATH

export XDG_CONFIG_HOME=$HOME/.config
export XDG_DATA_HOME=$HOME/.local/share
export XDG_STATE_HOME=$HOME/.local/state
export XDG_CACHE_HOME=$HOME/.cache

export ZSH_CUSTOM=${XDG_DATA_HOME}/oh-my-zsh/custom

export TERMINAL="alacritty"
export BROWSER="firefox-developer-edition"

export BC_ENV_ARGS="$HOME/.config/bc"

export QT_QPA_PLATFORMTHEME="qt5ct"
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
export QT_AUTO_SCREEN_SCALE_FACTOR=0
export OPENCV_LOG_LEVEL=ERROR

# https://github.com/MicrosoftDocs/live-share/issues/180
export DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1

export DISABLE_AUTO_UPDATE=true

export HOSTNAME=$HOST

EDITOR="vim"
if type nvim &> /dev/null; then
  EDITOR="nvim"
fi
export EDITOR
export DIFFPROG="$EDITOR -d"

export BEMENU_OPTS="-il 15 -p '> ' --fn 'sans-serif 14' --scrollbar autohide"

# Load host-specific environment
export ENV_HOME="$XDG_CONFIG_HOME/env"

if [ -f "$ENV_HOME/xdg-ninja" ]; then
  source "$ENV_HOME/xdg-ninja"
fi

if [ -f "$ENV_HOME/$HOST" ]; then
  source "$ENV_HOME/$HOST"
fi

if [ -f ~/.zshsecret ]; then
  source ~/.zshsecret
fi

