#!/bin/zsh

# $Source: /Users/x/Dropbox/2/src/blog/2025/09/03/src/RCS/rekey.zsh,v $
# $Date: 2025/09/04 01:35:43 $
# $Revision: 1.2 $

source getgitblobbykey.sh

eval "$(getgitblobbykey bash echodo)"

tmp_file_keys () { h1=$(git hash-object "$1"); shift; echodo envy set universal git hash "$@" $h1; }

tmp_file_keys evalgitblobbykey.sh bash evalgitblobbykey
tmp_file_keys getgitblobbykey.sh bash getgitblobbykey
tmp_file_keys logdir.sh bash logdir
tmp_file_keys useborg.sh bash useborg
tmp_file_keys mkdircd.sh bash mkdircd
tmp_file_keys redis-stardatestack.sh bash redis-stardatestack
tmp_file_keys redis-stringstack.sh bash redis-stringstack

# vim: set et ff=unix ft=zsh nocp sts=2 sw=2 ts=2:
