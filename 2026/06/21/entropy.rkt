;; $Source: /home/x/Dropbox/2/src/blog/2026/06/21/RCS/entropy.rkt,v $
;; $Date: 2026/06/21 19:50:31 $
;; $Revision: 1.1 $

#lang racket

(require racket/random)

(provide random-letters
         random-digits
         random-string
         random-minute
         random-port)

(define letters "abcdefghijklmnopqrstuvwxyz")
(define digits "0123456789")
(define letters+digits (string-append letters digits))

;; Convert a byte string to a nonnegative integer.
(define (bytes->nat bs)
  (for/fold ([acc 0])
            ([b (in-bytes bs)])
    (+ (* acc 256) b)))

;; Smallest k such that 256^k >= n.
(define (bytes-needed n)
  (let loop ([k 1]
             [m 256])
    (if (>= m n)
        k
        (loop (add1 k) (* m 256)))))

;; Like Python secrets.randbelow:
;; return an unbiased integer in [0, bound).
(define (crypto-randbelow bound)
  (unless (exact-positive-integer? bound)
    (raise-argument-error 'crypto-randbelow
                          "exact-positive-integer?"
                          bound))
  (define k (bytes-needed bound))
  (define modulus (expt 256 k))
  (define limit (- modulus (remainder modulus bound)))

  ;; Rejection sampling avoids modulo bias.
  (let loop ()
    (define x (bytes->nat (crypto-random-bytes k)))
    (if (< x limit)
        (remainder x bound)
        (loop))))

(define (check-n who n)
  (unless (exact-nonnegative-integer? n)
    (raise-argument-error who
                          "exact-nonnegative-integer?"
                          n)))

(define (random-char alphabet)
  (string-ref alphabet
              (crypto-randbelow (string-length alphabet))))

(define (random-from-alphabet who alphabet n)
  (check-n who n)
  (list->string
   (for/list ([_ (in-range n)])
     (random-char alphabet))))

(define (random-letters n)
  (random-from-alphabet 'random-letters letters n))

(define (random-digits n)
  (random-from-alphabet 'random-digits digits n))

(define (random-string n)
  (random-from-alphabet 'random-string letters+digits n))

(define (random-minute)
  (crypto-randbelow 60))

(define (random-port)
  ;; Unprivileged port range, inclusive.
  (+ 1024
     (crypto-randbelow (+ (- 65535 1024) 1))))

;; vim: set et ff=unix ft=racket nocp sts=2 sw=2 ts=2:
