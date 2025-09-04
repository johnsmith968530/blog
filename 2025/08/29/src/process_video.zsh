#!/bin/bash

for x1 in *.mkv *.webm
do
  if [ -e "$x1" ]
  then
    x2="${x1%.*}.opus"
    if [ ! -e "$x2" ]
    then
      echo "Converting $x1 -> $x2"
      ffmpeg -i "$x1" -c:a copy -vn "$x2"
    else
      echo "$x2 already exists"
    fi
  fi
done

for x1 in *.mp4 *.m4v
do
  if [ -e "$x1" ]
  then
    x2="${x1%.*}.aac"
    if [ ! -e "$x2" ] && [ ! -e "${x1%.*}.m4a" ]
    then
      echo "Converting $x1 -> $x2"
      ffmpeg -i "$x1" -c:a copy -vn "$x2"
    else
      echo "$x2 already exists"
    fi
  fi
done

# vim: set et ff=unix ft=sh nocp sts=2 sw=2 ts=2:
