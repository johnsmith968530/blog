#!/bin/bash

# $Source: /Users/x/Dropbox/2/src/blog/2025/11/21/src/RCS/quantization_recipe.sh,v $
# $Date: 2025/11/21 20:47:08 $
# $Revision: 1.3 $

export MODEL1_MAJOR="Goekdeniz-Guelmez"
export MODEL1_MINOR="Josiefied-Qwen3-14B-abliterated-v3"
export MODEL1_Q_BITS="8"
export MODEL1_DTS="$(date -z UTC +%Y%m%d_%H%M%SZ)"

echodo () { echo "$@" && "$@"; }
mkdir -p /tmp/mlx/lm/convert

echodo time mlx_lm.convert \
  --hf-path "$MODEL1_MAJOR/$MODEL1_MINOR" \
  --mlx-path "/tmp/mlx/lm/convert/$MODEL1_DTS" \
  --quantize \
  --q-bits "$MODEL1_Q_BITS" \
  --upload-repo \
    "johnsmith968530/$MODEL1_MAJOR-$MODEL1_MINOR-MLX-${MODEL1_Q_BITS}bit"

# vim: set et ff=unix ft=sh nocp sts=2 sw=2 ts=2:
