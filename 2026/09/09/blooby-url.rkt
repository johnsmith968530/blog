#lang racket

;; $Source: /home/x/Dropbox/2/src/blog/2026/09/09/RCS/blooby-url.rkt,v $
;; $Date: 2026/09/09 22:37:17 $
;; $Revision: 1.4 $

;; Return the base-10 logarithm of a number with specified precision.

(provide blooby-url)

(require blog/2026/09/09/mime-type)

(define (add-utf8-if-text mime-type)
  (if (string-prefix? mime-type "text/")
      (string-append mime-type "/utf-8")
      mime-type))

(define (blooby-url filename h)
  (define m (regexp-match #rx"[.]([^./]+)$" filename))
  (unless m
    (error 'blooby-url "filename has no extension: ~a" filename))

  (define ext (string-downcase (cadr m)))
  (define mime
    (hash-ref extension->mime-type ext
              (λ ()
                (error 'blooby-url
                       "unknown filename extension: ~a"
                       ext))))

  (format "http://blooby.m0x13.com:47815/git/blob/~a/~a"
          (add-utf8-if-text mime)
          (hash-ref h 'git-sha1)))

;; vim: set et ff=unix ft=racket nocp sts=2 sw=2 ts=2:
