#!/bin/zsh

# $Source: /Users/x/Dropbox/2/src/blog/2025/09/22/src/RCS/rekey.zsh,v $
# $Date: 2025/09/22 16:20:31 $
# $Revision: 1.3 $

source "/Users/x/Dropbox/2/src/blog/2025/09/03/src/evalgitblobbykey.sh"

evalgitblobbykey bash echodo

tmp_file_keys () { h1=$(git hash-object "$1"); shift; echodo envy set universal git hash "$@" $h1; }

tmp_file_keys video2audio.sh bash video2audio

# vim: set et ff=unix ft=zsh nocp sts=2 sw=2 ts=2:
