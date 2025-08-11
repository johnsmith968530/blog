#!/bin/zsh

# $Source: /Users/x/Dropbox/2/src/blog/2025/08/11/src/RCS/test_quantization_1.zsh,v $
# $Date: 2025/08/11 21:56:28 $
# $Revision: 1.3 $

source getgitblobbykey.sh
eval "$(getgitblobbykey bash echodo)"
eval "$(getgitblobbykey bash useborg)"
promptblob1="9f47dd79feaf9b10976b8650d4ea7c8bb9741dfd"
models1=(${(f)"$(ollama ls | awk '{print $1}' | grep -v NAME | grep huggingface.co/bartowski/Qwen_Qwen3-4B-Instruct-2507-GGUF)"})
for m1 in $models1
do
  echo "Testing model $m1" && \
  n1=$(echo -n "$m1" | sed -e 's|[:/]|_|g') && \
  git cat-file blob $promptblob1 | tr -d '\n' | \
    ollama run "$m1" | tee "quantization_test/$promptblob1/result_$n1.txt"
done
popd

# vim: set et ff=unix ft=zsh nocp sts=2 sw=2 ts=2:
