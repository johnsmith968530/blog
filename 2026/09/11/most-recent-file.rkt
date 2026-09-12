#lang racket

;; $Source: /home/x/Dropbox/2/src/blog/2026/09/11/RCS/most-recent-file.rkt,v $
;; $Date: 2026/09/12 01:24:08 $
;; $Revision: 1.1 $

(provide most-recent-file)

(define (most-recent-file dir)
  (path->string
    (argmax file-or-directory-modify-seconds
            (filter file-exists?
              (directory-list dir #:build? #t)))))

;; vim: set et ff=unix ft=racket nocp sts=2 sw=2 ts=2:
