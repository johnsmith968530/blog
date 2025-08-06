# $Source: /Users/x/Dropbox/2/src/blog/2025/08/06/src/RCS/redis-stringstack.sh,v $
# $Date: 2025/08/06 15:06:53 $
# $Revision: 1.2 $

# Set up the OS variable
export ORG_AU0_OS="`envy global get OS`"

# Set up Redis authentication
export REDISCLI_AUTH="$(envy secret get redis password)"
[ -z "$REDISCLI_AUTH" ] && unset REDISCLI_AUTH

# Push arguments onto the string stack. If no arguments, then push
# the clipboard onto the string stack.
prS() {
    if [ ${#@} -eq 0 ]; then
        case "$ORG_AU0_OS" in
            Cygwin)
                /usr/bin/cat /dev/clipboard | redis-cli -x LPUSH org.au0:stack:string
                ;;
            Darwin)
                /usr/bin/pbpaste | redis-cli -x LPUSH org.au0:stack:string
                ;;
            FreeBSD)
                ;;
            GNU/Linux)
                /usr/bin/xclip -out -selection clipboard | redis-cli -x LPUSH org.au0:stack:string
                ;;
            *)
                echo "Unknown operating system"
                ;;
        esac
    else
        redis-cli LPUSH org.au0:stack:string "$@"
    fi
}

# Display the string stack
rS() {
    echo "Note: redis-cli displays 1-based indices, but all commands use 0-based indexing" >&2
    redis-cli LRANGE org.au0:stack:string 0 -1
}

# Delete item at specified index (0-based)
delrS() {
    if [ -z "$1" ]; then
        /usr/bin/printf "Usage: delsS <n>\n"
        return 1
    fi
    redis-cli LSET org.au0:stack:string $1 "__DELETED__" && \
    redis-cli LREM org.au0:stack:string 1 "__DELETED__"
}

# Pop the top item from the stack
poprS() {
    redis-cli LPOP org.au0:stack:string
    rS
}

# Copy top of stack to clipboard
crS() {
    local top="$(redis-cli LINDEX org.au0:stack:string 0)"
    if [ -n "$top" ]; then
        case "$ORG_AU0_OS" in
            Cygwin)
                echo -n "$top" > /dev/clipboard
                ;;
            Darwin)
                echo -n "$top" | /usr/bin/pbcopy
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

# Get item at index 0 (top of stack)
rS0 () { redis-cli LINDEX org.au0:stack:string 0; }

# Get item at index 1
rS1 () { redis-cli LINDEX org.au0:stack:string 1; }

# Get item at index 2
rS2 () { redis-cli LINDEX org.au0:stack:string 2; }

# Get item at index 3
rS3 () { redis-cli LINDEX org.au0:stack:string 3; }

# Clear the entire stack
clrS() {
    redis-cli DEL org.au0:stack:string
}

# Get item at specified index (0-based)
rSn() {
    if [ -z "$1" ]; then
        /usr/bin/printf "Usage: rSn <n>\n"
        return 1
    fi
    redis-cli LINDEX org.au0:stack:string $1
}

# vim: set et ff=unix ft=sh nocp sts=2 sw=2 ts=2:
