#!/bin/bash

# $Source: /Users/x/Dropbox/2/src/blog/2025/09/19/src/envy/RCS/deploy.sh,v $
# $Date: 2025/09/19 17:26:51 $
# $Revision: 1.1 $

echodo () { echo "$@" && "$@"; }

echodo cp "target/debug/envy" "$(which envy)"

# vim: set et ff=unix ft=sh nocp sts=2 sw=2 ts=2:
