#!/usr/bin/env zsh

# $Source: /home/x/Dropbox/2/src/blog/RCS/backup.zsh,v $
# $Date: 2026/07/30 14:54:37 $
# $Revision: 1.1 $

: ${BLOG_ROOT:=$(envy get global blog root)}
cd "$BLOG_ROOT/.."

notes=()
for note in "$@"; do
  notes+=(--note "$note")
done

~/Dropbox/1/bin/borg-backup.py blog blog "${notes[@]}"

# vim: set et ff=unix ft=zsh nocp sts=2 sw=2 ts=2:
