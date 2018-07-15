#!/usr/bin/env bash

disk=$1
backupmount=192.168.1.14:/c/dimages

ddcmd="dd if=$disk"

if command -v pv > /dev/null; then
  disksize=$(fdisk -l $1 | grep Disk | head -n1 | awk '{print $5}')
  statcmd="pv -s $disksize"
  echo "Using pv"
fi

if command -v pigz > /dev/null; then gzipcmd="pigz"; else gzipcmd="gzip"; fi

echo "Using $gzipcmd"

path=$(mktemp -d)
printf "Mounting..."
if mount "$backupmount" "$path" ; then
  printf "Backupping...\n"

  backpath="$path/$HOSTNAME/$HOSTNAME-$(date +%Y-%m-%d).img.gz"
  ! $ddcmd | $statcmd | $gzipcmd -c > "$backpath"  && echo "Backup failed. Removing file" && rm "$backpath"

  old=`ls -1t "$path/$HOSTNAME" | tail -1`
  [ $(ls -1 "$path/$HOSTNAME" | wc -l) -gt 3 ] && echo "Removing $old" && rm "$path/$HOSTNAME/$old"

  echo "Unmounting and cleanup..."
  umount "$path" && rm -rf "$path"
fi

