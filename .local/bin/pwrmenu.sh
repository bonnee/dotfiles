#!/bin/sh

case "$(echo -e "🔒 Lock\n💤 Suspend\n🛑 Hibernate\n Exit sway\n⏻ Power Off\n🔄 Reboot" | bemenu -p "Power:")" in
"🔒 Lock") loginctl lock-session ;;
" Exit sway") swaymsg exit ;;
"💤 Suspend") systemctl suspend ;;
"🛑 Hibernate") systemctl hibernate ;;
"⏻ Power Off") systemctl poweroff ;;
"🔄 Reboot") systemctl reboot ;;
esac
