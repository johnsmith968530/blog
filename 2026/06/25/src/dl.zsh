# $Source: /Users/x/Dropbox/2/src/blog/2026/06/25/src/RCS/dl.zsh,v $
# $Date: 2026/06/25 19:27:51 $
# $Revision: 1.1 $

(( ${+functions[datestamp]} )) || source "$(envy get global blog root)/2026/06/25/src/datestamp.zsh"

dl() {
  local dl1
  dl1="$HOME/Downloads/$(datestamp)"
  mkdir -p "$dl1" || return 1
  print -r -- "$dl1"
}

alias cd.dl='cd "$(dl)"'

# vim: set et ff=unix ft=zsh nocp sts=2 sw=2 ts=2:
