```text
$Source: /Users/x/Dropbox/2/src/blog/2025/08/16/RCS/README.md,v $
$Date: 2025/08/17 13:55:28 $
$Revision: 1.8 $
```

* It was a bit hard trying to find Cline's MCP server settings on MacOS.
  * `envy global set cline mcp settings "$HOME/Library/Application Support/Code/User/globalStorage/saoudrizwan.claude-dev/settings/cline_mcp_settings.json"`
  * I also put it under RCS version control. I sometimes ask Cline to modify its own config files, including this one, and sometimes it messes it up and breaks itself so it can't repair itself. Having the config files in version control lets me revert breaking changes that Cline (or I myself) sometimes makes.

# TechAlley Event
* https://www.meetup.com/las-vegas-ai-meetup/events/310508226/

## Cracking the Spine of Unfairness: The Future of Law in a Post-AI World
* Joshua Stacy
* Experienced pro se litigant
* Former State Senate candidate
  * https://ballotpedia.org/Joshua_Stacy
    * Joshua Stacy (Republican Party) ran for election to the Nevada State Senate to represent District 6. He lost in the Republican primary on June 11, 2024.
    * I'm a passionate innovator with a deep background in computer engineering and website development. My software company helps businesses in Las Vegas and nationwide harness modern computing advancements. By helping small and mid-sized businesses use technology to improve their productivity I help the businesses better serve their customers and employees. I am deeply excited for the opportunity to represent the good people of Senate District 6 (and Nevadans in general) at the state legislature to help leverage our lawmaking process with improvements in technology. I have personally given presentations at Tech Alley Las Vegas on Web 5.0, WordPress, Artificial Intelligence, and more. Nevada is a wonderful state with a long and rich history of limited government, an emphasis on individual liberties, and a beacon of excitement in the desert. I love living in Las Vegas and I believe the future looks bright!
  * A person in the audience mentioned some problems with putting stuff in LLMs. Implied confidentiality issues.
    * Speaker mentioned Google's open source model release.
  * Speaker mentioned Grok is better at pointing out flaws and weaknesses, as ChatGPT tends to be supportive to the point of uselessness, as it can lead to fighting unwinnable court battles.

# Caritas Abundat in Omnia Music Video
* [Hildegard of Bingen](https://en.wikipedia.org/wiki/Hildegard_of_Bingen) was a writer, composer, philosopher, visionary mystic, and abbess during the High Middle Ages. She wrote a song, Caritas abundat in omnia (Love Abounds in All Things), which I've combined with Classical Chinese in a hip hop music video. It's my attempt to fuse Western Traditions (Christian thought, Latin language) with Eastern traditions (Daoism, Classical Chinese poetry) in a modern way (hip hop music, a bit of punk fashion, AI-generated).
* Prompt to Claude Sonnet 4: *Come up with a prompt for an AI image generator. I've got a hip hop song that's a mix of Latin and Classical Chinese with female vocals, and I wanted to come up with an avatar that's a mix of modern hip hop clothing, Classical Chinese fashion, with a touch of the Western Classical style.*
* Response: *Portrait of a stylish female avatar with East Asian features, wearing an elegant fusion outfit that blends hip hop streetwear with classical Chinese hanfu and Western classical elements. She has a modern fitted crop top or bomber jacket in rich silk brocade with traditional Chinese patterns, layered over flowing wide sleeves reminiscent of Tang dynasty robes. Bottom half features contemporary baggy pants or a pleated skirt with classical Chinese embroidery details. Accessories include chunky gold chains mixed with jade jewelry, ornate hair pins in an elaborate updo with some loose strands, and perhaps a silk sash or corset-style bodice element inspired by Western classical dress. The color palette combines deep jewel tones (emerald, sapphire, gold) with modern urban colors. Confident, artistic pose against a subtle background that suggests both ancient Chinese architecture and contemporary urban elements. Photorealistic style with dramatic lighting that emphasizes the cultural fusion aesthetic.*
* The result is [here](https://github.com/johnsmith968530/blog/blob/here-and-now/2025/08/16/ChatGPT_Image_Aug_16%2C_2025%2C_05_11_29_PM.png). I like the nose ring, tattoos, pants with pockets
* Prompt to Suno 4.5:
  * Lyrics: *Caritas abundat in omnia, 春风又绿江南岸 (chūn fēng yòu lǜ jiāng nán àn), Gratia divina in omne floret, 流水何处寄此情 (liú shuǐ hé chù jì cǐ qíng).*
  * Style: *hip hop with high pitched female voices*
* I combined the image with the music using HeyGen Avatar IV.
  * I wasn't completely satisfied with the result, and I feel like this is the weakest step in the procedure. The hands aren't quite right: the rings on her hand appear and disappear when she puts her hand into her pocket, and sometimes the fingers in her other hand aren't rendered correctly.
  * I posted the result on TikTok [here](https://www.tiktok.com/@johnsmith968530/video/7539350955167632654).

```text
vim: set et ff=unix ft=markdown nocp sts=2 sw=2 ts=2:
```
