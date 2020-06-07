#!/bin/zsh

config="$1"
pid=0

kill_pid()
{
  if [ "$pid" -ne "0" ]
  then
    kill $pid
    pid=0
  fi
}

playerctl -F status 2> /dev/null > >(while read line
do
  case $line in
    "Playing")
      if [ "$pid" -eq "0" ]; then
	cava_cmmk $config &
	pid=$!
      fi
      ;;
    "" )
      if [ "$(playerctl -l | wc -l)" -eq "0" ]
      then
	echo "Killing cava_cmmk"
	kill_pid
      fi
      ;;
    * )
      echo "Received '$line'"
      ;;
    esac
done)

wait $!
