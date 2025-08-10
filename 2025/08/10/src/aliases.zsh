#!/bin/zsh

# $Source: /Users/x/Dropbox/2/src/blog/2025/08/10/src/RCS/aliases.zsh,v $
# $Date: 2025/08/10 14:09:23 $
# $Revision: 1.1 $

alias rLS='rlog "$(rS0)" | less'
alias rIS='rcs_init "$(rS0)" && co -f -l "$(rS0)"'

# vim: set et ff=unix ft=zsh nocp sts=2 sw=2 ts=2:
