```text
$Source: /Users/x/Dropbox/2/src/blog/2025/08/28/src/my-whisper-project/RCS/README.md,v $
$Date: 2025/08/28 15:43:34 $
$Revision: 1.2 $
```

Set up the environment:
```
uv init
uv add mlx-whisper
envy global set whisper root \
  ~/Dropbox/2/src/blog/2025/08/28/src/my-whisper-project
source "$(envy global get whisper root)/aliases.zsh"
```

Usage:
```zsh
whisperit foo1.mp3 foo2.mp3 ...
```

```text
vim: set et ff=unix ft=markdown nocp sts=2 sw=2 ts=2:
```
