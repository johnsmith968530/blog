#!/bin/zsh

# $Source: /Users/x/Dropbox/2/src/blog/2025/08/11/src/RCS/extract_archives.zsh,v $
# $Date: 2025/08/11 21:45:41 $
# $Revision: 1.1 $

source getgitblobbykey.sh
eval "$(getgitblobbykey bash echodo)"
eval "$(getgitblobbykey bash useborg)"

useborg 2024.595435

archives1=(${(f)"$(borg list --short | grep Instruct | grep -v bf16)"})
pushd ~
for a1 in $archives1
do
  echo "Processing archive $a1" && \
  echodo borg extract --{list,show-{rc,version},verbose} "::$a1"
done
popd

# vim: set et ff=unix ft=zsh nocp sts=2 sw=2 ts=2:
