# $Source: /home/x/Dropbox/2/src/blog/2026/07/01/src/RCS/monthstamp.zsh,v $
# $Date: 2026/07/02 03:59:21 $
# $Revision: 1.1 $

# Usage:
#
#   : ${BLOG_ROOT:=$(envy get global blog root)}
#   (( ${+functions[monthstamp]} )) || . "$BLOG_ROOT/2026/07/01/src/monthstamp.zsh"
#

monthstamp () { date '+%Y/%m' }

# vim: set et ff=unix ft=zsh nocp sts=2 sw=2 ts=2:
