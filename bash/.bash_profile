
# ~/.bash_profile
#

export PATH=~/bin:~/.npm-global/bin:$PATH

# BEGIN laptop
#CYCLES_OPENCL_SPLIT_KERNEL_TEST=1; export CYCLES OPENCL_SPLIT_KERNEL_TEST
#
#export QT_AUTO_SCREEN_SCALE_FACTOR=1
#export GDK_SCALE=1
#export _JAVA_AWT_WM_NONREPARENTING=1
#
#
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
