# $Source: /Users/x/Dropbox/2/src/blog/2025/09/07/src/redis-streams-worker/python/redis_streams_test/RCS/setenv.sh,v $
# $Date: 2025/09/07 23:39:48 $
# $Revision: 1.3 $

. /t/venv/rq/bin/activate
export PYTHONPATH="/home/x/Dropbox/2/src/rust/redis-streams-worker/python:/home/x/Dropbox/2/src/python/3:/home/x/Nextcloud/1/lib/python"
export REDISCLI_AUTH="$(envy get secret redis password)"

# vim: set et ff=unix ft=sh nocp sts=2 sw=2 ts=2:
