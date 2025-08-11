```text
$Source: /Users/x/Dropbox/2/src/blog/2025/08/11/RCS/README.md,v $
$Date: 2025/08/11 22:42:30 $
$Revision: 1.8 $
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
    * The safety features effect is old news, but the quantization effect might be more nuanced than I'd originally imagined. I'd assumed that quantization affects all tasks equally, but it's possible that some tasks that have well-defined "correct" solutions (such as coding tasks) are more robust under quantization than other tasks (such as writing literary fiction) that rely more on complex nuances that are hard to define. One might imagine that while an old computer monitor with low resolution and few colors might be sufficient for, say, spreadsheet work (where pixellation doesn't matter much), it's less ideal for other tasks such as displaying fine art (where pixellation would destroy much of the artistic effect in many works).
    * I thought the quantization issues was worth pursuing, so I wrote a test that runs that same movie quote continuation prompt through the same model with different quantizations
      * https://github.com/johnsmith968530/blog/blob/here-and-now/2025/08/11/src/test_quantization_1.zsh
      * Results: https://github.com/johnsmith968530/blog/tree/here-and-now/2025/08/11/src/quantization_test/9f47dd79feaf9b10976b8650d4ea7c8bb9741dfd
        * I think I can sense a degradation going from the full `bf16` to even the `Q8_0` quantization.
        * At `Q6_K_L` (there was no `Q6_K_M` model, so I chose `Q6_K_L`), the result seems somewhat off-key.
        * By the time we get to `Q4_K_M`, the model shows signs of "cognitive difficulties" in that it doesn't remember the girl with the parasol didn't see the narrator (as stated in the prompt).
        * At `Q3_K_M`, the model starts to ramble.
    * I ran the same model series with a different prompt involving an arithmetic sequence:
      * https://github.com/johnsmith968530/blog/blob/here-and-now/2025/08/11/src/test_quantization_2.zsh
      * https://github.com/johnsmith968530/blog/blob/here-and-now/2025/08/05/prompt/testing_squares.txt
      * Results: https://github.com/johnsmith968530/blog/tree/here-and-now/2025/08/11/src/quantization_test/3144023318fa0ba2a79ae5a7e21a02d6203e0ac4
        * Looks like even `Q3_K_M` managed to get it right.
        * So the "quantization hurts writing more than coding & math" hypothesis seems to hold up, at least for now.
    * It also seems likely that the early quantization tests people did were with models that had a relatively high parameter to training data tokens ratio, and were therefore more "compressible" than the current models, which are operating at higher efficiency in the bf16 training mode. And Google did have some research on quantization-aware training or some such, which may mean that re-quantizing the model would lead to Pareto sub-optimal performance on the quality vs size curve. I've gone `Q4_K_M` simply because the quantized model's page stated "Good quality, default size for most use cases, recommended", but it's possible this is boilerplate that was generated quite a while ago for an entirely different model with the assumption that `Q4_K_M` would have similar effects on different models.

```text
vim: set et ff=unix ft=markdown nocp sts=2 sw=2 ts=2:
```
