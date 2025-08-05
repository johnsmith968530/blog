```text
$Source: /Users/x/Dropbox/2/src/blog/2025/08/05/RCS/README.md,v $
$Date: 2025/08/05 14:24:47 $
$Revision: 1.5 $
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
* I was surprised to see `/usr/local/bin` doesn't exist even though it's in my `PATH`, so I created it:
  * `sudo mkdir /usr/local/bin && sudo chown x /usr/local/bin`
  * All my dev machines are one-person setups, so that's why I set the owner of `/usr/local/bin` to myself (`x`).
* I tweaked my old [`rcs_init`](https://github.com/johnsmith968530/blog/tree/here-and-now/2025/08/05/src/rcs_init) tool to work on MacOS X as well as Linux.

```text
vim: set et ff=unix ft=markdown nocp sts=2 sw=2 ts=2:
```
