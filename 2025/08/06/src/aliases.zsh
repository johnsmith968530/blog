# $Source: /Users/x/Dropbox/2/src/blog/2025/08/06/src/RCS/aliases.zsh,v $
# $Date: 2025/08/06 21:51:56 $
# $Revision: 1.4 $

alias catS='cat "$(rS0)"'
alias cd.blog='mkdircd "$(envy global get blog root)/$(date +%Y/%m/%d)"'
alias cd.src='mkdircd $HOME/Dropbox/2/src'
alias g='git'
alias ciS='ci -l "$(rS0)"'
alias borgS='echodo borg create --list --show-rc --show-version --stats --verbose "::$(rS0)" "$(rS0).asc" "$(rS0)"'
alias hc="taskmaster copy"
alias gpg.signS='gpg --armor --detach-sign "$(rS0)"'
alias hi="taskmaster inspect"
alias hl="taskmaster find"
alias lessS='less "$(rS0)"'
alias mk.readme='prS README.md; getgitblobbykey markdown github > "$(rS0)"; rIS'
alias nS='nvim "$(rS0)"'
alias rDS='rcsdiff "$(rS0)"'
alias rIS='rcs_init "$(rS0)"'

# vim: set et ff=unix ft=zsh nocp sts=2 sw=2 ts=2:
