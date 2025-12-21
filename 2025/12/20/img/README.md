```text
$Source$
$Date$
$Revision$
```

```text
# Here's the aspect ratio of the VistaPrint 8.5 x 11 poster safety area
# that the image must fit in.
In [1]: 10.875/8.375
Out[1]: 1.2985074626865671

# The image, however, has a 1.5 aspect ratio. The limiting dimension is
# therefore the vertical dimension.
In [2]: 1536.0/1024
Out[2]: 1.5

# Set x to the pixel density.
In [3]: x = 1536.0/10.875

# Compute the height of the resulting (padded) image. Round up later.
In [4]: 11 * x
Out[4]: 1553.655172413793

# Compute the width of the resulting (padded) image. Round up later.
In [5]: 8.5 * x
Out[5]: 1200.551724137931
```

```bash
magick FLUX.2_max_2.jpg -gravity center -background white -extent 1201x1554 FLUX.2_max_2_padded.png
```

Once you upload the image, you'll have to adjust the edges so that the image actually ends up in the safety area (the dotted lines) -- the software will initially attempt to resize the image, but if you adjust it to undo the resizing, it will snap to the correct size like a rubber band.

```text
vim: set et ff=unix ft=markdown nocp sts=2 sw=2 ts=2:
```
