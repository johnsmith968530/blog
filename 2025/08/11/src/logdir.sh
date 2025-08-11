# $Source: /Users/x/Dropbox/2/src/blog/2025/08/11/src/RCS/logdir.sh,v $
# $Date: 2025/08/11 17:03:05 $
# $Revision: 1.1 $

export TODAY1=$(date +"`envy global get blog root`/%Y/%m/%d")
export LOGDIR1="$TODAY1/log"
[ -e "$LOGDIR1" ] || mkdir -p "$LOGDIR1"

# vim: set et ff=unix ft=zsh nocp sts=2 sw=2 ts=2:
