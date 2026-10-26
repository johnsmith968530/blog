;; $Source: /home/x/Dropbox/2/src/blog/2026/10/26/RCS/multidigest.rkt,v $
;; $Date: 2026/10/26 23:11:00 $
;; $Revision: 1.3 $

#lang racket/base

;; multidigest.rkt -- a small library for computing multiple digests of data.
;;
;; Modified from blog/09/20/multidigest.rkt
;;
;; This is a simplified, Redis-free port of the Rust `multidigest-rs-worker`
;; program. Instead of computing hashes inside the process with Rust crates,
;; it shells out to the standard command-line tools `sha256sum`, `sha3sum`,
;; and `ssdeep`, which are expected to be on the user's PATH.
;;
;; A "multidigest" of some bytes is a hash table with five fields, mirroring
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
;;   (multidigest-bytes  bytes #:include-metadata? [#t]) -> hash
;;   (multidigest-string str   #:include-metadata? [#t]) -> hash
;;   (multidigest-file   path  #:include-metadata? [#t]) -> hash
;;
;; When available, comments and tags are returned under 'comment and 'tag,
;; the same keys used by the cached JSON document. Set the keyword to #f
;; to obtain only the cached multidigest object.
;;
;; Metadata may also be read without recalculating hashes:
;;   (multidigest-get-metadata digest) -> hash of all top-level annotations
;;   (multidigest-get-comments digest) -> stardate -> comment hash
;;   (multidigest-get-tags digest)     -> nested tag tree
;;
;; plus a JSON encoder for convenience:
;;
;;   (multidigest->jsexpr hash) -> jsexpr?

(require racket/contract
         racket/list
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
  [multidigest-bytes
   (->* (bytes?) (#:include-metadata? boolean?) hash?)]
  [multidigest-string
   (->* (string?) (#:include-metadata? boolean?) hash?)]
  [multidigest-file
   (->* (path-string?) (#:include-metadata? boolean?) hash?)]
  [multidigest->jsexpr (-> hash? jsexpr?)]
  [digest-result? (-> any/c boolean?)]
  [multidigest-get-metadata (-> hash? hash?)]
  [multidigest-get-comments (-> hash? hash?)]
  [multidigest-get-tags (-> hash? hash?)]
  [multidigest-add-comment! (-> hash? string? hash?)]
  [multidigest-add-tag!
   (->* (hash? string? string?) () #:rest (listof string?) hash?)]))

;; ---------------------------------------------------------------------------
;; Configuration
;; ---------------------------------------------------------------------------

;; Names of the external hashing programs. Override these by parameterizing
;; the module if your system installs them under different names.

(define sha256sum-bin (make-parameter "sha256sum"))
;; /usr/bin/sha3sum is broken on some machines due to a bug in a Rust
;; package, so prefer the `sha3sum.perl` implementation when it is
;; available on the PATH; it takes the -a flag as expected.
(define sha3sum-bin
  (make-parameter
   (if (find-executable-path "sha3sum.perl")
       "sha3sum.perl"
       "sha3sum")))
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

(define (compute-multidigest data #:include-metadata? [include-metadata? #t])
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
  (cache-multidigest! result #:include-metadata? include-metadata?))

;; ---------------------------------------------------------------------------
;; On-disk cache
;; ---------------------------------------------------------------------------

;; Root of the digest cache. Override by parameterizing the module.
(define cache-root
  (make-parameter
   (build-path (find-system-path 'home-dir)
               "Documents" "Hashes" "Git" "1")))

(define digest-fields '(size sha2-256 sha3-256 ssdeep git-sha1))
(define json-digest-fields '(size sha2_256 sha3_256 ssdeep git_sha1))

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

;; All reads of the JSON cache go through this helper. Verify every digest
;; field against the caller's digest, rather than trusting a matching file name
;; (which only establishes the git-sha1). Returns the full JSON document.
(define (read-cache-document h who)
  (unless (digest-result? h)
    (raise-argument-error who "digest-result?" h))
  (define p (digest-cache-path h))
  (unless (file-exists? p)
    (error who "cache file ~a does not exist; compute the digest first" p))
  (define doc (with-input-from-file p read-json))
  (define cached (and (hash? doc) (hash-ref doc 'multidigest #f)))
  (unless (digest-result? cached)
    (error who "cache file ~a does not contain a valid multidigest object" p))
  (for ([k (in-list digest-fields)])
    (unless (equal? (hash-ref h k) (hash-ref cached k))
      (error who
             "cache file ~a disagrees on ~a: cached ~s, supplied ~s"
             p k (hash-ref cached k) (hash-ref h k))))
  doc)

;; The cache stores annotations as siblings of "multidigest". Extract
;; everything except the digest, preserving additional metadata keys added
;; by future versions or external tools.
(define (document-metadata doc)
  (hash-remove doc 'multidigest))

;; Put cache annotations on the public digest hash using the same symbol keys.
;; Never allow a top-level annotation to overwrite a digest field.
(define (digest-with-document-metadata md doc)
  (for/fold ([result md])
            ([(k v) (in-hash (document-metadata doc))]
             #:unless (memq k digest-fields))
    (hash-set result k v)))

;; Use the JSON library to escape all string control characters correctly.
;; The custom serializer below is for indentation, not string encoding.
(define (json-quote-string s)
  (jsexpr->string s))

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

;; Create a bare digest record if no cache file exists; otherwise validate
;; the stored hashes and return either the bare record or the record enriched
;; with sibling metadata. Both modes always validate the cache file.
(define (cache-multidigest! h #:include-metadata? [include-metadata? #t])
  (define p (digest-cache-path h))
  (if (file-exists? p)
      (let* ([doc (read-cache-document h 'multidigest)]
             [cached (hash-ref doc 'multidigest)])
        (if include-metadata?
            (digest-with-document-metadata cached doc)
            cached))
      (begin
        (make-directory* (path-only p))
        (call-with-atomic-output-file
         p
         (lambda (out _path)
           (display (multidigest->pretty-json h) out)))
        h)))

;; Generic pretty-printed JSON serializer for jsexpr-compatible values
;; (hashes with symbol keys, lists, strings, and numbers). Used when writing back
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
      [(list? v)
       (if (null? v)
           "[]"
           (string-append
            "[\n"
            (string-join
             (for/list ((item (in-list v)))
               (string-append (indent (add1 n))
                              (loop item (add1 n))))
             ",\n")
            "\n" (indent n) "]"))]
      [(string? v) (json-quote-string v)]
      [(number? v) (number->string v)]
      [(boolean? v) (if v "true" "false")]
      [(eq? v 'null) "null"]
      [else (error 'jsexpr->pretty-json "unsupported value: ~e" v)])))

;; Atomic write shared by the annotation update functions.
(define (write-cache-document! h doc)
  (define p (digest-cache-path h))
  (call-with-atomic-output-file
   p
   (lambda (out _path)
     (display (jsexpr->pretty-json doc) out))))

;; Retrieve the top-level JSON annotations without recomputing any hashes.
;; The input must be an existing multidigest hash (even if it has metadata).
;; A missing annotation is simply absent from the returned hash.
(define (multidigest-get-metadata h)
  (document-metadata (read-cache-document h 'multidigest-get-metadata)))

;; Convenience accessors return empty hashes when no comments/tags exist.
(define (multidigest-get-comments h)
  (define comments (hash-ref (multidigest-get-metadata h) 'comment (hasheq)))
  (unless (hash? comments)
    (error 'multidigest-get-comments "cached comment field is not a JSON object"))
  comments)

(define (multidigest-get-tags h)
  (define tags (hash-ref (multidigest-get-metadata h) 'tag (hasheq)))
  (unless (hash? tags)
    (error 'multidigest-get-tags "cached tag field is not a JSON object"))
  tags)

;; Add a comment to the cached JSON document for the digest `h`.
;; The comment is stored under the top-level "comment" key of the JSON
;; document (a sibling of "multidigest"), keyed by the current stardate in
;; its canonical 15-digit string form:
;;   jsonobject["comment"][<canonical stardate>] = <comment>
;; Existing comments (under other stardates) are preserved, and the whole
;; document is written back to disk atomically. Returns the multidigest
;; object with up-to-date cached annotations attached.
(define (multidigest-add-comment! h comment)
  (unless (string? comment)
    (raise-argument-error 'multidigest-add-comment! "string?" comment))
  (define doc (read-cache-document h 'multidigest-add-comment!))
  (define md (hash-ref doc 'multidigest))
  (define p (digest-cache-path h))
  (define old-comments (hash-ref doc 'comment #f))
  (cond
    [(not old-comments) (set! old-comments (hasheq))]
    [(not (hash? old-comments))
     (error 'multidigest-add-comment!
            "\"comment\" field of ~a is not a JSON object" p)])
  (define key (string->symbol (stardate-canonical (current-stardate))))
  (define new-doc
    (hash-set doc 'comment (hash-set old-comments key comment)))
  (write-cache-document! h new-doc)
  (digest-with-document-metadata md new-doc))


;; Add a tag to the cached JSON document for the digest `h`.  The final
;; argument is the tag string; all preceding string arguments form a path
;; beneath the top-level "tag" object.  The leaf is a JSON array of unique,
;; lexicographically sorted strings.  For example:
;;
;;   (multidigest-add-tag! h "com" "imdb" "tt33332385")
;;
;; produces (or extends):
;;
;;   "tag": { "com": { "imdb": [ "tt33332385" ] } }
;;
;; Existing tag branches are preserved.  An existing non-object intermediate
;; node, or a leaf that is not an array of strings, is treated as malformed
;; data and causes an error rather than being overwritten.
(define (multidigest-add-tag! h path1 tag-or-path . rest)
  (define path+tag (cons path1 (cons tag-or-path rest)))
  (define tag (last path+tag))
  (define path (drop-right path+tag 1))
  (define doc (read-cache-document h 'multidigest-add-tag!))
  (define md (hash-ref doc 'multidigest))
  (define p (digest-cache-path h))
  (define old-tags
    (cond
      [(not (hash-has-key? doc 'tag)) (hasheq)]
      [(hash? (hash-ref doc 'tag)) (hash-ref doc 'tag)]
      [else
       (error 'multidigest-add-tag!
              "\"tag\" field of ~a is not a JSON object" p)]))
  (define (add-at-path obj keys)
    (define key (string->symbol (car keys)))
    (cond
      [(null? (cdr keys))
       (define old-values
         (if (hash-has-key? obj key)
             (hash-ref obj key)
             '()))
       (unless (and (list? old-values) (andmap string? old-values))
         (error 'multidigest-add-tag!
                "tag leaf ~a in ~a is not a JSON array of strings"
                (string-join path "/") p))
       (define new-values
         (sort (remove-duplicates (cons tag old-values) string=?) string<?))
       (hash-set obj key new-values)]
      [else
       (define child
         (if (hash-has-key? obj key)
             (hash-ref obj key)
             (hasheq)))
       (unless (hash? child)
         (error 'multidigest-add-tag!
                "tag path component ~a in ~a is not a JSON object"
                (car keys) p))
       (hash-set obj key (add-at-path child (cdr keys)))]))
  (define new-doc
    (hash-set doc 'tag (add-at-path old-tags path)))
  (write-cache-document! h new-doc)
  (digest-with-document-metadata md new-doc))

;; ---------------------------------------------------------------------------
;; Public entry points
;; ---------------------------------------------------------------------------

(define (multidigest-bytes b #:include-metadata? [include-metadata? #t])
  (compute-multidigest b #:include-metadata? include-metadata?))

(define (multidigest-string s #:include-metadata? [include-metadata? #t])
  (compute-multidigest (string->bytes/utf-8 s)
                       #:include-metadata? include-metadata?))

(define (multidigest-file path #:include-metadata? [include-metadata? #t])
  (compute-multidigest (file->bytes path)
                       #:include-metadata? include-metadata?))

;; ---------------------------------------------------------------------------
;; JSON encoding
;; ---------------------------------------------------------------------------

;; Match the original Rust field names while carrying along any annotations
;; present on the digest. Without annotations, output is unchanged.
(define (multidigest->jsexpr h)
  (define base
    (hasheq 'size      (hash-ref h 'size)
            'sha2_256  (hash-ref h 'sha2-256)
            'sha3_256  (hash-ref h 'sha3-256)
            'ssdeep    (hash-ref h 'ssdeep)
            'git_sha1  (hash-ref h 'git-sha1)))
  (for/fold ([result base])
            ([(k v) (in-hash h)]
             #:unless (or (memq k digest-fields)
                          (memq k json-digest-fields)))
    (hash-set result k v)))

;; ---------------------------------------------------------------------------
;; Module-as-script demo
;; ---------------------------------------------------------------------------

(module+ main
  (require racket/cmdline
           net/base64)
  (define mode (make-parameter 'string))
  (define input (make-parameter #f))
  (define include-metadata? (make-parameter #t))
  (command-line
   #:program "multidigest"
   #:once-each
   [("-s" "--string") "treat argument as a literal string" (mode 'string)]
   [("-f" "--file")   "treat argument as a file path"      (mode 'file)]
   [("-b" "--bytes")  "treat argument as base64-encoded bytes" (mode 'blob)]
   [("--no-metadata") "omit cached comments, tags, and other annotations"
    (include-metadata? #f)]
   #:args (arg)
   (input arg))
  (define result
    (case (mode)
      [(string) (multidigest-string (input)
                                    #:include-metadata? (include-metadata?))]
      [(file)   (multidigest-file (input)
                                  #:include-metadata? (include-metadata?))]
      [(blob)   (multidigest-bytes
                 (base64-decode (string->bytes/utf-8 (input)))
                 #:include-metadata? (include-metadata?))]))
  (displayln (jsexpr->string (multidigest->jsexpr result))))

;; ---------------------------------------------------------------------------
;; Cache/metadata regression tests (no external hash programs needed)
;; ---------------------------------------------------------------------------

(module+ test
  (require rackunit)
  (define temporary-cache (make-temporary-file "multidigest-cache~a" 'directory))
  (dynamic-wind
   void
   (lambda ()
     (parameterize ([cache-root temporary-cache])
       (define h
         (hash 'size 5
               'sha2-256 "sha2-example"
               'sha3-256 "sha3-example"
               'ssdeep "3:abc:def"
               'git-sha1 "0123456789abcdef0123456789abcdef01234567"))
       (check-equal? (cache-multidigest! h) h)
       (check-equal? (hash-count (multidigest-get-metadata h)) 0)
       (check-equal? (hash-count (multidigest-get-comments h)) 0)
       (check-equal? (hash-count (multidigest-get-tags h)) 0)

       (define with-first-tag
         (multidigest-add-tag! h "com" "imdb" "tt33332385"))
       (check-equal? (hash-ref (hash-ref (hash-ref with-first-tag 'tag) 'com) 'imdb)
                     '("tt33332385"))
       (multidigest-add-tag! h "com" "imdb" "tt11111111")
       (multidigest-add-tag! h "com" "imdb" "tt33332385")
       (check-equal? (hash-ref (hash-ref (multidigest-get-tags h) 'com) 'imdb)
                     '("tt11111111" "tt33332385"))

       (define annotated (multidigest-add-comment! h "hello, metadata!"))
       (check-true (hash-has-key? annotated 'comment))
       (check-true (hash-has-key? annotated 'tag))
       (check-equal? (hash-values (multidigest-get-comments h))
                     '("hello, metadata!"))
       (check-equal? (hash-ref (multidigest->jsexpr annotated) 'tag)
                     (multidigest-get-tags h))
       (check-equal? (cache-multidigest! h #:include-metadata? #f) h)
       (check-equal? (hash-ref (cache-multidigest! h) 'comment)
                     (multidigest-get-comments h))

       ;; Unknown metadata keys should also be accessible without new APIs.
       (define doc (read-cache-document h 'test))
       (write-cache-document! h
                              (hash-set doc 'source (hasheq 'tool "unit-test"
                                                              'verified #t)))
       (check-equal? (hash-ref (hash-ref (multidigest-get-metadata h) 'source)
                               'verified)
                     #t)
       (check-true (hash-has-key? (cache-multidigest! h) 'source))

       ;; A matching cache path is not sufficient if digest fields disagree.
       (check-exn exn:fail?
                  (lambda ()
                    (multidigest-get-metadata
                     (hash-set h 'sha2-256 "wrong-sha256"))))))
   (lambda () (delete-directory/files temporary-cache))))

;; vim: set et ff=unix ft=racket nocp sts=2 sw=2 ts=2:
