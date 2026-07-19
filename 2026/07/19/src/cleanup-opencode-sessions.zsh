#!/usr/bin/env zsh

# $Source$
# $Date$
# $Revision$

# Delete every OpenCode session.
emulate -L zsh
setopt err_return no_unset pipe_fail

for id in $(opencode session list --format json | jq -r '.[].id'); do
  opencode session delete "$id"
  print "deleted: $id"
done

# vim: set et ff=unix ft=zsh nocp sts=2 sw=2 ts=2:
