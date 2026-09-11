#lang racket

;; $Source: /home/x/Dropbox/2/src/blog/2026/09/09/RCS/mime-type.rkt,v $
;; $Date: 2026/09/09 22:41:48 $
;; $Revision: 1.2 $

(provide most-recent-file)

(define (most-recent-file dir)
  (path->string
    (argmax file-or-directory-modify-seconds
            (filter file-exists?
              (directory-list dir #:build? #t)))))

;; vim: set et ff=unix ft=racket nocp sts=2 sw=2 ts=2:
