#!/bin/sh
includes=/etc/X11/xinit/xinitrc.d/

if [ -d "$includes" ]
then
for f in "$includes/"*
do
[ -x "$f" ] && . "$f"
done
unset f
fi
unset includes

dbus-update-activation-environment --all
[[ -f ~/.Xresources ]] && xrdb -merge ~/.Xresources

xset b off  # turn off bell

wmname LG3D

export _JAVA_OPTIONS='-Dswing.defaultlaf=com.sun.java.swing.plaf.gtk.GTKLookAndFeel -Dawt.useSystemAAFontSettings=gasp'

export TERMINAL=alacritty

export GDK_SCALE=1
export GDK_DPI_SCALE=1
export QT_AUTO_SCREEN_SCALE_FACTOR=0

xset s 600		# lock at 600s
xset dpms 900  # stdby at 900s
xss-lock -l -- lockx.sh -n &
numlockx &
xcape -e 'Control_L=Escape'

/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 &
#exec i3
