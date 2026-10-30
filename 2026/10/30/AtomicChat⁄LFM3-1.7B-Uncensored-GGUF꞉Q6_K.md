# Some `zsh` commands for backing up a Hugging Face repo (tweaked lightly from the procedure for [AtomicChat⁄LFM3-VL-2B-GGUF꞉Q8_0](../28/AtomicChat⁄LFM3-VL-2B-GGUF꞉Q8_0.md)):

```zsh
. "$BLOG_ROOT/2026/10/22/slugify_path.zsh"

export HF0="/run/media/x/h365/co/huggingface"

export X1="AtomicChat/LFM3-1.7B-Uncensored-GGUF"
export Q1="Q6_K"
export X2="$X1"

export X2="$X2:$Q1"

export X2=$(slugify_path "$X2")

echo "$HF0/$X2"

R1="$(blog)/${X2}.md" && echo "$R1"

mkdir -p "$HF0/$X2"
uv tool upgrade hf

hf download --local-dir "$HF0/$X2" "hf://$X1" --include "*$Q1*" --dry-run
export HF_XET_RECONSTRUCT_WRITE_SEQUENTIALLY=1
hf download --local-dir "$HF0/$X2" "hf://$X1" --include "*$Q1*"

export SLUG1="🤗⁄$(slugify_path "$X2")★$(stardate)" && echo "$SLUG1"
cd "$HF0" && borg-backup.py --exact-name --no-excludes "$SLUG1" "$X2"
hf cache verify --local-dir "$HF0/$X2" "$X1"

lms import --copy "$HF0/$X2/LFM3-1.7B-Uncensored-AD-Q6_K.gguf"

✔ Choose categorization option Auto search Hugging Face (Recommended for models downloaded from Hugging Face)
Searching for the model on Hugging Face using the file name...
Found the following repositories on Hugging Face containing this file:
✔ Please select the correct one | AtomicChat/LFM3-1.7B-Uncensored-GGUF
File copied to /home/x/.lmstudio/models/AtomicChat/LFM3-1.7B-Uncensored-GGUF/LFM3-1.7B-Uncensored-AD-Q6_K.gguf

rm -rf "$HF0/$X2"
```
