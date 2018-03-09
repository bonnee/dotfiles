#!/usr/bin/env bash

path="/mnt"

mount 192.168.1.14:/c/dimages $path

dd if=/dev/mmcblk0 status=progress | pigz -c > $path/$HOSTNAME/$HOSTNAME-$(date +%Y-%m-%d).img.gz

[ $(ls -1 | wc -l) -gt 3 ] && rm $(ls -1t | tail -1)

umount /mnt
