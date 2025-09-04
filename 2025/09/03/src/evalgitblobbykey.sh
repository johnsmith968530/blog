evalgitblobbykey () { local hash=$(envy get universal git hash "$@"); local blob="$(git cat-file blob $hash)"; eval "$blob" }
