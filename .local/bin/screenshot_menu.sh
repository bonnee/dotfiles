#!/bin/sh

base_cmd="grimshot --notify"
santino_cmd="santino.sh"
action="$1"

case "$(printf "➕ Select Area\n🗔 Select window\n🖥️ Sceen\n😇 Santino\n*️ All Screens" |\
  bemenu -np "$action")" in
  "➕ Select Area") $base_cmd "$action" area ;;
  "🗔 Select window") $base_cmd "$action" window ;;
  "🖥️ Sceen" )$base_cmd "$action" output ;;
  "😇 Santino" )$santino_cmd;;
  "*️ All Screens") $base_cmd "$action" screen ;;
esac

