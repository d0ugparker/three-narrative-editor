;;; tne-render.el --- Three Narrative Editor renderer -*- lexical-binding: t; -*-

;; Version: 0.1.0

;;; Commentary:

;; This file renders three independent narrative strings into a woven display.
;;
;; Design rule:
;;
;;   Stored model:
;;     Narrative 1 string
;;     Narrative 2 string
;;     Narrative 3 string
;;
;;   Rendered display:
;;     Narrative 1 row 1
;;     Narrative 2 row 1
;;     Narrative 3 row 1
;;
;;     Narrative 1 row 2
;;     Narrative 2 row 2
;;     Narrative 3 row 2
;;
;; Version 0.1.0 uses monospaced character columns.

;;; Code:

(require 'cl-lib)
(require 'tne-model)

(defcustom tne-render-width 60
  "Monospace render width for each narrative row."
  :type 'integer
  :group 'tne)

(defun tne-render--words (text)
  "Split TEXT into words while dropping empty tokens."
  (split-string text "[ \t\n]+" t))

(defun tne-render-wrap-text (text width)
  "Wrap TEXT into a list of rows no wider than WIDTH.
This is a simple word-wrapper for Version 0.1.0."
  (let ((words (tne-render--words text))
        (rows nil)
        (line ""))
    (dolist (word words)
      (cond
       ((string-empty-p line)
        (setq line word))
       ((<= (+ (length line) 1 (length word)) width)
        (setq line (concat line " " word)))
       (t
        (push line rows)
        (setq line word))))
    (when (or rows (not (string-empty-p line)))
      (push line rows))
    (nreverse rows)))

(defun tne-render--pad-rows (rows target)
  "Pad ROWS to TARGET rows with empty strings."
  (let ((copy (copy-sequence rows)))
    (while (< (length copy) target)
      (setq copy (append copy (list ""))))
    copy))

(defun tne-render-woven-lines (&optional doc)
  "Return woven display lines for DOC or current document."
  (let* ((doc (or doc (tne-model-ensure-document)))
         (rows1 (tne-render-wrap-text (tne-document-narrative-1 doc) tne-render-width))
         (rows2 (tne-render-wrap-text (tne-document-narrative-2 doc) tne-render-width))
         (rows3 (tne-render-wrap-text (tne-document-narrative-3 doc) tne-render-width))
         (maxrows (max 1 (length rows1) (length rows2) (length rows3)))
         (rows1 (tne-render--pad-rows rows1 maxrows))
         (rows2 (tne-render--pad-rows rows2 maxrows))
         (rows3 (tne-render--pad-rows rows3 maxrows))
         (out nil))
    (dotimes (i maxrows)
      (push (nth i rows1) out)
      (push (nth i rows2) out)
      (push (nth i rows3) out)
      (push "" out))
    (nreverse out)))

(defun tne-render-string (&optional doc)
  "Return full rendered woven display string."
  (mapconcat #'identity (tne-render-woven-lines doc) "\n"))

(defun tne-render-insert (&optional doc)
  "Insert rendered woven display for DOC or current document."
  (insert (tne-render-string doc)))

(provide 'tne-render)

;;; tne-render.el ends here
