set PATH /usr/lib/ccache/bin $PATH
set PATH ~/bin ~/.npm-global/bin $PATH

set __fish_git_prompt_showdirtystate 'yes'
set __fish_git_prompt_showstashstate 'yes'
set __fish_git_prompt_showuntrackedfiles 'yes'
#set __fish_git_prompt_showupstream 'yes'
set __fish_git_prompt_color_branch yellow
set __fish_git_prompt_color_upstream_ahead green
set __fish_git_prompt_color_upstream_behind red

set -x XDG_SESSION_TYPE wayland
#set -x GDK_BACKEND wayland
set -x CLUTTER_BACKEND wayland
set -x QT_QPA_PLATFORM wayland-egl
set -x XDG_CURRENT_DESKTOP Unity
set -x MOZ_ENABLE_WAYLAND 1

set -x QT_WAYLAND_DISABLE_WINDOWDECORATION 1
set -x _JAVA_AWT_WM_NONREPARENTING 1
set -x EDIT nvim
set -x EDITOR nvim
set -x BC_ENV_ARGS '/home/bonnee/.bc'

set -x BW_SESSION "EwsA9Z6/QRfv2Trr/zEa4eO27sFRJZ6UHXGv1n1vJ7BxZw4NCB3wvfDpEazeNJlID3/wUFDG77COriTUjoMmGg=="

set -x QT_QPA_PLATFORMTHEME qt5ct
