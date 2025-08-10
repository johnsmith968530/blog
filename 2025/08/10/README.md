```text
$Source: /Users/x/Dropbox/2/src/blog/2025/08/10/RCS/README.md,v $
$Date: 2025/08/10 14:01:27 $
$Revision: 1.2 $
```

# envy
I like to version control my environment config files using RCS:
```zsh
for x1 in global local secret universal
do
  for y1 in Date Revision Source
  do
    envy $x1 set RCS $y1 "\$$y1\$"
  done
done
```
Once I do that, I can get the RCS headers with
* `envy local get RCS`
and the specific revision number with
* `envy local get RCS Revision`

```text
vim: set et ff=unix ft=markdown nocp sts=2 sw=2 ts=2:
```
