# $Source: /home/x/Dropbox/2/src/blog/2026/06/27/src/RCS/tmp.zsh,v $
# $Date: 2026/06/28 04:02:20 $
# $Revision: 1.1 $

# In .zshenv:
#
#   : ${BLOG_ROOT:=$(envy get global blog root)}
#   (( ${+functions[tmp]} )) || . "$BLOG_ROOT/2026/06/27/src/tmp.zsh"
#

(( ${+functions[datestamp]} )) || . "$BLOG_ROOT/2026/06/27/src/datestamp.zsh"

tmp() {
  local tmp1
  tmp1="/tmp/com/m0x13/$(datestamp)"
  mkdir -p "$tmp1" || return 1
  print -r -- "$tmp1"
}

alias cd.tmp='cd "$(tmp)"'

# vim: set et ff=unix ft=zsh nocp sts=2 sw=2 ts=2:
