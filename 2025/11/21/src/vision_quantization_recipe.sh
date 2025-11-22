#!/bin/bash

# $Source: /Users/x/Dropbox/2/src/blog/2025/11/21/src/RCS/vision_quantization_recipe.sh,v $
# $Date: 2025/11/22 04:11:13 $
# $Revision: 1.2 $

export MODEL1_MAJOR="Qwen"
export MODEL1_MINOR="Qwen3-VL-8B-Thinking"
export MODEL1_Q_BITS="8"
export MODEL1_DTS="$(date -z UTC +%Y%m%d_%H%M%SZ)"

echodo () { echo "$@" && "$@"; }
mkdir -p /tmp/mlx/vlm/convert

# uv tool install -U "mlx-vlm[torch]"

echodo time mlx_vlm.convert \
  --hf-path "$MODEL1_MAJOR/$MODEL1_MINOR" \
  --mlx-path "/tmp/mlx/lm/convert/$MODEL1_DTS" \
  --quantize \
  --q-bits "$MODEL1_Q_BITS" \
  --upload-repo \
    "johnsmith968530/$MODEL1_MAJOR-$MODEL1_MINOR-MLX-${MODEL1_Q_BITS}bit"

# vim: set et ff=unix ft=sh nocp sts=2 sw=2 ts=2:
