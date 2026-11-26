# Some `zsh` commands for backing up a Hugging Face repo.

```zsh
. "$BLOG_ROOT/2026/10/22/slugify_path.zsh"
. "$BLOG_ROOT/2025/08/06/src/echodo.sh"

export HF_XET_RECONSTRUCT_WRITE_SEQUENTIALLY=1
export HF0="/mnt/h374/co/huggingface"

export X1="ggml-org/parakeet-GGUF"
export MODEL1="ggml-parakeet-tdt-0.6b-v3-f32.bin"

export X2="$X1"

export X2="$X2:$MODEL1"

export X2=$(slugify_path "$X2")

echo "$HF0/$X2"

R1="$(blog)/${X2}.md" && echo "$R1"

echodo mkdir -p "$HF0/$X2"
echodo uv tool upgrade hf

echodo hf download --local-dir "$HF0/$X2" "hf://$X1" --include "*$MODEL1*" --dry-run
echodo hf download --local-dir "$HF0/$X2" "hf://$X1" --include "*$MODEL1*"

export SLUG1="🤗⁄$X2★$(stardate)" && echo "$SLUG1"
cd "$HF0" && borg-backup.py --exact-name --no-excludes "$SLUG1" "$X2"
echodo hf cache verify --local-dir "$HF0/$X2" "$X1"
echodo borg list --short "::$SLUG1"

echodo rm -rf "$HF0/$X2"
```
