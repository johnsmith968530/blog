#!/usr/bin/env racket

;; $Source: /home/x/Dropbox/2/src/blog/2026/06/21/RCS/doxjr.rkt,v $
;; $Date: 2026/06/21 21:45:53 $
;; $Revision: 1.1 $

#lang racket/base
;; doxjr.rkt — Racket port of doxjr.c (circa 1991 "poor man's TeX").
;;
;; Reads "source" text in which lines beginning with `$` contain formula
;; markup (e.g. "$pu=Integrate[tau*dtau,Minus[Infinity],Infinity]"), and
;; produces typeset ASCII-art output. Lines not beginning with `$` pass
;; through verbatim. A line that is exactly "$DEFINE" is followed by two
;; lines giving a macro name and its expansion. Inline `~name~expansion~`
;; defines a macro; `` `name` `` undefines one.
;;
;; The port is deliberately faithful to the original C, including its
;; quirks (operator tables, RPN evaluation order, fgets buffer-size line
;; splitting, the raise2 stride bug, a final line without a trailing
;; newline being dropped, etc.), so that for any input the C program
;; accepts, (dox input) returns exactly the bytes doxjr would have
;; written to the .tc1 file. Console-only chatter from the C program
;; (the "Processing" banner, the echo of each block, error beeps) is not
;; part of the result; diagnostics go to `current-error-port` instead.
;;
;; Main entry point:
;;   (dox input-string [#:page-length pl]) -> output-string
;; pl > 0 reproduces the optional page-length feature (argv[2] in C),
;; emitting a form-feed line between pages and one at the end.

(provide dox)

(require racket/string racket/list)

;; ---------------------------------------------------------------------
;; Blocks
;;
;; A "block" is a rectangle of characters stored row-major in a mutable
;; string, exactly like the char* grids in C. The renderer keeps four
;; parallel vectors -- bstack/hsize/vsize/center -- plus a stack pointer,
;; mirroring the C calling convention so the original index arithmetic
;; ports verbatim. (C's free() becomes a no-op; Racket has GC.)
;; ---------------------------------------------------------------------

(define (clear size)                       ; C: clear()
  (make-string (max size 0) #\space))

;; Safe cell accessors. The C code occasionally reads or writes a hair
;; outside a block (heap garbage / UB). We ignore out-of-range writes
;; and read spaces, which matches C behavior on all well-formed input.
(define (gref s idx)
  (if (and (>= idx 0) (< idx (string-length s))) (string-ref s idx) #\space))
(define (gset! s idx ch)
  (when (and (>= idx 0) (< idx (string-length s))) (string-set! s idx ch)))

;; C: hinsert() — centered horizontal insertion of x (hx×vx) into y
;; (width hy) starting at row vs.
(define (hinsert x hx vx y hy vs)
  (define k (quotient (- hy hx) 2))
  (for* ([i (in-range vx)] [j (in-range hx)])
    (gset! y (+ (* (+ i vs) hy) j k) (gref x (+ (* i hx) j)))))

;; C: getnum() — sscanf("%d") on the first n chars of s.
(define (getnum n s)
  (define t (substring s 0 (min n (string-length s))))
  (define m (regexp-match #px"^[ \t]*([+-]?[0-9]+)" t))
  (if m (string->number (cadr m)) 0))

;; ---------------------------------------------------------------------
;; Operator tables (verbatim from C)
;; ---------------------------------------------------------------------

(define binop '("+" "-" "/" "*" "!" "@" "#" "=" "?" "<" ">"
                "LE" "GE" "LL" "GG" "IMPLIES" "NE"))
(define binch '(" + " " - " "/" " " "" "*" " -> " " = " "." " < " " > "
                " <= " " => " " << " " >> " " ==> " " <> "))

(define triop '("Integrate" "Sum" "Product" "Limit"))
(define trich '("/|||/" "---\\  /  ---" "----- | |  | | " "lim"))
(define trih  '(1 3 5 3))
(define triv  '(5 4 3 1))

(define ovrop '("Dot" "Hat" "Tilde" "Bar"))
(define ovrch '(#\. #\^ #\~ #\_))

(define nxtop '("Prime" "Fact"))
(define nxtch '(#\' #\!))

(define purop '("Colon" "Period" "Semicolon" "Star" "Comma" "Tick" "Add" "Sub"
                "Del" "DelSqr" "PlusMinus" "Dots" "QM" "Vert" "Bang"
                "LParen" "RParen" "BLParen" "BRParen"))
(define purch '(":" "." ";" "*" "," "'" "+" "-" "__\\/" "__2\\/ " "+-" "..."
                "?" "|" "!" "(" ")" "/|\\" "\\|/"))
(define purh '(1 1 1 1 1 1 1 1 2 3 2 3 1 1 1 1 1 1 1))
(define purv '(1 1 1 1 1 1 1 1 2 2 1 1 1 1 1 1 1 3 3))

;; Parser tables
(define prefixes '("NOT" "Minus" "Integrate" "Sum" "Abs"
                   "Dot" "Hat" "Dirac" "Tilde" "Bra"
                   "Ket" "Bar" "Brace" "Eval" "Prime"
                   "Product" "Sqrt" "Fact" "BoxIt" "Bigger"
                   "Number" "Both" "SuBoth" "Limit" "Over" "Group" "Tab"
                   "Space" "Plus" "Paren" "Vec" "List" "Matrix" "Brack"))
(define prefixlvl (make-list 34 1))
(define infixes '("," "+" "-" "/" "!" "@" "#" "%" "^" "&" "*" "=" "\\"
                  "<" ">" "?" "GG" "GE" "LE" "LL" "NE" "IMPLIES" "'"))
(define infixlvl '(6 4 4 3 3 2 5 3 2 2 3 5 2 5 5 3 5 5 5 5 5 5 2))
(define bdelims '("(" "[" "{"))
(define edelims '(")" "]" "}"))

;; ---------------------------------------------------------------------
;; doxform — render an RPN token list into a single block
;; Returns (values grid-string h v). Mirrors C doxform() exactly.
;; ---------------------------------------------------------------------

(define (doxform cstack plinec pline)
  (define cap (+ (length cstack) 2))
  (define bstack (make-vector cap ""))
  (define hsize  (make-vector cap 0))
  (define vsize  (make-vector cap 0))
  (define center (make-vector cap 0))
  (define nstack 0)

  (define (b i) (vector-ref bstack i))
  (define (h i) (vector-ref hsize i))
  (define (v i) (vector-ref vsize i))
  (define (c i) (vector-ref center i))
  (define (set-b! i x) (vector-set! bstack i x))
  (define (set-h! i x) (vector-set! hsize i x))
  (define (set-v! i x) (vector-set! vsize i x))
  (define (set-c! i x) (vector-set! center i x))

  ;; C: binary()
  (define (binary op)
    (define x (- nstack 2)) (define y (- nstack 1))
    (define hx (h x)) (define hy (h y)) (define vx (v x)) (define vy (v y))
    (define len (string-length op))
    (define cx (c x)) (define cy (c y))
    (define h1 (max cx cy)) (define h2 (max (- vx cx) (- vy cy)))
    (define w (+ hx hy len))
    (define temp (clear (* w (+ h1 h2))))
    (for* ([i (in-range hx)] [j (in-range vx)])
      (gset! temp (+ (* (+ j h1 (- cx)) w) i) (gref (b x) (+ (* j hx) i))))
    (for ([i (in-range len)])
      (gset! temp (+ (* (- h1 1) w) i hx) (string-ref op i)))
    (for* ([i (in-range hy)] [j (in-range vy)])
      (gset! temp (+ (* (+ j h1 (- cy)) w) i hx len) (gref (b y) (+ (* j hy) i))))
    (set-h! x w) (set-v! x (+ h1 h2)) (set-c! x h1)
    (set! nstack (- nstack 1)) (set-b! x temp))

  ;; C: trinary() — Integrate/Sum/Product/Limit with optional limits
  (define (trinary op oh ov)
    (define nparms 1)
    (set! nstack (- nstack 1))
    (let loop ()
      (when (char=? (gref (b nstack) 0) #\,)
        (set! nparms (+ nparms 1))
        (set! nstack (- nstack 1))
        (loop)))
    (define hmax oh) (define vs ov)
    (define cenl (quotient (+ ov 1) 2))
    (when (> nparms 1)
      (for ([i (in-range (- nparms 1))])
        (set! hmax (max hmax (h (- nstack i))))
        (set! vs (+ vs (v (- nstack i))))))
    (when (> nparms 2) (set! cenl (+ cenl (v nstack))))
    (define arg (+ nstack (- nparms) 1))
    (define harg (h arg))
    (define hout (+ hmax harg))
    (define upr (max cenl (c arg)))
    (define varg (v arg))
    (define lwr (max (- vs cenl) (- varg (c arg))))
    (define vout (+ lwr upr))
    (define temp (clear (* hout vout)))
    (define voff (if (> cenl (c arg)) 0 (- (c arg) cenl)))
    (when (> nparms 2)                            ; upper limit
      (define me nstack)
      (define hoff (quotient (- hmax (h me)) 2))
      (for* ([i (in-range (h me))] [j (in-range (v me))])
        (gset! temp (+ (* (+ voff j) hout) i hoff) (gref (b me) (+ (* j (h me)) i))))
      (set! voff (+ voff (v me))))
    (let ([hoff (quotient (- hmax oh) 2)])        ; the operator glyph
      (for* ([i (in-range oh)] [j (in-range ov)])
        (gset! temp (+ (* (+ voff j) hout) i hoff) (string-ref op (+ (* j oh) i))))
      (set! voff (+ voff ov)))
    (when (> nparms 1)                            ; lower limit
      (define me (+ nstack (- nparms) 2))
      (define hoff (quotient (- hmax (h me)) 2))
      (for* ([i (in-range (h me))] [j (in-range (v me))])
        (gset! temp (+ (* (+ voff j) hout) i hoff) (gref (b me) (+ (* j (h me)) i)))))
    (let* ([me arg]
           [voff (if (> (c me) cenl) 0 (- cenl (c me)))])
      (for* ([i (in-range harg)] [j (in-range varg)])
        (gset! temp (+ (* (+ j voff) hout) i hmax) (gref (b me) (+ (* j harg) i)))))
    (set-b! arg temp) (set-h! arg hout) (set-v! arg vout) (set-c! arg upr)
    (set! nstack (- nstack (- nparms 2))))

  ;; C: ovrhead() — Dot/Hat/Tilde/Bar
  (define (ovrhead ch)
    (define me (- nstack 1)) (define hx (h me)) (define vx (v me))
    (define temp (clear (* hx (+ vx 1))))
    (gset! temp (quotient hx 2) ch)
    (for* ([j (in-range vx)] [i (in-range hx)])
      (gset! temp (+ (* (+ j 1) hx) i) (gref (b me) (+ (* j hx) i))))
    (set-b! me temp) (set-v! me (+ vx 1)) (set-c! me (+ (c me) 1)))

  ;; C: nextto() — Prime/Fact
  (define (nextto ch)
    (define me (- nstack 1)) (define hx (h me)) (define vx (v me))
    (define temp (clear (* (+ hx 1) vx)))
    (gset! temp (+ (* (- (c me) 1) (+ hx 1)) hx) ch)
    (for* ([j (in-range vx)] [i (in-range hx)])
      (gset! temp (+ (* j (+ hx 1)) i) (gref (b me) (+ (* j hx) i))))
    (set-b! me temp) (set-h! me (+ hx 1)))

  ;; C: pure() — push a fixed glyph
  (define (pure purch purh purv)
    (define temp (clear (* purh purv)))
    (for ([i (in-range (min (* purh purv) (string-length purch)))])
      (string-set! temp i (string-ref purch i)))
    (set-b! nstack temp)
    (set-h! nstack purh) (set-v! nstack purv)
    (set-c! nstack (+ (quotient purv 2) 1))
    (set! nstack (+ nstack 1)))

  ;; C: over() — fractions (Over / %)
  (define (over)
    (define y (- nstack 1))
    (when (char=? (gref (b y) 0) #\,) (set! y (- y 1)))
    (define x (- y 1))
    (define hx (h x)) (define hy (h y)) (define vx (v x)) (define vy (v y))
    (define ho (+ (max hx hy) 2)) (define vo (+ vx vy 1))
    (set-h! x ho) (set-v! x vo) (set-c! x (+ vx 1))
    (define temp (clear (* ho vo)))
    (hinsert (b x) hx vx temp ho 0)
    (for ([j (in-range ho)]) (gset! temp (+ (* vx ho) j) #\-))
    (hinsert (b y) hy vy temp ho (+ vx 1))
    (set! nstack y)
    (set-b! x temp))

  ;; C: raise1() — superscript (^)
  (define (raise1)
    (define x (- nstack 2)) (define y (- nstack 1))
    (define hx (h x)) (define hy (h y)) (define vx (v x)) (define vy (v y))
    (define w (+ hx hy))
    (define temp (clear (* w (+ vx vy))))
    (set-h! x w) (set-v! x (+ vx vy)) (set-c! x (+ (c x) vy))
    (for* ([i (in-range hx)] [j (in-range vx)])
      (gset! temp (+ (* (+ j vy) w) i) (gref (b x) (+ i (* hx j)))))
    (for* ([i (in-range hy)] [j (in-range vy)])
      (gset! temp (+ (* j w) hx i) (gref (b y) (+ i (* hy j)))))
    (set-b! x temp) (set! nstack (- nstack 1)))

  ;; C: raise2() — tight superscript (')
  ;; NOTE: faithfully preserves the original's stride bug — the second
  ;; copy indexes bstack[y] with hx (not hy). Harmless when vy==1.
  (define (raise2)
    (define x (- nstack 2)) (define y (- nstack 1))
    (define hx (h x)) (define hy (h y)) (define vx (v x)) (define vy (v y))
    (define w (+ hx hy))
    (define temp (clear (* w (- (+ vx vy) 1))))
    (set-h! x w) (set-v! x (- (+ vx vy) 1)) (set-c! x (+ (c x) vy -1))
    (for* ([i (in-range hx)] [j (in-range vx)])
      (gset! temp (+ (* (+ j vy -1) w) i) (gref (b x) (+ i (* hx j)))))
    (for* ([i (in-range hy)] [j (in-range vy)])
      (gset! temp (+ (* j w) hx i) (gref (b y) (+ i (* hx j)))))  ; sic: hx
    (set-b! x temp) (set! nstack (- nstack 1)))

  ;; C: lower() — subscript (&)
  (define (lower)
    (define x (- nstack 2)) (define y (- nstack 1))
    (define hx (h x)) (define hy (h y)) (define vx (v x)) (define vy (v y))
    (define w (+ hx hy))
    (define temp (clear (* w (+ vx vy))))
    (set-h! x w) (set-v! x (+ vx vy))
    (for* ([i (in-range hx)] [j (in-range vx)])
      (gset! temp (+ (* j w) i) (gref (b x) (+ i (* hx j)))))
    (for* ([i (in-range hy)] [j (in-range vy)])
      (gset! temp (+ (* (+ j vx) w) i hx) (gref (b y) (+ i (* hy j)))))
    (set-b! x temp) (set! nstack (- nstack 1)))

  ;; C: bkslash() — function application f\(x)
  (define (bkslash)
    (define x (- nstack 2)) (define y (- nstack 1))
    (define hx (h x)) (define hy (h y)) (define vx (v x)) (define vy (v y))
    (define cx (c x)) (define cy (c y))
    (define h1 (max cx cy)) (define h2 (max (- vx cx) (- vy cy)))
    (define w (+ hx hy 2))
    (define temp (clear (* w (+ h1 h2))))
    (for* ([i (in-range hx)] [j (in-range vx)])
      (gset! temp (+ (* (+ j h1 (- cx)) w) i) (gref (b x) (+ (* j hx) i))))
    (for* ([i (in-range hy)] [j (in-range vy)])
      (gset! temp (+ (* (+ j h1 (- cy)) w) i hx 1) (gref (b y) (+ (* j hy) i))))
    (if (< vy 3)
        (begin
          (gset! temp (+ (* (- h1 1) w) hx) #\()
          (gset! temp (+ (* (- h1 1) w) hx hy 1) #\)))
        (begin
          (gset! temp hx #\/)
          (gset! temp (+ (* (- (+ h1 h2) 1) w) hx hy 1) #\/)
          (gset! temp (+ hx hy 1) #\\)
          (gset! temp (+ (* (- (+ h1 h2) 1) w) hx) #\\)
          (for ([i (in-range 1 (- (+ h1 h2) 1))])
            (gset! temp (+ hx (* i w)) #\|)
            (gset! temp (+ hx hy 1 (* i w)) #\|))))
    (set-h! x w) (set-v! x (+ h1 h2)) (set-c! x h1)
    (set! nstack (- nstack 1)) (set-b! x temp))

  ;; C: minus() — unary minus
  (define (minus)
    (define me (- nstack 1)) (define hx (h me)) (define vx (v me))
    (set-h! me (+ hx 1))
    (define temp (clear (* (+ hx 1) vx)))
    (for* ([i (in-range hx)] [j (in-range vx)])
      (gset! temp (+ (* j (+ hx 1)) i 1) (gref (b me) (+ (* j hx) i))))
    (gset! temp (* (- (c me) 1) (+ hx 1)) #\-)
    (set-b! me temp))

  ;; C: space() — Space[n] → n blanks
  (define (space)
    (define me (- nstack 1))
    (define nspc (getnum (h me) (b me)))
    (set-b! me (clear nspc))
    (set-h! me nspc) (set-v! me 1) (set-c! me 1))

  ;; C: tab() — Tab[n] → pad to column n
  (define (tab)
    (set! nstack (- nstack 2))
    (define me (- nstack 2))
    (define nspc (- (getnum (h me) (b me)) (h (- me 1))))
    (set-b! me (clear nspc))
    (set-h! me nspc) (set-v! me 1) (set-c! me 1)
    (binary "") (binary ""))

  ;; C: both() — Both[sub,super]
  (define (both)
    (set! nstack (- nstack 2))
    (define me (- nstack 2))
    (define hy (h me)) (define hx (h (+ me 1)))
    (define vy (v me)) (define vx (v (+ me 1)))
    (define vz (v (- me 1)))
    (define tx (max hx hy)) (define ux (+ vx vy vz))
    (define temp (clear (* tx ux)))
    (hinsert (b (+ me 1)) hx vx temp tx 0)
    (hinsert (b me) hy vy temp tx (+ vx vz))
    (set-b! me temp) (set-c! me (+ (c (- me 1)) vx))
    (set-h! me tx) (set-v! me ux)
    (set! nstack (- nstack 1))
    (binary ""))

  ;; C: both2() — SuBoth[sub,super] (tighter)
  (define (both2)
    (set! nstack (- nstack 2))
    (define me (- nstack 2))
    (define hy (h me)) (define hx (h (+ me 1)))
    (define vy (v me)) (define vx (v (+ me 1)))
    (define vz (v (- me 1)))
    (define tx (max hx hy)) (define ux (- (+ vx vy vz) 1))
    (define temp (clear (* tx ux)))
    (hinsert (b (+ me 1)) hx vx temp tx 0)
    (hinsert (b me) hy vy temp tx (- (+ vx vz) 1))
    (set-b! me temp) (set-c! me (- (+ (c (- me 1)) vx) 1))
    (set-h! me tx) (set-v! me ux)
    (set! nstack (- nstack 1))
    (binary ""))

  ;; C: eval() — Eval[expr,lo] / Eval[expr,lo,hi]: evaluation bar
  (define (evalfn)
    (define np 1)
    (set! nstack (- nstack 1))
    (when (char=? (gref (b (- nstack 1)) 0) #\,)
      (set! np (+ np 1))
      (set! nstack (- nstack 1)))
    (define me (- nstack np))
    (define hx (h me)) (define vx (v me))
    (define hy (if (> np 1) (h (+ me 1)) 0))
    (define vy (if (> np 1) (v (+ me 1)) 0))
    (define vz (v (- me 1)))
    (define tx (max hx hy)) (define ux (+ vx vy vz))
    (define temp (clear (* tx ux)))
    (when (> np 1) (hinsert (b (+ me 1)) hy vy temp tx 0))
    (hinsert (b me) hx vx temp tx (+ vy vz))
    (for ([j (in-range vz)]) (gset! temp (* (+ j vy) tx) #\|))
    (set-b! me temp) (set-c! me (+ (c (- me 1)) vy))
    (set-h! me tx) (set-v! me ux)
    (when (> np 1) (set! nstack (- nstack 1)))
    (binary ""))

  ;; C: bigger() — force minimum height
  (define (bigger)
    (define me (- nstack 1))
    (define hx (h me)) (define vx (v me)) (define cx (c me))
    (define temp (clear (* (+ vx 1) hx)))
    (for* ([j (in-range vx)] [i (in-range hx)])
      (gset! temp (+ (* (+ 2 (- cx) j) hx) i) (gref (b me) (+ (* hx j) i))))
    (set-b! me temp) (set-v! me (+ vx 1)) (set-c! me 2))

  ;; C: number() — right-justify an equation number at column 75
  (define (number)
    (set! nstack (- nstack 1))
    (define hx (h (- nstack 2))) (define hy (h (- nstack 1)))
    (define vx (v (- nstack 2)))
    (define temp (clear (* (- 75 hy) vx)))
    (hinsert (b (- nstack 2)) hx vx temp (- 75 hy) 0)
    (set-b! (- nstack 2) temp)
    (set-h! (- nstack 2) (- 75 hy))
    (binary ""))

  ;; C: surround() — Brace/Bra/Ket and small Brack
  (define (surround ch1 ch2)
    (define me (- nstack 1))
    (define hx (h me)) (define vx (v me)) (define cx (c me))
    (define temp (clear (* (+ hx 2) vx)))
    (gset! temp (* (- cx 1) (+ hx 2)) ch1)
    (gset! temp (+ (* (- cx 1) (+ hx 2)) hx 1) ch2)
    (for* ([j (in-range vx)] [i (in-range hx)])
      (gset! temp (+ (* (+ hx 2) j) i 1) (gref (b me) (+ (* hx j) i))))
    (set-b! me temp) (set-h! me (+ hx 2)))

  ;; C: dirac() — Dirac[a] / Dirac[a,b] → <a|b>
  (define (dirac)
    (when (char=? (gref (b (- nstack 1)) 0) #\,)
      (set! nstack (- nstack 1))
      (binary "|"))
    (surround #\< #\>))

  ;; C: vec() — arrow over
  (define (vec)
    (define me (- nstack 1))
    (define hx (h me)) (define vx (v me))
    (define temp (clear (* (+ hx 2) (+ vx 1))))
    (for ([i (in-range (+ hx 1))]) (gset! temp i #\-))
    (gset! temp (+ hx 1) #\>)
    (for* ([j (in-range vx)] [i (in-range hx)])
      (gset! temp (+ (* (+ j 1) (+ hx 2)) i 1) (gref (b me) (+ (* j hx) i))))
    (set-b! me temp)
    (set-v! me (+ vx 1)) (set-c! me (+ (c me) 1)) (set-h! me (+ hx 2)))

  ;; C: brack() — square brackets, tall form for vx>=3
  (define (brack)
    (define me (- nstack 1))
    (define hx (h me)) (define vx (v me))
    (if (< vx 3)
        (surround #\[ #\])
        (let ([temp (clear (* (+ hx 4) (+ vx 2)))]
              [w (+ hx 4)])
          (for ([j (in-range vx)])
            (for ([i (in-range hx)])
              (gset! temp (+ (* (+ j 1) w) 2 i) (gref (b me) (+ (* j hx) i))))
            (gset! temp (* (+ j 1) w) #\|)
            (gset! temp (+ (* (+ j 1) w) hx 3) #\|))
          (for ([idx (list 0 (+ hx 3) (* (+ vx 1) w) (+ (* (+ vx 1) w) hx 3))])
            (gset! temp idx #\+))
          (for ([idx (list 1 (+ hx 2) (+ (* (+ vx 1) w) 1) (+ (* (+ vx 1) w) hx 2))])
            (gset! temp idx #\-))
          (set-b! me temp)
          (set-v! me (+ vx 2)) (set-c! me (+ (c me) 1)) (set-h! me (+ hx 4)))))

  ;; C: boxit() — draw a box around
  (define (boxit)
    (define me (- nstack 1))
    (define hx (h me)) (define vx (v me))
    (define w (+ hx 4))
    (define temp (clear (* w (+ vx 4))))
    (for* ([j (in-range vx)] [i (in-range hx)])
      (gset! temp (+ (* (+ j 2) w) 2 i) (gref (b me) (+ (* j hx) i))))
    (for ([j (in-range 1 (+ vx 3))])
      (gset! temp (* j w) #\|)
      (gset! temp (+ (* j w) hx 3) #\|))
    (for ([i (in-range 1 (+ hx 3))])
      (gset! temp i #\-)
      (gset! temp (+ (* w (+ vx 3)) i) #\-))
    (for ([idx (list 0 (+ hx 3) (* w (+ vx 3)) (+ (* w (+ vx 3)) hx 3))])
      (gset! temp idx #\+))
    (set-b! me temp)
    (set-v! me (+ vx 4)) (set-c! me (+ (c me) 2)) (set-h! me (+ hx 4)))

  ;; C: absol() — |x|
  (define (absol)
    (set! nstack (- nstack 1))
    (define hx (h nstack)) (define vx (v nstack))
    (define temp (clear (* (+ hx 2) vx)))
    (for ([j (in-range vx)])
      (gset! temp (* j (+ hx 2)) #\|)
      (gset! temp (+ (* j (+ hx 2)) hx 1) #\|)
      (for ([i (in-range hx)])
        (gset! temp (+ (* j (+ hx 2)) i 1) (gref (b nstack) (+ (* j hx) i)))))
    (set-h! nstack (+ hx 2))
    (set-b! nstack temp)
    (set! nstack (+ nstack 1)))

  ;; C: list() — comma-joined list, center-aligned
  (define (listfn)
    (set! nstack (- nstack 1))
    (when (char=? (gref (b (- nstack 1)) 0) #\,) (listfn))
    (define cx (c (- nstack 2))) (define vx (v (- nstack 2)))
    (define cy (c (- nstack 1))) (define vy (v (- nstack 1)))
    (define hx (h (- nstack 2))) (define hy (h (- nstack 1)))
    (define cout (max cx cy)) (define h1 (max (- vx cx) (- vy cy)))
    (define vout (+ cout h1)) (define hout (+ hx hy 1))
    (define temp (clear (* vout hout)))
    (let ([voff (if (> cx cy) 0 (- cy cx))])
      (for* ([i (in-range hx)] [j (in-range vx)])
        (gset! temp (+ (* (+ j voff) hout) i) (gref (b (- nstack 2)) (+ (* j hx) i)))))
    (let ([voff (if (> cy cx) 0 (- cx cy))])
      (for* ([i (in-range hy)] [j (in-range vy)])
        (gset! temp (+ (* (+ j voff) hout) i hx 1) (gref (b (- nstack 1)) (+ (* j hy) i)))))
    (gset! temp (+ (* (- cout 1) hout) hx) #\,)
    (set-c! (- nstack 2) cout) (set-h! (- nstack 2) hout) (set-v! (- nstack 2) vout)
    (set-b! (- nstack 2) temp)
    (set! nstack (- nstack 1)))

  ;; C: paren() — parentheses, tall form for vx>2
  (define (paren)
    (when (char=? (gref (b (- nstack 1)) 0) #\,) (listfn))
    (define me (- nstack 1))
    (define hx (h me)) (define vx (v me))
    (define w (+ hx 2))
    (define temp (clear (* vx w)))
    (for* ([i (in-range hx)] [j (in-range vx)])
      (gset! temp (+ (* j w) i 1) (gref (b me) (+ (* j hx) i))))
    (if (> vx 2)
        (begin
          (for ([j (in-range 1 (- vx 1))])
            (gset! temp (* j w) #\|)
            (gset! temp (+ (* j w) hx 1) #\|))
          (gset! temp 0 #\/)
          (gset! temp (+ (* (- vx 1) w) hx 1) #\/)
          (gset! temp (+ hx 1) #\\)
          (gset! temp (* (- vx 1) w) #\\))
        (begin
          (gset! temp (* (- (c me) 1) w) #\()
          (gset! temp (+ (* (- (c me) 1) w) hx 1) #\))))
    (set-b! me temp) (set-h! me (+ hx 2)))

  ;; C: squarert() — Sqrt[x] = (x)^(1/2)
  (define (squarert)
    (paren)
    (set-b! nstack (string-copy "1/2"))
    (set-h! nstack 3) (set-v! nstack 1) (set-c! nstack 1)
    (set! nstack (+ nstack 1))
    (raise1))

  ;; C: matrix() — Matrix[rows,cols,cellv,cellh,e11,e12,...]
  (define (matrix)
    (define nparms 1)
    (let loop ()
      (when (char=? (gref (b (- nstack 1)) 0) #\,)
        (set! nstack (- nstack 1))
        (set! nparms (+ nparms 1))
        (loop)))
    (define me (+ nstack (- nparms) 4))
    (define n   (getnum (h (- me 4)) (b (- me 4))))
    (define m   (getnum (h (- me 3)) (b (- me 3))))
    (define ver (getnum (h (- me 2)) (b (- me 2))))
    (define hor (getnum (h (- me 1)) (b (- me 1))))
    (define temp (clear (* n m ver hor)))
    (for* ([i (in-range n)] [j (in-range m)])
      (define cell (+ me (* i m) j))
      (define voff (quotient (- ver (v cell)) 2))
      (define hoff (quotient (- hor (h cell)) 2))
      (for* ([k (in-range (v cell))] [l (in-range (h cell))])
        (gset! temp (+ (* i hor m ver) (* j hor) (* (+ k voff) hor m) l hoff)
               (gref (b cell) (+ (* k (h cell)) l)))))
    (set-b! (- me 4) temp)
    (set-h! (- me 4) (* m hor))
    (set-v! (- me 4) (* n ver))
    (set-c! (- me 4) (quotient (+ (* n ver) 1) 2))
    (set! nstack (- me 3)))

  ;; --- token dispatch loop (C: body of doxform) ---
  (for ([cmd (in-list cstack)])
    (cond
      [(member cmd binop)
       => (λ (tl) (binary (list-ref binch (- (length binop) (length tl)))))]
      [(member cmd triop)
       => (λ (tl) (let ([i (- (length triop) (length tl))])
                    (trinary (list-ref trich i) (list-ref trih i) (list-ref triv i))))]
      [(member cmd ovrop)
       => (λ (tl) (ovrhead (list-ref ovrch (- (length ovrop) (length tl)))))]
      [(member cmd nxtop)
       => (λ (tl) (nextto (list-ref nxtch (- (length nxtop) (length tl)))))]
      [(member cmd purop)
       => (λ (tl) (let ([i (- (length purop) (length tl))])
                    (pure (list-ref purch i) (list-ref purh i) (list-ref purv i))))]
      [(or (string=? cmd "Over") (char=? (gref cmd 0) #\%)) (over)]
      [(char=? (gref cmd 0) #\^) (raise1)]
      [(char=? (gref cmd 0) #\') (raise2)]
      [(char=? (gref cmd 0) #\&) (lower)]
      [(char=? (gref cmd 0) #\\) (bkslash)]
      [(string=? cmd "Minus") (minus)]
      [(string=? cmd "Space") (space)]
      [(string=? cmd "Tab") (tab)]
      [(or (string=? cmd "Paren") (char=? (gref cmd 0) #\()) (paren)]
      [(string=? cmd "List") (listfn)]
      [(string=? cmd "Vec") (vec)]
      [(string=? cmd "Abs") (absol)]
      [(string=? cmd "Group") (void)]
      [(string=? cmd "Brace") (surround #\{ #\})]
      [(string=? cmd "Brack") (brack)]
      [(string=? cmd "BoxIt") (boxit)]
      [(string=? cmd "Sqrt") (squarert)]
      [(string=? cmd "Both") (both)]
      [(string=? cmd "SuBoth") (both2)]
      [(string=? cmd "Eval") (evalfn)]
      [(string=? cmd "Bigger") (bigger)]
      [(string=? cmd "Number") (number)]
      [(string=? cmd "Bra") (surround #\< #\|)]
      [(string=? cmd "Ket") (surround #\| #\>)]
      [(string=? cmd "Dirac") (dirac)]
      [(string=? cmd "Matrix") (matrix)]
      [(or (char=? (gref cmd 0) #\[) (char=? (gref cmd 0) #\{)) (void)]
      [else                                  ; literal atom
       (set-v! nstack 1)
       (set-h! nstack (string-length cmd))
       (set-c! nstack 1)
       (set-b! nstack (string-copy cmd))
       (set! nstack (+ nstack 1))]))

  (unless (= nstack 1)
    (eprintf "Error: nstack=~a\nLine ~a: ~a\n" nstack plinec pline))
  (if (> nstack 0)
      (values (b 0) (h 0) (v 0))
      (values "" 0 0)))

;; ---------------------------------------------------------------------
;; doxpre — macro expansion + tokenization into atoms (C: doxpre)
;; Takes the line (after '$') and the mutable macro table; returns the
;; list of atom strings. The macro table is a box holding an ordered
;; list of (name . expansion) pairs.
;; ---------------------------------------------------------------------

;; The C compares macro names with strncmp(...,25): equality on the
;; first 25 characters.
(define (mac-name=? a b)
  (define (cut s) (substring s 0 (min 25 (string-length s))))
  (string=? (cut a) (cut b)))

(define (mac-find macs name)               ; index of macro or #f
  (for/first ([p (in-list macs)] [i (in-naturals)]
              #:when (mac-name=? (car p) name))
    i))

(define (mac-set macs name out)            ; overwrite or append
  (define i (mac-find macs name))
  (if i
      (append (take* macs i) (list (cons name out)) (drop* macs (+ i 1)))
      (append macs (list (cons name out)))))

(define (mac-del macs name)
  (define i (mac-find macs name))
  (if i (append (take* macs i) (drop* macs (+ i 1))) macs))

(define (take* l n) (for/list ([x (in-list l)] [_ (in-range n)]) x))
(define (drop* l n) (if (or (zero? n) (null? l)) l (drop* (cdr l) (- n 1))))

(define (char-index s start ch)            ; first ch at index >= start, or #f
  (for/first ([i (in-range start (string-length s))]
              #:when (char=? (string-ref s i) ch))
    i))

;; Macro-expansion pass: repeat until no replacement occurs (mirrors the
;; C do/while(repl) with restart-after-each-replacement).
(define (expand-macros line0 macbox)
  (let scan ([line line0])
    (define len (string-length line))
    (define result
      (let loop ([j 0])
        (cond
          [(>= j len) #f]
          [(char=? (string-ref line j) #\`)            ; `name` — undefine
           (define k (char-index line (+ j 1) #\`))
           (if k
               (let ([name (substring line (+ j 1) k)])
                 (set-box! macbox (mac-del (unbox macbox) name))
                 (string-append (substring line 0 j) (substring line (+ k 1))))
               (loop (+ j 1)))]
          [(char=? (string-ref line j) #\~)            ; ~name~out~ — define
           (define k (char-index line (+ j 1) #\~))
           (define l (and k (char-index line (+ k 1) #\~)))
           (if l
               (let ([name (substring line (+ j 1) k)]
                     [out  (substring line (+ k 1) l)])
                 (set-box! macbox (mac-set (unbox macbox) name out))
                 (string-append (substring line 0 j) (substring line (+ l 1))))
               (loop (+ j 1)))]
          [else                                        ; try each macro at j
           (define hit
             (for/first ([p (in-list (unbox macbox))]
                         #:when (let ([n (car p)])
                                  (and (<= (+ j (string-length n)) len)
                                       (string=? (substring line j (+ j (string-length n))) n))))
               p))
           (if hit
               (string-append (substring line 0 j) (cdr hit)
                              (substring line (+ j (string-length (car hit)))))
               (loop (+ j 1)))])))
    (if result (scan result) line)))

;; Atom splitter: ports the C state machine (state 0=alpha, 1=number,
;; 2=symbol, -1=start) including the space-elision flag trick.
(define (split-atoms line)
  (define atoms '())                       ; reversed list of reversed char lists
  (define natom 0)
  (define state -1)
  (define atomstart 0)
  (define flag 0)
  (define (new-atom!) (set! atoms (cons '() atoms)) (set! natom (+ natom 1))
    (set! atomstart 0))
  (define (drop-atom!) (set! atoms (cdr atoms)) (set! natom (- natom 1)))
  (for ([ch (in-string line)])
    (when (and (char-alphabetic? ch) (ascii-alpha? ch) (not (= state 0)))
      (set! state 0) (new-atom!))
    (when (and (char-numeric? ch) (ascii-digit? ch) (not (= state 1)))
      (set! state 1) (new-atom!))
    (when (and (not (ascii-alnum? ch))
               (not (and (char=? ch #\.) (= state 1))))
      (set! state 2) (new-atom!))
    (when (and (> flag 0) (= atomstart 0) (> natom 1))
      (set! atoms (cons (car atoms) (cddr atoms)))  ; overwrite previous (space) atom
      (set! natom (- natom 1))
      (set! flag (- flag 1)))
    (when (null? atoms) (new-atom!))       ; safety (cannot occur for ASCII input)
    (set! atoms (cons (cons ch (car atoms)) (cdr atoms)))
    (set! atomstart (+ atomstart 1))
    (when (char=? ch #\space) (set! flag (+ flag 1))))
  (map (λ (a) (list->string (reverse a))) (reverse atoms)))

(define (ascii-alpha? ch)
  (or (char<=? #\a ch #\z) (char<=? #\A ch #\Z)))
(define (ascii-digit? ch) (char<=? #\0 ch #\9))
(define (ascii-alnum? ch) (or (ascii-alpha? ch) (ascii-digit? ch)))

(define (doxpre line macbox)
  (split-atoms (expand-macros line macbox)))

;; ---------------------------------------------------------------------
;; doxparse — precedence-climbing parse to RPN (C: doxparse)
;; ---------------------------------------------------------------------

(define HIGH 6)

(define (doxparse level start end atoms out plinec pline)
  ;; atoms: vector of strings; out: box of reversed token list
  (define (push! s) (set-box! out (cons s (unbox out))))
  (define (atom i) (vector-ref atoms i))
  (if (= level 0)
      (for ([j (in-range start (+ end 1))]) (push! (atom j)))
      (let ([flag 0] [ds 0])
        ;; prefixes at this level
        (for/first ([p (in-list prefixes)] [lv (in-list prefixlvl)]
                    #:when (and (= lv level)
                                (<= start end)
                                (string=? (atom start) p)))
          (doxparse level (+ start 1) end atoms out plinec pline)
          (set! flag (+ flag 1))
          (push! (atom start)))
        ;; delimiter-wrapped expression: restart at highest level
        (unless (> flag 0)
          (for/first ([bd (in-list bdelims)] [ed (in-list edelims)]
                      #:when (and (<= start end)
                                  (string=? (atom start) bd)
                                  (string=? (atom end) ed)))
            (set! flag (+ flag 1))
            (let loop ([dc 1] [i (+ start 1)])
              (when (< i end)
                (let ([dc2 (cond [(string=? (atom i) bd) (+ dc 1)]
                                 [(string=? (atom i) ed) (- dc 1)]
                                 [else dc])])
                  (if (zero? dc2)
                      (set! flag (- flag 1))   ; not a full wrap
                      (loop dc2 (+ i 1))))))
            (when (> flag 0)
              (doxparse HIGH (+ start 1) (- end 1) atoms out plinec pline)
              (push! (atom start)))))
        ;; infixes at this level (leftmost, outside any delimiters)
        (let jloop ([j start])
          (when (and (<= j end) (= flag 0))
            (for ([bd (in-list bdelims)] [ed (in-list edelims)])
              (cond [(string=? (atom j) bd) (set! ds (+ ds 1))]
                    [(string=? (atom j) ed) (set! ds (- ds 1))]))
            (when (zero? ds)
              (for/first ([inf (in-list infixes)] [lv (in-list infixlvl)]
                          #:when (and (= lv level) (string=? (atom j) inf)))
                (set! flag (+ flag 1))
                (doxparse level start (- j 1) atoms out plinec pline)
                (doxparse level (+ j 1) end atoms out plinec pline)
                (push! (atom j))))
            (jloop (+ j 1))))
        (when (= flag 0)
          (doxparse (- level 1) start end atoms out plinec pline))
        (unless (zero? ds)
          (eprintf "Bad # of delimeters! (~a)\nLine ~a: ~a\n" ds plinec pline)))))

;; ---------------------------------------------------------------------
;; fgets simulation — preserves the C program's line-reading semantics,
;; including buffer-size splitting (250 for normal lines, 25 for macro
;; names) and the feof() check that drops a final unterminated line.
;; ---------------------------------------------------------------------

(define (make-reader str)
  (define pos 0)
  (define len (string-length str))
  (define eof-flag #f)
  (define (feof?) eof-flag)
  (define (fgets n)                        ; -> string or #f
    (if (>= pos len)
        (begin (set! eof-flag #t) #f)
        (let loop ([acc '()] [cnt 0])
          (cond
            [(>= cnt (- n 1)) (list->string (reverse acc))]
            [(>= pos len)
             (set! eof-flag #t)
             (list->string (reverse acc))]
            [else
             (define ch (string-ref str pos))
             (set! pos (+ pos 1))
             (if (char=? ch #\newline)
                 (list->string (reverse (cons ch acc)))
                 (loop (cons ch acc) (+ cnt 1)))]))))
  (values fgets feof?))

(define (chomp s)                          ; C: if(in[j-1]=='\n') in[j-1]=0
  (define j (string-length s))
  (if (and (> j 0) (char=? (string-ref s (- j 1)) #\newline))
      (substring s 0 (- j 1))
      s))

;; ---------------------------------------------------------------------
;; dox — the whole program (C: main), minus the file I/O.
;; ---------------------------------------------------------------------

(define (dox input #:page-length [pl 0])
  (define-values (fgets feof?) (make-reader input))
  (define out (open-output-string))
  (define macbox (box '()))
  (define plinec 0)
  (define line-count 0)                    ; C: `line` (page-fill counter)
  (let loop ()
    (unless (feof?)
      (define in (fgets 250))
      (when in
        (set! plinec (+ plinec 1))
        (define ln (chomp in))
        (unless (feof?)
          (cond
            ;; $DEFINE: next two lines are macro name (<=24 chars read)
            ;; and macro expansion
            [(string=? ln "$DEFINE")
             (define name-raw (fgets 25))
             (set! plinec (+ plinec 1))
             (define name (chomp (or name-raw "")))
             (define out-raw (fgets 250))
             (set! plinec (+ plinec 1))
             (define expansion (chomp (or out-raw "")))
             (set-box! macbox (mac-set (unbox macbox) name expansion))]
            ;; formula line
            [(and (> (string-length ln) 0) (char=? (string-ref ln 0) #\$))
             (define body (substring ln 1))
             (define atoms (doxpre body macbox))
             (define natom (length atoms))
             (if (zero? natom)
                 (eprintf "Empty formula on line ~a\n" plinec)
                 (let ([rpn (box '())])
                   (doxparse HIGH 0 (- natom 1) (list->vector atoms)
                             rpn plinec body)
                   (define-values (grid hh vv)
                     (doxform (reverse (unbox rpn)) plinec body))
                   (when (and (> pl 0) (> (+ line-count vv) pl))
                     (write-string "\f\n" out)
                     (set! line-count 0))
                   (for ([j (in-range vv)])     ; C: fpblock()
                     (for ([i (in-range hh)])
                       (write-char (gref grid (+ (* j hh) i)) out))
                     (write-char #\newline out))
                   (set! line-count (+ line-count vv))))]
            ;; pass-through line
            [else
             (when (and (> pl 0) (> (+ line-count 1) pl))
               (write-string "\f\n" out)
               (set! line-count 0))
             (write-string ln out)
             (write-char #\newline out)
             (set! line-count (+ line-count 1))])))
      (loop)))
  (when (> pl 0) (write-string "\f\n" out))
  (get-output-string out))

;; ---------------------------------------------------------------------
;; Command-line shim for testing: racket doxjr.rkt < in.tch > out.tc1
;; ---------------------------------------------------------------------
(module+ main
  (require racket/port)
  (define args (current-command-line-arguments))
  (define pl (if (> (vector-length args) 0)
                 (or (string->number (vector-ref args 0)) 0)
                 0))
  (display (dox (port->string (current-input-port)) #:page-length pl)))

;; vim: set et ff=unix ft=racket nocp sts=2 sw=2 ts=2:
