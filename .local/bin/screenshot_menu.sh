#!/bin/sh

base_cmd="grimshot --notify"
santino_cmd="santino.sh"
action="$1"

case "$(printf "🗔 Select window\n➕ Select Area\n🖥️ Sceen\n😇 Santino\n*️ All Screens" |\
  bemenu -np "$action")" in
  "🗔 Select window") $base_cmd "$action" window ;;
  "➕ Select Area") $base_cmd "$action" area ;;
  "🖥️ Sceen" )$base_cmd "$action" output ;;
  "😇 Santino" )$santino_cmd;;
  "*️ All Screens") $base_cmd "$action" screen ;;
esac

