typeset -U PATH path
path=("$HOME/.local/bin" "$HOME/.npm-global/bin" "/usr/lib/ccache/bin", "$path[@]")
export PATH

export ZSH_CUSTOM=${XDG_DATA_HOME}/oh-my-zsh/custom

export XDG_CONFIG_HOME=$HOME/.config
export XDG_DATA_HOME=$HOME/.local/share
export XDG_STATE_HOME=$HOME/.local/state
export XDG_CACHE_HOME=$HOME/.cache

# xdg-ninja <3
export ANDROID_HOME=$XDG_DATA_HOME/android
export GTK2_RC_FILES="$XDG_CONFIG_HOME"/gtk-2.0/gtkrc
export CARGO_HOME="$XDG_DATA_HOME"/cargo
export CCACHE_DIR=${XDG_CACHE_HOME}/ccache
export GNUPGHOME="$XDG_DATA_HOME"/gnupg
export GRIPHOME="$XDG_CONFIG_HOME/grip"
export LESSHISTFILE=${XDG_CACHE_HOME}/less/history
export MPLAYER_HOME="$XDG_CONFIG_HOME"/mplayer
export NVM_DIR="$XDG_DATA_HOME"/nvm
export _JAVA_OPTIONS=-Djava.util.prefs.userRoot="$XDG_CONFIG_HOME"/java
export SQLITE_HISTORY=$XDG_CACHE_HOME/sqlite_history
export STACK_ROOT="$XDG_DATA_HOME"/stack
export TEXMFVAR=$XDG_CACHE_HOME/texlive/texmf-var
export XAUTHORITY="$XDG_RUNTIME_DIR"/Xauthority
export USERXSESSION="$XDG_CACHE_HOME/X11/xsession"

alias wget=wget --hsts-file="$XDG_DATA_HOME/wget-hsts"


export TERMINAL="alacritty --config-file ~/.config/alacritty/`hostname`.yml"
export BROWSER="firefox"

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

export ENV_HOME="$XDG_CONFIG_HOME/env"
if [ -f "$ENV_HOME/$HOST" ]; then
  source "$ENV_HOME/$HOST"
fi

if [ -f ~/.zshsecret ]; then
  source ~/.zshsecret
fi

