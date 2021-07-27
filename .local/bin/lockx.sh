#!/usr/bin/env bash
# Lock wrapper around i3lock-color

tmpbg='/tmp/screen.png'

trans="#00000000"
black="$(xgetres color8)BB"
white="$(xgetres color15)FF"
blue="$(xgetres color4)FF"
red="$(xgetres color1)FF"
green="$(xgetres color10)FF"

playerctl pause

# Turn off desk light through Home Assistant
curl -X POST \
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiIwMmZhZGJlODcwYzk0Nzg0OWI2YmE3MDBjOTgxZmJmMyIsImlhdCI6MTYxNzAwNzI3MiwiZXhwIjoxOTMyMzY3MjcyfQ.Obyi-6ZrkMkEOcLZnk5B9VMnmomLJpjWKAAbu0dUwag" \
  -H "Content-Type: application/json" --data '{"entity_id":"light.scrivania"}' \
  "http://192.168.1.113:8123/api/services/light/turn_off" &

#scrot --overwrite "$tmpbg"
#convert "$tmpbg" -scale 50% -scale 10% -scale 1000% -scale 200% "$tmpbg"
blur_screen.sh $tmpbg

i3lock --clock --indicator --pass-media-keys \
\
--insidever-color="$black" \
--ringver-color="$blue" \
\
--insidewrong-color="$black" \
--ringwrong-color="$red" \
\
--inside-color="$black" \
--ring-color="$trans" \
--line-uses-ring \
--separator-color="$trans" \
--keyhl-color="$green" \
--bshl-color="$red" \
\
--verif-color="$white" \
--wrong-color="$white" \
--time-color="$white" \
--date-color="$white" \
--layout-color="$white" \
\
--verif-text="Mhm..." \
--wrong-text="Nope!" \
--time-str="%H:%M" \
--date-str="%a %d %b" \
\
-i "$tmpbg"

