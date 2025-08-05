#!/bin/bash

# $Source: /Users/x/Dropbox/2/src/blog/2025/08/05/src/RCS/setenv.zsh,v $
# $Date: 2025/08/05 18:51:30 $
# $Revision: 1.2 $

mkdircd () { mkdir -p "$1" && cd "$1"; }

export MT1="$HOME/Dropbox/2/src/blog/2025/07/30/src/github_markdown_template.md"
alias cd.blog='mkdircd $HOME/Dropbox/2/src/blog/$(date "+%Y/%m/%d")'
alias cd.src='mkdircd $HOME/Dropbox/2/src'
alias g='git'
alias mk.readme='prS README.md; cp "$MT1" "$(rS0)"; rIS'

# vim: set et ff=unix ft=sh nocp sts=2 sw=2 ts=2:
