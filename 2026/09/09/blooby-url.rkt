#lang racket

;; $Source: /home/x/Dropbox/2/src/blog/2026/06/21/RCS/pl10.rkt,v $
;; $Date: 2026/06/21 19:20:45 $
;; $Revision: 1.1 $

;; Return the base-10 logarithm of a number with specified precision.

(provide blooby-url)

(define extension->mime
  (hash "jpg"  "image/jpeg"
        "jpeg" "image/jpeg"
        "png"  "image/png"
        "gif"  "image/gif"
        "webp" "image/webp"
        "svg"  "image/svg+xml"
        "mp4"  "video/mp4"
        "webm" "video/webm"
        "mp3"  "audio/mpeg"
        "wav"  "audio/wav"
        "ogg"  "audio/ogg"
        "txt"  "text/plain"
        "html" "text/html"
        "htm"  "text/html"
        "css"  "text/css"
        "json" "application/json"
        "pdf"  "application/pdf"))

(define (blooby-url filename h)
  (define m (regexp-match #rx"[.]([^./]+)$" filename))
  (unless m
    (error 'blooby-url "filename has no extension: ~a" filename))

  (define ext (string-downcase (cadr m)))
  (define mime
    (hash-ref extension->mime ext
              (λ ()
                (error 'blooby-url
                       "unknown filename extension: ~a"
                       ext))))

  (format "http://blooby.m0x13.com:47815/git/blob/~a/~a"
          mime
          (hash-ref h 'git-sha1)))

;; vim: set et ff=unix ft=racket nocp sts=2 sw=2 ts=2:
