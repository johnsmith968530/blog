# $Source: /home/x/Dropbox/2/src/blog/2026/06/25/src/RCS/dl.zsh,v $
# $Date: 2026/06/25 20:44:17 $
# $Revision: 1.3 $

# In .zshenv:
#
#   (( ${+functions[dl]} )) || . "$(envy get global blog root)/2026/06/25/src/dl.zsh"
#

(( ${+functions[datestamp]} )) || . "$(envy get global blog root)/2026/06/25/src/datestamp.zsh"

dl() {
  local dl1
  dl1="$HOME/Downloads/$(datestamp)"
  mkdir -p "$dl1" || return 1
  print -r -- "$dl1"
}

alias cd.dl='cd "$(dl)"'

# vim: set et ff=unix ft=zsh nocp sts=2 sw=2 ts=2:
