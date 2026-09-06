#!/usr/bin/env zsh

# $Source$
# $Date$
# $Revision$

. /mnt/git/com/github/ggml-org/llama.cpp/.venv/bin/activate
export MODEL_ROOT="/home/x/.cache/huggingface/hub/models--orcarouter--GLM-5.3-Flash-Uncensored-FP8"
export MODEL1="$MODEL_ROOT/snapshots/"$(cat "$MODEL_ROOT/refs/main")
export OUTFILE1="/mnt/h367/test1/Orcarouter-GLM-5.3-Flash-Uncensored-TQ2_0.gguf"

/mnt/git/com/github/ggml-org/llama.cpp/build/bin/llama-server \
  -m "$OUTFILE1" \
  --load-mode mmap \
  -c 256 \
  -np 1 \
  -fa off

# vim: set et ff=unix ft=zsh nocp sts=2 sw=2 ts=2:
