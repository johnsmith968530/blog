```text
$Source: /home/x/Dropbox/2/src/blog/2025/07/30/RCS/README.md,v $
$Date: 2025/07/30 13:21:08 $
$Revision: 1.6 $
```

* So, this is my first dated entry to my online blog. I'm an old-school Linux guy at heart, so I write snippets like
```bash
alias cd.blog='mkdircd /home/x/Dropbox/2/src/blog/$(date "+%Y/%m/%d")'
```
out of habit. Over the years, I've built up my own little setup of scripts and tools, and since I've been retired from the tech scene for over a decade, I think they're all rather quaint by today's standards, and I'll refer to commands like `mkdircd`, which I defined as
```bash
mkdircd () { /usr/bin/mkdir -p "$1" && cd "$1"; }
```
so there's a lot of stuff that's convenient for me but might make no sense to anyone else. I've put the original motivation for this blog in https://github.com/johnsmith968530/blog/tree/9c25b3cbb3e9e7cc9fe8e32bfed464d9468c082b -- I think that's a permanent link, so if the `README.md` changes, it should stay the same.
* Oh, and yeah: I use a combination of `rcs` and `git` in my workflow, so you'll see RCS headers. I like RCS because:
  * It can automatically write version numbers, which I don't have with git.
  * Many times in my coding, I'll want to use different versions of, like, four different files, and that's easy to do with RCS. If I tried to do that with git, I'd have to deal with isolating four different files from four different commits, some of which may be in branches that were deleted long ago. I like having an orthogonal versioning system.
    * For the version control systems to be truly orthogonal, the RCS files (files ending in `,v`) *can't* be checked into Git, or else the RCS versions will be affected by Git operations. This means that `.gitignore` should auto-exclude RCS files.

```text
vim: set et ff=unix ft=markdown nocp sts=2 sw=2 ts=2:
```
