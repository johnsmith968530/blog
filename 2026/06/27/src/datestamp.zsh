# $Source: /home/x/Dropbox/2/src/blog/2026/06/27/src/RCS/datestamp.zsh,v $
# $Date: 2026/06/28 04:02:41 $
# $Revision: 1.2 $

# Usage:
#
#   : ${BLOG_ROOT:=$(envy get global blog root)}
#   (( ${+functions[datestamp]} )) || . "$BLOG_ROOT/2026/06/27/src/datestamp.zsh"
#

datestamp () { date '+%Y/%m/%d' }

# vim: set et ff=unix ft=zsh nocp sts=2 sw=2 ts=2:
