# $Source: /Users/x/Dropbox/2/src/blog/2025/09/22/src/RCS/video2audio.sh,v $
# $Date: 2025/09/22 16:16:51 $
# $Revision: 1.1 $

webm2opus () {
  local x
  for x in "$@"
  do
    echo "webm2opus: processing $x"
    echodo ffmpeg -i "$x" -c:a copy -vn "${x%.*}.opus"
  done
}

mp42aac () {
  local x
  for x in "$@"
  do
    echo "mp42aac: processing $x"
    echodo ffmpeg -i "$x" -c:a copy -vn "${x%.*}.aac"
  done
}

mkv2opus () {
  local x
  for x in "$@"
  do
    echo "mkv2opus: processing $x"
    echodo ffmpeg -i "$x" -c:a copy -vn "${x%.*}.opus"
  done
}

# vim: set et ff=unix ft=sh nocp sts=2 sw=2 ts=2:
