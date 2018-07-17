#!/usr/bin/env bash

disk=$1
gzip=1
remote="192.168.1.14:/c/dimages"
mount_point=$(mktemp -d)
subdir="$HOSTNAME"
dir="$mount_point/$subdir"

backup_image="$HOSTNAME-$(date +%Y-%m-%d).img"
log_name="$HOSTNAME.log"

ddcmd="dd if=$disk"

function log {
  echo "$(date --rfc-3339=seconds)" "$1" >> "$dir/$log_name"
}

function msg {
  echo "$1"
  log "$1"
}

printf "Mounting $remote..."
if mount "$remote" "$mount_point" ; then
  echo "Done."
else
  echo "Error mounting."
  exit 1
fi

sync; sync

log "New backup starting"

if command -v pv > /dev/null; then
  disksize=$(blockdev --getsize64 $disk)
  statcmd="pv -s $disksize"
  log "Using pv"
fi

if [ $gzip = 1 ]; then

  if command -v pigz > /dev/null; then
    gzipcmd="pigz -c";
  else
    gzipcmd="gzip -c"
  fi
  log "Compression enabled with '$gzipcmd'"

  backup_image="$backup_image.gz"

  msg "Backup started"
  log "Saving in '$backup_image'"
  $ddcmd | $statcmd | $gzipcmd > "$dir/$backup_image"
else
  msg "Compression disabled"

  msg "Backup started"
  log "Saving in '$backup_image'"
  $ddcmd | $statcmd > "$dir/$backup_image"
fi

state=$?

if [ $state = 0 ]; then
  msg "Backup succedded."
  old=`ls -1t "$mount_point/$subdir" | tail -1`
  [ $(ls -1 "$mount_point/$subdir" | wc -l) -gt 3 ] && msg "Removing $old" && rm "$dir/$old" && msg "$old removed."
else
  msg "Backup failed. Cleaning up"
  rm "$dir/$backup_image"
  echo "File system cleaned."
  log "'$backup_image' removed."
fi

log "Bye."
printf "Unmounting..."
umount "$mount_point" && rm -rf "$mount_point" && echo "Done."

