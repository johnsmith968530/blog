# $Source: /home/x/Dropbox/2/src/blog/2026/11/23/src/RCS/dl.zsh,v $
# $Date: 2026/11/23 20:47:19 $
# $Revision: 1.2 $

# In .zshenv:
#
#   : ${BLOG_ROOT:=$(envy get global blog root)}
#   (( ${+functions[dl]} )) || . "$BLOG_ROOT/2026/11/23/src/dl.zsh"
#

(( ${+functions[datestamp]} )) || . "$(envy get global blog root)/2026/06/27/src/datestamp.zsh"

export DOWNLOADS0="${DOWNLOADS0:-/home/x/Downloads}"

dl() {
  local dl1
  dl1="$DOWNLOADS0/$(datestamp)"
  mkdir -p "$dl1" || return 1
  print -r -- "$dl1"
}

alias cd.dl0='cd "$DOWNLOADS0"'
alias cd.dl1='cd "$(dl)"'

# vim: set et ff=unix ft=zsh nocp sts=2 sw=2 ts=2:
