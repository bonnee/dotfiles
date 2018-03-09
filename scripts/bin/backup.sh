#!/usr/bin/env bash

path="/mnt/$HOSTNAME"

mount 192.168.1.14:/c/dimages /mnt

dd if=/dev/mmcblk | pigz -c > $path/$HOSTNAME-$(date +%Y-%m-%d).img.gz

[ $(ls -1 | wc -l) -gt 3 ] && rm $(ls -1t | tail -1)
