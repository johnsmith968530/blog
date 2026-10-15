```text
$Source: /home/x/Dropbox/2/src/blog/2026/10/14/RCS/README.md,v $
$Date: 2026/10/15 15:27:26 $
$Revision: 1.1 $
```

Some `zsh` commands for backing up a Hugging Face repo (tweaked lightly from [2026-09-30](../../09/30)):

```zsh
export HF0="/run/media/x/h365/co/huggingface"
export X1="AtomicChat/LFM2.5-24B-A2B-Uncensored-GGUF"
export Q1="Q8_0"
export X2="$X1"
export X2="$X2:$Q1"
export X2="${X2//:/꞉}"
echo "$HF0/$X2"
mkdir -p "$HF0/$X2"
# hf download --local-dir "$HF0/$X2" "hf://$X1" --include "mmproj*" --include "*$Q1.gguf" --dry-run
hf download --local-dir "$HF0/$X2" "hf://$X1" --include "*$Q1.gguf" --dry-run

export HF_XET_RECONSTRUCT_WRITE_SEQUENTIALLY=1
# hf download --local-dir "$HF0/$X2" "hf://$X1" --include "mmproj*" --include "*$Q1.gguf"
hf download --local-dir "$HF0/$X2" "hf://$X1" --include "*$Q1.gguf"

slugify_path() {
    local s="$1"
    s="${s//\//⁄}"
    s="${s//:/꞉}"
    print -r -- "$s"
}

unslugify_path() {
    local s="$1"
    s="${s//⁄//}"
    s="${s//꞉/:}"
    print -r -- "$s"
}

export SLUG1="🤗⁄$(slugify_path "$X2")★$(stardate)" && echo "$SLUG1"

cd "$HF0" && borg-backup.py --exact-name --no-excludes "$SLUG1" "$X2"

hf cache verify --local-dir "$HF0/$X2" "$X1"

lms import --copy /run/media/x/h365/co/huggingface/AtomicChat/LFM2.5-24B-A2B-Uncensored-GGUF꞉Q8_0/LFM2.5-24B-A2B-Uncensored-AD-Q8_0.gguf

rm -rf "$HF0/$X2"
```

```text
vim: set et ff=unix ft=markdown nocp sts=2 sw=2 ts=2:
```
