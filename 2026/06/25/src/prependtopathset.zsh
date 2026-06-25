# $Source: /home/x/Dropbox/2/src/blog/2026/06/25/src/RCS/prependtopathset.zsh,v $
# $Date: 2026/06/25 21:09:12 $
# $Revision: 1.2 $

# Usage:
#
#   (( ${+functions[prependtopathset]} )) || . "$(envy get global blog root)/2026/06/25/src/prependtopathset.zsh"
#
#   prependtopathset PATH "/Applications/Google Chrome.app/Contents/MacOS"
#
prependtopathset () {
  local v="$1"
  shift
  local x
  for x in "$@"
  do
    if [ -e "$x" ] &&
       [[ ! "${(P)v}" =~ (^|:)"$x"(:|$) ]]
    then
      if [ -z "${(P)v}" ]
      then
        export "$v"="$x"
      else
        export "$v"="$x:${(P)v}"
      fi
    fi
  done
}

# vim: set et ff=unix ft=zsh nocp sts=2 sw=2 ts=2:
