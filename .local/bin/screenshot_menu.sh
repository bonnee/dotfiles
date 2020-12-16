#!/bin/sh

base_cmd="grimshot --notify"
action="$1"

case "$(echo -e "🗔 Select window\n➕ Select Area\n🖥️ Sceen\n*️ All Screens\n" | bemenu -l 4 -p "Screenshot:")" in
  "🗔 Select window") $base_cmd $action window ;;
  "➕ Select Area") $base_cmd $action area ;;
  "🖥️ Sceen" )$base_cmd $action output ;;
  "*️ All Screens") $base_cmd $action screen ;;
esac

