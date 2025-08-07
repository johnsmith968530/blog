# $Source: /Users/x/Dropbox/2/src/blog/2025/08/06/src/RCS/setenv.zsh,v $
# $Date: 2025/08/06 21:58:55 $
# $Revision: 1.1 $

# Use a function so we can scope temporary variables and hide them from
# the global namespace.
tmp1 () {
  local blog_root="$(envy global get blog root)"
  pushd "$blog_root"
  local src="$blog_root/2025/08/06/src"
  local f1
  for f1 in \
    echodo.sh \
    getgitblobbyhash.sh \
    getgitblobbykey.sh \
    mkdircd.sh \
    prependtopathset.zsh \
    redis-stardatestack.sh \
    redis-stringstack.sh \
    aliases.zsh \

  do
#   echo "$src/$f1"
    source "$src/$f1"
  done
  local src="$blog_root/2025/08/07/src"
  for f1 in \
    backup_ollama.zsh \

  do
#   echo "$src/$f1"
    source "$src/$f1"
  done
  popd
}

tmp1

prependtopathset PATH /Applications/Google\ Chrome.app/Contents/MacOS
prependtopathset PATH /Applications/VLC.app/Contents/MacOS

# vim: set et ff=unix ft=zsh nocp sts=2 sw=2 ts=2:
