;;; tne-mode.el --- Three Narrative Editor major mode -*- lexical-binding: t; -*-

;; Version: 0.1.0

;;; Commentary:

;; First clean major mode package for the Three Narrative Editor.
;;
;; Version 0.1.0 goal:
;;
;;   Prove the separation between:
;;
;;     stored model:
;;       three independent narratives
;;
;;     rendered display:
;;       woven rows
;;
;; This version is command-based. Direct editing of the woven display is
;; intentionally deferred.

;;; Code:

(require 'cl-lib)

(defvar tne-mode-directory
  (file-name-directory (or load-file-name buffer-file-name))
  "Directory containing TNE files.")

(add-to-list 'load-path tne-mode-directory)

(require 'tne-model)
(require 'tne-render)

(defgroup tne nil
  "Three Narrative Editor."
  :group 'editing)

(defface tne-narrative-1-face
  '((t :weight bold))
  "Face for Narrative 1 rows."
  :group 'tne)

(defface tne-narrative-2-face
  '((t :slant italic))
  "Face for Narrative 2 rows."
  :group 'tne)

(defface tne-narrative-3-face
  '((t :foreground "gray50"))
  "Face for Narrative 3 rows."
  :group 'tne)

(defvar tne-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-c C-1") #'tne-set-narrative-1)
    (define-key map (kbd "C-c C-2") #'tne-set-narrative-2)
    (define-key map (kbd "C-c C-3") #'tne-set-narrative-3)
    (define-key map (kbd "C-c C-r") #'tne-render-refresh)
    (define-key map (kbd "C-c C-s") #'tne-show-model)
    map)
  "Keymap for `tne-mode'.")

(defun tne--read-narrative (n)
  "Read text for narrative N."
  (read-string (format "Narrative %s text: " n) (tne-model-get n)))

(defun tne-set-narrative (n)
  "Set narrative N, then refresh display."
  (interactive "nNarrative number: ")
  (tne-model-set n (tne--read-narrative n))
  (tne-render-refresh))

(defun tne-set-narrative-1 ()
  "Set Narrative 1."
  (interactive)
  (tne-set-narrative 1))

(defun tne-set-narrative-2 ()
  "Set Narrative 2."
  (interactive)
  (tne-set-narrative 2))

(defun tne-set-narrative-3 ()
  "Set Narrative 3."
  (interactive)
  (tne-set-narrative 3))

(defun tne--apply-row-faces ()
  "Apply faces to rendered rows."
  (save-excursion
    (goto-char (point-min))
    (let ((row 0))
      (while (not (eobp))
        (let ((role (mod row 4)))
          (pcase role
            (0 (add-text-properties
                (line-beginning-position) (line-end-position)
                '(face tne-narrative-1-face)))
            (1 (add-text-properties
                (line-beginning-position) (line-end-position)
                '(face tne-narrative-2-face)))
            (2 (add-text-properties
                (line-beginning-position) (line-end-position)
                '(face tne-narrative-3-face)))))
        (setq row (1+ row))
        (forward-line 1)))))

(defun tne-render-refresh ()
  "Refresh rendered woven display."
  (interactive)
  (let ((inhibit-read-only t))
    (erase-buffer)
    (tne-render-insert)
    (goto-char (point-min))
    (tne--apply-row-faces)
    (setq buffer-read-only t)))

(defun tne-show-model ()
  "Show stored narrative model in a temporary buffer."
  (interactive)
  (let ((buf (get-buffer-create "*TNE Model*")))
    (with-current-buffer buf
      (erase-buffer)
      (insert "Narrative 1:\n")
      (insert (tne-model-get 1))
      (insert "\n\nNarrative 2:\n")
      (insert (tne-model-get 2))
      (insert "\n\nNarrative 3:\n")
      (insert (tne-model-get 3))
      (insert "\n"))
    (display-buffer buf)))

;;;###autoload
(define-derived-mode tne-mode special-mode "TNE"
  "Major mode for Three Narrative Editor."
  (setq-local tne-current-document (tne-model-create-default))
  (setq-local buffer-read-only nil)
  (tne-render-refresh)
  (message "TNE 0.1.0 loaded. Use C-c C-1, C-c C-2, C-c C-3."))

(provide 'tne-mode)

;;; tne-mode.el ends here
