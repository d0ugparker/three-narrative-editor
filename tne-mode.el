(add-to-list 'load-path (file-name-directory (or load-file-name buffer-file-name)))
(require 'tne-model)(require 'tne-render)
(defvar tne-mode-map (let ((m (make-sparse-keymap)))
 (define-key m (kbd "C-c C-2 a") #'tne-add-n2-segment)
 (define-key m (kbd "C-c C-3 a") #'tne-add-n3-segment)
 (define-key m (kbd "C-c C-r") #'tne-redraw) m))
(defun tne-redraw () (interactive)
 (let ((inhibit-read-only t))
  (erase-buffer)
  (insert (tne-document-narrative-1 tne-current-document) "\n")
  (insert (tne-render-segments (tne-document-n2-segments tne-current-document)) "\n")
  (insert (tne-render-segments (tne-document-n3-segments tne-current-document)) "\n")))

(defun tne-first-word-length (text)
(length (car (split-string text "[ \t]+" t))))

(defun tne-minimum-width (text)
(max 10 (tne-first-word-length text)))

(defun tne-territory-overlap-p (start1 width1 start2 width2)
(let ((end1 (+ start1 width1 -1))
(end2 (+ start2 width2 -1)))
(not (or (< end1 start2)
(< end2 start1)))))

(defun tne-add-segment (n)
(let ((c (read-number "Start column: "))
(txt (read-string "Segment text: ")))

(let* ((new-width (tne-minimum-width txt))
       (collision nil)
       (segments (if (= n 2)
                     (tne-document-n2-segments tne-current-document)
                     (tne-document-n3-segments tne-current-document))))

  (dolist (s segments)
    (let* ((existing-start
            (tne-segment-start-column s))
           (existing-width
            (tne-minimum-width
             (tne-segment-text s))))

      (when (tne-territory-overlap-p
             c new-width
             existing-start existing-width)
        (setq collision t))))

  (if collision
      (message "Not enough space to add this segment.")

    (let ((s (make-tne-segment
              :start-column c
              :text txt)))

      (if (= n 2)
          (setf (tne-document-n2-segments tne-current-document)
                (cons s
                      (tne-document-n2-segments
                       tne-current-document)))
        (setf (tne-document-n3-segments tne-current-document)
              (cons s
                    (tne-document-n3-segments
                     tne-current-document))))

      (tne-redraw))))))

(defun tne-add-n2-segment()(interactive)(tne-add-segment 2))
(defun tne-add-n3-segment()(interactive)(tne-add-segment 3))
(define-derived-mode tne-mode special-mode "TNE"
 (setq tne-current-document (tne-model-create-default))
 (setq buffer-read-only nil)(tne-redraw))
(provide 'tne-mode)
