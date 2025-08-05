```text
$Source: /Users/x/Dropbox/2/src/blog/2025/08/05/RCS/README.md,v $
$Date: 2025/08/05 13:52:39 $
$Revision: 1.3 $
```

# h353 setup
* Continuing to set up my [new Macbook Air](https://github.com/johnsmith968530/blog/tree/here-and-now/2025/08/04#h353). It's been a while since I've used a Mac.
* I had a problem getting GnuPG to sign my git commits:
```
% git commit -m "Add my public key"
error: gpg failed to sign the data
fatal: failed to write commit object
```
I fixed it with `brew install pinentry-mac` and using
```
pinentry-program /opt/homebrew/bin/pinentry-mac
```
in my [`~/.gnupg/gpg-agent.conf`](https://github.com/johnsmith968530/blog/blob/here-and-now/2025/08/05/src/gpg-agent.conf).

```text
vim: set et ff=unix ft=markdown nocp sts=2 sw=2 ts=2:
```
