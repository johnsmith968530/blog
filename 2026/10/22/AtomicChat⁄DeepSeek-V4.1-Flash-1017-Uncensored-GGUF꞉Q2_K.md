# Some `zsh` commands for backing up a Hugging Face repo (tweaked lightly from [2026-10-14](../../10/14)):

```zsh
. "$BLOG_ROOT/2026/10/22/slugify_path.zsh"

export HF0="/run/media/x/h365/co/huggingface"

export X1="AtomicChat/DeepSeek-V4.1-Flash-1017-Uncensored-GGUF"
export Q1="Q2_K"
export X2="$X1"

export X2="$X2:$Q1"

export X2="${X2//:/꞉}"

echo "$HF0/$X2"

R1=$(slugify_path "${X2}.md")

mkdir -p "$HF0/$X2"
uv tool upgrade hf

# This HuggingFace repo puts each quantization in its own subdirectory.
hf download --local-dir "$HF0/$X2" "hf://$X1" --include "*$Q1/*" --dry-run
export HF_XET_RECONSTRUCT_WRITE_SEQUENTIALLY=1
hf download --local-dir "$HF0/$X2" "hf://$X1" --include "*$Q1/*"
```
