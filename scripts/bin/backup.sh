#!/usr/bin/env bash

disk=$1

corever=`dd --version | head -n1 | awk '{print $3}'`
minver=8.24

ddcmd="dd if=$disk"
[ $(sort -V <(echo $corever) <(echo $minver) | head -n1) == "$minver" ] && ddcmd="$ddcmd status=progress"

if command -v pigz; then gzipcmd="pigz -c"; else gzipcmd="gzip -c"; fi

echo $gzipcmd
echo $ddcmd

if mount 192.168.1.14:/c/dimages $path ; then
  path=$(mktemp -d)
  backpath=$path/$HOSTNAME/$HOSTNAME-$(date +%Y-%m-%d).img.gz

  $ddcmd | $gzipcmd > $backpath
  chown bonnee:bonnee $backpath

  [ $(ls -1 | wc -l) -gt 3 ] && rm $(ls -1t | tail -1)

  umount $path && rm -rf $path
fi

