#lang racket/base

;; $Source: /home/x/Dropbox/2/src/blog/2026/06/21/RCS/stardate-interval.rkt,v $
;; $Date: 2026/06/21 19:18:36 $
;; $Revision: 1.1 $

;; Stardate intervals — port of stardate_interval.rb.
;;
;; An interval is the (signed) span between two stardates. Construct one
;; with `stardate-interval` or by "subtracting" two stardates with
;; `stardate-` (mirroring Ruby's `Stardate#-`, which returns an interval).

(require racket/format
         racket/math
         "stardate.rkt")

(provide (struct-out stardate-interval)
         stardate-                 ; (stardate- start stop) -> interval
         interval-negate
         interval-lifespans
         interval-years
         interval-months
         interval-weeks
         interval-days
         interval-hours
         interval-minutes
         interval-seconds
         interval-milliseconds
         interval->human
         interval->string)

(struct stardate-interval (start stop) #:transparent)

;; Ruby: stop - start => StardateInterval.new(start, stop)
(define (stardate- start stop)
  (stardate-interval start stop))

(define (interval-negate iv)
  (stardate-interval (stardate-interval-stop iv)
                     (stardate-interval-start iv)))

(define (interval-years iv)
  (- (stardate-interval-stop iv) (stardate-interval-start iv)))

(define (interval-lifespans iv)    (/ (interval-years iv) stardate-lifespan))
(define (interval-months iv)       (/ (interval-years iv) stardate-month))
(define (interval-weeks iv)        (/ (interval-years iv) stardate-week))
(define (interval-days iv)         (/ (interval-years iv) stardate-day))
(define (interval-hours iv)        (/ (interval-years iv) stardate-hour))
(define (interval-minutes iv)      (/ (interval-years iv) stardate-minute))
(define (interval-seconds iv)      (/ (interval-years iv) stardate-second))
(define (interval-milliseconds iv) (/ (interval-years iv) stardate-millisecond))

(define scales
  (list (cons "lifespans"    interval-lifespans)
        (cons "years"        interval-years)
        (cons "months"       interval-months)
        (cons "weeks"        interval-weeks)
        (cons "days"         interval-days)
        (cons "hours"        interval-hours)
        (cons "minutes"      interval-minutes)
        (cons "seconds"      interval-seconds)
        (cons "milliseconds" interval-milliseconds)))

;; Human-readable span at the largest scale with magnitude >= 1,
;; e.g. "2.515 weeks". Falls back to scientific-notation seconds.
(define (interval->human iv [precision 3])
  (or
   (for/or ([scale (in-list scales)])
     (define x ((cdr scale) iv))
     (and (>= (abs x) 1)
          (format "~a ~a"
                  (real->decimal-string x precision)
                  (car scale))))
   (let* ([s (interval-seconds iv)]
          [e (if (zero? s) 0 (exact-floor (/ (log (abs s)) (log 10))))]
          [m (if (zero? s) 0.0 (/ s (expt 10.0 e)))])
     (format "~ae~a~a seconds"
             (real->decimal-string m precision)
             (if (negative? e) "-" "+")
             (~r (abs e) #:min-width 2 #:pad-string "0")))))

;; "[2020.000... - 2026.440...] (6.440 years)" — Ruby's inspect.
(define (interval->string iv)
  (format "[~a - ~a] (~a)"
          (stardate-canonical (stardate-interval-start iv))
          (stardate-canonical (stardate-interval-stop iv))
          (interval->human iv)))

;; vim: set et ff=unix ft=racket nocp sts=2 sw=2 ts=2:
