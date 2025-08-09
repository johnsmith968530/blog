#!/bin/zsh

# $Source$
# $Date$
# $Revision$

alias borgS='echodo borg create --{list,show-{rc,version},stats,verbose} "::$(rS0)" "$(rS0).asc" "$(rS0)"'

# vim: set et ff=unix ft=zsh nocp sts=2 sw=2 ts=2:
