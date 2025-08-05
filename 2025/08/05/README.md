```text
$Source: /Users/x/Dropbox/2/src/blog/2025/08/05/RCS/README.md,v $
$Date: 2025/08/05 15:06:55 $
$Revision: 1.8 $
```

# h353 setup
* Continuing to set up my [new Macbook Air](https://github.com/johnsmith968530/blog/tree/here-and-now/2025/08/04#h353). It's been a while since I've used a Mac.
* I uploaded my [GnuPG public key](https://github.com/johnsmith968530/blog/blob/here-and-now/2025/08/05/src/gnupg2-public-key-1C259584204ECDA913257A0BE718A5BD2F23B1D7.asc).
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
* Same for my old [`stardate`](https://github.com/johnsmith968530/blog/tree/here-and-now/2025/08/05/src/stardate) tool.
* Installed [VideoLAN VLC 3.0.21](https://get.videolan.org/vlc/3.0.21/macosx/vlc-3.0.21-arm64.dmg) and [Zoom Workplace for Mac 6.5.7](https://zoom.us/download#room_client) from the respective websites.

```text
vim: set et ff=unix ft=markdown nocp sts=2 sw=2 ts=2:
```
