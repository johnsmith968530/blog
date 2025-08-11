evalgitblobbykey () { local hash=$(envy universal get git hash "$@"); eval $(git cat-file blob "$hash") }
