typeset -U PATH path
path=("$HOME/.local/bin/" "$HOME/.npm-global/bin/" "$path[@]")
export PATH

export QT_AUTO_SCREEN_SCALE_FACTOR=1
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1

export EDITOR=vim
export BC_ENV_ARGS="$HOME/.bc"
export QT_QPA_PLATFORMTHEME=qt5ct

export DISABLE_AUTO_UPDATE=true

export HOSTNAME=$HOST


alias dots='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
alias yeet='yay -Rsn'

# pywal
if [ -d ~/.cache/wal ]; then
  (cat ~/.cache/wal/sequences &)
  source ~/.cache/wal/colors-tty.sh
  source ~/.cache/wal/colors.sh
fi

export BEMENU_OPTS="-bi -p '> ' --fn 'sans-serif' --tb '$background' --fb '$background' --nb '$background' --hb '$foreground' --sb '$background' --scb '$background' --tf '$foreground' --ff '$foreground' --nf '$foreground' --hf '$background' --sf '$foreground' --scf '$foreground'"

if [ -f ~/."$HOST"_env ]; then
  source ~/."$HOST"_env
fi
