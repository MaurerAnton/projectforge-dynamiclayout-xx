;;; DynamicLayout Common Lisp API — generate layout JSON from Common Lisp code.
;;; Single-file. Zero dependencies outside ANSI Common Lisp.
;;; Works on SBCL, CCL, ECL, ABCL, CLISP.
;;;
;;; Example:
;;;   (load "dynamiclayout.lisp")
;;;   (let ((b (dl-begin "My Page")))
;;;     (dl-fieldset b "Info")
;;;     (dl-label b "Hello from Lisp!")
;;;     (dl-end-fieldset b)
;;;     (dl-button b "ok" "OK" "primary" t)
;;;     (format t "~a~%" (dl-end b)))

(defpackage :dynamiclayout
  (:use :cl)
  (:export :dl-begin :dl-end
           :dl-fieldset :dl-end-fieldset
           :dl-label :dl-alert :dl-badge :dl-spacer
           :dl-input :dl-checkbox :dl-rating
           :dl-button :dl-section))

(in-package :dynamiclayout)

(defstruct builder
  (buf (make-array 4096 :element-type 'character :fill-pointer 0 :adjustable t))
  (depth 0 :type fixnum)
  (comma nil)
  (cnt 0 :type fixnum))

(defun dl-putc (b c) (vector-push-extend c (builder-buf b)) b)
(defun dl-puts (b s) (loop for c across s do (dl-putc b c)) b)
(defun dl-indent (b)
  (dl-putc b #\Newline)
  (loop repeat (builder-depth b) do (dl-puts b "  "))
  b)
(defun dl-cm (b)
  (when (builder-comma b) (dl-putc b #\,))
  (setf (builder-comma b) nil)
  b)
(defun dl-esc (b s)
  (dl-putc b #\")
  (loop for c across s do
    (case c
      (#\" (dl-puts b "\\\""))
      (#\\ (dl-puts b "\\\\"))
      (#\Newline (dl-puts b "\\n"))
      (#\Return (dl-puts b "\\r"))
      (#\Tab (dl-puts b "\\t"))
      (t (dl-putc b c))))
  (dl-putc b #\"))

(defun dl-kv (b k v)
  (dl-cm b) (dl-putc b #\,) (dl-indent b)
  (dl-esc b k) (dl-puts b ": ") (dl-esc b v)
  (setf (builder-comma b) t) b)

(defun dl-kvint (b k v)
  (dl-cm b) (dl-putc b #\,) (dl-indent b)
  (dl-esc b k) (dl-puts b (format nil ": ~d" v))
  (setf (builder-comma b) t) b)

(defun dl-kvbool (b k)
  (dl-cm b) (dl-putc b #\,) (dl-indent b)
  (dl-esc b k) (dl-puts b ": true")
  (setf (builder-comma b) t) b)

(defun dl-obj (b)
  (dl-cm b) (dl-putc b #\,) (dl-indent b) (dl-putc b #\{)
  (incf (builder-depth b)) (setf (builder-comma b) nil) b)

(defun dl-co (b)
  (decf (builder-depth b)) (dl-indent b) (dl-putc b #\})
  (setf (builder-comma b) t) b)

(defun dl-arr (b k)
  (dl-cm b) (dl-putc b #\,) (dl-indent b) (dl-esc b k) (dl-puts b ": [")
  (incf (builder-depth b)) (setf (builder-comma b) nil) b)

(defun dl-ca (b)
  (decf (builder-depth b)) (dl-indent b) (dl-putc b #\])
  (setf (builder-comma b) t) b)

(defun dl-key (b prefix)
  (incf (builder-cnt b))
  (format nil "~a_~d" prefix (builder-cnt b)))

;; Public
(defun dl-begin (title)
  (let ((b (make-builder)))
    (dl-puts b "{\"ui\":{")
    (setf (builder-depth b) 2 (builder-comma b) nil)
    (dl-kv b "title" title)
    (dl-arr b "layout")
    b))

(defun dl-end (b)
  (dl-ca b)
  (setf (builder-comma b) nil) (dl-putc b #\,)
  (dl-puts b "\"translations\":{},")
  (dl-puts b "\"userAccess\":{\"cancel\":true}")
  (dl-puts b "}}")
  (builder-buf b))

(defun dl-fieldset (b title)
  (dl-obj b) (dl-kv b "type" "FIELDSET") (dl-kv b "key" (dl-key b "fs"))
  (dl-kv b "title" title) (dl-arr b "content") b)
(defun dl-end-fieldset (b) (dl-ca b) (dl-co b) b)

(defun dl-label (b text)
  (dl-obj b) (dl-kv b "type" "LABEL") (dl-kv b "key" (dl-key b "l"))
  (dl-kv b "label" text) (dl-co b) b)
(defun dl-alert (b msg &optional (color "info"))
  (dl-obj b) (dl-kv b "type" "ALERT") (dl-kv b "key" (dl-key b "a"))
  (dl-kv b "message" msg) (dl-kv b "color" color) (dl-co b) b)
(defun dl-badge (b title &optional (color "primary"))
  (dl-obj b) (dl-kv b "type" "BADGE") (dl-kv b "key" (dl-key b "bd"))
  (dl-kv b "title" title) (dl-kv b "color" color) (dl-co b) b)
(defun dl-spacer (b &optional (px 20))
  (dl-obj b) (dl-kv b "type" "SPACER") (dl-kv b "key" (dl-key b "sp"))
  (dl-kvint b "width" px) (dl-co b) b)
(defun dl-input (b id label &optional (required nil))
  (dl-obj b) (dl-kv b "type" "INPUT") (dl-kv b "key" (dl-key b "i"))
  (dl-kv b "id" id) (dl-kv b "label" label)
  (when required (dl-kvbool b "required")) (dl-co b) b)
(defun dl-checkbox (b id &optional (label ""))
  (dl-obj b) (dl-kv b "type" "CHECKBOX") (dl-kv b "key" (dl-key b "cb"))
  (dl-kv b "id" id) (dl-kv b "label" label) (dl-co b) b)
(defun dl-rating (b id &optional (label ""))
  (dl-obj b) (dl-kv b "type" "RATING") (dl-kv b "key" (dl-key b "rt"))
  (dl-kv b "id" id) (dl-kv b "label" label) (dl-co b) b)
(defun dl-button (b id title color &optional (default nil))
  (dl-obj b) (dl-kv b "type" "BUTTON") (dl-kv b "key" (dl-key b "btn"))
  (dl-kv b "id" id) (dl-kv b "title" title) (dl-kv b "color" color)
  (when default (dl-kvbool b "default")) (dl-co b) b)
(defun dl-section (b title text)
  (dl-fieldset b title) (dl-label b text) (dl-end-fieldset b) b)
