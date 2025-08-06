```text
$Source: /Users/x/Dropbox/2/src/blog/2025/08/06/RCS/README.md,v $
$Date: 2025/08/06 15:11:42 $
$Revision: 1.3 $
```

# More h353 Setup
I often like to put environment-variable-ish stuff in my `envy` globals because it allows me to change `TZ`, `USER_AGENT`, etc. on a system-wide basis without having to restart all processes that use the environment variable. Also, since the file that stores these values (`/usr/local/var/lib/org/au0/envy.json`) is version controlled with RCS, I can roll back any changes that had unintended consequences more easily than if I did everything via a GUI, like the way Windows does with environment variables and the registry.
```zsh
envy global set HOSTNAME "h353"
envy global set ALTNAME "MacBook Air 2025 (32 GB unified memory, 1 TB SSD)"
envy global set OS "$(uname -o)"
envy global set TZ "America/Los_Angeles"
envy global set USER_AGENT "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/139.0.0.0 Safari/537.36"
```
I think I'll set up a few new entries:
```zsh
envy global set blog root "$HOME/Dropbox/2/src/blog"
envy global set blog url "https://github.com/johnsmith968530/blog"
# The next line allows me to do
#   git cat-file blob $(envy global get git hash markdown github) > README.md
envy global set git hash markdown github $(git hash-object \
  "`envy global get blog root`/2025/07/30/src/github_markdown_template.md")
envy global set git hash gitignore rust $(git hash-object \
  "`envy global get blog root`/2025/08/05/src/rcs_init/.gitignore")
```
* I have an implementation of a "string stack" I built on top of Redis, which I've tweaked to work with MacOS.
  * https://github.com/johnsmith968530/blog/blob/here-and-now/2025/08/06/src/redis-stringstack.sh
* Printable ruler
  * https://github.com/johnsmith968530/blog/tree/here-and-now/2025/08/06/src/printable-ruler.html
    * I tried using Claude Opus 4.1 to create this using the prompt in https://github.com/johnsmith968530/blog/blob/here-and-now/2025/08/06/prompt/ruler.txt but the printed ruler didn't display the tick marks and other essential elements properly (the browser displayed them, though).
    * ChatGPT o4-mini-high made something that worked, and worked well, using the same prompt and that's what I went with.
  * In the "Scale" box on the HTML, 1.496 made the measurements right when calibrated against multiple rulers in both inches and centimeters.
    * The accuracy was so high that the thickness of the ruler I calibrated against made a difference (a slight change in viewing angle gets multiplied by the thickness of the ruler to create a micron-scale measurement error).
  * Printed using Google Chrome (not system dialog):
    * Orientation: Landscape
    * No headers or footers
    * Margins: None
    * Scale: Custom (100%)

```text
vim: set et ff=unix ft=markdown nocp sts=2 sw=2 ts=2:
```
