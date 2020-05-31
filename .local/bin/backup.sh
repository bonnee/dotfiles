#!/usr/bin/env bash

#disk=$1
#remote="192.168.1.14:/c/dimages"
#subdir="$HOSTNAME"
#dir="$mount_point/$subdir"

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

file_name="$HOSTNAME-$(date +%Y-%m-%d).img"
log_name="$HOSTNAME.log"

compress_cmd="cat"

disk=""
output=""
remote=""
dir=""

in_flag=false
out_flag=false

while getopts "cr:o:d:" opt; do
  case $opt in
    c)
      if command -v pigz > /dev/null ; then
        compress_cmd="pigz -c";
      else
	compress_cmd="gzip -c"
      fi

      log "Compression enabled with '$compress_cmd'"

      file_name="$file_name.gz"
      ;;
    d)
      echo "Device to backup: $OPTARG"
      disk="$OPTARG"
      in_flag=true
      ;;
    o)
      echo "Output dir: $OPTARG"
      output="$OPTARG"
      dir="$output"
      out_flag=true
      ;;
    r)
      echo "Remote out: $OPTARG"
      remote="$OPTARG"
      mount_point=$(mktemp -d)
      dir="$mount_point"
      out_flag=true
      ;;
    \?)
      echo "Invalid option: -$OPTARG"
      exit 1;
      ;;
    :)
      echo "$OPTARG requires an argument"
      exit 1
      ;;
  esac
done

if ! ( $in_flag && $out_flag ); then
  echo "In and out options must be provided!"
  exit 1;
fi

read_cmd="pv $disk"

if [ "$remote" != "" ]; then
  printf "Mounting %s to %s..." "$remote" "$mount_point"
  if mount "$remote" "$mount_point" ; then
    echo "Done."
  else
    echo "Error mounting."
    exit 1
  fi
fi

sync; sync

msg "Backup starting"
msg "Executing '$read_cmd | $compress_cmd > \"$dir/$file_name\"'"
$read_cmd | $compress_cmd > "$dir/$file_name"

state=$?

if [ $state -eq 0 ]; then
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
  rm "$dir/$file_name"
  echo "File system cleaned."
  log "'$file_name' removed."
fi

log "Bye."
if [ "$remote" != "" ]; then
  printf "Unmounting..."
  umount "$mount_point" && rm -rf "$mount_point" && echo "Done."
fi
