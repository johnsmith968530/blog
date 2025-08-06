# $Source: /Users/x/Dropbox/2/src/blog/2025/08/06/src/RCS/prependtopathset.zsh,v $
# $Date: 2025/08/06 20:40:34 $
# $Revision: 1.2 $

# Usage:
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

# vim: set et ff=unix ft=sh nocp sts=2 sw=2 ts=2:
