# $Source: /Users/x/Dropbox/2/src/blog/2026/06/25/src/RCS/blog.zsh,v $
# $Date: 2026/06/25 15:41:07 $
# $Revision: 1.1 $

(( ${+functions[datestamp]} )) || source "$(envy get global blog root)/2026/06/25/src/datestamp.zsh"

blog() {
  local blog1
  blog1="$(envy get global blog root)/$(datestamp)"
  mkdir -p "$blog1" || return 1
  print -r -- "$blog1"
}

alias cd.blog='cd "$(blog)"'

# vim: set et ff=unix ft=zsh nocp sts=2 sw=2 ts=2:
