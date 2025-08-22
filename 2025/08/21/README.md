```text
$Source: /Users/x/Dropbox/2/src/blog/2025/08/21/RCS/README.md,v $
$Date: 2025/08/22 00:25:50 $
$Revision: 1.2 $
```

* Updated `envy` to be able search in subtrees.
  * I used Cline in Visual Studio with `claude-sonnet-4-20250514:1m`.
  * Prompt: *There's a Rust program in `/Users/x/Dropbox/2/src/blog/2025/08/21/src/envy` that has the command line form `envy <section> search <expression>` that searches the JSON tree of the specified section for the expression. I'd like to generalize this command to `envy <section> search key1 key2 ... <expression>`, which descends down the JSON tree using the specified keys before searching the subtree for the expression (the keys, which are optional, narrow the search).*o


```text
vim: set et ff=unix ft=markdown nocp sts=2 sw=2 ts=2:
```
