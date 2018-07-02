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

xset +fp ~/.fonts
xset +fp /usr/share/fonts/misc
xset fp rehash
wmname LG3D

export _JAVA_OPTIONS='-Dswing.defaultlaf=com.sun.java.swing.plaf.gtk.GTKLookAndFeel -Dawt.useSystemAAFontSettings=gasp'

export TERMINAL=termite

# BEGIN desktop
#export GDK_SCALE=1.7
#export GDK_DPI_SCALE=0.7
#export QT_AUTO_SCREEN_SCALE_FACTOR=1
#
#xset s 600		# lock at 600s
#xset dpms 900  # stdby at 900s
#xss-lock -l -- lock.sh -n &
#numlockx &
# END desktop

# BEGIN laptop
#xset s 120 180  # dim at 120s. lock at 120+180s
#xset dpms 360   # stdby at 360s
#xss-lock -l -n dim-screen.sh -- lock.sh -n &
# END laptop

/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 &
/usr/bin/pulseaudio-dlna &
exec i3
