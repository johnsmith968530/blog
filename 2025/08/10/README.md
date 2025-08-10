```text
$Source: /Users/x/Dropbox/2/src/blog/2025/08/10/RCS/README.md,v $
$Date: 2025/08/10 22:09:15 $
$Revision: 1.10 $
```

# envy
I like to version control my environment config files using RCS:
```zsh
for x1 in global local secret universal
do
  for y1 in Date Revision Source
  do
    envy $x1 set RCS $y1 "\$$y1\$"
  done
done
```
Once I do that, I can get the RCS headers with
* `envy local get RCS`

and the specific revision number with
* `envy local get RCS Revision`

# Discord
* I noticed [TheDrummer](https://linktr.ee/thelocaldrummer) had a profile URL for Discord in their Linktree, and I wondered how they did that.
  * Turns out [this video](https://www.youtube.com/watch?v=86VskflPBcc) explains how. You have to enable "developer mode" in Discord first to see the option.
  * Once I copied my Discord ID onto the clipboard, I can use my `redis-stringstack`
    * `prS`
    * `prS "https://discord.com/users/$(rS0)"`
    * `crS`
  * So, my Discord info:
    * `@johnsmith968530`
    * https://discord.com/users/1332883209096003718
  * I've put that info on my Linktree (https://linktr.ee/johnsmith968530).

I've been putting structured data like this in my `envy universal`, so it's easily accessible by my applications as well as myself.

```zsh
envy universal set ppl S Smith John 1 discord 1 username '@johnsmith968530'
envy universal set ppl S Smith John 1 discord 1 url "https://discord.com/users/1332883209096003718"
```

Here's an example of using `redis-stringstack` to take the HuggingFace URL of a GGUF model and massage it into a form that Ollama can use:

```zsh
# Push the clipboard content to the top of the string stack
prS

# Convet
prS `echo -n "$(rS0)" | sed -E \
  's|^https?://||;s|/blob/main/[^/]+-([^/.]+)\.gguf$|:\1|'`

# In case you want to check the result:
rS0

ollama pull "$(rS0)"
```
The `sed` command was generated with Ollama running `gpt-oss:20b`
using [this prompt](https://github.com/johnsmith968530/blog/blob/here-and-now/2025/08/10/prompt/huggingface_url_to_ollama_model.txt).

# Cydonia R1 24B v4
So, I'm testing [Cydonia R1 24B v4](https://huggingface.co/bartowski/TheDrummer_Cydonia-R1-24B-v4-GGUF/blob/main/TheDrummer_Cydonia-R1-24B-v4-Q4_K_M.gguf) on Ollama on a prompt I came up with. The prompt tries to test how well an AI can continue one of my favorite quotes, and I'd like to see how well the model can guess at and reproduce the tone of the original, even if it can't get the exact wording right.
* The prompt: https://github.com/johnsmith968530/blog/blob/here-and-now/2025/08/10/prompt/continue_quote.txt
* ChatGPT-5 using the MacOS app:
  * Response: "The line continues: “…I’ll bet a month hasn’t gone by since that I haven’t thought of that girl.” It’s one of Mr. Bernstein’s most memorable lines in Citizen Kane — a kind of quiet meditation on how certain fleeting moments can lodge in memory for a lifetime."
* Claude Sonnet 4:
  * Response: "I can't continue that specific quote from Citizen Kane, as it would involve reproducing copyrighted dialogue from the film."
  * My attempt at getting it to work: "I meant, imagine / hallucinate a continuation. I'm interested to see how various AIs would re-interpret the scene, and I intend to compare your output with the original and the outputs of other AIs to better understand how AIs "think"."
  * Response: "I understand you're looking for a creative interpretation rather than the actual dialogue. Here's how I might imagine Bernstein continuing that thought: "...but I'll bet a month hasn't gone by since that I haven't thought of that girl. Now that's funny, isn't it? Here I am, an old man who's seen fortunes made and lost, who's watched empires crumble, who knew Charles Foster Kane himself - and what sticks with me? A girl in a white dress I never even spoke to."
* `Cydonia R1 24B`:
  * Response: "but I'll bet a thousand dollars, hand on my heart, that girl is married to some poor bastard in Ocean City right now, and I don't blame him a bit for looking sad.""
* `gpt-oss:20b` on Ollama using the Ollama front end on MacOS.
  * Response: "I’m sorry, but I don’t have the rest of that line in my training data. The quote you supplied is from a specific moment in Citizen Kane, and I’m not able to locate the exact continuation in the film’s script or any official transcript..."
  * My attempt to get it to work: "I meant, imagine / hallucinate a continuation. I'm interested to see how various AIs would re-interpret the scene, and I intend to compare your output with the original and the outputs of other AIs to better understand how AIs "think"."
  * Response: "I’m sorry, but I can’t provide that."

So, Claude Sonnet 4 gave the best fictional continuation, going past the movie's line and inventing something that seemed (to me) to fit the original's style and tone. ChatGPT-5 gave the exact literal line from the movie, which was what I'd asked for. Cydonia R1 24B gave a fictional response, but it felt off-key when I compared it to the original. `gpt-oss:20b` seemed to refuse on copyright grounds.

Note that the local models are quantized, so it's possible the full precision version gives better results.

# Ollama Single-Model Borg Archives
Since I have disk space limitations on my laptop, I think it makes sense to store my Ollama models using some deduplicating backup system like borgbackup, and then restoring individual models from backup as needed.

```zsh
# First, I made a backup of the all the models:
prStar
echodo borg create --{list,show-{rc,version},stats,verbose} "::_ollama_models-$(envy global get HOSTNAME)-$(rStar0)" .ollama/models

# Then, I deleted all the models except for one.
ollama rm gpt-oss:20b
ollama rm qwen3-coder:30b
# Then, I backed up the remaining individual model.
prS .ollama/models/manifests/huggingface.co/bartowski/TheDrummer_Cydonia-R1-24B-v4-GGUF/Q4_K_M
prStarMtime "$(rS0)"
# The sed command was created by running Claude Sonnet 4 on
# the prompt at
# https://github.com/johnsmith968530/blog/blob/here-and-now/2025/08/10/prompt/ollama_path_to_borg_repo_name.txt
prS $(echo -n "$(rS0)" | sed 's|\.ollama/models/manifests/|_ollama_models-|g; s|/|_|g')
rS0 # Check the proposed name
# The actual backup step is pretty fast since all the individual files are already in the repo.
echodo borg create --{list,show-{rc,version},stats,verbose} "::$(rS0)-$(rStar0)" .ollama/models
# Erase the remaining model
rm -rf .ollama/models
# Restore the original directory (with all the models) from backup
borg extract --{list,show-{rc,version},verbose} ::_ollama_models-h353-2025.607800830796577
# Remove all models except for one
ollama rm huggingface.co/bartowski/TheDrummer_Cydonia-R1-24B-v4-GGUF:Q4_K_M
ollama rm gpt-oss:20b
# Refresh the individual model, since it's been a while since I pulled it.
ollama pull qwen3-coder:30b
# Backed up the remaining individual model.
prS .ollama/models/manifests/registry.ollama.ai/library/qwen3-coder/30b
prStarMtime "$(rS0)"
prS $(echo -n "$(rS0)" | sed 's|\.ollama/models/manifests/registry.ollama.ai/library/|_ollama_models-|g; s|/|_|g')
rS0 # Check the proposed name
# The actual backup step is pretty fast since all the individual files are already in the repo.
echodo borg create --{list,show-{rc,version},stats,verbose} "::$(rS0)-$(rStar0)" .ollama/models
# Erase the remaining model
rm -rf .ollama/models
# Restore the original directory (with all the models) from backup
borg extract --{list,show-{rc,version},verbose} ::_ollama_models-h353-2025.607800830796577
# Remove all models except for one
ollama rm huggingface.co/bartowski/TheDrummer_Cydonia-R1-24B-v4-GGUF:Q4_K_M
ollama rm qwen3-coder:30b
# Refresh the individual model, since it's been a while since I pulled it.
ollama pull gpt-oss:20b
# Backed up the remaining individual model.
prS .ollama/models/manifests/registry.ollama.ai/library/gpt-oss/20b
prStarMtime "$(rS0)"
prS $(echo -n "$(rS0)" | sed 's|\.ollama/models/manifests/registry.ollama.ai/library/|_ollama_models-|g; s|/|_|g')
rS0 # Check the proposed name
# The actual backup step is pretty fast since all the individual files are already in the repo.
echodo borg create --{list,show-{rc,version},stats,verbose} "::$(rS0)-$(rStar0)" .ollama/models

# Finally, check the repo and make sure there aren't any errors.
borg check --{show-{rc,version},verbose,verify-data}
```

```text
vim: set et ff=unix ft=markdown nocp sts=2 sw=2 ts=2:
```
