;; $Source: /home/x/Dropbox/2/src/blog/2026/06/21/RCS/localhost.rkt,v $
;; $Date: 2026/06/21 21:44:59 $
;; $Revision: 1.1 $

#lang racket

(provide HOME Dropbox)

(require com/m0x13/checked-system)

(define HOME
  (or
    (getenv "HOME")
    (error 'localhost "HOME environment variable is not set")))

(define Dropbox
  (build-path HOME "Dropbox"))

;; vim: set et ff=unix ft=racket nocp sts=2 sw=2 ts=2:
