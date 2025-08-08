```text
$Source: /Users/x/Dropbox/2/src/blog/2025/08/07/RCS/README.md,v $
$Date: 2025/08/08 12:53:35 $
$Revision: 1.7 $
```

# More h353 Setup
* Installed zint 2.15.0 via `brew install zint`.

# Ollama
## Backup
```zsh
envy global set ollama models backup 1 /Volumes/h337/cache/ollama/models
rsync -avP ~/.ollama/models/ "$(envy global get ollama models backup 1)/"
```

# GPT-5
* GPT-5 was officially released this morning (2025.598423) and I see it's available on [OpenRouter](https://openrouter.ai/openai/gpt-5-chat) and [NanoGPT](https://nano-gpt.com/conversation/new).
* I tried asking GPT-5 on OpenRouter about simulating a quantum spin liquid.
  * The prompt:
    * https://github.com/johnsmith968530/blog/tree/here-and-now/2025/08/07/prompt/quantum_spin_liquid.txt
  * The reply:
    * https://github.com/johnsmith968530/blog/tree/here-and-now/2025/08/07/OpenRouter_GPT-5_quantum_spin_liquid.md
  * For comparison, I also asked `qwen3-coder:30b` running locally on my MacBook Air (h353):
    * https://github.com/johnsmith968530/blog/tree/here-and-now/2025/08/07/ollama_qwen3-coder_30b_quantum_spin_liquid.md

# h354
* iPhone 16
  * Does not have a physical SIM card slot.
    * I had to call T-mobile to transfer service from my old physical SIM to an eSIM.

```text
vim: set et ff=unix ft=markdown nocp sts=2 sw=2 ts=2:
```
