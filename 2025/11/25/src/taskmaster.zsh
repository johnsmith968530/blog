#!/bin/zsh

# $Source: /Users/x/Dropbox/2/src/blog/2025/11/25/src/RCS/taskmaster.zsh,v $
# $Date: 2025/11/25 21:02:44 $
# $Revision: 1.3 $

alias hc="taskmaster copy"
alias hi="taskmaster inspect"
alias hl="taskmaster find"
hx () {
  local x1="$1"
  local d1="$HOME/.cache/taskmaster"
  mkdir -p "$d1"
  local f1="$d1/$x1"
  taskmaster print "$x1" > "$f1"
  source "$f1"
}

# vim: set et ff=unix ft=zsh nocp sts=2 sw=2 ts=2:
