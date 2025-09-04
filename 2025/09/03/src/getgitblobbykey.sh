getgitblobbykey () { git cat-file blob $(envy get universal git hash "$@") }
