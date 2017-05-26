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

exec i3
