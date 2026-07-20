#!/usr/bin/env racket

;; $Source: /Users/x/Dropbox/2/src/blog/2026/07/20/src/RCS/stardate-mcp.rkt,v $
;; $Date: 2026/07/20 10:36:39 $
;; $Revision: 1.1 $

#lang racket/base

;; Stardate MCP server — stdio JSON-RPC for Cline.
;;
;; Exposes the same functionality as the command-line `stardate/cli` program
;; (and a few extra library helpers) as MCP tools.

(require racket/cmdline
         racket/file
         racket/format
         json
         racket/list
         racket/match
         racket/string
         blog/2026/06/21/stardate
         blog/2026/06/21/stardate-interval)

;; ---------------------------------------------------------------------------
;; JSON-RPC helpers

;; MCP stdio transport uses newline-delimited JSON: each JSON-RPC message
;; is a single line on stdin/stdout (no Content-Length framing). Blank lines
;; are ignored so we tolerate stray newlines between messages.
(define (read-json-message)
  (let loop ()
    (define line (read-line (current-input-port) 'any))
    (cond
      [(eof-object? line) #f]
      [(string=? (string-trim line) "") (loop)]
      [else (string->jsexpr line)])))

(define (write-message obj)
  (define out (current-output-port))
  (write-string (jsexpr->string obj) out)
  (write-char #\newline out)
  (flush-output out))


(define (response id result)
  (hasheq 'jsonrpc "2.0"
          'id id
          'result result))

(define (error-response id code message [data #f])
  (define err (hasheq 'code code 'message message))
  (write-message
   (hasheq 'jsonrpc "2.0"
           'id id
           'error (if data (hash-set err 'data data) err))))

;; ---------------------------------------------------------------------------
;; Logging (stderr)

;; Per MCP 2025-11-25, stdio servers may use stderr for all log levels,
;; not just errors. We emit one JSON object per line so that clients which
;; capture stderr can parse structured logs, while the line is still
;; human-readable enough for `tail -f` debugging.
(define log-levels '(debug info notice warning error critical alert emergency))

(define (level>=? a b)
  (>= (index-of log-levels a) (index-of log-levels b)))

(define current-log-level (make-parameter 'debug))

(define (log level fmt . args)
  (define msg (apply format fmt args))
  ;; log-levels is ordered least-severe (debug) -> most-severe (emergency).
  ;; Show a message when its severity is at or above the configured threshold,
  ;; so a threshold of 'debug shows everything and 'error shows only errors.
  (when (level>=? level (current-log-level))
    (define out (current-error-port))
    (write-string
     (jsexpr->string
      (hasheq 'jsonrpc "2.0"
              'method "notifications/message"
              'params (hasheq 'level (symbol->string level)
                              'logger "stardate-mcp"
                              'data (hasheq 'message msg))))
     out)
    (write-char #\newline out)
    (flush-output out)))

;; ---------------------------------------------------------------------------
;; Argument / schema helpers

(define (get-string h key [default #f])
  (define v (hash-ref h key default))
  (if (string? v) v default))

(define (get-number h key [default #f])
  (define v (hash-ref h key default))
  (if (real? v) v default))

(define (get-bool h key [default #f])
  (define v (hash-ref h key default))
  (if (boolean? v) v default))

;; Accept a stardate as either a number or a string (e.g. "2026.44",
;; "2026_44", "2026-44"), mirroring the CLI's use of unformat-stardate
;; for --diff and --localtime arguments.
(define (stardate-arg h key [default #f])
  (define v (hash-ref h key default))
  (cond
    [(real? v) v]
    [(string? v) (unformat-stardate v)]
    [else default]))

(define (digits-key k)
  (case k [("short") 'short] [("medium") 'medium] [("canonical") 'canonical]
          [else (if (real? k) (inexact->exact (round k)) 'canonical)]))

(define (separator-char k)
  (case k [("_") #\_] [("-") #\-] [(".") #f]
          [else (if (char? k) k #f)]))

;; ---------------------------------------------------------------------------
;; Tool dispatch

(define tools
  (list
   (hasheq
    'name "current_stardate"
    'description "Return the current stardate (now) with optional formatting."
    'inputSchema
    (hasheq 'type "object"
            'properties
            (hasheq 'digits (hasheq 'type "string"
                                    'description "short | medium | canonical")
                    'separator (hasheq 'type "string"
                                      'description "Decimal separator: . - _")
                    'tz (hasheq 'type "string"
                               'description "IANA zone or offset (used only for display context; default UTC)"))
            'required '()))

    (hasheq
     'name "format_stardate"
     'description "Format an arbitrary stardate value."
     'inputSchema
     (hasheq 'type "object"
             'properties
             (hasheq 'stardate (hasheq 'type (list "number" "string")
                                       'description "Stardate value (number or \"2026.44\" / \"2026_44\" / \"2026-44\")")
                     'digits (hasheq 'type "string"
                                     'description "short | medium | canonical")
                     'separator (hasheq 'type "string"
                                       'description "Decimal separator: . - _"))
             'required '("stardate")))

   (hasheq
    'name "parse_stardate"
    'description "Parse an ISO-8601-ish datetime or numeric stardate string."
    'inputSchema
    (hasheq 'type "object"
            'properties
            (hasheq 'value (hasheq 'type "string"
                                   'description "ISO datetime or 2026.44 / 2026_44 / 2026-44")
                    'tz (hasheq 'type "string"
                               'description "Default time zone when not in the string")
                    'digits (hasheq 'type "string"
                                    'description "short | medium | canonical")
                    'separator (hasheq 'type "string"
                                      'description "Decimal separator: . - _"))
            'required '("value")))

   (hasheq
    'name "make_stardate"
    'description "Build a stardate from calendar components."
    'inputSchema
    (hasheq 'type "object"
            'properties
            (hasheq 'year (hasheq 'type "integer")
                    'month (hasheq 'type "integer")
                    'day (hasheq 'type "integer")
                    'hour (hasheq 'type "integer" 'description "Default: 12")
                    'minute (hasheq 'type "integer" 'description "Default: 0")
                    'second (hasheq 'type "integer" 'description "Default: 0")
                    'microsecond (hasheq 'type "integer" 'description "Default: 0")
                    'tz (hasheq 'type "string"
                               'description "IANA name, UTC, Z, +HH:MM, -HHMM")
                    'digits (hasheq 'type "string"
                                    'description "short | medium | canonical")
                    'separator (hasheq 'type "string"
                                      'description "Decimal separator: . - _"))
            'required '("year" "month" "day")))

    (hasheq
     'name "stardate_to_datetime"
     'description "Convert a stardate to a human or machine-readable datetime string."
     'inputSchema
     (hasheq 'type "object"
             'properties
             (hasheq 'stardate (hasheq 'type (list "number" "string")
                                       'description "Stardate value (number or \"2026.44\" / \"2026_44\" / \"2026-44\")")
                     'format (hasheq 'type "string"
                                    'description "human | iso8601 | rfc2822 | dts")
                     'tz (hasheq 'type "string"
                                'description "Time zone (default UTC)"))
             'required '("stardate")))

    (hasheq
     'name "stardate_diff"
     'description "Human-readable difference between two stardates."
     'inputSchema
     (hasheq 'type "object"
             'properties
             (hasheq 'a (hasheq 'type (list "number" "string")
                                'description "Stardate value (number or \"2026.44\" / \"2026_44\" / \"2026-44\")")
                     'b (hasheq 'type (list "number" "string")
                                'description "Stardate value (number or \"2026.44\" / \"2026_44\" / \"2026-44\")"))
             'required '("a" "b")))

    (hasheq
     'name "stardate_interval"
     'description "Detailed interval between two stardates (years, months, weeks, days, etc.)."
     'inputSchema
     (hasheq 'type "object"
             'properties
             (hasheq 'start (hasheq 'type (list "number" "string")
                                   'description "Stardate value (number or \"2026.44\" / \"2026_44\" / \"2026-44\")")
                     'stop (hasheq 'type (list "number" "string")
                                  'description "Stardate value (number or \"2026.44\" / \"2026_44\" / \"2026-44\")"))
             'required '("start" "stop")))

   (hasheq
    'name "file_mtime_stardate"
    'description "Stardate corresponding to a file's modification time."
    'inputSchema
    (hasheq 'type "object"
            'properties
            (hasheq 'path (hasheq 'type "string" 'description "Absolute or relative file path")
                    'digits (hasheq 'type "string"
                                    'description "short | medium | canonical")
                    'separator (hasheq 'type "string"
                                      'description "Decimal separator: . - _"))
            'required '("path")))))

(define (handle-call name args)
  (case name
    [("current_stardate")
     (define sd (current-stardate))
     (define digits (digits-key (get-string args 'digits "canonical")))
     (define sep (separator-char (get-string args 'separator ".")))
     (stardate->string sd #:digits digits #:separator sep)]

    [("format_stardate")
     (define sd (stardate-arg args 'stardate))
     (unless (real? sd) (error "missing or invalid stardate"))
     (define digits (digits-key (get-string args 'digits "canonical")))
     (define sep (separator-char (get-string args 'separator ".")))
     (stardate->string sd #:digits digits #:separator sep)]

    [("parse_stardate")
     (define s (get-string args 'value))
     (unless (string? s) (error "missing value"))
     (define tz (or (get-string args 'tz #f) "UTC"))
     (define sd (string->stardate s #:tz tz))
     (define digits (digits-key (get-string args 'digits "canonical")))
     (define sep (separator-char (get-string args 'separator ".")))
     (stardate->string sd #:digits digits #:separator sep)]

    [("make_stardate")
     (define y (hash-ref args 'year #f))
     (define mo (hash-ref args 'month #f))
     (define d (hash-ref args 'day #f))
     (unless (and (real? y) (real? mo) (real? d))
       (error "year, month, day required"))
     (define tz (or (get-string args 'tz #f) (or (getenv "TZ") "UTC")))
     (define sd
       (make-stardate #:year (inexact->exact (round y))
                      #:month (inexact->exact (round mo))
                      #:day (inexact->exact (round d))
                      #:hour (inexact->exact (round (hash-ref args 'hour 12)))
                      #:minute (inexact->exact (round (hash-ref args 'minute 0)))
                      #:second (inexact->exact (round (hash-ref args 'second 0)))
                      #:microsecond (inexact->exact (round (hash-ref args 'microsecond 0)))
                      #:tz tz))
     (define digits (digits-key (get-string args 'digits "canonical")))
     (define sep (separator-char (get-string args 'separator ".")))
     (stardate->string sd #:digits digits #:separator sep)]

    [("stardate_to_datetime")
     (define sd (stardate-arg args 'stardate))
     (unless (real? sd) (error "missing or invalid stardate"))
     (define fmt (get-string args 'format "human"))
     (define tz (or (get-string args 'tz #f) "UTC"))
     (case fmt
       [("iso8601") (stardate->iso8601 sd #:tz tz)]
       [("rfc2822") (stardate->rfc2822 sd #:tz tz)]
       [("dts") (stardate->dts sd)]
       [else (stardate->date-string sd #:tz tz)])]

    [("stardate_diff")
     (define a (stardate-arg args 'a))
     (define b (stardate-arg args 'b))
     (unless (and (real? a) (real? b)) (error "a and b required"))
     (interval->human (stardate- (min a b) (max a b)))]

    [("stardate_interval")
     (define start (stardate-arg args 'start))
     (define stop (stardate-arg args 'stop))
     (unless (and (real? start) (real? stop)) (error "start and stop required"))
     (define iv (stardate- start stop))
     (jsexpr->string
      (hasheq 'years (interval-years iv)
              'months (interval-months iv)
              'weeks (interval-weeks iv)
              'days (interval-days iv)
              'hours (interval-hours iv)
              'minutes (interval-minutes iv)
              'seconds (interval-seconds iv)
              'milliseconds (interval-milliseconds iv)
              'lifespans (interval-lifespans iv)
              'human (interval->human iv)))]

    [("file_mtime_stardate")
     (define p (get-string args 'path))
     (unless (string? p) (error "missing path"))
     (define sd (file-mtime-stardate p))
     (define digits (digits-key (get-string args 'digits "canonical")))
     (define sep (separator-char (get-string args 'separator ".")))
     (stardate->string sd #:digits digits #:separator sep)]

    [else (error "unknown tool:" name)]))

;; ---------------------------------------------------------------------------
;; Main loop

(define (run)
  (let loop ()
    (define msg (read-json-message))
    (when msg
      (define id (hash-ref msg 'id #f))
      (define method (hash-ref msg 'method #f))
      (with-handlers ([exn:fail?
                       (λ (e)
                         (error-response id -32603 (exn-message e)))])
        (case method
           [("initialize")
            (define params (hash-ref msg 'params (hasheq)))
            (define requested (hash-ref params 'protocolVersion #f))
            (define negotiated
              (if (equal? requested "2025-11-25") "2025-11-25" "2025-11-25"))
            (log 'info "initialize: client=~a negotiated=~a" requested negotiated)
            (write-message
             (response id
                       (hasheq 'protocolVersion negotiated
                               'capabilities (hasheq 'tools (hasheq))
                               'serverInfo (hasheq 'name "stardate-mcp"
                                                   'version "1.0.0"))))]

          [("notifications/initialized")
           ;; no response
           (void)]

          [("tools/list")
           (write-message (response id (hasheq 'tools tools)))]

           [("tools/call")
            (define params (hash-ref msg 'params (hasheq)))
            (define name (hash-ref params 'name #f))
            (define args (hash-ref params 'arguments (hasheq)))
            (log 'debug "tools/call: ~a args=~a" name args)
            (define-values (text err?)
              (with-handlers ([exn:fail?
                               (λ (e)
                                 (log 'warning "tool error (~a): ~a" name (exn-message e))
                                 (values (exn-message e) #t))])
                (values (handle-call name args) #f)))
            (define content (list (hasheq 'type "text" 'text text)))
            (write-message
             (response id
                       (if err?
                           (hasheq 'content content 'isError #t)
                           (hasheq 'content content))))]

          [else
           (error-response id -32601 (format "method not found: ~a" method))]))
      (loop))))

(module+ main
  (run))

;; vim: set et ff=unix ft=racket nocp sts=2 sw=2 ts=2:
