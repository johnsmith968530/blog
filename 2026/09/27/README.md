```text
$Source: /home/x/Dropbox/2/src/blog/2026/09/27/RCS/README.md,v $
$Date: 2026/09/27 15:43:10 $
$Revision: 1.1 $
```

Some `zsh` commands for backing up a Hugging Face repo (updated from [yesterday](../26)):

```zsh
export HF0="/run/media/x/h365/co/huggingface"
export X1="datasets/XiaomiMiMo/MiMo-V2.6-RL-oss"
export X2="${X1//:/꞉}"
mkdir -p "$HF0/$X2"
hf download --local-dir "$HF0/$X2" "hf://$X1" --dry-run

export HF_XET_RECONSTRUCT_WRITE_SEQUENTIALLY=1
hf download --local-dir "$HF0/$X1" "hf://$X1"

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

export SLUG1="🤗⁄$(slugify_path "$X1")★$(stardate)" && echo "$SLUG1"

cd "$HF0"
borg-backup.py --exact-name --no-excludes "$SLUG1" "$X1"

hf cache verify --fail-on-missing-files --local-dir "$HF0/$X1" "$X1"
```

```text
vim: set et ff=unix ft=markdown nocp sts=2 sw=2 ts=2:
```
