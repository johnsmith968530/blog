#lang racket

;; $Source: /home/x/Dropbox/2/src/blog/2026/09/14/RCS/write-image-page.rkt,v $
;; $Date: 2026/09/14 23:08:15 $
;; $Revision: 1.1 $

(provide write-image-page)

(require racket/string)

(define (html-escape s)
  (string-replace
   (string-replace
    (string-replace
     (string-replace
      (string-replace s "&" "&amp;")
      "<" "&lt;")
     ">" "&gt;")
    "\"" "&quot;")
   "'" "&#39;"))

(define (write-image-page urls title filename)
  (call-with-output-file filename
    #:exists 'truncate/replace
    (lambda (out)
      (fprintf out "<!DOCTYPE html>\n")
      (fprintf out "<html lang=\"en\">\n")
      (fprintf out "<head>\n")
      (fprintf out "  <meta charset=\"utf-8\">\n")
      (fprintf out "  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">\n")
      (fprintf out "  <title>~a</title>\n" (html-escape title))
      (fprintf out #<<CSS
  <style>
    body {
      margin: 0;
      padding: 2rem;
      background: #111;
      color: #eee;
      font-family: sans-serif;
      text-align: center;
    }

    .images {
      display: flex;
      flex-direction: column;
      align-items: center;
      gap: 1rem;
    }

    img {
      display: block;
      max-width: 100%;
      height: auto;
    }
  </style>
CSS
               )
      (fprintf out "</head>\n")
      (fprintf out "<body>\n")
      (fprintf out "  <h1>~a</h1>\n" (html-escape title))
      (fprintf out "  <div class=\"images\">\n")

      (for ([url urls])
        (fprintf out
                 "    <img src=\"~a\" loading=\"lazy\">\n"
                 (html-escape url)))

      (fprintf out "  </div>\n")
      (fprintf out "</body>\n")
      (fprintf out "</html>\n"))))

;; vim: set et ff=unix ft=racket nocp sts=2 sw=2 ts=2:
