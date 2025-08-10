```text
$Source: /Users/x/Dropbox/2/src/blog/2025/08/10/RCS/README.md,v $
$Date: 2025/08/10 16:50:30 $
$Revision: 1.4 $
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

```text
vim: set et ff=unix ft=markdown nocp sts=2 sw=2 ts=2:
```
