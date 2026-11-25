#lang racket/base

;; $Source: /home/x/Dropbox/2/src/blog/2026/11/24/RCS/omdb.rkt,v $
;; $Date: 2026/11/25 06:02:06 $
;; $Revision: 1.1 $

;; Minimal OMDb client for IMDb title IDs, with a timestamped JSON cache.
;; Requires only modules included with Racket.
;; Obtain a free API key at https://www.omdbapi.com/apikey.aspx
;; Set OMDB_API_KEY or pass #:api-key explicitly.
;; Adapted from blog/2026/10/20/omdb.rkt

(require json
         racket/date
         net/url
         net/url-connect
         net/uri-codec
         racket/file
         racket/port
         racket/string
         racket/system
         )

;; Only the lookup API is public. Cache layout is an implementation detail.
(provide omdb-add-comment
         omdb-get-title
         omdb-get-title-data)

(define default-cache-root "/home/x/Dropbox/2/Data/com/omdbapi")

(define (validate-title-id imdb-id)
  (unless (and (string? imdb-id)
               (regexp-match? #px"^tt[0-9]+$" imdb-id))
    (raise-argument-error 'omdb-get-title
                          "IMDb title ID string (e.g. \"tt0133093\")"
                          imdb-id)))

(define (validate-api-key api-key)
  (unless (and (string? api-key)
               (not (string=? (string-trim api-key) "")))
    (error 'omdb-get-title-data
           "OMDb API key required for a cache miss; set OMDB_API_KEY or pass #:api-key")))

;; imdb-cache-path : String [#:cache-root Path-String] -> Path
;; Works with ID prefixes such as tt (titles) and nm (people), even though
;; OMDb's lookup implemented below supports only tt IDs.
;; e.g. tt45368240 -> <root>/tt/4/5/3/6/tt45368240.json
(define (imdb-cache-path imdb-id #:cache-root [cache-root default-cache-root])
  (unless (and (string? imdb-id)
               (regexp-match? #px"^[a-z]{2}[0-9]+$" imdb-id))
    (raise-argument-error 'imdb-cache-path
                          "IMDb ID string (e.g. \"tt45368240\" or \"nm0000206\")"
                          imdb-id))
  (define prefix (substring imdb-id 0 2))
  (define digits (substring imdb-id 2))
  (define levels
    (for/list ([digit (in-string (substring digits 0 (min 4 (string-length digits))))])
      (string digit)))
  (apply build-path cache-root prefix
         (append levels (list (string-append imdb-id ".json")))))

(define (successful-title-response? response imdb-id)
  (and (hash? response)
       (equal? (hash-ref response 'Response #f) "True")
       (equal? (hash-ref response 'imdbID #f) imdb-id)))

;; An absent, corrupted, or mismatched cache entry is a cache miss.
(define (read-cached-title path imdb-id)
  (and (file-exists? path)
       (with-handlers ([exn:fail:read? (lambda (_) #f)])
         (define response (call-with-input-file* path read-json))
         (and (successful-title-response? response imdb-id)
              response))))

(define (fetch-title-data imdb-id api-key)
  (validate-api-key api-key)
  (define query
    (parameterize ([current-alist-separator-mode 'amp])
      (alist->form-urlencoded
       (list (cons 'apikey api-key)
             (cons 'i imdb-id)))))
  (define endpoint
    (string->url (string-append "https://www.omdbapi.com/?" query)))

  ;; Racket's default HTTPS mode does not validate certificates.
  ;; 'secure enables TLS certificate verification.
  (define response
    (parameterize ([current-https-protocol 'secure])
      (call/input-url endpoint get-pure-port read-json)))

  (unless (hash? response)
    (error 'omdb-get-title-data "unexpected non-object response from OMDb"))
  (unless (equal? (hash-ref response 'Response #f) "True")
    (error 'omdb-get-title-data "OMDb: ~a"
           (hash-ref response 'Error "unexpected API response")))
  (unless (equal? (hash-ref response 'imdbID #f) imdb-id)
    (error 'omdb-get-title-data "OMDb returned a different IMDb ID for ~a" imdb-id))
  response)

;; ISO 8601 UTC retrieval time, e.g. "2026-10-20T18:42:00Z".
;; Using UTC makes cached records unambiguous across machines/time zones.
(define (unix-seconds->iso8601-utc seconds)
  (define utc (seconds->date seconds #f))
  (define (two n)
    (if (< n 10) (format "0~a" n) (number->string n)))
  (format "~a-~a-~aT~a:~a:~aZ"
          (date-year utc) (two (date-month utc)) (two (date-day utc))
          (two (date-hour utc)) (two (date-minute utc))
          (two (date-second utc))))

;; Put our metadata alongside the original OMDb properties, without
;; modifying them. This is called only for newly fetched API data.
(define (stamp-retrieval response)
  (hash-set response '_retrieved_at
            (unix-seconds->iso8601-utc (current-seconds))))

(define (write-cached-title path response)
  (make-parent-directory* path)
  ;; Write into a temporary file and rename it into place, so concurrent
  ;; readers don't observe a partially written JSON document.
  (call-with-atomic-output-file
   path
   (lambda (out _temporary-path)
     (write-json response out)
     (newline out))))

;; omdb-get-title-data : String [#:api-key String]
;;                         [#:cache-root Path-String]
;;                         [#:refresh? Boolean] -> Hash
;; Return OMDb's JSON fields with symbol keys ('Title, 'Actors, etc.), plus
;; '_retrieved_at (ISO 8601 UTC) on freshly fetched/cached records.
;; Legacy cache files without a timestamp remain readable and unchanged.
;; On a cache hit, no API key or network connection is needed.
(define (omdb-get-title-data imdb-id
                        #:api-key [api-key (getenv "OMDB_API_KEY")]
                        #:cache-root [cache-root default-cache-root]
                        #:refresh? [refresh? #f])
  (validate-title-id imdb-id)
  (define path (imdb-cache-path imdb-id #:cache-root cache-root))
  (define cached
    (and (not refresh?) (read-cached-title path imdb-id)))
  (if cached
      cached
      (let* ([response (fetch-title-data imdb-id api-key)]
             [stamped (stamp-retrieval response)])
        ;; Cache only validated, successful API responses; stamp just once
        ;; on retrieval, and preserve that timestamp on future cache hits.
        (write-cached-title path stamped)
        stamped)))

;; omdb-get-title : String [#:api-key String]
;;                    [#:cache-root Path-String]
;;                    [#:refresh? Boolean] -> String
(define (omdb-get-title imdb-id
                   #:api-key [api-key (getenv "OMDB_API_KEY")]
                   #:cache-root [cache-root default-cache-root]
                   #:refresh? [refresh? #f])
  (define data (omdb-get-title-data imdb-id
                               #:api-key api-key
                               #:cache-root cache-root
                               #:refresh? refresh?))
  (define title (hash-ref data 'Title #f))
  (unless (string? title)
    (error 'omdb-get-title "OMDb returned no title for ~a" imdb-id))
  title)

(module+ test
  (require rackunit)

  (check-equal?
   (path->string (imdb-cache-path "tt45368240"))
   "/home/x/Dropbox/2/Data/com/omdbapi/tt/4/5/3/6/tt45368240.json")
  (check-equal?
   (path->string (imdb-cache-path "nm0000206"))
   "/home/x/Dropbox/2/Data/com/omdbapi/nm/0/0/0/0/nm0000206.json")
  (check-equal? (unix-seconds->iso8601-utc 0) "1970-01-01T00:00:00Z")
  (check-equal? (unix-seconds->iso8601-utc 946684800) "2000-01-01T00:00:00Z")

  (check-exn exn:fail:contract?
             (lambda () (omdb-get-title "nm0000206" #:api-key "test")))

  ;; Exercise a real disk-cache hit without OMDb credentials or a network.
  (define temp-root (make-temporary-file "imdb-cache-test~a" 'directory))
  (dynamic-wind
    void
    (lambda ()
      (define imdb-id "tt0133093")
      (define path (imdb-cache-path imdb-id #:cache-root temp-root))
      (define legacy-response
        (hasheq 'Response "True"
                'imdbID imdb-id
                'Title "The Matrix"
                'Year "1999"))
      (define stamped (stamp-retrieval legacy-response))
      (define retrieved-at (hash-ref stamped '_retrieved_at))
      (check-exn exn:fail?
                 (lambda () (omdb-get-title imdb-id
                                       #:api-key #f
                                       #:cache-root temp-root)))
      (make-parent-directory* path)
      (call-with-output-file path
        (lambda (out) (write-json legacy-response out)))
      ;; Existing un-stamped caches stay valid. We don't pretend to know
      ;; their original retrieval time.
      (check-equal? (omdb-get-title imdb-id #:api-key #f #:cache-root temp-root)
                    "The Matrix")
      (check-false (hash-has-key? (omdb-get-title-data imdb-id
                                                #:api-key #f
                                                #:cache-root temp-root)
                                    '_retrieved_at))
      ;; Emulate a successful online retrieval and check that the timestamp
      ;; survives the JSON disk round trip and future offline lookups.
      (check-true (regexp-match? #px"^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$"
                                 retrieved-at))
      (write-cached-title path stamped)
      (check-equal? (call-with-input-file* path read-json) stamped)
      (check-equal? (hash-ref (omdb-get-title-data imdb-id
                                               #:api-key #f
                                               #:cache-root temp-root)
                              '_retrieved_at)
                    retrieved-at)
      (check-equal? (hash-ref (omdb-get-title-data imdb-id
                                               #:api-key #f
                                               #:cache-root temp-root)
                              'Year)
                    "1999"))
    (lambda () (delete-directory/files temp-root))))

;; current-stardate : -> String
;; Obtain the current stardate from the external command.
(define (current-stardate)
  (define executable (find-executable-path "stardate"))
  (unless executable
    (error 'current-stardate "stardate not found in PATH"))
  (define output
    (string-trim
     (with-output-to-string
       (lambda ()
         (unless (system* executable)
           (error 'current-stardate "stardate command failed"))))))
  (when (string=? output "")
    (error 'current-stardate "stardate returned empty output"))
  output)

;; omdb-add-comment : String String
;;                    [#:api-key String]
;;                    [#:cache-root Path-String] -> Hash
;;
;; Add a timestamped comment to the cached JSON record.
;; Return the updated record.
(define (omdb-add-comment omdb-id comment-string
                          #:api-key [api-key (getenv "OMDB_API_KEY")]
                          #:cache-root [cache-root default-cache-root])
  (unless (string? comment-string)
    (raise-argument-error 'omdb-add-comment "string?" comment-string))

  (define data
    (omdb-get-title-data omdb-id
                         #:api-key api-key
                         #:cache-root cache-root))

  (define comments
    (hash-ref data 'comment (hasheq)))

  (define timestamp
    (string->symbol (current-stardate)))

  (define updated
    (hash-set data 'comment
              (hash-set comments timestamp comment-string)))

  (write-cached-title
   (imdb-cache-path omdb-id #:cache-root cache-root)
   updated)

  updated)

;; vim: set et ff=unix ft=racket nocp sts=2 sw=2 ts=2:
