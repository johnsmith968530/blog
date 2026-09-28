```text
$Source: /home/x/Dropbox/2/src/blog/2026/09/28/RCS/README.md,v $
$Date: 2026/09/28 22:11:25 $
$Revision: 1.4 $
```

Some `zsh` commands for backing up a Hugging Face repo (tweaked lightly from [yesterday](../27)):

```zsh
export HF0="/run/media/x/h365/co/huggingface"
export X1="bartowski/TheDrummer_Artemis-31B-v1.2-GGUF"
export Q1="Q8_0"
export X2="$X1:$Q1"
export X2="${X2//:/꞉}"
echo "$HF0/$X2"
mkdir -p "$HF0/$X2"
hf download --local-dir "$HF0/$X2" "hf://$X1" --include "mmproj*" --include "*$Q1.gguf" --dry-run

export HF_XET_RECONSTRUCT_WRITE_SEQUENTIALLY=1
hf download --local-dir "$HF0/$X2" "hf://$X1" --include "mmproj*" --include "*$Q1.gguf"

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
borg-backup.py --exact-name --no-excludes "$SLUG1" "$X2"

hf cache verify --local-dir "$HF0/$X2" "$X1"

# Searching HF for auto-populating the provider and model names worked
lms import --copy /run/media/x/h365/co/huggingface/bartowski/TheDrummer_Artemis-31B-v1.2-GGUF꞉Q8_0/TheDrummer_Artemis-31B-v1.2-Q8_0.gguf

# 
# ✔ Choose categorization option Auto search Hugging Face (Recommended for models
#  downloaded from Hugging Face)                                                  
# Searching for the model on Hugging Face using the file name...               
# W Cannot find the model on Hugging Face, you need to manually specify the user/repo.
# ✔ Who is the creator of the model? bartowski                  
# ✔ What is the model name? TheDrummer_Artemis-31B-v1.2-GGUF

 lms import --copy /run/media/x/h365/co/huggingface/bartowski/TheDrummer_Artemis-31B-v1.2-GGUF꞉Q8_0/mmproj-TheDrummer_Artemis-31B-v1.2-f16.gguf


rm -rf "$HF0/$X2"
```

```text
vim: set et ff=unix ft=markdown nocp sts=2 sw=2 ts=2:
```
