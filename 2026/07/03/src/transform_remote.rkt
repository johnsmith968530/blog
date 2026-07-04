#!/usr/bin/env racket
#lang racket

;; $Source: /home/x/Dropbox/2/src/blog/2026/07/03/src/RCS/transform_remote.rkt,v $
;; $Date: 2026/07/04 00:06:27 $
;; $Revision: 1.1 $

;; Unified CLONE1 → REMOTE1/BRANCH1 transformation.
;;
;; Supports:
;; - GitHub SSH: git@github.com:user/repo.git
;; - GitHub HTTPS: https://github.com/user/repo.git
;; - GitHub Pages: https://user.github.io/repo/...
;; - Codeberg SSH: ssh://git@codeberg.org/user/repo.git
;; - OpenClaw SSH: ssh://user@host/path
;; - Gist HTTPS: https://gist.github.com/user/hash

(require json racket/system racket/port)

(struct remote-info (remote branch clone dir volpath zfs) #:transparent)

(define (reverse-domain domain)
  ;; Convert 'github.com' → 'com.github'
  (string-join (reverse (string-split domain ".")) "."))

(define (slash-domain domain)
  ;; Convert 'github.com' → 'com/github'
  (string-join (reverse (string-split domain ".")) "/"))

(define (run-envy-cmd cmd)
  (define-values (proc out in err) (apply subprocess #f #f #f (find-executable-path "envy") cmd))
  (subprocess-wait proc)
  (close-input-port out)
  (close-output-port in)
  (close-input-port err)
  (define ec (subprocess-status proc))
  (unless (eqv? ec 0)
    (error 'envy "envy command failed: ~a" (string-join (cons "envy" cmd) " "))))

(define (set-envy-globals info)
  ;; Set git remote, branch, and clone via envy set global.
  (define zfs (remote-info-zfs info))
  (define dir (remote-info-dir info))
  (define remote (remote-info-remote info))
  (define clone (remote-info-clone info))
  (define volpath (remote-info-volpath info))
  (define branch (remote-info-branch info))
  (define command-str
    (string-append
     "1"
     " [ ! -e \"/mnt/" zfs "\" ] && sudo zfs create \"h367/" zfs "\""
     " && sudo chown -R x:x \"/mnt/" zfs "\""
     " && [ ! -e \"" dir "\" ]; cd \"/mnt/" zfs "\""
     " && git clone -o \"" remote "\" \"" clone "\""))
  (for ([cmd (list (list "set" "global" "git" "remote" remote)
                  (list "set" "global" "git" "branch" branch)
                  (list "set" "global" "git" "clone" clone)
                  (list "set" "global" "git" "dir" dir)
                  (list "set" "global" "git" "volpath" volpath)
                  (list "set" "global" "git" "command" command-str))])
    (run-envy-cmd cmd)))

(define (transform-remote clone-url [branch0 "main"])
  ;; Transform a git clone URL into REMOTE1 and BRANCH1 names.
  ;;
  ;; REMOTE1 uses dots: com.github.user.repo
  ;; BRANCH1 uses slashes: com.github/user/repo/branch0
  (cond
    ;; Pattern 1: SSH shorthand (git@github.com:user/repo.git)
    [(regexp-match #px"^git@([^:]+):([^/]+)/(.+)\\.git$" clone-url)
     =>
     (lambda (m)
       (define domain (cadr m))
       (define user (caddr m))
       (define repo (cadddr m))
       (remote-info
        (string-join (list (reverse-domain domain) user repo) ".")
        (string-join (list (reverse-domain domain) user repo branch0) "/")
        clone-url
        (format "/mnt/git/~a/~a/~a" (slash-domain domain) user repo)
        (format "git/~a/~a" (slash-domain domain) user)
        (format "git/~a/~a" (slash-domain domain) user)))]

    ;; Pattern 1b: Gist SSH (git@gist.github.com:HASH.git) - needs HTTPS URL
    [(regexp-match #px"^git@gist\\.github\\.com:([a-f0-9]+)\\.git$" clone-url)
     =>
     (lambda (m)
       (error (format "Gist SSH URL lacks username. Use HTTPS URL instead: https://gist.github.com/USER/~a" (cadr m))))]

    ;; Pattern 1c: GitHub Pages (https://user.github.io/repo/...)
    [(regexp-match #px"^https://([^.]+)\\.github\\.io/([^/]+)(?:/.*)?$" clone-url)
     =>
     (lambda (m)
       (define user (cadr m))
       (define repo (caddr m))
       (remote-info
        (format "com.github.~a.~a" user repo)
        (format "com.github/~a/~a/~a" user repo branch0)
        (format "https://github.com/~a/~a.git" user repo)
        (format "/mnt/git/com/github/~a/~a" user repo)
        (format "git/com/github/~a" user)
        (format "git/com/github/~a" user)))]

    ;; Pattern 2: GitHub/GitLab HTTPS (https://github.com/user/repo.git)
    [(regexp-match #px"^https://([^/]+)/([^/]+)/(.+)\\.git$" clone-url)
     =>
     (lambda (m)
       (define domain (cadr m))
       (define user (caddr m))
       (define repo (cadddr m))
       (remote-info
        (string-join (list (reverse-domain domain) user repo) ".")
        (string-join (list (reverse-domain domain) user repo branch0) "/")
        clone-url
        (format "/mnt/git/~a/~a/~a" (slash-domain domain) user repo)
        (format "git/~a/~a" (slash-domain domain) user)
        (format "git/~a/~a" (slash-domain domain) user)))]

    ;; Pattern 2b: Gist HTTPS (https://gist.github.com/user/hash)
    [(regexp-match #px"^https://gist\\.github\\.com/([^/]+)/([a-f0-9]+)$" clone-url)
     =>
     (lambda (m)
       (define user (cadr m))
       (define gist-hash (caddr m))
       (remote-info
        (format "com.github.gist.~a.~a" user gist-hash)
        (format "com.github.gist/~a/~a/~a" user gist-hash branch0)
        clone-url
        (format "/mnt/git/com/github/gist/~a/~a" user gist-hash)
        (format "git/com/github/gist/~a" user)
        (format "git/com/github/gist/~a" user)))]

    ;; Pattern 3: Full SSH URL (ssh://user@host:port/path or ssh://user@host/path)
    [(regexp-match #px"^ssh://[^@]+@([^:/]+)(?::[0-9]+)?/(.+)$" clone-url)
     =>
     (lambda (m)
       (define host (cadr m))
       (define raw-path (caddr m))
       ;; Clean path: strip /root prefix if present, then leading slash
       (define path
         (regexp-replace #px"^/" (regexp-replace #px"^/root/" raw-path "") ""))
       (cond
         ;; Sub-pattern 3a: Hosted git service (ssh://git@host/user/repo.git)
         [(regexp-match #px"^([^/]+)/(.+)\\.git$" path)
          =>
          (lambda (hm)
            (define user (cadr hm))
            (define repo (caddr hm))
            (remote-info
             (string-join (list (reverse-domain host) user repo) ".")
             (string-join (list (slash-domain host) user repo branch0) "/")
             clone-url
             (format "/mnt/git/~a/~a/~a" (slash-domain host) user repo)
             (format "git/~a/~a" (slash-domain host) user)
             (format "git/~a/~a" (slash-domain host) user)))]
         ;; Sub-pattern 3b: Generic SSH (ssh://user@host/path/to/something)
         [else
          (define path-dots (regexp-replace* #px"/" path "."))
          (define path-slashes path)
          (remote-info
           (string-join (list (reverse-domain host) path-dots) ".")
           (string-join (list (slash-domain host) path-slashes branch0) "/")
           clone-url
           (format "/mnt/git/~a/~a" (slash-domain host) path-slashes)
           (format "git/~a" (slash-domain host))
           (format "git/~a" (slash-domain host)))]))]

    [else
     (error (format "Unrecognized clone URL format: ~a" clone-url))]))

(struct test-case (name url branch expect-error? error-message expected) #:transparent)

(define (info->hash i)
  (hash 'remote (remote-info-remote i)
        'branch (remote-info-branch i)
        'clone (remote-info-clone i)
        'dir (remote-info-dir i)
        'volpath (remote-info-volpath i)
        'zfs (remote-info-zfs i)))

(define (self-test)
  ;; Run self-test exercising each parsing special case.
  (define test-cases
    (list
     (test-case "Pattern 1: SSH shorthand (GitHub)"
                "git@github.com:torvalds/linux.git" #f #f #f
                (hash 'remote "com.github.torvalds.linux"
                      'branch "com.github/torvalds/linux/main"
                      'clone "git@github.com:torvalds/linux.git"
                      'dir "/mnt/git/com/github/torvalds/linux"
                      'volpath "git/com/github/torvalds"
                      'zfs "git/com/github/torvalds"))
     (test-case "Pattern 1: SSH shorthand (non-GitHub domain)"
                "git@gitlab.com:user/project.git" #f #f #f
                (hash 'remote "com.gitlab.user.project"
                      'branch "com.gitlab/user/project/main"
                      'clone "git@gitlab.com:user/project.git"
                      'dir "/mnt/git/com/gitlab/user/project"
                      'volpath "git/com/gitlab/user"
                      'zfs "git/com/gitlab/user"))
     (test-case "Pattern 1b: Gist SSH (should error)"
                "git@gist.github.com:abc123.git" #f #t
                "Gist SSH URL lacks username. Use HTTPS URL instead: https://gist.github.com/USER/abc123" #f)
     (test-case "Pattern 1c: GitHub Pages (trailing slash)"
                "https://octocat.github.io/myproject/" #f #f #f
                (hash 'remote "com.github.octocat.myproject"
                      'branch "com.github/octocat/myproject/main"
                      'clone "https://github.com/octocat/myproject.git"
                      'dir "/mnt/git/com/github/octocat/myproject"
                      'volpath "git/com/github/octocat"
                      'zfs "git/com/github/octocat"))
     (test-case "Pattern 1c: GitHub Pages with trailing path"
                "https://octocat.github.io/myproject/sub/page" #f #f #f
                (hash 'remote "com.github.octocat.myproject"
                      'branch "com.github/octocat/myproject/main"
                      'clone "https://github.com/octocat/myproject.git"
                      'dir "/mnt/git/com/github/octocat/myproject"
                      'volpath "git/com/github/octocat"
                      'zfs "git/com/github/octocat"))
     (test-case "Pattern 2: GitHub HTTPS"
                "https://github.com/torvalds/linux.git" #f #f #f
                (hash 'remote "com.github.torvalds.linux"
                      'branch "com.github/torvalds/linux/main"
                      'clone "https://github.com/torvalds/linux.git"
                      'dir "/mnt/git/com/github/torvalds/linux"
                      'volpath "git/com/github/torvalds"
                      'zfs "git/com/github/torvalds"))
     (test-case "Pattern 2b: Gist HTTPS"
                "https://gist.github.com/octocat/abc123def456" #f #f #f
                (hash 'remote "com.github.gist.octocat.abc123def456"
                      'branch "com.github.gist/octocat/abc123def456/main"
                      'clone "https://gist.github.com/octocat/abc123def456"
                      'dir "/mnt/git/com/github/gist/octocat/abc123def456"
                      'volpath "git/com/github/gist/octocat"
                      'zfs "git/com/github/gist/octocat"))
     (test-case "Pattern 3a: Full SSH hosted (Codeberg)"
                "ssh://git@codeberg.org/user/repo.git" #f #f #f
                (hash 'remote "org.codeberg.user.repo"
                      'branch "org/codeberg/user/repo/main"
                      'clone "ssh://git@codeberg.org/user/repo.git"
                      'dir "/mnt/git/org/codeberg/user/repo"
                      'volpath "git/org/codeberg/user"
                      'zfs "git/org/codeberg/user"))
     (test-case "Pattern 3a: Full SSH hosted with port"
                "ssh://git@codeberg.org:2222/user/repo.git" #f #f #f
                (hash 'remote "org.codeberg.user.repo"
                      'branch "org/codeberg/user/repo/main"
                      'clone "ssh://git@codeberg.org:2222/user/repo.git"
                      'dir "/mnt/git/org/codeberg/user/repo"
                      'volpath "git/org/codeberg/user"
                      'zfs "git/org/codeberg/user"))
     (test-case "Pattern 3b: Generic SSH"
                "ssh://deploy@myserver.com/opt/app/myproject" #f #f #f
                (hash 'remote "com.myserver.opt.app.myproject"
                      'branch "com/myserver/opt/app/myproject/main"
                      'clone "ssh://deploy@myserver.com/opt/app/myproject"
                      'dir "/mnt/git/com/myserver/opt/app/myproject"
                      'volpath "git/com/myserver"
                      'zfs "git/com/myserver"))
     (test-case "Pattern 3b: Generic SSH with /root/ prefix stripping"
                "ssh://deploy@myserver.com//root/opt/app/myproject" #f #f #f
                (hash 'remote "com.myserver.opt.app.myproject"
                      'branch "com/myserver/opt/app/myproject/main"
                      'clone "ssh://deploy@myserver.com//root/opt/app/myproject"
                      'dir "/mnt/git/com/myserver/opt/app/myproject"
                      'volpath "git/com/myserver"
                      'zfs "git/com/myserver"))
     (test-case "Unrecognized URL format (should error)"
                "invalid-url" #f #t
                "Unrecognized clone URL format: invalid-url" #f)
     (test-case "Custom branch name"
                "git@github.com:user/repo.git" "develop" #f #f
                (hash 'remote "com.github.user.repo"
                      'branch "com.github/user/repo/develop"
                      'clone "git@github.com:user/repo.git"
                      'dir "/mnt/git/com/github/user/repo"
                      'volpath "git/com/github/user"
                      'zfs "git/com/github/user"))))

  (define passed 0)
  (define failed 0)

  (define (info-fields-match? info expected-hash)
    (for/and ([(k v) (in-hash expected-hash)])
      (equal? (hash-ref (info->hash info) k) v)))

  (define (run-one tc)
    (define name (test-case-name tc))
    (define result
      (with-handlers ([exn:fail? (lambda (e) (cons 'error (exn-message e)))])
        (cons 'ok
              (if (test-case-branch tc)
                  (transform-remote (test-case-url tc) (test-case-branch tc))
                  (transform-remote (test-case-url tc))))))
    (cond
      [(eq? (car result) 'error)
       (define msg (cdr result))
       (cond
         [(test-case-expect-error? tc)
          (cond
            [(and (test-case-error-message tc)
                  (not (equal? msg (test-case-error-message tc))))
             (eprintf "  FAIL: ~a — error message mismatch\n" name)
             (eprintf "        Expected: ~a\n" (test-case-error-message tc))
             (eprintf "        Got:      ~a\n" msg)
             (set! failed (add1 failed))]
            [else
             (printf "  PASS: ~a\n" name)
             (set! passed (add1 passed))])]
         [else
          (eprintf "  FAIL: ~a — unexpected error: ~a\n" name msg)
          (set! failed (add1 failed))])]
      [(test-case-expect-error? tc)
       (eprintf "  FAIL: ~a — expected error but got result\n" name)
       (eprintf "        Result: ~a\n" (jsexpr->string (info->hash (cdr result))))
       (set! failed (add1 failed))]
      [(info-fields-match? (cdr result) (test-case-expected tc))
       (printf "  PASS: ~a\n" name)
       (set! passed (add1 passed))]
      [else
       (eprintf "  FAIL: ~a\n" name)
       (define result-hash (info->hash (cdr result)))
       (for ([(k v) (in-hash (test-case-expected tc))])
         (unless (equal? (hash-ref result-hash k) v)
           (eprintf "        ~a: expected ~a, got ~a\n"
                    k v (hash-ref result-hash k))))
       (set! failed (add1 failed))]))

  (for ([tc test-cases])
    (run-one tc))

  (printf "\n~a passed, ~a failed, ~a total\n" passed failed (length test-cases))
  (when (> failed 0)
    (exit 1)))

(define (main)
  ;; CLI interface: transform_remote CLONE_URL [BRANCH]
  (define args (vector->list (current-command-line-arguments)))

  (cond
    [(and (pair? args) (equal? (car args) "--test"))
     (self-test)]
    [(< (length args) 1)
     (eprintf "Usage: transform_remote CLONE_URL [BRANCH]\n")
     (eprintf "       transform_remote --test\n")
     (eprintf "  Outputs: JSON with 'remote', 'branch', and 'clone' fields\n")
     (eprintf "  Also sets envy global git.remote, git.branch, git.clone, git.volpath and git.dir\n")
     (exit 1)]
    [else
     (define clone-url (car args))
     (define branch0 (if (>= (length args) 2) (cadr args) "main"))
     (with-handlers ([exn:fail?
                      (lambda (e)
                        (eprintf "~a\n"
                                 (jsexpr->string (hash 'error (exn-message e))))
                        (exit 1))])
       (define info (transform-remote clone-url branch0))
       (set-envy-globals info)
       (define-values (proc out in err) (subprocess #f #f #f (find-executable-path "envy") "get" "global" "git"))
        (display (port->string out)))]))


(main)

;; vim: set et ff=unix ft=racket nocp sts=2 sw=2 ts=2:
