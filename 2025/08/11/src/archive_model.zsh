#!/bin/zsh

# $Source: /Users/x/Dropbox/2/src/blog/2025/08/11/src/RCS/archive_model.zsh,v $
# $Date: 2025/08/11 20:06:02 $
# $Revision: 1.6 $

source getgitblobbykey.sh
eval "$(getgitblobbykey bash echodo)"
eval "$(getgitblobbykey bash logdir)"
eval "$(getgitblobbykey bash useborg)"

pushd ~
count1="$(find .ollama/models/manifests -type f | wc -l | tr -d ' ')"
if [ "$count1" != "1" ]
then
  echo "Wrong number of models in ~/.ollama/models : $count1"
  exit 1
fi
export f1="$(find .ollama/models/manifests -type f)"
echo "Attempting to archive model with manifest file $f1"
echo "Make sure it is the only model in ~/.ollama/models!"

if [ ! -e "$f1" ]
then
  echo "No such manifest exists"
  popd
  exit 1
fi

sd1=$(stardate --mtime "$f1")
n1=$(echo -n "$f1" | sed -E 's|\.ollama/models/manifests(/registry.ollama.ai(/library)?)?/|_ollama_models-|g; s|/|_|g')
echo "Proposed archive name with no stardate: $n1"
n2="$n1-$sd1"
echo "Proposed archive name with stardate: $n2"
sleep 10
for r1 in 2024.595435 41 42
do
  useborg $r1 && \
    echodo borg create --{list,show-{rc,version},stats,verbose} \
      "$BORG_REPO::$n2" .ollama/models && \
    echo $(stardate) borg create --{list,show-{rc,version},stats,verbose} \
      "$BORG_REPO::$n2" .ollama/models | tee -a "$LOGDIR1/borg.log"
done

popd

# vim: set et ff=unix ft=zsh nocp sts=2 sw=2 ts=2:
