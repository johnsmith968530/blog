# $Source: /home/x/Dropbox/2/src/blog/2026/06/27/src/RCS/dl.zsh,v $
# $Date: 2026/06/28 04:02:20 $
# $Revision: 1.1 $

# In .zshenv:
#
#   : ${BLOG_ROOT:=$(envy get global blog root)}
#   (( ${+functions[dl]} )) || . "$BLOG_ROOT/2026/06/27/src/dl.zsh"
#

(( ${+functions[datestamp]} )) || . "$(envy get global blog root)/2026/06/27/src/datestamp.zsh"

dl() {
  local dl1
  dl1="$HOME/Downloads/$(datestamp)"
  mkdir -p "$dl1" || return 1
  print -r -- "$dl1"
}

alias cd.dl='cd "$(dl)"'

# vim: set et ff=unix ft=zsh nocp sts=2 sw=2 ts=2:
