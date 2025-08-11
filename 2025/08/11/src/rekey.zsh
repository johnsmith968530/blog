#!/bin/zsh

# $Source: /Users/x/Dropbox/2/src/blog/2025/08/11/src/RCS/rekey.zsh,v $
# $Date: 2025/08/11 15:16:44 $
# $Revision: 1.4 $

source getgitblobbykey.sh

eval "$(getgitblobbykey bash echodo)"

tmp_file_keys () { h1=$(git hash-object "$1"); shift; echodo envy universal set git hash "$@" $h1; }

tmp_file_keys getgitblobbykey.sh bash getgitblobbykey
tmp_file_keys useborg.sh bash useborg

# vim: set et ff=unix ft=zsh nocp sts=2 sw=2 ts=2:
