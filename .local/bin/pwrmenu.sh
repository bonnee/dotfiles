#!/bin/sh

case "$(printf "🔒 Lock\n💤 Suspend\n🛑 Hibernate\n Exit sway\n⏻ Power Off\n🔄 Reboot" | bemenu -p "Power:")" in
"🔒 Lock") loginctl lock-session ;;
" Exit sway") swaymsg exit ;;
"💤 Suspend") systemctl suspend-then-hibernate ;;
"🛑 Hibernate") systemctl hibernate ;;
"⏻ Power Off") systemctl poweroff ;;
"🔄 Reboot") systemctl reboot ;;
esac
