# $Source: /home/x/Dropbox/2/src/blog/2026/07/01/src/RCS/camera_uploads.zsh,v $
# $Date: 2026/07/02 03:59:21 $
# $Revision: 1.1 $

# In .zshenv:
#
#   : ${BLOG_ROOT:=$(envy get global blog root)}
#   (( ${+functions[camera_uploads]} )) || . "$BLOG_ROOT/2026/07/01/src/camera_uploads.zsh"
#

(( ${+functions[monthstamp]} )) || . "$(envy get global blog root)/2026/07/01/src/monthstamp.zsh"

camera_uploads() {
  local d1
  d1="$HOME/Dropbox/Camera Uploads/$(monthstamp)"
  mkdir -p "$d1" || return 1
  print -r -- "$d1"
}

alias cd.cu='cd "$(camera_uploads)"'

# vim: set et ff=unix ft=zsh nocp sts=2 sw=2 ts=2:
