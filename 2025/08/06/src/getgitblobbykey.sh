getgitblobbykey () { git cat-file blob $(envy global get git hash "$@") }
