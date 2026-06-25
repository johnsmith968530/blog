# $Source: /Users/x/Dropbox/2/src/blog/2026/06/25/src/RCS/blog.zsh,v $
# $Date: 2026/06/25 19:15:18 $
# $Revision: 1.2 $

(( ${+functions[datestamp]} )) || source "$(envy get global blog root)/2026/06/25/src/datestamp.zsh"
(( ${+functions[prependtopathset]} )) || source "$(envy get global blog root)/2026/06/25/src/prependtopathset.zsh"

blog() {
  local blog1
  blog1="$(envy get global blog root)/$(datestamp)"
  mkdir -p "$blog1" || return 1
  print -r -- "$blog1"
}

alias cd.blog='cd "$(blog)"'

prependtopathset PATH "$(blog)/src"

# vim: set et ff=unix ft=zsh nocp sts=2 sw=2 ts=2:
