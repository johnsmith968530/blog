```text
$Source: /Users/x/Dropbox/2/src/blog/2025/11/26/RCS/README.md,v $
$Date: 2025/11/26 20:52:05 $
$Revision: 1.4 $
```

# h345 APFS container and volumes

## List what's there
```zsh
x@h353 ~ % diskutil list /dev/disk6

/dev/disk6 (external, physical):
   #:                       TYPE NAME                    SIZE       IDENTIFIER
   0:     FDisk_partition_scheme                        *1.0 TB     disk6
   1:               Windows_NTFS h345                    1.0 TB     disk6s1

x@h353 ~ % sudo diskutil eraseDisk APFSX "h345" /dev/disk6
Started erase on disk6
Unmounting disk
Creating the partition map
Waiting for partitions to activate
Formatting disk6s2 as APFS (Case-sensitive) with name h345
tx_flush:1185: rdisk6s2 tx xid 1 took 7494581 us to flush
Mounting disk
Finished erase on disk6

x@h353 ~ % diskutil list /dev/disk6                   
/dev/disk6 (external, physical):
   #:                       TYPE NAME                    SIZE       IDENTIFIER
   0:      GUID_partition_scheme                        *1.0 TB     disk6
   1:                        EFI EFI                     209.7 MB   disk6s1
   2:                 Apple_APFS Container disk7         1.0 TB     disk6s2
```

Note the container is identified as `disk7`.

## Create volumes inside the container

```zfs
x@h353 ~ % sudo diskutil apfs addVolume disk7 APFSX borg43
Will export new APFS (Case-sensitive) Volume "borg43" from APFS Container Reference disk7
Started APFS operation on disk7
Preparing to add APFS Volume to APFS Container disk7
Creating APFS Volume
Created new APFS Volume disk7s2
Mounting APFS Volume
Setting volume permissions
Disk from APFS operation: disk7s2
Finished APFS operation on disk7

x@h353 ~ % sudo diskutil apfs addVolume disk7 APFSX svnjak65
Password:
Will export new APFS (Case-sensitive) Volume "svnjak65" from APFS Container Reference disk7
Started APFS operation on disk7
Preparing to add APFS Volume to APFS Container disk7
Creating APFS Volume
Created new APFS Volume disk7s3
Mounting APFS Volume
Setting volume permissions
Disk from APFS operation: disk7s3
Finished APFS operation on disk7
```

## Uh-oh
```zfs
x@h353 ~ % sudo tmutil snapshot /Volumes/svnjak65
NOTE: local snapshots are considered purgeable and may be removed at any time by deleted(8).
Created local snapshot with date: 2025-11-26-124008
x@h353 ~ % diskutil apfs listSnapshots /Volumes/svnjak65
No snapshots for disk7s3
x@h353 ~ %
```


```text
vim: set et ff=unix ft=markdown nocp sts=2 sw=2 ts=2:
```
