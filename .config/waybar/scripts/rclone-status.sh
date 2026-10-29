#!/usr/bin/env bash

# rclone mounts exposing the RC API: label:port
MOUNTS=(
    "Photography:5572"
    "RT_ITALY:5573"
    "RT_CAD:5574"
)

entries=()
for entry in "${MOUNTS[@]}"; do
    name=${entry%%:*}
    port=${entry##*:}
    vfs=$(rclone rc --url "localhost:$port" vfs/stats --timeout 1s 2>/dev/null) || continue
    [[ -z "$vfs" ]] && continue
    core=$(rclone rc --url "localhost:$port" core/stats --timeout 1s 2>/dev/null)
    entries+=("$(jq -c -n --arg name "$name" --arg vfs "$vfs" --arg core "$core" \
        '{name: $name, vfs: ($vfs | fromjson? // {}), core: ($core | fromjson? // {})}')")
done

if [[ ${#entries[@]} -eq 0 ]]; then
    echo '{"text":""}'
    exit 0
fi

printf '%s\n' "${entries[@]}" | jq -s -c '
  def fmt_bytes:
    if . > 1073741824 then
      ((. / 1073741824 * 10 | floor) / 10 | tostring) + " GB"
    elif . > 1048576 then
      ((. / 1048576 * 10 | floor) / 10 | tostring) + " MB"
    else
      ((. / 1024 | floor) | tostring) + " KB"
    end;

  def fmt_speed:
    if . > 1048576 then
      ((. / 1048576 * 10 | floor) / 10 | tostring) + " MB/s"
    elif . > 1024 then
      ((. / 1024 | floor) | tostring) + " KB/s"
    else
      (tostring) + " B/s"
    end;

  map({
    name: .name,
    active: (.vfs.diskCache.uploadsInProgress // 0),
    queued: (.vfs.diskCache.uploadsQueued // 0),
    cache: (.vfs.diskCache.bytesUsed // 0),
    speed: (.core.speed // 0),
    files: [.core.transferring[]? | .name + " (" + ((.percentage // 0) | tostring) + "%)"]
  }) as $m |

  ($m | map(.active + .queued) | add // 0) as $total |

  if $total == 0 then
    { text: "", tooltip: "All local changes synced" }
  else
    {
      text: ("󰑮 " + ($total | tostring)),
      class: "uploading",
      tooltip: (
        ($m | map(
          select((.active + .queued) > 0) |
          .name + ": " + (.active | tostring) + " active, " + (.queued | tostring) + " queued @ " + (.speed | fmt_speed) +
          (if (.files | length) > 0 then "\n  " + (.files | join("\n  ")) else "" end)
        ) | join("\n"))
        + "\nCache: " + (($m | map(.cache) | add // 0) | fmt_bytes)
      )
    }
  end
'
