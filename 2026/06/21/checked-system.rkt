;; $Source: /home/x/Dropbox/2/src/blog/2026/06/21/RCS/checked-system.rkt,v $
;; $Date: 2026/06/21 21:40:00 $
;; $Revision: 1.1 $

#lang racket

(provide checked-system*
         checked-system)

(define (->cmd-arg x)
  (cond
    [(string? x) x]
    [(path? x) (path->string x)]
    [(number? x) (number->string x)]
    [(symbol? x) (symbol->string x)]
    [(boolean? x) (if x "true" "false")]
    [else
     (error '->cmd-arg
            "not a safe command-line argument: ~e"
            x)]))

(define (checked-system* who program . args)
  (define converted-args
    (map ->cmd-arg args))
  (define ok?
    (apply system* program converted-args))
  (unless ok?
    (error who
           "command failed: ~s"
           (cons program converted-args)))
  ok?)

(define (checked-system who command)
  (define ok? (system command))
  (unless ok?
    (error who
           "command failed: ~a"
           command))
  ok?)

;; vim: set et ff=unix ft=racket nocp sts=2 sw=2 ts=2:
