#!/usr/bin/env racket

;; $Source: /home/x/Dropbox/2/src/blog/2026/06/21/RCS/git.rkt,v $
;; $Date: 2026/06/21 21:46:56 $
;; $Revision: 1.1 $

#lang racket

(require racket/system
         racket/string
         "checked-system.rkt")

(provide git-push-to-all
         git-remotes)

(define default-git "/usr/bin/git")

(define (command->lines who program . args)
  (define output
    (with-output-to-string
      (lambda ()
        (define ok?
          (apply system* program args))
        (unless ok?
          (error who
                 "command failed: ~s"
                 (cons program args))))))

  (filter non-empty-string?
          (map string-trim
               (string-split output "\n"))))

(define (git-remotes #:git [git default-git])
  (command->lines 'git-remotes git "remote"))

(define (git-push-to-all [branch "--all"]
                         #:git [git default-git]
                         #:remotes [remotes (git-remotes #:git git)])
  (when (null? remotes)
    (error 'git-push-to-all
           "no git remotes found"))

  (for ([remote remotes])
    (checked-system* (string->symbol
                      (format "git-push:~a:~a" remote branch))
                     git
                     "push"
                     remote
                     branch)))

;; vim: set et ff=unix ft=racket nocp sts=2 sw=2 ts=2:
