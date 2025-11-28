```text
$Source: /Users/x/Dropbox/2/src/blog/2025/11/28/RCS/README.md,v $
$Date: 2025/11/28 21:38:07 $
$Revision: 1.2 $
```

# h345 re-format as single-volume case-sensitive APFS

A few days ago, I tried to use APFS volumes the same way I might use btrfs or
ZFS volumes. Unfortunately, the snapshot mechanism seems to be broken for my use cases:
* https://github.com/johnsmith968530/blog/tree/here-and-now/2025/11/26

So, I'm re-formatting it as a single-volume case-sensitive APFS.

```zfs
sudo diskutil eraseDisk APFSX "h345" /dev/disk6
```


```text
vim: set et ff=unix ft=markdown nocp sts=2 sw=2 ts=2:
```
