typeset -U PATH path
path=("$HOME/bin" "$HOME/.npm-global/bin" "/usr/lib/ccache/bin" "$path[@]")
export PATH

export XDG_SESSION_TYPE=wayland
export CLUTTER_BACKEND=wayland
export QT_QPA_PLATFORM=wayland-egl
export XDG_CURRENT_DESKTOP=unity
export MOZ_ENABLE_WAYLAND=1
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
export _JAVA_AWT_WM_NONREPARENTING=1
export EDIT=nvim
export EDITOR=nvim
export BC_ENV_ARGS="$HOME/.bc"
export QT_QPA_PLATFORMTHEME=qt5ct
export DISABLE_AUTO_UPDATE=true

