#lang racket

;; $Source: /home/x/Dropbox/2/src/blog/2026/09/09/RCS/blooby-url.rkt,v $
;; $Date: 2026/09/09 21:39:49 $
;; $Revision: 1.3 $

;; Return the base-10 logarithm of a number with specified precision.

(provide blooby-url)

(define extension->mime
  (hash
        "bash" "text/plain/utf-8"
        "css"  "text/css"
        "gif"  "image/gif"
        "htm"  "text/html/utf-8"
        "html" "text/html/utf-8"
        "jpg"  "image/jpeg"
        "jpeg" "image/jpeg"
        "json" "application/json"
        "md"   "text/plain/utf-8"
        "mp3"  "audio/mpeg"
        "mp4"  "video/mp4"
        "ogg"  "audio/ogg"
        "pdf"  "application/pdf"
        "png"  "image/png"
        "py"   "text/plain/utf-8"
        "rkt"  "text/plain/utf-8"
        "sh"   "text/plain/utf-8"
        "svg"  "image/svg+xml"
        "txt"  "text/plain/utf-8"
        "wav"  "audio/wav"
        "webp" "image/webp"
        "webm" "video/webm"
        "zsh"  "text/plain/utf-8"
  )
)

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
