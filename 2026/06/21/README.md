```text
$Source: /home/x/Dropbox/2/src/blog/2026/06/21/RCS/README.md,v $
$Date: 2026/06/21 19:18:26 $
$Revision: 1.1 $
```

I came up with a new trick for Racket's require paths for this blog. I set up a directory that lets me
specify the paths for the require:

```bash
mkdir -p ~/.config/PLTCOLLECTS
cd ~/.config/PLTCOLLECTS

rm -f blog
ln -s ~/Dropbox/2/src/blog blog

export PLTCOLLECTS="$HOME/.config/PLTCOLLECTS:$PLTCOLLECTS"
```

Now I can do stuff like:

```racket
(require blog/2026/06/21/kardashev)
(require blog/2026/06/21/stardate)
```

```text
vim: set et ff=unix ft=markdown nocp sts=2 sw=2 ts=2:
```
