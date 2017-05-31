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

xautolock -detectsleep \
# BEGIN desktop
#          -notify   10 -notifier "xset dpms force off" \
#          -time     15 -locker   "lock.sh"
# END desktop
# BEGIN laptop
          #-notify  5 -notifier "xset dpms force off" \
          #-time     8 -locker   "lock.sh" \
          #-killtime 10 -killer   "systemctl suspend" &
# END laptop
compton --config $HOME/.config/compton.conf &
exec i3
