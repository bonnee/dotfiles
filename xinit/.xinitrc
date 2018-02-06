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
#xautolock -detectsleep \
#          #-notify   10 -notifier "xset dpms force off" \
#          #-time     15 -locker   "lock.sh"
#numlockx &
# END desktop

# BEGIN laptop
#xss-lock -- lock.sh &
##xautolock -detectsleep \
##          -notify  5 -notifier "xset dpms force off" \
##          -time     8 -locker   "lock.sh" \
##          -killtime 10 -killer   "systemctl suspend" &
# END laptop

exec i3
