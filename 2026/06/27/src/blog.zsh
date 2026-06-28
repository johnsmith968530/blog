# $Source: /home/x/Dropbox/2/src/blog/2026/06/27/src/RCS/blog.zsh,v $
# $Date: 2026/06/28 03:58:39 $
# $Revision: 1.1 $

# In .zshenv:
#
#   : ${BLOG_ROOT:=$(envy get global blog root)}
#   (( ${+functions[blog]} )) || . "$BLOG_ROOT/2026/06/27/src/blog.zsh"
#

: ${BLOG_ROOT:=$(envy get global blog root)}
(( ${+functions[datestamp]} )) || . "$BLOG_ROOT/2026/06/27/src/datestamp.zsh"
(( ${+functions[prependtopathset]} )) || . "$BLOG_ROOT/2026/06/27/src/prependtopathset.zsh"

blog() {
  local blog1
  blog1="$BLOG_ROOT/$(datestamp)"
  mkdir -p "$blog1" || return 1
  print -r -- "$blog1"
}

blog_url() {
  print -r -- "https://github.com/johnsmith968530/blog/tree/here-and-now/$(datestamp)"
}

alias cd.blog='cd "$(blog)"'

prependtopathset PATH "$(blog)/src"

# vim: set et ff=unix ft=zsh nocp sts=2 sw=2 ts=2:
