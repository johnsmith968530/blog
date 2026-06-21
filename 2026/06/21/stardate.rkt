#lang racket/base

;; $Source: /home/x/Dropbox/2/src/blog/2026/06/21/RCS/stardate.rkt,v $
;; $Date: 2026/06/21 19:18:36 $
;; $Revision: 1.1 $

;; stardate — the current year in UTC, with linear extrapolation.
;;
;; A stardate is an ordinary real number, e.g. 2026.4403...
;; The integer part is the Gregorian year (UTC); the fractional part is
;; the fraction of that year that has elapsed.
;;
;; Racket port encompassing the Python, Ruby, and Rust implementations.

(require racket/date
         racket/math
         racket/path
         racket/string
         racket/format
         racket/list)

(provide
 ;; Constants (fractions of a year, based on 365.2425 days/Gregorian year)
 stardate-millisecond stardate-second stardate-minute stardate-hour
 stardate-day stardate-week stardate-fortnight stardate-month
 stardate-lifespan

 ;; Core conversions
 seconds->stardate          ; epoch seconds (real) -> stardate
 stardate->seconds          ; stardate -> epoch seconds (real)
 date->stardate             ; Racket date struct -> stardate
 stardate->date             ; stardate -> Racket date* struct (in a tz)
 string->stardate           ; ISO-8601-ish string OR numeric stardate string -> stardate
 current-stardate           ; now
 make-stardate              ; from calendar components (+ tz)

 ;; Formatting
 stardate->string           ; #:digits 'short | 'medium | 'canonical | n, #:separator
 stardate-short             ; 3 digits
 stardate-medium            ; 6 digits
 stardate-canonical         ; 15 digits
 stardate->femtoyears
 unformat-stardate          ; "2026_44" / "2026-44" -> 2026.44

 ;; Datetime renderings
 stardate->iso8601          ; rounded to nearest second
 stardate->rfc2822          ; rounded to nearest second
 stardate->dts              ; compact UTC timestamp YYYYMMDD_HHMMSSZ
 stardate->date-string      ; "YYYY-MM-DD HH:MM:SS (Weekday, Month D, YYYY in TZ +HH:MM)"

 ;; Files
 file-mtime-stardate
 file-ctime-stardate
 stardate-filename          ; insert stardate before the extension
 stardate-rename!           ; rename a file with its mtime/ctime stardate

 ;; Time zones
 tz-offset                  ; resolve a tz spec to a UTC offset (seconds) at an instant
 tzinfo-available?)

;; ---------------------------------------------------------------------------
;; Constants

(define stardate-millisecond (/ 1.0 31556952000.0))
(define stardate-second      (/ 1.0 31556952.0))
(define stardate-minute      (/ 1.0 525949.2))
(define stardate-hour        (/ 1.0 8765.82))
(define stardate-day         (/ 1.0 365.2425))
(define stardate-week        (/ 7.0 365.2425))
(define stardate-fortnight   (/ 14.0 365.2425))
(define stardate-month       (/ 1.0 12.0))
(define stardate-lifespan    80.0)

;; ---------------------------------------------------------------------------
;; Time zone handling
;;
;; A tz spec is one of:
;;   'utc                — UTC (default everywhere)
;;   'local              — the OS local time zone
;;   exact-integer       — a fixed UTC offset in seconds
;;   "UTC" | "Z"         — UTC
;;   "+HH:MM" / "-HHMM"  — a fixed UTC offset
;;   "Area/City"         — an IANA zone (requires the `tzinfo` package)

(define tzinfo-utc-seconds->tzoffset
  (with-handlers ([exn:fail? (λ (_) #f)])
    (dynamic-require 'tzinfo 'utc-seconds->tzoffset)))

(define tzinfo-local-seconds->tzoffset
  (with-handlers ([exn:fail? (λ (_) #f)])
    (dynamic-require 'tzinfo 'local-seconds->tzoffset)))

(define tzinfo-tzoffset-utc-seconds
  (with-handlers ([exn:fail? (λ (_) #f)])
    (dynamic-require 'tzinfo 'tzoffset-utc-seconds)))

(define (tzinfo-available?)
  (and tzinfo-utc-seconds->tzoffset #t))

(define fixed-offset-rx
  #px"^([+-])([0-9]{2}):?([0-9]{2})$")

(define (parse-fixed-offset s)
  (define m (regexp-match fixed-offset-rx s))
  (and m
       (let ([sign (if (string=? (second m) "-") -1 1)]
             [h (string->number (third m))]
             [mn (string->number (fourth m))])
         (* sign (+ (* h 3600) (* mn 60))))))

;; Offset (seconds east of UTC) for `tz` at the UTC instant `utc-seconds`.
;; When `local?` is #t, `utc-seconds` is interpreted as *wall-clock* seconds
;; in that zone instead (needed to convert local datetimes to UTC).
(define (tz-offset tz utc-seconds #:local? [local? #f])
  (cond
    [(or (eq? tz 'utc) (equal? tz "UTC") (equal? tz "Z") (not tz)) 0]
    [(exact-integer? tz) tz]
    [(eq? tz 'local)
     (date-time-zone-offset
      (seconds->date (exact-floor utc-seconds) #t))]
    [(string? tz)
     (or (parse-fixed-offset tz)
         (iana-offset tz utc-seconds local?))]
    [else (raise-argument-error 'tz-offset
                                "(or/c 'utc 'local exact-integer? string?)"
                                tz)]))

(define (iana-offset name secs local?)
  (unless (tzinfo-available?)
    (error 'stardate
           "IANA time zone ~s requested, but the `tzinfo` package is not installed;\n install it with: raco pkg install tzinfo"
           name))
  (define s (exact-floor secs))
  (if local?
      (let ([r (tzinfo-local-seconds->tzoffset name s)])
        ;; During DST transitions this can be a list (ambiguous) — take the first.
        (tzinfo-tzoffset-utc-seconds (if (pair? r) (car r) r)))
      (tzinfo-tzoffset-utc-seconds (tzinfo-utc-seconds->tzoffset name s))))

;; ---------------------------------------------------------------------------
;; Core conversions

(define (utc-year-boundary y)
  (find-seconds 0 0 0 1 1 y #f))

;; Real epoch seconds -> stardate
(define (seconds->stardate secs)
  (define y0 (date-year (seconds->date (exact-floor secs) #f)))
  (define t0 (utc-year-boundary y0))
  (define t1 (utc-year-boundary (add1 y0)))
  (+ y0 (/ (- (exact->inexact secs) t0) (- t1 t0))))

;; Stardate -> real epoch seconds
(define (stardate->seconds sd)
  (define y0 (exact-floor sd))
  (define t0 (utc-year-boundary y0))
  (define t1 (utc-year-boundary (add1 y0)))
  (+ t0 (* (- sd y0) (- t1 t0))))

;; Racket `date` struct -> stardate (honors the struct's time-zone-offset)
(define (date->stardate d)
  (seconds->stardate (date->seconds d #f)))  ; #f: use the struct's own offset... see below

;; NOTE: racket's (date->seconds d local?) ignores d's offset when local? is #f
;; and treats the fields as UTC, so subtract the embedded offset explicitly:
(set! date->stardate
      (λ (d)
        (define nanos (if (date*? d) (date*-nanosecond d) 0))
        (seconds->stardate
         (+ (- (date->seconds d #f) (date-time-zone-offset d))
            (/ nanos 1e9)))))

;; Stardate -> date* struct in the given time zone
(define (stardate->date sd #:tz [tz 'utc])
  (define secs (stardate->seconds sd))
  (define off (tz-offset tz secs))
  (define shifted (exact-floor (+ secs off)))
  (define d (seconds->date shifted #f))
  (define frac (- secs (exact-floor secs)))
  (date* (date-second d) (date-minute d) (date-hour d)
         (date-day d) (date-month d) (date-year d)
         (date-week-day d) (date-year-day d)
         (date-dst? d)
         off
         (exact-round (* frac 1e9))
         (tz-label tz)))

(define (tz-label tz)
  (cond [(or (eq? tz 'utc) (not tz)) "UTC"]
        [(eq? tz 'local) "local"]
        [(string? tz) tz]
        [(exact-integer? tz) (offset->string tz)]
        [else ""]))

;; Now
(define (current-stardate)
  (seconds->stardate (/ (current-inexact-milliseconds) 1000.0)))

;; From calendar components, like Python's stardate(year=..., month=..., ...).
;; Hour defaults to noon. `tz` defaults to the TZ environment variable, or UTC.
(define (make-stardate #:year year #:month month #:day day
                       #:hour [hour 12] #:minute [minute 0]
                       #:second [second 0] #:microsecond [microsecond 0]
                       #:tz [tz (or (getenv "TZ") 'utc)])
  (define wall (+ (find-seconds 0 0 0 1 1 year #f) ; anchor; recompute below
                  0))
  ;; wall-clock seconds as if the components were UTC:
  (define naive (find-seconds second minute hour day month year #f))
  (define off (tz-offset tz naive #:local? #t))
  (seconds->stardate (+ (- naive off) (/ microsecond 1e6))))

;; ---------------------------------------------------------------------------
;; Parsing

(define iso-rx
  #px"^([0-9]{4})-([0-9]{2})-([0-9]{2})(?:[ T]([0-9]{2}):([0-9]{2})(?::([0-9]{2})(\\.[0-9]+)?)?)?(Z|[+-][0-9]{2}:?[0-9]{2})?$")

;; Parse either an ISO-8601-ish datetime string ("2026-06-10 14:30:00Z",
;; "2026-06-10T14:30:00.5-07:00", "2026-06-10") or a numeric stardate string
;; ("2026.44", "2026_44", "2026-44" via unformat). Datetime strings with no
;; explicit offset are interpreted via #:tz (default UTC).
(define (string->stardate s #:tz [tz 'utc])
  (define m (regexp-match iso-rx (string-trim s)))
  (cond
    [m
     (define (num x [d 0]) (if x (string->number x) d))
     (define-values (y mo dy h mi se fr zs)
       (apply values (cdr m)))
     (define naive (find-seconds (num se) (num mi) (num h)
                                 (num dy) (num mo) (num y) #f))
     (define frac (if fr (string->number (string-append "0" fr)) 0))
     (define off
       (if zs
           (if (string=? zs "Z") 0 (parse-fixed-offset zs))
           (tz-offset tz naive #:local? #t)))
     (seconds->stardate (+ (- naive off) frac))]
    [(string->number s) => values]
    [else (unformat-stardate s)]))

;; "2026_4403" or "2026-4403" -> 2026.4403  (the Rust CLI's `unfmt`)
(define (unformat-stardate s)
  (or (string->number (string-replace (string-replace s "_" ".") "-" "."))
      0.0))

;; ---------------------------------------------------------------------------
;; Formatting

(define (digits->n digits)
  (case digits
    [(short) 3]
    [(medium) 6]
    [(canonical) 15]
    [else (if (exact-nonnegative-integer? digits)
              digits
              (raise-argument-error 'stardate->string
                                    "'short, 'medium, 'canonical, or a natural number"
                                    digits))]))

;; Format a stardate. #:separator replaces the decimal point, e.g. #\_ or #\-
;; (the Rust CLI's --underscore / --hyphen).
(define (stardate->string sd
                          #:digits [digits 'canonical]
                          #:separator [sep #f])
  (define s (real->decimal-string sd (digits->n digits)))
  (if sep (string-replace s "." (string sep)) s))

(define (stardate-short sd)     (stardate->string sd #:digits 'short))
(define (stardate-medium sd)    (stardate->string sd #:digits 'medium))
(define (stardate-canonical sd) (stardate->string sd #:digits 'canonical))

(define (stardate->femtoyears sd)
  (exact-truncate (* sd 1e15)))

;; ---------------------------------------------------------------------------
;; Datetime renderings

(define day-names   #("Sunday" "Monday" "Tuesday" "Wednesday" "Thursday" "Friday" "Saturday"))
(define month-names #("" "January" "February" "March" "April" "May" "June" "July"
                      "August" "September" "October" "November" "December"))

(define (pad2 n) (~r n #:min-width 2 #:pad-string "0"))

(define (offset->string off #:colon? [colon? #t])
  (define sign (if (negative? off) "-" "+"))
  (define a (abs off))
  (string-append sign (pad2 (quotient a 3600))
                 (if colon? ":" "")
                 (pad2 (quotient (remainder a 3600) 60))))

;; Rounded to the nearest second, like the Ruby implementation.
(define (stardate->iso8601 sd #:tz [tz 'utc])
  (define d (stardate->date (seconds->stardate
                             (+ (stardate->seconds sd) 0.5))
                            #:tz tz))
  (string-append
   (number->string (date-year d)) "-" (pad2 (date-month d)) "-" (pad2 (date-day d))
   "T" (pad2 (date-hour d)) ":" (pad2 (date-minute d)) ":" (pad2 (date-second d))
   (if (zero? (date-time-zone-offset d))
       "Z"
       (offset->string (date-time-zone-offset d)))))

(define rfc-day-abbr   #("Sun" "Mon" "Tue" "Wed" "Thu" "Fri" "Sat"))
(define rfc-month-abbr #("" "Jan" "Feb" "Mar" "Apr" "May" "Jun" "Jul"
                         "Aug" "Sep" "Oct" "Nov" "Dec"))

;; Rounded to the nearest second, like the Ruby implementation.
(define (stardate->rfc2822 sd #:tz [tz 'utc])
  (define d (stardate->date (seconds->stardate
                             (+ (stardate->seconds sd) 0.5))
                            #:tz tz))
  (format "~a, ~a ~a ~a ~a:~a:~a ~a"
          (vector-ref rfc-day-abbr (date-week-day d))
          (date-day d)
          (vector-ref rfc-month-abbr (date-month d))
          (date-year d)
          (pad2 (date-hour d)) (pad2 (date-minute d)) (pad2 (date-second d))
          (offset->string (date-time-zone-offset d) #:colon? #f)))

;; Compact UTC timestamp: YYYYMMDD_HHMMSSZ (Ruby's to_dts)
(define (stardate->dts sd)
  (define d (stardate->date sd #:tz 'utc))
  (format "~a~a~a_~a~a~aZ"
          (date-year d) (pad2 (date-month d)) (pad2 (date-day d))
          (pad2 (date-hour d)) (pad2 (date-minute d)) (pad2 (date-second d))))

;; "2026-06-10 14:30:00 (Wednesday, June 10, 2026 in America/New_York -04:00)"
;; — the Rust CLI's --localtime output format.
(define (stardate->date-string sd #:tz [tz 'utc])
  (define d (stardate->date sd #:tz tz))
  (format "~a-~a-~a ~a:~a:~a (~a, ~a ~a, ~a in ~a ~a)"
          (date-year d) (pad2 (date-month d)) (pad2 (date-day d))
          (pad2 (date-hour d)) (pad2 (date-minute d)) (pad2 (date-second d))
          (vector-ref day-names (date-week-day d))
          (vector-ref month-names (date-month d))
          (date-day d)
          (date-year d)
          (tz-label tz)
          (offset->string (date-time-zone-offset d))))

;; ---------------------------------------------------------------------------
;; Files

(define (file-mtime-stardate path)
  (seconds->stardate
   (hash-ref (file-or-directory-stat path) 'modify-time-seconds)))

(define (file-ctime-stardate path)
  (seconds->stardate
   (hash-ref (file-or-directory-stat path) 'change-time-seconds)))

;; "photo.jpg" + 2026.44... -> "photo-2026.440000000000000.jpg"
(define (stardate-filename path sd)
  (define p (if (path? path) (path->string path) path))
  (define ext (let ([e (path-get-extension p)])
                (if e (bytes->string/utf-8 e) "")))
  (define base (if (string=? ext "")
                   p
                   (substring p 0 (- (string-length p) (string-length ext)))))
  (string-append base "-" (stardate-canonical sd) ext))

;; Rename a file to embed its mtime (or ctime) stardate. Returns the new path.
(define (stardate-rename! path #:mode [mode 'mtime])
  (define sd
    (case mode
      [(mtime) (file-mtime-stardate path)]
      [(ctime) (file-ctime-stardate path)]
      [else (error 'stardate-rename! "unknown mode: ~a" mode)]))
  (define new-path (stardate-filename path sd))
  (rename-file-or-directory path new-path)
  new-path)

;; vim: set et ff=unix ft=racket nocp sts=2 sw=2 ts=2:
