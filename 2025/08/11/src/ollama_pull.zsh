#!/bin/zsh

# $Source: /Users/x/Dropbox/2/src/blog/2025/08/11/src/RCS/ollama_pull.zsh,v $
# $Date: 2025/08/11 16:43:24 $
# $Revision: 1.1 $

source getgitblobbykey.sh
eval $(getgitblobbykey bash echodo)
eval $(getgitblobbykey bash redis-stringstack)

echo "Original URL: $(rS0)"
prS `echo -n "$(rS0)" | sed -E \
  's|^https?://||;s|/blob/main/[^/]+-([^/.]+)\.gguf$|:\1|'`
echo "Ollama name: $(rS0)"
sleep 10
echodo ollama pull "$(rS0)"

# vim: set et ff=unix ft=zsh nocp sts=2 sw=2 ts=2:
