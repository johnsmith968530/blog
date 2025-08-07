```text
$Source: /Users/x/Dropbox/2/src/blog/2025/08/06/RCS/README.md,v $
$Date: 2025/08/07 01:08:54 $
$Revision: 1.13 $
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
envy global set git hash gitignore rcs $(git hash-object \
  "`envy global get blog root`/.gitignore")
envy global set git hash bash template $(git hash-object \
  "`envy global get blog root`/2025/08/06/src/bash_template.txt")
envy global set git hash zsh template $(git hash-object \
  "`envy global get blog root`/2025/08/06/src/zsh_template.txt")
```

There's lots of repeated code in the above, so let's define some temporary convenience functions:
```zsh
export TODAY1=$(date +"`envy global get blog root`/%Y/%m/%d")  
tmp_file_keys () { h1=$(git hash-object "$TODAY1/src/$1"); shift; echodo envy global set git hash "$@" $h1; }
tmp_file_keys echodo.sh bash echodo
tmp_file_keys getgitblobbyhash.sh bash getgitblobbyhash
tmp_file_keys getgitblobbykey.sh bash getgitblobbykey
tmp_file_keys redis-stringstack.sh bash redis-stringstack
tmp_file_keys redis-stardatestack.sh bash redis-stardatestack
tmp_file_keys prependtopathset.zsh zsh prependtopathset
tmp_file_keys nodejs_template.txt javascript template
```
* I have an implementation of a "string stack" I built on top of Redis, which I've tweaked to work with MacOS.
  * https://github.com/johnsmith968530/blog/blob/here-and-now/2025/08/06/src/redis-stringstack.sh
* Here's the corresponding "stardate stack", which works along similar lines.
  * https://github.com/johnsmith968530/blog/blob/here-and-now/2025/08/06/src/redis-stardatestack.sh
* Installed [SBCL](https://www.sbcl.org/) 2.5.7 with `brew install sbcl`.
* Added a way of getting and evaluating git blobs from Lisp
  * https://github.com/johnsmith968530/blog/blob/here-and-now/2025/08/06/src/getgitblobbyhash.lisp
  * To make it, I just tweaked the output of Claude Sonnet 4.
    * The prompt: https://github.com/johnsmith968530/blog/blob/here-and-now/2025/08/06/prompt/getgitblob_lisp.txt
* Added a way of getting and evaluating git blobs from Node.js
  * https://github.com/johnsmith968530/blog/blob/here-and-now/2025/08/06/src/getgitblobbyhash.js
  * To make it, I just tweaked the output of Claude Sonnet 4.
    * The prompt: https://github.com/johnsmith968530/blog/blob/here-and-now/2025/08/06/prompt/getgitblob_node.txt
  * Unfortunately, JavaScript's `eval` command doesn't work when the string it tries to eval has `import` statements.
    * See [test3.js](https://github.com/johnsmith968530/blog/blob/here-and-now/2025/08/06/src/test3.js) for an example of this failure mode.

# Printable ruler
* https://github.com/johnsmith968530/blog/tree/here-and-now/2025/08/06/src/printable-ruler.html
  * I tried using Claude Opus 4.1 to create this using the prompt in https://github.com/johnsmith968530/blog/blob/here-and-now/2025/08/06/prompt/ruler.txt but the printed ruler didn't display the tick marks and other essential elements properly (the browser displayed them, though).
  * ChatGPT o4-mini-high made something that worked, and worked well, using the same prompt and that's what I went with. The git hash is `e746964f738a14be45670ec8b93e820c0271921f`.
* In the "Scale" box on the HTML, 1.496 made the measurements right on my Brother printer when calibrated against multiple rulers in both inches and centimeters.
  * The accuracy was so high that the thickness of the ruler I calibrated against made a difference (a slight change in viewing angle gets multiplied by the thickness of the ruler to create a micron-scale measurement error).
* Printed using Google Chrome (not system dialog):
  * Orientation: Landscape
  * No headers or footers
  * Margins: None
  * Scale: Custom (100%)

```text
vim: set et ff=unix ft=markdown nocp sts=2 sw=2 ts=2:
```
