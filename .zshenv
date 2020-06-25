typeset -U PATH path
path=("$HOME/.local/bin/" "$HOME/.npm-global/bin/" "$path[@]")
export PATH

export QT_AUTO_SCREEN_SCALE_FACTOR=0
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1

EDITOR="vim"
if type nvim &> /dev/null; then
  alias vim="nvim"
  EDITOR="nvim"
fi
export EDITOR

export TERMINAL="alacritty --config-file ~/.config/alacritty/`hostname`.yml"
export BROWSER="firefox"

export BC_ENV_ARGS="$HOME/.config/bc"
export QT_QPA_PLATFORMTHEME=qt5ct

export DISABLE_AUTO_UPDATE=true

export HOSTNAME=$HOST

alias dots='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
alias yeet='yay -Rsn'

alias v="$EDITOR"
alias s="systemctl"

export BEMENU_OPTS="-bi -p '> ' --fn 'sans-serif' --tb '$background' --fb '$background' --nb '$background' --hb '$foreground' --sb '$background' --scb '$background' --tf '$foreground' --ff '$foreground' --nf '$foreground' --hf '$background' --sf '$foreground' --scf '$foreground'"

if [ -f ~/."$HOST"_env ]; then
  source ~/."$HOST"_env
fi
