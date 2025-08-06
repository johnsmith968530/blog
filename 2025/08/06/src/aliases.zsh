# $Source: /Users/x/Dropbox/2/src/blog/2025/08/06/src/RCS/aliases.zsh,v $
# $Date: 2025/08/06 21:21:52 $
# $Revision: 1.3 $

alias catS='cat "$(rS0)"'
alias ciS='ci -l "$(rS0)"'
alias borgS='echodo borg create --list --show-rc --show-version --stats --verbose "::$(rS0)" "$(rS0).asc" "$(rS0)"'
alias hc="taskmaster copy"
alias gpg.signS='gpg --armor --detach-sign "$(rS0)"'
alias hi="taskmaster inspect"
alias hl="taskmaster find"
alias lessS='less "$(rS0)"'
alias nS='nvim "$(rS0)"'
alias rDS='rcsdiff "$(rS0)"'

# vim: set et ff=unix ft=zsh nocp sts=2 sw=2 ts=2:
