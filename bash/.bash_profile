#
# ~/.bash_profile
#

export PATH=~/bin:$PATH

# BEGIN laptop
#CYCLES_OPENCL_SPLIT_KERNEL_TEST=1; export CYCLES OPENCL_SPLIT_KERNEL_TEST
# END laptop

[ "$XDG_CURRENT_DESKTOP" = "KDE" ] || [ "$XDG_CURRENT_DESKTOP" = "GNOME" ] || export QT_QPA_PLATFORMTHEME="qt5ct"

function notvim {
    echo "¯\_(ツ)_/¯";
}

function :wq {
    notvim;
}

function :w {
    notvim;
}

function :q {
    notvim;
}

[[ -d ~/.profile.d ]] && source ~/.profile.d/*
[[ -f ~/.bashrc ]] && . ~/.bashrc
