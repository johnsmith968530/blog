;; $Source: /home/x/Dropbox/2/src/blog/2026/08/25/RCS/multidigest.rkt,v $
;; $Date: 2026/08/25 22:00:39 $
;; $Revision: 1.5 $

#lang racket/base

;; multidigest.rkt -- a small library for computing multiple digests of data.
;;
;; This is a simplified, Redis-free port of the Rust `multidigest-rs-worker`
;; program. Instead of computing hashes inside the process with Rust crates,
;; it shells out to the standard command-line tools `sha256sum`, `sha3sum`,
;; and `ssdeep`, which are expected to be on the user's PATH.
;;
;; A "multidigest" of some bytes is a hash table with four fields, mirroring
;; the original `DigestResult` struct:
;;
;;   size      : exact-nonnegative-integer?  -- byte length of the input
;;   sha2-256  : string?                     -- lowercase hex SHA-256 digest
;;   sha3-256  : string?                     -- lowercase hex SHA3-256 digest
;;   ssdeep    : string?                     -- ssdeep fuzzy hash string
;;   git-sha1  : string?                     -- git blob SHA-1 (git hash-object)
;;
;; The module provides three entry points, one per input shape:
;;
;;   (multidigest-bytes   bytes)  -> hash
;;   (multidigest-string  str)    -> hash
;;   (multidigest-file    path)   -> hash
;;
;; plus a JSON encoder for convenience:
;;
;;   (multidigest->jsexpr hash) -> jsexpr?

(require racket/contract
         racket/match
         racket/port
         racket/string
         racket/system
         racket/file
         racket/path
         json
         blog/2026/06/21/stardate)

(provide
 (contract-out
  [multidigest-bytes  (-> bytes? hash?)]
  [multidigest-string (-> string? hash?)]
  [multidigest-file   (-> path-string? hash?)]
  [multidigest->jsexpr (-> hash? jsexpr?)]
  [digest-result?     (-> any/c boolean?)]
   [multidigest-add-comment! (-> hash? string? hash?)]))

;; ---------------------------------------------------------------------------
;; Configuration
;; ---------------------------------------------------------------------------

;; Names of the external hashing programs. Override these by parameterizing
;; the module if your system installs them under different names.

(define sha256sum-bin (make-parameter "sha256sum"))
(define sha3sum-bin   (make-parameter "sha3sum"))
(define ssdeep-bin    (make-parameter "ssdeep"))
(define git-bin       (make-parameter "git"))

;; ---------------------------------------------------------------------------
;; Internal helpers
;; ---------------------------------------------------------------------------

;; Run a command with `input` fed to its stdin and return its stdout as bytes.
;; Raises an exn:fail if the process exits non-zero or cannot be started.

(define (run/capture command args input-bytes)
  ;; process*/ports signature: (process*/ports stdout stdin stderr cmd args ...)
  ;; - stdout: an output port that receives the child's stdout
  ;; - stdin:  an input port that the child reads from, or #f
  ;; - stderr: an output port that receives the child's stderr
  ;; It returns (list child-stdout-in child-stdin-out pid child-stderr-in ctrl).
  (define stdout-buf (open-output-bytes))
  (define stderr-buf (open-output-bytes))
  (define stdin-buf  (open-input-bytes input-bytes))
  (define proc
    (apply process*/ports
           stdout-buf stdin-buf stderr-buf
           (find-executable-path (car command))
           (cdr command)))
  (define ctrl (list-ref proc 4))
  ;; Wait for the child to finish, then inspect its status.
  (ctrl 'wait)
  (define status (ctrl 'status))
  ;; `status` is a symbol like 'done-ok or 'done-error after 'wait, or
  ;; a list like '(exited N) if queried without waiting.
  (define exit-code
    (match status
      ['done-ok 0]
      ['done-error 1]
      [(list 'exited n) n]
      ['running -2]
      [(list 'signaled _) -1]
      [_ -2]))
  (when (not (eq? exit-code 0))
    (error 'multidigest
           "command ~a exited with code ~a: ~a"
           (string-join (map ~a command) " ")
           exit-code
           (get-output-bytes stderr-buf)))
  (get-output-bytes stdout-buf))

;; A tiny convenience for formatting values as strings.

(define (~a x)
  (if (string? x) x (format "~a" x)))

;; Parse the first whitespace-delimited token of a checksum tool's output.
;; `sha256sum` and `sha3sum` both print "<hex>  <name>".

(define (parse-checksum-line out-bytes)
  (define line (car (string-split (bytes->string/utf-8 out-bytes #\space) "\n")))
  (car (string-split (string-trim line))))

;; Parse an ssdeep `-s` output. The program prints a header line followed by
;; one line of the form "blocksize:hash:hash,filename". We want just the
;; "blocksize:hash:hash" portion.

(define (parse-ssdeep out-bytes)
  (define lines (string-split (bytes->string/utf-8 out-bytes #\space) "\n"))
  (define data-line
    (for/first ([l (in-list lines)]
                #:when (and (> (string-length l) 0)
                            (not (string-prefix? l "ssdeep,"))))
      l))
  (unless data-line
    (error 'multidigest "ssdeep produced no hash line"))
  (define comma-idx (string-index-of data-line #\,))
  (if comma-idx
      (substring data-line 0 comma-idx)
      data-line))

(define (string-index-of str ch)
  (for/first ([i (in-range (string-length str))]
              #:when (char=? (string-ref str i) ch))
    i))

;; ---------------------------------------------------------------------------
;; Core digest computation
;; ---------------------------------------------------------------------------

(define (digest-result? v)
  (and (hash? v)
       (hash-has-key? v 'size)
       (hash-has-key? v 'sha2-256)
       (hash-has-key? v 'sha3-256)
       (hash-has-key? v 'ssdeep)
       (hash-has-key? v 'git-sha1)))

(define (compute-multidigest data)
  (define sha2-out
    (run/capture (list (sha256sum-bin)) '() data))
  (define sha3-out
    (run/capture (list (sha3sum-bin) "-a" "256") '() data))
  (define ssdeep-out
    (run/capture (list (ssdeep-bin) "-s") '() data))
  ;; `git hash-object --stdin` prints the blob SHA-1 followed by a newline.
  (define git-out
    (run/capture (list (git-bin) "hash-object" "--stdin") '() data))
  (define result
    (hash 'size      (bytes-length data)
          'sha2-256  (parse-checksum-line sha2-out)
          'sha3-256  (parse-checksum-line sha3-out)
          'ssdeep    (parse-ssdeep ssdeep-out)
          'git-sha1  (string-trim (bytes->string/utf-8 git-out #\space))))
  (cache-multidigest! result))

;; ---------------------------------------------------------------------------
;; On-disk cache
;; ---------------------------------------------------------------------------

;; Root of the digest cache. Override by parameterizing the module.
(define cache-root
  (make-parameter
   (build-path (find-system-path 'home-dir)
               "Dropbox" "2" "Data" "Hashes" "Git" "1")))

;; Return the cache path for a digest:
;;   <cache-root>/<h0>/<h1>/<h2>/<h3>/<git-sha1>.json
;; where h0..h3 are the first four hex digits of the git hash.
(define (digest-cache-path h)
  (define sha (hash-ref h 'git-sha1))
  (build-path (cache-root)
              (substring sha 0 1)
              (substring sha 1 2)
              (substring sha 2 3)
              (substring sha 3 4)
              (string-append sha ".json")))

;; JSON string-escape (Racket's json library has no pretty-printer, so we
;; format the document by hand).
(define (json-quote-string s)
  (string-append "\""
                 (string-append*
                  (for/list ([c (in-string s)])
                    (case c
                            [(#\backspace) "\\b"]
                            [(#\page)     "\\f"]
                            [(#\newline)  "\\n"]
                            [(#\return)   "\\r"]
                            [(#\tab)      "\\t"]
                            [(#\\)        "\\\\"]
                            [(#\")        "\\\""]
                            [else (string c)])))
                 "\""))

;; Render a digest hash as pretty-printed JSON, matching the shape:
;;   {
;;     "multidigest": {
;;       "git-sha1": "...",
;;       "sha2-256": "...",
;;       ...
;;     }
;;   }
(define (multidigest->pretty-json h)
  (string-append
   "{\n"
   "  \"multidigest\": {\n"
   "    \"size\": "     (number->string (hash-ref h 'size)) ",\n"
   "    \"sha2-256\": " (json-quote-string (hash-ref h 'sha2-256)) ",\n"
   "    \"sha3-256\": " (json-quote-string (hash-ref h 'sha3-256)) ",\n"
   "    \"ssdeep\": "   (json-quote-string (hash-ref h 'ssdeep)) ",\n"
   "    \"git-sha1\": " (json-quote-string (hash-ref h 'git-sha1)) "\n"
   "  }\n"
   "}\n"))

;; If the cache file for this digest's git hash does not yet exist, create
;; its parent directories and write the pretty-formatted JSON document.
;; If it does exist, parse the stored JSON document and verify that its
;; size and hash fields agree with the freshly computed ones; raise an
;; error on any mismatch. On success return the cached multidigest object
;; (a hash that may contain fields beyond the calculated hashes).
(define (cache-multidigest! h)
  (define p (digest-cache-path h))
  (if (file-exists? p)
      (let* ((doc (with-input-from-file p read-json))
             (cached (if (hash? doc) (hash-ref doc 'multidigest #f) #f)))
        (unless (digest-result? cached)
          (error 'multidigest
                 "cache file ~a does not contain a valid multidigest object"
                 p))
        (for ((k '(size sha2-256 sha3-256 ssdeep git-sha1)))
          (unless (equal? (hash-ref h k) (hash-ref cached k))
            (error 'multidigest
                   "cache file ~a disagrees on ~a: cached ~s, computed ~s"
                   p k (hash-ref cached k) (hash-ref h k))))
        cached)
      (begin
        (make-directory* (path-only p))
        (call-with-atomic-output-file
         p
         (lambda (out _path)
           (display (multidigest->pretty-json h) out)))
        h)))

;; Generic pretty-printed JSON serializer for jsexpr-compatible values
;; (hashes with symbol keys, strings, and numbers). Used when writing back
;; documents that contain fields beyond the five digest fields.
(define (jsexpr->pretty-json v)
  (define (indent n) (make-string (* 2 n) #\space))
  (let loop ((v v) (n 0))
    (cond
      [(hash? v)
       (string-append
        "{\n"
        (string-join
         (for/list (((k val) (in-hash v)))
           (string-append
            (indent (add1 n))
            (json-quote-string (symbol->string k)) ": "
            (loop val (add1 n))))
         ",\n")
        "\n" (indent n) "}")]
      [(string? v) (json-quote-string v)]
      [(number? v) (number->string v)]
      [else (error 'jsexpr->pretty-json "unsupported value: ~e" v)])))

;; Add a comment to the cached JSON document for the digest `h`.
;; The comment is stored under the top-level "comment" key of the JSON
;; document (a sibling of "multidigest"), keyed by the current stardate in
;; its canonical 15-digit string form:
;;   jsonobject["comment"][<canonical stardate>] = <comment>
;; Existing comments (under other stardates) are preserved, and the whole
;; document is written back to disk atomically. Returns the multidigest
;; object (unchanged; the comment lives outside it).
(define (multidigest-add-comment! h comment)
  (unless (string? comment)
    (raise-argument-error 'multidigest-add-comment! "string?" comment))
  (define p (digest-cache-path h))
  (unless (file-exists? p)
    (error 'multidigest-add-comment!
           "cache file ~a does not exist; compute the digest first" p))
  (define doc (with-input-from-file p read-json))
  (unless (and (hash? doc) (digest-result? (hash-ref doc 'multidigest #f)))
    (error 'multidigest-add-comment!
           "cache file ~a does not contain a valid multidigest object" p))
  (define md (hash-ref doc 'multidigest))
  (define old-comments (hash-ref doc 'comment #f))
  (cond
    [(not old-comments) (set! old-comments (hasheq))]
    [(not (hash? old-comments))
     (error 'multidigest-add-comment!
            "\"comment\" field of ~a is not a JSON object" p)])
  (define key (string->symbol (stardate-canonical (current-stardate))))
  (define new-doc
    (hash-set doc 'comment (hash-set old-comments key comment)))
  (call-with-atomic-output-file
   p
   (lambda (out _path)
     (display (jsexpr->pretty-json new-doc) out)))
  md)

;; ---------------------------------------------------------------------------
;; Public entry points
;; ---------------------------------------------------------------------------

(define (multidigest-bytes b)
  (compute-multidigest b))

(define (multidigest-string s)
  (compute-multidigest (string->bytes/utf-8 s)))

(define (multidigest-file path)
  (compute-multidigest (file->bytes path)))

;; ---------------------------------------------------------------------------
;; JSON encoding
;; ---------------------------------------------------------------------------

;; Match the field names used by the original Rust `DigestResult` struct so
;; that JSON consumers stay compatible.

(define (multidigest->jsexpr h)
  (hasheq 'size      (hash-ref h 'size)
          'sha2_256  (hash-ref h 'sha2-256)
          'sha3_256  (hash-ref h 'sha3-256)
          'ssdeep    (hash-ref h 'ssdeep)
          'git_sha1  (hash-ref h 'git-sha1)))

;; ---------------------------------------------------------------------------
;; Module-as-script demo
;; ---------------------------------------------------------------------------

(module+ main
  (require racket/cmdline
           net/base64)
  (define mode (make-parameter 'string))
  (define input (make-parameter #f))
  (command-line
   #:program "multidigest"
   #:once-each
   [("-s" "--string") "treat argument as a literal string" (mode 'string)]
   [("-f" "--file")   "treat argument as a file path"      (mode 'file)]
   [("-b" "--bytes")  "treat argument as base64-encoded bytes" (mode 'blob)]
   #:args (arg)
   (input arg))
  (define result
    (case (mode)
      [(string) (multidigest-string (input))]
      [(file)   (multidigest-file   (input))]
      [(blob)   (multidigest-bytes
                 (base64-decode
                  (string->bytes/utf-8 (input))))]))
  (displayln (jsexpr->string (multidigest->jsexpr result))))

;; vim: set et ff=unix ft=racket nocp sts=2 sw=2 ts=2:
