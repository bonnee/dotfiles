typeset -U PATH path
path=("$HOME/.local/bin" "$HOME/.npm-global/bin" "/usr/lib/ccache/bin" "$path[@]")
export PATH

export XDG_CONFIG_HOME=$HOME/.config
export XDG_DATA_HOME=$HOME/.local/share
export XDG_STATE_HOME=$HOME/.local/state
export XDG_CACHE_HOME=$HOME/.cache

export ZSH_CUSTOM=${XDG_DATA_HOME}/oh-my-zsh/custom

export TERMINAL="footclient"
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

if [ -d "$ENV_HOME" ]; then
  source <(cat $ENV_HOME/* 2> /dev/null) > /dev/null
  #for file in "$ENV_HOME/*" ; do
  #  echo $file
  #  if [ -f "$file" ] ; then
  #    source "$file"
  #  fi
  #done
fi

if [ -d "$ENV_HOME/$HOST" ]; then
  source <(cat $ENV_HOME/$HOST/* 2> /dev/null) > /dev/null
fi

if [ -f ~/.zshsecret ]; then
  source ~/.zshsecret
fi

# Wayland session (uwsm): log in on tty1 to start Sway.
# Other VTs stay plain login shells; `uwsm check may-start` decides.
if [ -z "${DBUS_SESSION_BUS_ADDRESS:-}" ] &&
   [ -S "${XDG_RUNTIME_DIR:-/run/user/$UID}/bus" ]; then
  export DBUS_SESSION_BUS_ADDRESS="unix:path=${XDG_RUNTIME_DIR:-/run/user/$UID}/bus"
fi

if uwsm check may-start; then
  exec uwsm start default
elif [ "$(tty)" = /dev/tty1 ] &&
     ! pgrep -x sway >/dev/null 2>&1 &&
     systemctl --user is-active --quiet graphical-session.target 2>/dev/null; then
  # Session targets left over from a sway that died outside uwsm: nothing stops
  # graphical-session.target when a non-uwsm compositor exits, and it blocks
  # `uwsm check may-start` above.
  echo "uwsm: clearing stale graphical-session.target" >&2
  systemctl --user stop graphical-session.target
  if uwsm check may-start; then
    exec uwsm start default
  fi
fi

