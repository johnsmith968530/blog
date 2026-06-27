#!/usr/bin/env racket

;; $Source: /home/x/Dropbox/2/src/blog/2026/06/27/src/RCS/sanitize.rkt,v $
;; $Date: 2026/06/27 16:12:37 $
;; $Revision: 1.1 $

#lang racket

;; Racket port of /Users/x/Dropbox/2/m/bin/sanitize.pl
;;
;; Replaces problematic characters (spaces, quotes, ampersands, semicolons,
;; and shell metacharacters) in each file name with underscores, collapses
;; runs of underscores into a single one, and renames the file if the name
;; actually changed.

;; Characters that get turned into underscores. This mirrors the Perl
;; character class [\p{Zs}\s\'"&;\\`$*?<>!%(){}\[\]~^:+@#].
(define bad-chars
  '(#\space #\tab #\newline #\return #\page #\vtab ; \s
    #\u00A0 ; \p{Zs} -- Unicode "space separator" characters
    #\u1680 #\u2000 #\u2001 #\u2002 #\u2003 #\u2004
    #\u2005 #\u2006 #\u2007 #\u2008 #\u2009 #\u200A
    #\u202F #\u205F #\u3000
    #\' #\" #\& #\; #\\ #\` #\$ #\* #\? #\< #\> #\!
    #\% #\( #\) #\{ #\} #\[ #\] #\~ #\^ #\: #\+ #\@ #\#))

(define bad-set (for/set ([c bad-chars]) c))

;; Replace each bad character with an underscore, then collapse runs of
;; one or more underscores into a single underscore.
(define (sanitize-name name)
  (define replaced
    (list->string
     (for/list ([c (in-string name)])
       (if (set-member? bad-set c) #\_ c))))
  (regexp-replace* #rx"_+" replaced "_"))

(define (sanitize-filename file-path)
  (define-values (base name must-be-dir?) (split-path file-path))
  (define file-name (path->string name))
  (define new-file-name (sanitize-name file-name))
  (cond
    [(equal? new-file-name file-name)
     (printf "No changes made to '~a'\n" file-path)]
    [else
     (define new-file-path
       (cond
         [(and base (not (eq? base 'relative)))
          (build-path base new-file-name)]
         [else (string->path new-file-name)]))
     (with-handlers ([exn:fail:filesystem?
                      (lambda (e)
                        (eprintf "Cannot rename '~a' to '~a': ~a\n"
                                 file-path
                                 (path->string new-file-path)
                                 (exn-message e))
                        (exit 1))])
       (rename-file-or-directory file-path new-file-path))
     (printf "File renamed from '~a' to '~a'\n"
             file-path
             (path->string new-file-path))]))

(define args (vector->list (current-command-line-arguments)))
(when (null? args)
  (displayln "Usage: sanitize.rkt <file1> <file2> ...")
  (exit 1))

(for ([file-path (in-list args)])
  (sanitize-filename file-path))

; vim: set et ff=unix ft=racket nocp sts=2 sw=2 ts=2:
