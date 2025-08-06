;; $Source: /Users/x/Dropbox/2/src/blog/2025/08/06/src/RCS/getgitblobbyhash.lisp,v $
;; $Date: 2025/08/06 23:06:05 $
;; $Revision: 1.2 $

(defun get-git-blob-by-hash (hash)
  "Retrieve a git blob as a string."
  (with-output-to-string (output)
    (sb-ext:run-program "/usr/bin/git" (list "cat-file" "blob" hash)
                       :output output
                       :error :stream
                       :wait t)))

(defun eval-git-blob-by-hash (hash)
  "Safely evaluate Lisp code from a git blob, form by form."
  (let ((code-string (get-git-blob-by-hash hash)))
    (with-input-from-string (stream code-string)
      (let ((results '()))
        (handler-case
            (loop for form = (read stream nil :eof)
                  until (eq form :eof)
                  do (push (eval form) results))
          (error (e)
            (format t "Error evaluating form: ~A~%" e)
            (return-from eval-git-blob-by-hash nil)))
        (nreverse results)))))

