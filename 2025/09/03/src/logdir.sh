# $Source: /Users/x/Dropbox/2/src/blog/2025/09/03/src/RCS/logdir.sh,v $
# $Date: 2025/09/04 01:13:45 $
# $Revision: 1.1 $

export TODAY1=$(date +"`envy get global blog root`/%Y/%m/%d")
export LOGDIR1="$TODAY1/log"
[ -e "$LOGDIR1" ] || mkdir -p "$LOGDIR1"

# vim: set et ff=unix ft=zsh nocp sts=2 sw=2 ts=2:
