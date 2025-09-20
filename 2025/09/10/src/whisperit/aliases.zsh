#!/bin/zsh

# $Source: /Users/x/Dropbox/2/src/blog/2025/09/10/src/whisperit/RCS/aliases.zsh,v $
# $Date: 2025/09/10 21:59:28 $
# $Revision: 1.2 $

alias whisperit='uv run --project "$(envy get global whisper root)" "$(envy get global whisper root)/whisper.py"'

# vim: set et ff=unix ft=zsh nocp sts=2 sw=2 ts=2:
