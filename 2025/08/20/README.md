```text
$Source: /Users/x/Dropbox/2/src/blog/2025/08/20/RCS/README.md,v $
$Date: 2025/08/25 16:22:15 $
$Revision: 1.4 $
```

* I just heard about a new standard called `Agents.md`.
  * There's a [YouTube video](https://www.youtube.com/watch?v=XDP94mYMCzA) that gave me a decent overview.
  * The standard appears to have its own website: https://agents.md/
* I thought it'd be fun learning Spanish via lessons in the form of AI-generated hip hop music.
  * Prompt to Claude Opus 4.1: *Describe Don Quixote’s relationship to both modernism and postmodernism, but write it as the lyrics to a hip hop song and also structure it so it teaches some Spanish vocabulary and phrases to English-language speakers.*
  * The result was [El Caballero's Legacy](https://www.tiktok.com/@johnsmith968530/video/7540732400121154829).
  * I faced the same trouble I had yesterday with the cover image being too small when I uploaded the video to TikTok, so I did the same upscaling:
    * `convert A\ confident\ young\ Latina\ teacher\ in\ her\ 30s\ standing\ next\ to\ \(3\).png -resize 1080x1920^ -gravity center -extent 1080x1920 El\ Caballero\'s\ Legacy.png`
  * I had some trouble getting iMovie to create a 9:16 aspect ratio video in portrait orientation, so I resorted to ffmpeg:
    * `ffmpeg -loop 1 -i El_Caballero\'s_Legacy.png -i El_Caballero\'s_Legacy.mp3 -c:v libx264 -tune stillimage -c:a aac -b:a 192k -pix_fmt yuv420p -shortest El_Caballero\'s_Legacy.mp4`
* Useful phrase of the day:
  * ¿Cómo se dice EXPRESSION en {español|inglés}?
* Some open weight LLMs available on their creator's websites:
  * https://chat.deepseek.com/
  * https://www.kimi.com/
  * https://chat.qwen.ai/
  * https://chat.z.ai/

```text
vim: set et ff=unix ft=markdown nocp sts=2 sw=2 ts=2:
```
