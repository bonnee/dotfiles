#!/usr/bin/env bash
# Lock wrapper around i3lock-color

tmpbg='/tmp/screen.png'

trans="#00000000"
black="$(xgetres color8)BB"
white="$(xgetres color15)FF"
blue="$(xgetres color4)FF"
red="$(xgetres color1)FF"
green="$(xgetres color10)FF"

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
--insidevercolor="$black" \
--ringvercolor="$blue" \
\
--insidewrongcolor="$black" \
--ringwrongcolor="$red" \
\
--insidecolor="$black" \
--ringcolor="$trans" \
--line-uses-ring \
--separatorcolor="$trans" \
--keyhlcolor="$green" \
--bshlcolor="$red" \
\
--verifcolor="$white" \
--wrongcolor="$white" \
--timecolor="$white" \
--datecolor="$white" \
--layoutcolor="$white" \
\
--veriftext="Mhm..." \
--wrongtext="Nope!" \
--timestr="%H:%M" \
--datestr="%a %d %b" \
\
-i "$tmpbg"

