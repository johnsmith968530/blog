#!/bin/zsh

# $Source: /Users/x/Dropbox/2/src/blog/2025/09/15/src/RCS/ollama_pull.zsh,v $
# $Date: 2025/09/15 08:37:19 $
# $Revision: 1.2 $

source evalgitblobbykey.sh
evalgitblobbykey bash logdir
evalgitblobbykey bash echodo
evalgitblobbykey bash redis-stringstack

echo "Original URL: $(rS0)"
prS `echo -n "$(rS0)" | sed -E \
  's|^https?://||;s|/blob/main/[^/]+-([^/.]+)\.gguf$|:\1|'`
echo "Ollama name: $(rS0)"
sleep 10
echodo ollama pull "$(rS0)" && \
  echo "$(stardate) $(rS0) $(rS1)" | tee -a "$LOGDIR1/ollama_pull.log"

# vim: set et ff=unix ft=zsh nocp sts=2 sw=2 ts=2:
