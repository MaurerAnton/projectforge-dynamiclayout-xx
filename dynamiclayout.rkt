#lang racket/base
;; DynamicLayout Racket/Scheme API — generate layout JSON from Scheme code.
;; Single-file. Zero dependencies. Works on Racket 8+, Guile 3+, Chicken 5+.
;;
;; Example:
;;   (require "dynamiclayout.rkt")
;;   (define b (dl-begin "My Page"))
;;   (dl-fieldset b "Info")
;;   (dl-label b "Hello from Scheme!")
;;   (dl-end-fieldset b)
;;   (dl-button b "ok" "OK" "primary" #t)
;;   (display (dl-end b))

(provide dl-begin dl-end dl-fieldset dl-end-fieldset dl-row dl-end-row
         dl-label dl-alert dl-badge dl-spacer dl-input dl-checkbox
         dl-textarea dl-rating dl-button dl-section)

(define (dl-begin title)
  (list "{\"ui\":{" 2 #f 0 title))

(define (dl-end b)
  (match-define (list buf depth comma cnt _) b)
  (string-append buf "],\"translations\":{},\"userAccess\":{\"cancel\":true}}}"))

(define (dl-putc b c) (match-define (list buf d c? n t) b) (list (string-append buf (string c)) d c? n t))
(define (dl-puts b s) (match-define (list buf d c? n t) b) (list (string-append buf s) d c? n t))
(define (dl-indent b) (match-define (list buf d c? n t) b) (list (string-append buf "\n" (make-string (* d 2) #\space)) d c? n t))
(define (dl-cm b) (match-define (list buf d c? n t) b) (if c? (list (string-append buf ",") d #f n t) (list buf d #f n t)))
(define (dl-esc b s) (match-define (list buf d c? n t) b) (list (string-append buf "\"" (regexp-replace* #rx"\"" (regexp-replace* #rx"\\\\" s "\\\\\\\\") "\\\\\"") "\"") d c? n t))
(define (dl-kv b k v) (let* ((b (dl-cm b)) (b (dl-putc b #\,)) (b (dl-indent b)) (b (dl-esc b k)) (b (dl-puts b ": ")) (b (dl-esc b v))) (match-define (list buf d _ n t) b) (list buf d #t n t)))
(define (dl-kvint b k v) (let* ((b (dl-cm b)) (b (dl-putc b #\,)) (b (dl-indent b)) (b (dl-esc b k)) (b (dl-puts b (format ": ~a" v)))) (match-define (list buf d _ n t) b) (list buf d #t n t)))
(define (dl-kvbool b k) (let* ((b (dl-cm b)) (b (dl-putc b #\,)) (b (dl-indent b)) (b (dl-esc b k)) (b (dl-puts b ": true"))) (match-define (list buf d _ n t) b) (list buf d #t n t)))
(define (dl-obj b) (let* ((b (dl-cm b)) (b (dl-putc b #\,)) (b (dl-indent b)) (b (dl-putc b #\{))) (match-define (list buf d _ n t) b) (list buf (+ d 1) #f n t)))
(define (dl-co b) (let* ((b (dl-indent (list (car b) (- (cadr b) 1) (caddr b) (cadddr b) (car (cddddr b))))) (b (dl-putc b #\}))) (match-define (list buf d _ n t) b) (list buf d #t n t)))
(define (dl-arr b k) (let* ((b (dl-cm b)) (b (dl-putc b #\,)) (b (dl-indent b)) (b (dl-esc b k)) (b (dl-puts b ": ["))) (match-define (list buf d _ n t) b) (list buf (+ d 1) #f n t)))
(define (dl-ca b) (let* ((b (dl-indent (list (car b) (- (cadr b) 1) (caddr b) (cadddr b) (car (cddddr b))))) (b (dl-putc b #\]))) (match-define (list buf d _ n t) b) (list buf d #t n t)))
(define (dl-key b p) (match-define (list buf d c? n t) b) (let ((n2 (+ n 1))) (list (values (list buf d c? n2 t) (format "~a_~a" p n2)))))

(define-syntax-rule (with-key b p body) (let-values (((b k) (dl-key b p))) body))

(define (dl-fieldset b title) (let-values (((b k) (dl-key b "fs"))) (let* ((b (dl-obj b)) (b (dl-kv b "type" "FIELDSET")) (b (dl-kv b "key" k)) (b (dl-kv b "title" title)) (b (dl-arr b "content"))) b)))
(define (dl-end-fieldset b) (let* ((b (dl-ca b)) (b (dl-co b))) b))
(define (dl-row b) (let-values (((b k) (dl-key b "r"))) (let* ((b (dl-obj b)) (b (dl-kv b "type" "ROW")) (b (dl-kv b "key" k)) (b (dl-arr b "content"))) b)))
(define (dl-end-row b) (let* ((b (dl-ca b)) (b (dl-co b))) b))
(define (dl-label b text) (let-values (((b k) (dl-key b "l"))) (let* ((b (dl-obj b)) (b (dl-kv b "type" "LABEL")) (b (dl-kv b "key" k)) (b (dl-kv b "label" text)) (b (dl-co b))) b)))
(define (dl-alert b msg (color "info")) (let-values (((b k) (dl-key b "a"))) (let* ((b (dl-obj b)) (b (dl-kv b "type" "ALERT")) (b (dl-kv b "key" k)) (b (dl-kv b "message" msg)) (b (dl-kv b "color" color)) (b (dl-co b))) b)))
(define (dl-badge b title (color "primary")) (let-values (((b k) (dl-key b "bd"))) (let* ((b (dl-obj b)) (b (dl-kv b "type" "BADGE")) (b (dl-kv b "key" k)) (b (dl-kv b "title" title)) (b (dl-kv b "color" color)) (b (dl-co b))) b)))
(define (dl-spacer b (px 20)) (let-values (((b k) (dl-key b "sp"))) (let* ((b (dl-obj b)) (b (dl-kv b "type" "SPACER")) (b (dl-kv b "key" k)) (b (dl-kvint b "width" px)) (b (dl-co b))) b)))
(define (dl-input b id label (required #f)) (let-values (((b k) (dl-key b "i"))) (let* ((b (dl-obj b)) (b (dl-kv b "type" "INPUT")) (b (dl-kv b "key" k)) (b (dl-kv b "id" id)) (b (dl-kv b "label" label)) (b (if required (dl-kvbool b "required") b)) (b (dl-co b))) b)))
(define (dl-checkbox b id (label "")) (let-values (((b k) (dl-key b "cb"))) (let* ((b (dl-obj b)) (b (dl-kv b "type" "CHECKBOX")) (b (dl-kv b "key" k)) (b (dl-kv b "id" id)) (b (dl-kv b "label" label)) (b (dl-co b))) b)))
(define (dl-textarea b id label (rows 3)) (let-values (((b k) (dl-key b "ta"))) (let* ((b (dl-obj b)) (b (dl-kv b "type" "TEXTAREA")) (b (dl-kv b "key" k)) (b (dl-kv b "id" id)) (b (dl-kv b "label" label)) (b (if (> rows 0) (dl-kvint b "rows" rows) b)) (b (dl-co b))) b)))
(define (dl-rating b id (label "")) (let-values (((b k) (dl-key b "rt"))) (let* ((b (dl-obj b)) (b (dl-kv b "type" "RATING")) (b (dl-kv b "key" k)) (b (dl-kv b "id" id)) (b (dl-kv b "label" label)) (b (dl-co b))) b)))
(define (dl-button b id title color (is-default #f)) (let-values (((b k) (dl-key b "btn"))) (let* ((b (dl-obj b)) (b (dl-kv b "type" "BUTTON")) (b (dl-kv b "key" k)) (b (dl-kv b "id" id)) (b (dl-kv b "title" title)) (b (dl-kv b "color" color)) (b (if is-default (dl-kvbool b "default") b)) (b (dl-co b))) b)))
(define (dl-section b title text) (dl-end-fieldset (dl-label (dl-fieldset b title) text)))
