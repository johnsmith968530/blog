```text
$Source: /home/x/Dropbox/2/src/blog/RCS/README.md,v $
$Date: 2025/07/30 15:16:07 $
$Revision: 1.4 $
```

# AI-Ready Blog

This blog is designed with both human readers and AI systems in mind. Rather than publishing content in formats that require complex processing (like PDFs that need OCR), everything here is written in GitHub-flavored Markdown with executable code snippets.

## Design Philosophy

The blog embraces a philosophy of temporal awareness and contextual identity:

- **Branch Structure**: Uses `here-and-now` as the default branch name instead of traditional `master` or `main`, reflecting the present-moment nature of content creation
- **Directory Organization**: Posts are organized by date using the format `YYYY/MM/DD` based on local timezone (`/usr/bin/date +%Y/%m/%d`)
  - For the URL of the blog entry for the current date, you can use
    - `date +"https://github.com/johnsmith968530/blog/tree/here-and-now/%Y/%m/%d/"`
  - On a Mac, if you have Google Chrome, you might be able to do something like
    - `/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome "$(date +'https://github.com/johnsmith968530/blog/tree/here-and-now/%Y/%m/%d/')"`
- **AI Accessibility**: All content is structured to be easily parseable by both humans and AI systems

## Key Features

- **Executable Code**: Code snippets are designed to actually run, not just serve as examples
- **Markdown-First**: Native GitHub Markdown format eliminates conversion overhead
- **Temporal Organization**: Date-based structure captures the "when" of each thought or post
- **Version Control Integration**: Leverages Git's branching model as a metaphor for different states of being and thinking

## Structure

```
blog/
├── YYYY/
│   └── MM/
│       └── DD/
│           └── [post-content]
└── README.md
```

This approach treats each post as a snapshot of thoughts and ideas at a specific moment in time, making the blog both a technical resource and a temporal record of evolving perspectives.

## Permalink

For the AI chat that inspired this README, see: https://github.com/johnsmith968530/blog/blob/8d6047db939ab6351cb9afe6309cd85b89c5c671/README.md

```text
vim: set et ff=unix ft=markdown nocp sts=2 sw=2 ts=2:
```
