#!/bin/zsh

# $Source: /Users/x/Dropbox/2/src/blog/2025/08/11/src/RCS/test_quantization_2.zsh,v $
# $Date: 2025/08/11 22:10:31 $
# $Revision: 1.2 $

source getgitblobbykey.sh
eval "$(getgitblobbykey bash echodo)"
eval "$(getgitblobbykey bash useborg)"
promptblob1="3144023318fa0ba2a79ae5a7e21a02d6203e0ac4"
models1=(${(f)"$(ollama ls | awk '{print $1}' | grep -v NAME | grep huggingface.co/bartowski/Qwen_Qwen3-4B-Instruct-2507-GGUF | grep IQ2_M)"})
for m1 in $models1
do
  echo "Testing model $m1" && \
  sleep 10 && \
  n1=$(echo -n "$m1" | sed -e 's|[:/]|_|g') && \
  git cat-file blob $promptblob1 | tr -d '\n' | \
    ollama run "$m1" | tee "quantization_test/$promptblob1/result_$n1.md"
done
popd

# vim: set et ff=unix ft=zsh nocp sts=2 sw=2 ts=2:
