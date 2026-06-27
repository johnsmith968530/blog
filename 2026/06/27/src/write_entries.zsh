# $Source: /home/x/Dropbox/2/src/blog/2026/06/27/src/RCS/write_entries.zsh,v $
# $Date: 2026/06/27 07:21:19 $
# $Revision: 1.2 $

#
# Usage:
#
#   entries=("OpenRouter" "🦊")
#   . "$(envy get global blog root)/2026/06/27/src/write_entries.zsh"
#

if [ -z "${ZSH_VERSION-}" ]; then
  printf '%s\n' "write_entries.sh: requires zsh" >&2
  return 1 2>/dev/null || exit 1
fi

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
