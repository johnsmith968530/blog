#!/bin/zsh

# $Source: /Users/x/Dropbox/2/src/blog/2025/11/25/src/RCS/parakeet.zsh,v $
# $Date: 2025/11/25 20:17:24 $
# $Revision: 1.1 $

parakeet () {
  local f1 x1
  for f1 in *.{aac,flac,m4a,mka,mp3,ogg,opus,wav}(N)
  do
    for x1 in srt txt
    do
      [ -f "$f1" ] && \
        [ ! -f "${f1%.*}.$x1" ] && \
          echodo parakeet-mlx --output-format $x1 "$f1"
    done
  done
  rcs_init *.srt *.txt
}

# vim: set et ff=unix ft=zsh nocp sts=2 sw=2 ts=2:
