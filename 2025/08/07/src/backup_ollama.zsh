#!/bin/zsh

# $Source: /Users/x/Dropbox/2/src/blog/2025/08/07/src/RCS/backup_ollama.zsh,v $
# $Date: 2025/08/07 19:05:26 $
# $Revision: 1.1 $

eval "$(git cat-file blob a8cc2ba487a5b52d00fff816ccb2b8b057b2f143)" # echodo

backup_ollama () {
  if [ -z "$1" ]; then
    echo "Usage: backup_ollama <n>"
    return 1
  fi
  local t1="$(envy global get ollama models backup $1)"
  if [ -z "$t1" ]; then
    echo "envy global get ollama models backup $1 returned nothing"
    return 2
  fi
  echodo rsync -avP ~/.ollama/models/ "$t1/"
}

# vim: set et ff=unix ft=zsh nocp sts=2 sw=2 ts=2:
