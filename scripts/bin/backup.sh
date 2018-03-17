#!/usr/bin/env bash

disk=$1
backupmount=192.168.1.14:/c/dimages

corever=`dd --version | head -n1 | awk '{print $3}'`
minver=8.24

ddcmd="dd if=$disk"
[ $(sort -V <(echo $corever) <(echo $minver) | head -n1) == "$minver" ] && ddcmd="$ddcmd status=progress" && printf "Showing progress. "

if command -v pigz > /dev/null; then gzipcmd="pigz"; else gzipcmd="gzip"; fi

echo "Using $gzipcmd"

path=$(mktemp -d)
printf "Mounting..."
if mount "$backupmount" "$path" ; then
  printf "Backupping...\n"

  backpath="$path/$HOSTNAME/$HOSTNAME-$(date +%Y-%m-%d).img.gz"
  ! $ddcmd | $gzipcmd -c > "$backpath"  && echo "Backup failed. Removing file" && rm "$backpath"

  old=`ls -1t "$path/$HOSTNAME" | tail -1`
  [ $(ls -1 "$path/$HOSTNAME" | wc -l) -gt 3 ] && echo "Removing $old" && rm "$path/$HOSTNAME/$old"

  echo "Unmounting and cleanup..."
  umount "$path" && rm -rf "$path"
fi

