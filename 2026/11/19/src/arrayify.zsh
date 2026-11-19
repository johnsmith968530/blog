# $Source: /home/x/Dropbox/2/src/blog/2026/11/19/src/RCS/arrayify.zsh,v $
# $Date: 2026/11/19 15:59:49 $
# $Revision: 1.2 $

# Put the following in ~/.zshrc :
#
#   : ${BLOG0:=$(envy get global blog root)}
#   (( ${+functions[arrayify]} )) || . "$BLOG0/2026/11/19/src/arrayify.zsh"
#

arrayify() { print -rn -- '"${'"$1"'[@]}"' | xclip -selection clipboard }

# vim: set et ff=unix ft=zsh nocp sts=2 sw=2 ts=2:
