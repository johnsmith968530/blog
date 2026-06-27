# $Source: /home/x/Dropbox/2/src/blog/2026/06/27/src/RCS/write_entries.zsh,v $
# $Date: 2026/06/27 07:02:58 $
# $Revision: 1.1 $

#
# Usage:
#
#   entries=("OpenRouter" "🦊")
#   . "$(envy get global blog root)/2026/06/27/src/write_entries.zsh"
#

() {
  emulate -L zsh
  local x
  for x in $entries; do
    print -rn -- "$x" > "$x.txt"
    git add -- "$x.txt"
    print -r -- "$(git hash-object -- "$x.txt")  $x"
  done
}

# vim: set et ff=unix ft=zsh nocp sts=2 sw=2 ts=2:
