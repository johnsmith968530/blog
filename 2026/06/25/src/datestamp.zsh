# $Source: /home/x/Dropbox/2/src/blog/2026/06/25/src/RCS/datestamp.zsh,v $
# $Date: 2026/06/25 21:10:52 $
# $Revision: 1.2 $

# Usage:
#
#   (( ${+functions[datestamp]} )) || . "$(envy get global blog root)/2026/06/25/src/datestamp.zsh"
#

datestamp () { date '+%Y/%m/%d' }

# vim: set et ff=unix ft=zsh nocp sts=2 sw=2 ts=2:
