```text
$Source: /Users/x/Dropbox/2/src/blog/2025/08/10/RCS/README.md,v $
$Date: 2025/08/10 18:00:11 $
$Revision: 1.6 $
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

```text
vim: set et ff=unix ft=markdown nocp sts=2 sw=2 ts=2:
```
