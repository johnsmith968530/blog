#!/usr/bin/env racket

;; $Source: /Users/x/Dropbox/2/src/blog/2026/07/07/src/RCS/cpdoi.rkt,v $
;; $Date: 2026/07/08 05:12:16 $
;; $Revision: 1.4 $

#lang racket/base

;; cpdoi — copy a PDF to its DOI-derived path and log the transaction.
;;
;; A simple command-line replacement for the cpdoi-rs-worker Redis Streams
;; worker.  No Redis, no external services — just file copying, hashing,
;; stardate timestamping, and JSON logging.
;;
;; Usage:
;;   cpdoi.rkt --doi <doi> --source-file <path> [options]
;;
;; Required:
;;   --doi <doi>           The DOI (e.g. 10.1234/test.123)
;;   --source-file <path>  Path to the PDF file to copy
;;
;; Optional:
;;   --title <string>      Document title
;;   --author <author>     Author (repeatable for multiple authors)
;;   --year <number>       Publication year
;;   --note <string>       Note (repeatable for multiple notes)

(require racket/cmdline
         racket/string
         racket/format
         racket/list
         racket/file
         racket/path
         json
         blog/2026/07/06/multidigest
         blog/2026/06/21/stardate
         com/m0x13/localhost)

;; ---------------------------------------------------------------------------
;; Configuration

(define (get-base-dir)
  (or (getenv "ORG_AU0_DOI_BASE_DIR")
      (build-path Dropbox "3" "Documents" "DOI")))

(define (get-log-dir)
  (build-path Dropbox "2" "Data" "Logs" "cpdoi"))

;; ---------------------------------------------------------------------------
;; DOI processing

(define doi-prefix-rx #px"^(?:https?://)?(?:dx\\.)?doi\\.org/|^doi:")

(define (clean-doi doi)
  (regexp-replace doi-prefix-rx doi ""))

(define (doi->path doi)
  (define clean (clean-doi doi))
  (define parts (string-split clean "/"))
  (define publisher-id (car parts))
  (define publisher-parts (string-split publisher-id "."))
  (define base (get-base-dir))
  (define path
    (for/fold ([p base])
              ([part (in-list (append publisher-parts (cdr parts)))])
      (build-path p part)))
  (string->path (string-append (path->string path) ".pdf")))

(define (get-server1-url doi)
  (format "https://server1.au0.org/doi/~a" (clean-doi doi)))

;; ---------------------------------------------------------------------------
;; PDF validation

(define (valid-pdf? path)
  (and (file-exists? path)
       (let* ([in (open-input-file path)]
              [header (read-bytes 5 in)])
         (close-input-port in)
         (equal? header #"%PDF-"))))

;; ---------------------------------------------------------------------------
;; Main

(define (main . argv)
  (define doi #f)
  (define source-file #f)
  (define title #f)
  (define authors '())
  (define year #f)
  (define notes '())

  (parse-command-line
   "cpdoi" (list->vector argv)
    `((once-each
       [("--doi")         ,(λ (_ d) (set! doi d))            ("DOI" "doi")]
       [("--source-file") ,(λ (_ f) (set! source-file f))    ("Source PDF path" "path")]
       [("--title")       ,(λ (_ t) (set! title t))          ("Document title" "title")]
       [("--year")        ,(λ (_ y) (set! year (string->number y))) ("Publication year" "year")])
      (multi
       [("--author")      ,(λ (_ a) (set! authors (append authors (list a)))) ("Author (repeatable for multiple)" "author")]
       [("--note")        ,(λ (_ n) (set! notes (append notes (list n)))) ("Note (repeatable for multiple)" "note")]))
   (λ (accum . rest) (void))
   '())

  ;; Validate required args
  (unless doi
    (eprintf "error: --doi is required\n")
    (exit 1))
  (unless source-file
    (eprintf "error: --source-file is required\n")
    (exit 1))

  ;; Validate source file
  (unless (file-exists? source-file)
    (eprintf "error: source file does not exist: ~a\n" source-file)
    (exit 1))
  (unless (valid-pdf? source-file)
    (eprintf "error: not a valid PDF file: ~a\n" source-file)
    (exit 1))

  ;; Compute destination
  (define dest-path (doi->path doi))
  (when (file-exists? dest-path)
    (eprintf "error: destination already exists: ~a\n" dest-path)
    (exit 1))

  ;; Compute multidigest
   (define multidigest (multidigest-file source-file))

  ;; Get stardate timestamp
  (define timestamp (stardate->string (current-stardate) #:digits 'canonical))

  ;; Build log entry
  (define log-entry
    (make-hasheq
     (filter-map
      (λ (pair) (and (cdr pair) pair))
      (list
       (cons 'timestamp timestamp)
       (cons 'input_file source-file)
       (cons 'doi doi)
       (cons 'output_file (path->string dest-path))
       (cons 'multidigest multidigest)
       (cons 'server1_url (get-server1-url doi))
       (cons 'title title)
       (cons 'notes (and (not (null? notes)) notes))
       (cons 'authors (and (not (null? authors)) authors))
       (cons 'year year)))))

  ;; Create destination directory and copy
  (define dest-dir (path-only dest-path))
  (when dest-dir
    (make-directory* dest-dir))
  (copy-file source-file dest-path)

  ;; Append log entry
  (define log-dir (get-log-dir))
  (make-directory* log-dir)
  (define log-file (build-path log-dir "cpdoi.log"))
  (define log-out (open-output-file log-file #:exists 'append))
  (displayln (jsexpr->string log-entry) log-out)
  (close-output-port log-out)

  ;; Print the log entry
  (displayln (jsexpr->string log-entry)))

(module+ main
  (apply main (vector->list (current-command-line-arguments))))

;; vim: set et ff=unix ft=racket nocp sts=2 sw=2 ts=2:
