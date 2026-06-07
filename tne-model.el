;;; tne-model.el --- Three Narrative Editor model -*- lexical-binding: t; -*-

;; Version: 0.1.0

;;; Commentary:

;; This file stores the document model for the Three Narrative Editor.
;;
;; Design rule:
;;   The document model is separate from the rendered display.
;;
;; Version 0.1.0 stores three independent narrative strings.

;;; Code:

(require 'cl-lib)

(cl-defstruct tne-document
  "Three Narrative Editor document model."
  (narrative-1 "" :type string)
  (narrative-2 "" :type string)
  (narrative-3 "" :type string))

(defvar-local tne-current-document nil
  "Buffer-local Three Narrative Editor document.")

(defun tne-model-create-default ()
  "Create a default TNE document."
  (make-tne-document
   :narrative-1 "Narrative 1"
   :narrative-2 ""
   :narrative-3 ""))

(defun tne-model-ensure-document ()
  "Ensure current buffer has a TNE document."
  (unless tne-current-document
    (setq tne-current-document (tne-model-create-default)))
  tne-current-document)

(defun tne-model-get (n)
  "Return narrative N as a string."
  (let ((doc (tne-model-ensure-document)))
    (pcase n
      (1 (tne-document-narrative-1 doc))
      (2 (tne-document-narrative-2 doc))
      (3 (tne-document-narrative-3 doc))
      (_ (error "Narrative must be 1, 2, or 3")))))

(defun tne-model-set (n text)
  "Set narrative N to TEXT."
  (let ((doc (tne-model-ensure-document)))
    (pcase n
      (1 (setf (tne-document-narrative-1 doc) text))
      (2 (setf (tne-document-narrative-2 doc) text))
      (3 (setf (tne-document-narrative-3 doc) text))
      (_ (error "Narrative must be 1, 2, or 3")))))

(defun tne-model-as-list ()
  "Return current narratives as a list."
  (list (tne-model-get 1)
        (tne-model-get 2)
        (tne-model-get 3)))

(provide 'tne-model)

;;; tne-model.el ends here
