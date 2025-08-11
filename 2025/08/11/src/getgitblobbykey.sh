getgitblobbykey () { git cat-file blob $(envy universal get git hash "$@") }
