#!/usr/bin/env racket

;; $Source: /home/x/Dropbox/2/src/blog/2026/06/21/RCS/kardashev.rkt,v $
;; $Date: 2026/06/21 19:18:36 $
;; $Revision: 1.1 $

#lang racket

(provide watts->kardashev
         kardashev->watts)

;; Carl Sagan's logarithmic interpolation formula for the Kardashev scale:
;;
;;   K = (log10(P) - 6) / 10
;;
;; where P is power in watts. The inverse is:
;;
;;   P = 10^((K * 10) + 6)

(define (watts->kardashev watts)
  (/ (- (log watts 10) 6) 10))

(define (kardashev->watts k)
  (expt 10 (+ (* k 10) 6)))

;; vim: set et ff=unix ft=racket nocp sts=2 sw=2 ts=2:
