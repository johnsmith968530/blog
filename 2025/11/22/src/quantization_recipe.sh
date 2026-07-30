#!/bin/bash

# $Source: /Users/x/Dropbox/2/src/blog/2025/11/22/src/RCS/quantization_recipe.sh,v $
# $Date: 2025/11/23 06:58:39 $
# $Revision: 1.7 $

export MODEL1_MAJOR="PleIAs"
export MODEL1_MINOR="Baguettotron"
export MODEL1_Q_BITS="8"
export MODEL1_DTS="$(date -z UTC +%Y%m%d_%H%M%SZ)"

echodo () { echo "$@" && "$@"; }
mkdir -p /tmp/mlx/lm/convert

# uv tool install -U mlx-lm

echodo time mlx_lm.convert \
  --hf-path "$MODEL1_MAJOR/$MODEL1_MINOR" \
  --mlx-path "/tmp/mlx/lm/convert/$MODEL1_DTS" \
  --quantize \
  --q-bits "$MODEL1_Q_BITS" \
  --upload-repo \
    "johnsmith968530/$MODEL1_MAJOR-$MODEL1_MINOR-MLX-${MODEL1_Q_BITS}bit"

# I tested the result using LM Studio 0.3.31
# on a MacBook Air, 13 inch, M4, 2025 with 32 GB unified memory
# macOS Tahoe 26.1.

# vim: set et ff=unix ft=sh nocp sts=2 sw=2 ts=2:
