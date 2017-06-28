# ~/.bash_profile
#
#
PATH=$PATH:$HOME/bin

[ "$XDG_CURRENT_DESKTOP" = "KDE" ] || [ "$XDG_CURRENT_DESKTOP" = "GNOME" ] || export QT_QPA_PLATFORMTHEME="qt5ct"
export QT_QPA_PLATFORMTHEME=gtk2

[[ -f ~/.bashrc ]] && . ~/.bashrc
