# Some `zsh` commands for backing up a Hugging Face repo (tweaked lightly from [2026-10-22](/home/x/Dropbox/2/src/blog/2026/10/22/AtomicChat⁄DeepSeek-V4.1-Flash-1017-Uncensored-GGUF꞉Q2_K.md)):

```zsh
. "$BLOG_ROOT/2026/10/22/slugify_path.zsh"

export HF0="/run/media/x/h365/co/huggingface"

export X1="LiquidAI/LFM3-Omni-2B-GGUF"
export Q1="Q8_0"
export X2="$X1"

export X2="$X2:$Q1"

export X2=$(slugify_path "$X2")

echo "$HF0/$X2"

R1="${X2}.md"

mkdir -p "$HF0/$X2"
uv tool upgrade hf

hf download --local-dir "$HF0/$X2" "hf://$X1" --include "*$Q1*" --dry-run
export HF_XET_RECONSTRUCT_WRITE_SEQUENTIALLY=1
hf download --local-dir "$HF0/$X2" "hf://$X1" --include "*$Q1*"

export SLUG1="🤗⁄$(slugify_path "$X2")★$(stardate)" && echo "$SLUG1"
cd "$HF0" && borg-backup.py --exact-name --no-excludes "$SLUG1" "$X2"
hf cache verify --local-dir "$HF0/$X2" "$X1"

lms import --copy "$HF0/$X2" # This requires a more recent version of llama.cpp than LM Studio currently has, I think

prependtopathset PATH /usr/local/llama.cpp/llama-b11960
llama-server -m "$HF0/$X2/LFM3-Omni-2B-Q8_0.gguf" -mm "$HF0/$X2/mmproj-LFM3-Omni-2B-Q8_0.gguf"
llama-tts -m "$HF0/$X2/LFM3-Omni-2B-Q8_0.gguf" -mm "$HF0/$X2/mmproj-LFM3-Omni-2B-Q8_0.gguf" -p "Hello, world." -o $(tmp)/hello.wav
```
