#!/bin/zsh

# $Source: /home/x/Dropbox/2/src/blog/2026/10/22/RCS/slugify_path.zsh,v $
# $Date: 2026/10/22 15:37:42 $
# $Revision: 1.1 $

# Usage:
#
#   . "$BLOG_ROOT/2026/10/22/slugify_path.zsh"
#

slugify_path() {
    local s="$1"
    s="${s//\//⁄}"
    s="${s//:/꞉}"
    print -r -- "$s"
}

unslugify_path() {
    local s="$1"
    s="${s//⁄//}"
    s="${s//꞉/:}"
    print -r -- "$s"
}

# vim: set et ff=unix ft=zsh nocp sts=2 sw=2 ts=2:
