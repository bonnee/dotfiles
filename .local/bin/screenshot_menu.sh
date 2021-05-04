#!/bin/sh

base_cmd="grimshot --notify"
action="$1"

case "$(printf "🗔 Select window\n➕ Select Area\n🖥️ Sceen\n*️ All Screens" | bemenu -p "$action")" in
  "🗔 Select window") $base_cmd "$action" window ;;
  "➕ Select Area") $base_cmd "$action" area ;;
  "🖥️ Sceen" )$base_cmd "$action" output ;;
  "*️ All Screens") $base_cmd "$action" screen ;;
esac

