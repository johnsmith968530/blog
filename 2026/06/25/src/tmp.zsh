# $Source: /Users/x/Dropbox/2/src/blog/2026/06/25/src/RCS/tmp.zsh,v $
# $Date: 2026/06/25 15:41:18 $
# $Revision: 1.1 $

(( ${+functions[datestamp]} )) || source "$(envy get global blog root)/2026/06/25/src/datestamp.zsh"

tmp() {
  local tmp1
  tmp1="/tmp/com/m0x13/$(datestamp)"
  mkdir -p "$tmp1" || return 1
  print -r -- "$tmp1"
}

alias cd.tmp='cd "$(tmp)"'

# vim: set et ff=unix ft=zsh nocp sts=2 sw=2 ts=2:
