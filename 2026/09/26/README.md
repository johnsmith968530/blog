```text
$Source: /home/x/Dropbox/2/src/blog/2026/09/26/RCS/README.md,v $
$Date: 2026/09/26 21:13:21 $
$Revision: 1.1 $
```

export D0="/run/media/x/h365/co/huggingface"
export X1="zai-org/GLM-5.3"
mkdir -p "$D0/$X1"
hf download --local-dir "$D0/$X1" "$X1" --dry-run

export HF_XET_RECONSTRUCT_WRITE_SEQUENTIALLY=1
hf download --local-dir "$D0/$X1" "$X1"

slugify_path() {
    print -r -- "${1//\//⁄}"
}

unslugify_path() {
    print -r -- "${1//⁄//}"
}

export SLUG1="🤗⁄$(slugify_path "$X1")★$(stardate)" && echo "$SLUG1"

cd "$D0"
borg-backup.py --exact-name --no-excludes "$SLUG1" "$X1"

hf cache verify --fail-on-missing-files --local-dir "$D0/$X1" "$X1"

```text
vim: set et ff=unix ft=markdown nocp sts=2 sw=2 ts=2:
```
