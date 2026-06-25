# $Source: /home/x/Dropbox/2/src/blog/2026/06/25/src/RCS/blog.zsh,v $
# $Date: 2026/06/25 20:43:14 $
# $Revision: 1.5 $

# In .zshenv:
#
#   (( ${+functions[blog]} )) || . "$(envy get global blog root)/2026/06/25/src/blog.zsh"
#

(( ${+functions[datestamp]} )) || . "$(envy get global blog root)/2026/06/25/src/datestamp.zsh"
(( ${+functions[prependtopathset]} )) || . "$(envy get global blog root)/2026/06/25/src/prependtopathset.zsh"

blog() {
  local blog1
  blog1="$(envy get global blog root)/$(datestamp)"
  mkdir -p "$blog1" || return 1
  print -r -- "$blog1"
}

blog_url() {
  print -r -- "https://github.com/johnsmith968530/blog/tree/here-and-now/$(datestamp)"
}

alias cd.blog='cd "$(blog)"'

prependtopathset PATH "$(blog)/src"

# vim: set et ff=unix ft=zsh nocp sts=2 sw=2 ts=2:
