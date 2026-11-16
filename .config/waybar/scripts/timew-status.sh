#!/bin/sh
# Waybar custom/timew: running Timewarrior project + elapsed time,
# today's per-project totals in the tooltip, warning on Syncthing conflicts.

db="${TIMEWARRIORDB:-${XDG_DATA_HOME:-$HOME/.local/share}/timewarrior}"
conflicts=$(find "$db" -name '*.sync-conflict-*' 2>/dev/null | wc -l)

timew export today 2>/dev/null | jq -c \
    --arg now "$(date -u +%Y%m%dT%H%M%SZ)" --argjson conflicts "$conflicts" --arg db "$db" '
  def ts: strptime("%Y%m%dT%H%M%SZ") | mktime;
  def hm: (. / 60 | floor) as $m
          | "\($m / 60 | floor):\($m % 60 | tostring | if length < 2 then "0" + . else . end)";
  map(. + { secs: (((.end // $now) | ts) - (.start | ts)),
            proj: ((.tags // ["(untagged)"]) | join(" ")) }) as $iv
  | ($iv | map(select(.end == null)) | first) as $act
  | ($iv | group_by(.proj) | map("\(.[0].proj)\t\(map(.secs) | add | hm)") | join("\n")) as $sum
  | (if ($iv | length) == 0 then "Nothing tracked today"
     else "Today: \($iv | map(.secs) | add | hm)\n\($sum)" end) as $tip
  | (if $conflicts > 0 then " ⚠" else "" end) as $warn
  | { text: (if $act then "󱎫 \($act.proj) \($act.secs | hm)" else "󱎫" end) + $warn,
      class: ([if $act then "active" else "idle" end] + (if $conflicts > 0 then ["conflict"] else [] end)),
      tooltip: ((if $conflicts > 0 then "Syncthing conflict files in \($db)!\n" else "" end) + $tip) }
'
