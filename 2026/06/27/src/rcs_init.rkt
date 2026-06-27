#!/usr/bin/env racket

;; $Source: /home/x/Dropbox/2/src/blog/2026/06/27/src/RCS/rcs_init.rkt,v $
;; $Date: 2026/06/27 19:08:28 $
;; $Revision: 1.1 $

#lang racket

;; Racket port of /Users/x/Dropbox/2/src/blog/2025/10/17/src/rcs_init/src/main.rs
;;
;; Initializes RCS revision control for each given file. For every file the
;; program:
;;   * creates an `RCS` directory next to it (mode 0770) if one is missing;
;;   * if an `RCS/<file>,v` archive already exists, checks for uncommitted
;;     changes with `rcsdiff -q` and aborts (with guidance) if any are found;
;;   * otherwise performs an initial check-in.
;;
;; In `--binary` mode the initial archive is created with `rcs -i -kb` and
;; then `ci -l`; in text mode it uses `ci -t-<desc> -x,v`, `co`, and
;; `rcs -l -x,v`. Finally the working file is made user-writable with
;; `chmod u+w`.
;;
;; The RCS description (<desc>) is the cloud-relative path when the file lives
;; under a Dropbox/MEGA/Nextcloud cloud-storage root, otherwise it is
;; `<hostname>:<abspath>`.

(require racket/cmdline
         racket/port
         racket/system)

;; ---------------------------------------------------------------------------
;; Helpers

;; Raise an exn:fail with a formatted message (stand-in for anyhow::anyhow!).
(define (fail fmt . args)
  (raise (exn:fail (apply format fmt args) (current-continuation-marks))))

;; Resolve a command name to an executable path, failing if it is not
;; installed (mirrors `which::which(...).context("... is not installed")`).
(define (exe-path cmd)
  (or (find-executable-path cmd)
      (fail "~a is not installed" cmd)))

;; Run `cmd` with `args`, letting stdout/stderr flow to the current ports.
;; Fail if the process exits non-zero (mirrors `safe_exec`).
(define (safe-exec cmd . args)
  (define code (apply system*/exit-code (exe-path cmd) args))
  (unless (zero? code)
    (fail "command ~a ~a failed with status ~a" cmd args code)))

;; Run `cmd` with `args`, discarding all output, returning the exit code
;; (mirrors `Command::new(...).output()` + `status.success()`).
(define (run-quiet cmd . args)
  (parameterize ([current-output-port (open-output-nowhere)]
                 [current-error-port  (open-output-nowhere)])
    (apply system*/exit-code (exe-path cmd) args)))

;; Return the system hostname with any trailing ".local" stripped.
(define (get-hostname)
  (define raw
    (with-output-to-string
      (lambda ()
        (parameterize ([current-error-port (open-output-nowhere)])
          (system* (exe-path "hostname"))))))
  (regexp-replace #rx"\\.local$" (string-trim raw) ""))

;; ---------------------------------------------------------------------------
;; Description

;; Match a cloud-storage root in any home directory. Group 2 captures the
;; cloud-relative path (e.g. "Dropbox/2/src/..."). This mirrors the Rust
;; regex `^/(home/[^/]+|Users/[^/]/Library/CloudStorage)/((Dropbox|MEGA|Nextcloud)/.*)$`
;; exactly, including the single-character `Users/[^/]` username class.
(define cloud-re
  #rx"^/(home/[^/]+|Users/[^/]/Library/CloudStorage)/((Dropbox|MEGA|Nextcloud)/.*)$")

;; Produce the RCS description string for `file-path`.
(define (get-description file-path)
  (define abs-str (path->string (resolve-path file-path)))
  (define m (regexp-match cloud-re abs-str))
  (if m
      (list-ref m 2)
      (format "~a:~a" (get-hostname) abs-str)))

;; ---------------------------------------------------------------------------
;; Per-file processing

(define (process-file raw-path binary)
  (define file-path (simplify-path raw-path #f))
  (define-values (parent name must-be-dir?) (split-path file-path))
  (define dir-path (if (and parent (not (eq? parent 'relative))) parent "."))
  (define rcs-dir (build-path dir-path "RCS"))

  ;; Create the RCS directory (mode 0770) if it doesn't exist.
  (unless (directory-exists? rcs-dir)
    (make-directory rcs-dir)
    (file-or-directory-permissions rcs-dir #o770))

  (define rcs-file
    (build-path rcs-dir (string-append (path->string name) ",v")))

  (unless (file-exists? file-path)
    (fail "~a does not exist or is not a file" file-path))

  (cond
    ;; Archive already exists: verify there are no uncommitted changes.
    [(or (file-exists? rcs-file) (directory-exists? rcs-file))
     (define code (run-quiet "rcsdiff" "-q" (path->string file-path)))
     (unless (zero? code)
       (fail "~a has uncommitted changes. Please check in manually using: ci -l -m\"<message>\" ~a"
             file-path file-path))]
    ;; Initialize a new RCS archive.
    [else
     (define desc (get-description file-path))
     (define file-str (path->string file-path))
     (if binary
         (begin
           (safe-exec "rcs" "-i" "-kb" (string-append "-t-" desc) "-x,v" file-str)
           (safe-exec "ci"  "-l" file-str))
         (begin
           (safe-exec "ci"  (string-append "-t-" desc) "-x,v" file-str)
           (safe-exec "co"  file-str)
           (safe-exec "rcs" "-l" "-x,v" file-str)))
     (safe-exec "chmod" "u+w" file-str)
     (displayln file-path)]))

;; ---------------------------------------------------------------------------
;; Entry point

;; `--binary` flag (clap `#[arg(long)] binary`).
(define binary-mode (make-parameter #f))

;; Positional file list (clap `files: Vec<String>`).
(define files
  (command-line
   #:program "rcs-init"
   #:once-each
   [("--binary") "Enable binary file mode" (binary-mode #t)]
   #:args files files))

;; Bail out early if RCS itself is not available.
(unless (find-executable-path "rcs")
  (fail "RCS is not installed"))

(define cwd (current-directory))
(define has-errors (box #f))

(for ([file (in-list files)])
  (define path (if (complete-path? file) file (build-path cwd file)))
  (with-handlers ([exn:fail?
                   (lambda (e)
                     (eprintf "Error processing ~a: ~a\n" path (exn-message e))
                     (set-box! has-errors #t))])
    (process-file path (binary-mode))))

(when (unbox has-errors)
  (exit 1))

; vim: set et ff=unix ft=racket nocp sts=2 sw=2 ts=2:
