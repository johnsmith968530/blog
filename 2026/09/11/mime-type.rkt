#lang racket

;; $Source: /home/x/Dropbox/2/src/blog/2026/09/09/RCS/mime-type.rkt,v $
;; $Date: 2026/09/09 22:41:48 $
;; $Revision: 1.2 $

(provide extension->mime-type)

(define extension->mime-type
  (hash
        "bash" "text/plain"
        "css"  "text/css"
        "gif"  "image/gif"
        "htm"  "text/html"
        "html" "text/html"
        "jpg"  "image/jpeg"
        "jpeg" "image/jpeg"
        "json" "application/json"
        "md"   "text/plain"
        "mp3"  "audio/mpeg"
        "mp4"  "video/mp4"
        "ogg"  "audio/ogg"
        "pdf"  "application/pdf"
        "png"  "image/png"
        "py"   "text/plain"
        "rkt"  "text/plain"
        "sh"   "text/plain"
        "svg"  "image/svg+xml"
        "txt"  "text/plain"
        "wav"  "audio/wav"
        "webp" "image/webp"
        "webm" "video/webm"
        "zsh"  "text/plain"
  )
)

;; vim: set et ff=unix ft=racket nocp sts=2 sw=2 ts=2:
