```text
$Source: /Users/x/Dropbox/2/src/blog/2025/08/11/RCS/README.md,v $
$Date: 2025/08/11 17:45:46 $
$Revision: 1.3 $
```

# Ollama Single-Model Borg Archives
* I've come up with a script for automating the archival process of a single Ollama model in borg.
  * https://github.com/johnsmith968530/blog/blob/here-and-now/2025/08/11/src/archive_model.zsh

# Abliterated Models
* I was taken by surprise by the quality of this 4B abliterated (non-quantized) model:
  * Model: https://ollama.com/huihui_ai/gemma3n-abliterated:e4b-fp16
  * Prompt: https://github.com/johnsmith968530/blog/blob/here-and-now/2025/08/10/prompt/continue_quote.txt
  * Response: "…but I never forgot her. Not a single detail. The way the sun caught the lace on her sleeve, the slight tilt of her head as she stepped onto the dock, the faint scent of lilacs that seemed to cling to the air around her. Years later, I’d walk down a busy street, hear a particular melody, see a flash of white – and there she’d be again, as vivid as if she’d just disembarked.
    And that’s the thing about memory, isn’t it? It doesn’t care about importance. It doesn’t care about significance. It latches onto the smallest, most seemingly insignificant things, and holds them fast. A fleeting glance, a whisper of a scent, a single, perfect moment… these are the things that truly define us. These are the things that echo through a lifetime."
  * Makes me wonder whether the safety features plus quantization really kill the creative writing abilities of these models.

```text
vim: set et ff=unix ft=markdown nocp sts=2 sw=2 ts=2:
```
