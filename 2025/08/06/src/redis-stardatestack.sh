# $Source: /Users/x/Dropbox/2/src/blog/2025/08/06/src/RCS/redis-stardatestack.sh,v $
# $Date: 2025/08/06 19:27:36 $
# $Revision: 1.1 $

# Set up the OS variable if it isn't set already
[[ -v ORG_AU0_OS ]] || export ORG_AU0_OS="`/usr/bin/uname -o`"

# Set up Redis authentication if not already set
[[ -v REDISCLI_AUTH ]] || export REDISCLI_AUTH="$(envy secret get redis password)"

# Push current stardate or given stardates onto the stack
prStar() {
    if [ ${#@} -eq 0 ]; then
        stardate | redis-cli -x LPUSH org.au0:stack:stardate
    else
        redis-cli LPUSH org.au0:stack:stardate "$@"
    fi
}

# Push stardate from mtime onto the stack
prStarMtime() {
    if [ $# -eq 0 ]; then
        local top="$(redis-cli LINDEX org.au0:stack:stardate 0)"
        if [ -n "$top" ]; then
            stardate --mtime "$top" | redis-cli -x LPUSH org.au0:stack:stardate
        else
            echo "Stardate stack is empty"
            return 1
        fi
    else
        stardate --mtime "$1" | redis-cli -x LPUSH org.au0:stack:stardate
    fi
}

# Display the stardate stack
rStar() {
    echo "Note: redis-cli displays 1-based indices, but all commands use 0-based indexing" >&2
    redis-cli LRANGE org.au0:stack:stardate 0 -1
}

# Delete stardate at specified index (0-based)
delrStar() {
    if [ -z "$1" ]; then
        /usr/bin/printf "Usage: delrStar <n>\n"
        return 1
    fi
    redis-cli LSET org.au0:stack:stardate $1 "__DELETED__" && \
    redis-cli LREM org.au0:stack:stardate 1 "__DELETED__"
}

# Pop the top stardate from the stack
poprStar() {
    redis-cli LPOP org.au0:stack:stardate
}

# Copy top stardate to clipboard
crStar() {
    local top="$(redis-cli LINDEX org.au0:stack:stardate 0)"
    if [ -n "$top" ]; then
        case "$ORG_AU0_OS" in
            Cygwin)
                echo -n "$top" > /dev/clipboard
                ;;
            FreeBSD)
                ;;
            GNU/Linux)
                echo -n "$top" | /usr/bin/xclip -sel clip
                ;;
            *)
                echo "Unknown operating system"
                ;;
        esac
    else
        echo "Stack is empty"
    fi
}

# Get stardate at index 0 (top of stack)
rStar0() { redis-cli LINDEX org.au0:stack:stardate 0; }

# Get stardate at index 1
rStar1() { redis-cli LINDEX org.au0:stack:stardate 1; }

# Get stardate at index 2
rStar2() { redis-cli LINDEX org.au0:stack:stardate 2; }

# Get stardate at index 3
rStar3() { redis-cli LINDEX org.au0:stack:stardate 3; }

# Clear the entire stardate stack
clrStar() {
    redis-cli DEL org.au0:stack:stardate
}

# Get stardate at specified index (0-based)
rStarn() {
    if [ -z "$1" ]; then
        /usr/bin/printf "Usage: rStarn <n>\n"
        return 1
    fi
    redis-cli LINDEX org.au0:stack:stardate $1
}

# Create ZFS snapshot using top stardate
alias zfs.snap='logbot_do zfs snapshot -r "$(rS0)@$(rStar0)"'

# vim: set et ff=unix ft=sh nocp sts=2 sw=2 ts=2:
