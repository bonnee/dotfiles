#!/usr/bin/env bash

path=$(mktemp -d)
backpath=$path/$HOSTNAME/$HOSTNAME-$(date +%Y-%m-%d).img.gz


if mount 192.168.1.14:/c/dimages $path ; then
  dd if=/dev/mmcblk0 status=progress | pigz -c > $backpath
  chown bonnee:bonnee $backpath

  [ $(ls -1 | wc -l) -gt 3 ] && rm $(ls -1t | tail -1)

  umount $path && rm -rf $path
fi
