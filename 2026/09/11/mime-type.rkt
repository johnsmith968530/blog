#lang racket

;; $Source: /home/x/Dropbox/2/src/blog/2026/09/11/RCS/mime-type.rkt,v $
;; $Date: 2026/09/12 01:33:02 $
;; $Revision: 1.3 $

(provide extension->mime-type)

(define extension->mime-type
  (hash
        "bash" "text/plain"
        "cfg"  "text/plain"
        "conf" "text/plain"
        "css"  "text/css"
        "gif"  "image/gif"
        "go"   "text/plain"
        "htm"  "text/html"
        "html" "text/html"
        "ico"  "image/x-icon"
        "iso"  "application/x-iso9660-image"
        "jpg"  "image/jpeg"
        "jpeg" "image/jpeg"
        "json" "application/json"
        "lua"  "text/plain"
        "md"   "text/plain"
        "m4a"  "audio/mp4"
        "m4v"  "video/mp4"
        "mka"  "audio/matroska"
        "mkv"  "video/x-matroska"
        "mov"  "video/quicktime"
        "mp3"  "audio/mpeg"
        "mp4"  "video/mp4"
        "mpeg" "video/mpeg"
        "mpg"  "video/mpeg"
        "ogg"  "audio/ogg"
        "opus" "audio/opus"
        "pdf"  "application/pdf"
        "png"  "image/png"
        "py"   "text/plain"
        "rb"   "text/plain"
        "rkt"  "text/plain"
        "rs"   "text/plain"
        "sh"   "text/plain"
        "svg"  "image/svg+xml"
        "ts"   "text/plain"
        "txt"  "text/plain"
        "wasm" "application/wasm"
        "wav"  "audio/wav"
        "webm" "video/webm"
        "webp" "image/webp"
        "wmv"  "video/x-ms-wmv"
        "zsh"  "text/plain"
  )
)

;; vim: set et ff=unix ft=racket nocp sts=2 sw=2 ts=2:
