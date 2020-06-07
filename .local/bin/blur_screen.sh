if [ -z "$1" ]; then
  out="$(mktemp -t tmp.XXXXXXXXXX.png)"
else
  out="$1"
fi

res="$(xdpyinfo | grep dimensions | sed -r 's/^[^0-9]*([0-9]+x[0-9]+).*$/\1/')"

#filters='noise=alls=10,scale=iw*.05:-1,scale=iw*20:-1:flags=neighbor'
filters='boxblur=8:8'

ffmpeg -y -loglevel 0 -s "$res" -f x11grab -i $DISPLAY -vframes 1 \
  -vf "$filters" "$out"

#ffmpeg -probesize 100M -thread_queue_size 32 -f x11grab -video_size $RES \
#  -y -i $DISPLAY -i $IMAGE -i $IMAGE -filter_complex \
#  "eq=gamma=0.75,boxblur=3:3,overlay=(main_w-overlay_w)/4:(main_h-overlay_h)/2,overlay=3*(main_w-overlay_w)/4:(main_h-overlay_h)/2" \
#  -vframes 1 "$OUT"

echo $out
