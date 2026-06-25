# $Source: /home/x/Dropbox/2/src/blog/2026/06/25/src/RCS/tmp.zsh,v $
# $Date: 2026/06/25 20:44:17 $
# $Revision: 1.3 $

# In .zshenv:
#
#   (( ${+functions[tmp]} )) || . "$(envy get global blog root)/2026/06/25/src/tmp.zsh"
#

(( ${+functions[datestamp]} )) || . "$(envy get global blog root)/2026/06/25/src/datestamp.zsh"

tmp() {
  local tmp1
  tmp1="/tmp/com/m0x13/$(datestamp)"
  mkdir -p "$tmp1" || return 1
  print -r -- "$tmp1"
}

alias cd.tmp='cd "$(tmp)"'

# vim: set et ff=unix ft=zsh nocp sts=2 sw=2 ts=2:
