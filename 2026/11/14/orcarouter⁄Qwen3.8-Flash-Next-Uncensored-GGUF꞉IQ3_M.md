# Some `zsh` commands for backing up a Hugging Face repo (tweaked lightly from the procedure for [huihui-ai⁄Huihui-GLM-5.3-Flash-abliterated-GGUF꞉UD-Q2_K_XL](../13/huihui-ai⁄Huihui-GLM-5.3-Flash-abliterated-GGUF꞉UD-Q2_K_XL.md).

```zsh
. "$BLOG_ROOT/2026/10/22/slugify_path.zsh"
. "$BLOG_ROOT/2025/08/06/src/echodo.sh"

export HF_XET_RECONSTRUCT_WRITE_SEQUENTIALLY=1
export HF0="/mnt/h374/co/huggingface"

export X1="orcarouter/Qwen3.8-Flash-Next-Uncensored-GGUF"
export Q1="IQ3_M"
export X2="$X1"

export X2="$X2:$Q1"

export X2=$(slugify_path "$X2")

echo "$HF0/$X2"

R1="$(blog)/${X2}.md" && echo "$R1"

echodo mkdir -p "$HF0/$X2"
echodo uv tool upgrade hf

echodo hf download --local-dir "$HF0/$X2" "hf://$X1" --include "*-$Q1*" --include "*mmproj*" --dry-run
echodo hf download --local-dir "$HF0/$X2" "hf://$X1" --include "*-$Q1*" --include "*mmproj*"

export SLUG1="🤗⁄$X2★$(stardate)" && echo "$SLUG1"
cd "$HF0" && borg-backup.py --exact-name --no-excludes "$SLUG1" "$X2"
echodo hf cache verify --local-dir "$HF0/$X2" "$X1"
echodo borg list --short "::$SLUG1"

lms import --copy /mnt/h374/co/huggingface/orcarouter⁄Qwen3.8-Flash-Next-Uncensored-GGUF꞉IQ3_M/Qwen3.8-Flash-Next-Uncensored-IQ3_M-00001-of-00002.gguf 
✔ Choose categorization option Auto search Hugging Face (Recommended for models downloaded from Hugging Face)
Searching for the model on Hugging Face using the file name...
Found the following repositories on Hugging Face containing this file:
✔ Please select the correct one | orcarouter/Qwen3.8-Flash-Next-Uncensored-GGUF
File copied to /home/x/.lmstudio/models/orcarouter/Qwen3.8-Flash-Next-Uncensored-GGUF/Qwen3.8-Flash-Next-Uncensored-IQ3_M-00001-of-00002.gguf
lms import --copy /mnt/h374/co/huggingface/orcarouter⁄Qwen3.8-Flash-Next-Uncensored-GGUF꞉IQ3_M/Qwen3.8-Flash-Next-Uncensored-IQ3_M-00002-of-00002.gguf 
✔ Choose categorization option Auto search Hugging Face (Recommended for models downloaded from Hugging Face)
Searching for the model on Hugging Face using the file name...
Found the following repositories on Hugging Face containing this file:
✔ Please select the correct one | orcarouter/Qwen3.8-Flash-Next-Uncensored-GGUF
File copied to /home/x/.lmstudio/models/orcarouter/Qwen3.8-Flash-Next-Uncensored-GGUF/Qwen3.8-Flash-Next-Uncensored-IQ3_M-00002-of-00002.gguf
lms import --copy /mnt/h374/co/huggingface/orcarouter⁄Qwen3.8-Flash-Next-Uncensored-GGUF꞉IQ3_M/mmproj-Qwen3.8-Flash-Next-Uncensored-F16.gguf
✔ Choose categorization option Auto search Hugging Face (Recommended for models downloaded from Hugging Face)
Searching for the model on Hugging Face using the file name...
W Cannot find the model on Hugging Face, you need to manually specify the user/repo.
✔ Who is the creator of the model? orcarouter
✔ What is the model name? Qwen3.8-Flash-Next-Uncensored-GGUF
File copied to /home/x/.lmstudio/models/orcarouter/Qwen3.8-Flash-Next-Uncensored-GGUF/mmproj-Qwen3.8-Flash-Next-Uncensored-F16.gguf

echodo rm -rf "$HF0/$X2"
```
