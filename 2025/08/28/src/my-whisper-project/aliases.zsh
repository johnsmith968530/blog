#!/bin/zsh

# $Source: /Users/x/Dropbox/2/src/blog/2025/08/28/src/my-whisper-project/RCS/aliases.zsh,v $
# $Date: 2025/08/28 15:32:15 $
# $Revision: 1.1 $

alias whisperit='uv run --project "$(envy global get whisper root)" "$(envy global get whisper root)/whisper.py"'

# vim: set et ff=unix ft=zsh nocp sts=2 sw=2 ts=2:
