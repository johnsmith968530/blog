```text
$Source: /home/x/Dropbox/2/src/blog/2025/08/03/RCS/README.md,v $
$Date: 2025/08/04 01:29:16 $
$Revision: 1.3 $
```

* If you want to do AI training, inference, etc. your choices of hardware are:
  * NVIDIA: the current leader
    * A A100 GPU comes with either 40GB or 80GB, although it may be faster even if some of the model gets offloaded into ordinary RAM.
    * A H100 GPU comes with 80 GB VRAM.
    * DGX Spark
      * https://www.nvidia.com/en-us/products/workstations/dgx-spark/
      * https://medium.com/@andreask_75652/will-nvidias-project-digits-kill-apple-m4-max-ai-2729bf55427e
  * Google's TPUs: specific to Google. You can rent the TPUs, but they're not readily available to consumers.
  * Groq's custom ASIC: Rentable, but not yet practical for consumers.
  * Apple Silicon: the unified memory model allows for a very good cost / performance ratio
    * https://johnwlittle.com/ollama-on-mac-silicon-local-ai-for-m-series-macs/
    * https://github.com/ml-explore/mlx
    * Currently, a 16-inch MacBook Pro laptop can have 128GB Unified Memory for about $5K.

```text
vim: set et ff=unix ft=markdown nocp sts=2 sw=2 ts=2:
```
