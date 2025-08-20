```text
$Source: /Users/x/Dropbox/2/src/blog/2025/08/19/RCS/README.md,v $
$Date: 2025/08/19 23:53:06 $
$Revision: 1.1 $
```

* Tried uploading a 576x1024 video to TikTok, but in the preview it showed up as being a small rectangle in the center of the example phone screen. So, I upscaled the base image using ImageMagick. It's not the highest quality, but:
  * `brew install imagemagick`
  * `convert Gathering_at_3_576x1024.png -resize 1080x1920^ -gravity center -extent 1080x1920 Gathering_at_3_1080x1920.png`


```text
vim: set et ff=unix ft=markdown nocp sts=2 sw=2 ts=2:
```
