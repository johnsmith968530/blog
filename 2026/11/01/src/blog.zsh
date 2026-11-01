# $Source: /home/x/Dropbox/2/src/blog/2026/11/01/src/RCS/blog.zsh,v $
# $Date: 2026/11/01 18:42:33 $
# $Revision: 1.2 $

# Adapted from $BLOG0/2026/06/27/src/blog.zsh
#
# In .zshenv:
#
#   : ${BLOG0:=$(envy get global blog root)}
#   (( ${+functions[blog]} )) || . "$BLOG0/2026/11/01/src/blog.zsh"
#

: ${BLOG0:=$(envy get global blog root)}
: ${BLOG_ROOT:=$BLOG0}
(( ${+functions[datestamp]} )) || . "$BLOG_ROOT/2026/06/27/src/datestamp.zsh"
(( ${+functions[prependtopathset]} )) || . "$BLOG_ROOT/2026/06/27/src/prependtopathset.zsh"

blog() {
  local blog1
  blog1="$BLOG0/$(datestamp)"
  mkdir -p "$blog1" || return 1
  print -r -- "$blog1"
}

blog_url() {
  print -r -- "https://github.com/johnsmith968530/blog/tree/here-and-now/$(datestamp)"
}

alias cd.blog='cd "$(blog)"'
alias cd.blog0='cd "$BLOG0"'
alias cd.blog1='cd "$(blog)"'

prependtopathset PATH "$(blog)/src"

# vim: set et ff=unix ft=zsh nocp sts=2 sw=2 ts=2:
