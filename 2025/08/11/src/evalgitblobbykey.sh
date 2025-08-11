evalgitblobbykey () { local hash=$(envy universal get git hash "$@"); local blob="$(git cat-file blob $hash)"; eval "$blob" }
