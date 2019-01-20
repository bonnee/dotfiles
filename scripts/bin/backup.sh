#!/usr/bin/env bash

disk=$1
headless=${2:-0}
gzip=1
remote="192.168.1.14:/c/dimages"
mount_point=$(mktemp -d)
subdir="$HOSTNAME"
dir="$mount_point/$subdir"

backup_image="$HOSTNAME-$(date +%Y-%m-%d).img"
log_name="$HOSTNAME.log"

ddcmd="dd if=$disk"

log() {
  echo "$(date --rfc-3339=seconds)" "$1" >> "$dir/$log_name"
}

msg() {
  echo "$1"
  log "$1"
}

count()
{
  echo "$1" | wc -l
}

first() {
  echo "$1" | head -1
}

printf "Mounting %s..." "$remote"
if mount "$remote" "$mount_point" ; then
  echo "Done."
else
  echo "Error mounting."
  exit 1
fi

if ! [ "$headless" = 1 ] && ! command -v pv > /dev/null ; then
  msg "pv not found. Using headless mode"
  headless=1
fi

sync; sync

log "New backup starting"

disksize=$(blockdev --getsize64 "$disk")
statcmd="pv -s $disksize"

if [ "$gzip" = 1 ]; then

  if command -v pigz > /dev/null ; then
    gzipcmd="pigz -c";
  else
    gzipcmd="gzip -c"
  fi
  log "Compression enabled with '$gzipcmd'"

  backup_image="$backup_image.gz"

  msg "Backup starting"
  if [ "$headless" = 1 ]; then
    log "Executing '$ddcmd | $gzipcmd > \"$dir/$backup_image\"'"
    $ddcmd | $gzipcmd > "$dir/$backup_image"
  else
    log "Executing '$ddcmd | $statcmd | $gzipcmd > \"$dir/$backup_image\"'"
    $ddcmd | $statcmd | $gzipcmd > "$dir/$backup_image"
  fi
else
  msg "Compression disabled"

  msg "Backup starting"
  if [ "$headless" = 1 ]; then
    log "Executing '$ddcmd > \"$dir/$backup_image\"'"
    $ddcmd > "$dir/$backup_image"
  else
    log "Executing '$ddcmd | $statcmd > \"$dir/$backup_image\"'"
    $ddcmd | $statcmd > "$dir/$backup_image"
  fi
fi

state=$?

if [ "$state" = 0 ]; then
  msg "Backup succedded."

  ifs=$IFS
  IFS= # https://unix.stackexchange.com/a/164548
  imgs=$(ls -1tr "$dir" | grep -E "(img.gz$|img$)")

  if [ $(count "$imgs") -gt 3 ] ; then
    old=$(first "$imgs")
    msg "Removing $old" && rm "$dir/$old" && msg "$old removed."

  fi
  IFS=$ifs
else
  msg "Backup failed. Cleaning up"
  rm "$dir/$backup_image"
  echo "File system cleaned."
  log "'$backup_image' removed."
fi

log "Bye."
printf "Unmounting..."
umount "$mount_point" && rm -rf "$mount_point" && echo "Done."
