#!/usr/bin/env racket

;; $Source: /home/x/Dropbox/2/src/blog/2026/08/06/RCS/chess-rating.rkt,v $
;; $Date: 2026/08/07 07:06:08 $
;; $Revision: 1.1 $

#lang racket/base

(require racket/contract
         racket/list
         racket/match)

(provide
 (contract-out
  [chess-rating
   (->* (real? rating-system? rating-system?)
        (#:round? boolean?)
        real?)]
  [rating-system? (-> any/c boolean?)]
  [stockfish-level? (-> any/c boolean?)]))

;; ----------------------------------------------------------------------
;; Public API
;; ----------------------------------------------------------------------
;;
;;   (chess-rating rating from-system to-system [#:round? #t])
;;
;; Supported systems:
;;
;;   'chesscom   Chess.com blitz
;;   'lichess    Lichess blitz
;;   'elo        traditional OTB / USCF-ish Elo strength
;;   'fide       current FIDE rating
;;   'stockfish  Lichess Stockfish level 1..8
;;
;; Examples:
;;
;;   (chess-rating 1000 'chesscom 'lichess)
;;   => 1425
;;
;;   (chess-rating 1500 'lichess 'chesscom)
;;   => approximately 1115
;;
;;   (chess-rating 4 'stockfish 'elo)
;;   => 1700
;;
;;   (chess-rating 1400 'elo 'stockfish)
;;   => approximately 3.0
;;
;; Conversions are deliberately approximate.
;;


(define rating-systems
  '(chesscom chess.com
    lichess lichess.org
    elo otb
    fide
    stockfish))


(define (rating-system? x)
  (and (symbol? x)
       (memq x rating-systems)
       #t))


(define (stockfish-level? x)
  (and (real? x)
       (<= 1 x 8)))


;; ----------------------------------------------------------------------
;; Generic piecewise-linear interpolation
;; ----------------------------------------------------------------------

(define (interpolate table x)
  (define pts
    (sort table < #:key car))

  (define (between p q)
    (match-define (list x0 y0) p)
    (match-define (list x1 y1) q)

    (+ y0
       (* (- x x0)
          (/ (- y1 y0)
             (- x1 x0)))))

  (cond
    ;; Linear extrapolation below the table.
    [(<= x (caar pts))
     (between (first pts)
              (second pts))]

    ;; Linear extrapolation above the table.
    [(>= x (car (last pts)))
     (between (list-ref pts (- (length pts) 2))
              (last pts))]

    ;; Piecewise-linear interpolation.
    [else
     (for/first ([p (in-list pts)]
                 [q (in-list (rest pts))]
                 #:when (<= (car p) x (car q)))
       (between p q))]))


(define (invert-table table)
  (for/list ([p (in-list table)])
    (list (second p)
          (first p))))


;; ----------------------------------------------------------------------
;; Empirical / heuristic conversion tables
;; ----------------------------------------------------------------------
;;
;; Chess.com and Lichess values are blitz ratings.
;;
;; 'elo is intended as an approximate traditional OTB/USCF-like strength
;; scale rather than literally meaning a current FIDE rating.
;;


;; Chess.com blitz -> Lichess blitz

(define chesscom->lichess
  '((500  1090)
    (800  1290)
    (1000 1425)
    (1200 1555)
    (1500 1755)
    (1800 1950)
    (2000 2080)
    (2200 2210)
    (2500 2410)
    (3000 2745)))


;; Chess.com blitz -> traditional OTB Elo-like strength

(define chesscom->elo
  '((500   925)
    (800  1150)
    (1000 1285)
    (1200 1415)
    (1500 1600)
    (1800 1775)
    (2000 1890)
    (2200 2010)
    (2500 2195)
    (3000 2535)))


;; Chess.com blitz -> current FIDE rating
;;
;; Low-end FIDE conversions should be treated particularly cautiously.

(define chesscom->fide
  '((1100 1660)
    (1200 1670)
    (1400 1710)
    (1600 1780)
    (1800 1865)
    (2000 1965)
    (2200 2075)
    (2400 2190)
    (2600 2300)
    (2800 2400)
    (3000 2485)))


;; Lichess Stockfish level -> nominal Elo-like strength
;;
;; VERY approximate.  Stockfish handicap levels do not play like human
;; players with stable Elo ratings.

(define stockfish->elo
  '((1  800)
    (2 1100)
    (3 1400)
    (4 1700)
    (5 2000)
    (6 2300)
    (7 2700)
    (8 3000)))


;; ----------------------------------------------------------------------
;; Normalize system names
;; ----------------------------------------------------------------------

(define (canonical-system system)
  (case system
    [(chesscom chess.com)   'chesscom]
    [(lichess lichess.org)  'lichess]
    [(elo otb)              'elo]
    [(fide)                 'fide]
    [(stockfish)            'stockfish]))


;; ----------------------------------------------------------------------
;; Convert arbitrary system -> latent Elo-like scale
;; ----------------------------------------------------------------------

(define (->elo x system)
  (case (canonical-system system)

    [(elo)
     x]

    [(chesscom)
     (interpolate chesscom->elo x)]

    [(lichess)
     (define chesscom-rating
       (interpolate (invert-table chesscom->lichess)
                    x))

     (interpolate chesscom->elo
                  chesscom-rating)]

    [(fide)
     (define chesscom-rating
       (interpolate (invert-table chesscom->fide)
                    x))

     (interpolate chesscom->elo
                  chesscom-rating)]

    [(stockfish)
     (unless (stockfish-level? x)
       (raise-argument-error
        'chess-rating
        "Lichess Stockfish level in the range 1 through 8"
        x))

     (interpolate stockfish->elo x)]))


;; ----------------------------------------------------------------------
;; Convert latent Elo-like scale -> arbitrary system
;; ----------------------------------------------------------------------

(define (elo-> x system)
  (case (canonical-system system)

    [(elo)
     x]

    [(chesscom)
     (interpolate (invert-table chesscom->elo)
                  x)]

    [(lichess)
     (define chesscom-rating
       (interpolate (invert-table chesscom->elo)
                    x))

     (interpolate chesscom->lichess
                  chesscom-rating)]

    [(fide)
     (define chesscom-rating
       (interpolate (invert-table chesscom->elo)
                    x))

     (interpolate chesscom->fide
                  chesscom-rating)]

    [(stockfish)
     (interpolate (invert-table stockfish->elo)
                  x)]))


;; ----------------------------------------------------------------------
;; Main conversion function
;; ----------------------------------------------------------------------

(define (chess-rating x from to #:round? [round? #t])
  (define from*
    (canonical-system from))

  (define to*
    (canonical-system to))

  ;; Avoid introducing interpolation error when the systems are identical.
  (define result
    (if (eq? from* to*)
        x
        (elo-> (->elo x from*)
               to*)))

  (cond
    ;; Fractional levels are useful:
    ;; 4.5 = approximately halfway between Stockfish 4 and 5.
    [(eq? to* 'stockfish)
     (exact->inexact result)]

    [round?
     (inexact->exact
      (round result))]

    [else
     result]))


;; ----------------------------------------------------------------------
;; Tests
;; ----------------------------------------------------------------------

(module+ test
  (require rackunit)

  (check-true  (rating-system? 'chesscom))
  (check-true  (rating-system? 'lichess))
  (check-true  (rating-system? 'fide))
  (check-true  (rating-system? 'stockfish))
  (check-false (rating-system? 'go))

  (check-true  (stockfish-level? 1))
  (check-true  (stockfish-level? 4.5))
  (check-true  (stockfish-level? 8))
  (check-false (stockfish-level? 0))
  (check-false (stockfish-level? 9))

  ;; Known table points.
  (check-equal?
   (chess-rating 1000 'chesscom 'lichess)
   1425)

  (check-equal?
   (chess-rating 1500 'chesscom 'lichess)
   1755)

  (check-equal?
   (chess-rating 4 'stockfish 'elo)
   1700)

  ;; Aliases.
  (check-equal?
   (chess-rating 1000 'chess.com 'lichess.org)
   1425)

  ;; Identity conversion.
  (check-equal?
   (chess-rating 1372 'chesscom 'chesscom)
   1372)

  ;; Approximate round trip.
  (define x 1500)
  (define y
    (chess-rating x 'chesscom 'lichess #:round? #f))
  (define z
    (chess-rating y 'lichess 'chesscom #:round? #f))

  (check-= z x 0.001))

;; vim: set et ff=unix ft=racket nocp sts=2 sw=2 ts=2:
