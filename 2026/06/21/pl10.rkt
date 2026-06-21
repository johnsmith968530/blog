#lang racket

;; $Source: /home/x/Dropbox/2/src/blog/2026/06/21/RCS/pl10.rkt,v $
;; $Date: 2026/06/21 19:20:45 $
;; $Revision: 1.1 $

;; Return the base-10 logarithm of a number with specified precision.

(provide pl10
         pxl10)

;; Return the base-10 logarithm of x with the given number of decimal digits.
;; x      : number? — the number to calculate the logarithm of
;; digits : exact-nonnegative-integer? — number of decimal digits to display (default 3)
(define (pl10 x [digits 3])
  (real->decimal-string (log x 10) digits))

;; Return x followed by its base-10 logarithm in power notation.
;;
;; Example:
;;   (pxl10 123.456789)
;;   => "123.456789 (10^2.092)"
(define (pxl10 x [digits 3])
  (format "~a (10 ** ~a)"
          x
          (pl10 x digits)))

;; vim: set et ff=unix ft=racket nocp sts=2 sw=2 ts=2:
