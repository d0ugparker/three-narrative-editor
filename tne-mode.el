(add-to-list 'load-path (file-name-directory (or load-file-name buffer-file-name)))
(require 'tne-model)(require 'tne-render)
(defvar tne-mode-map (let ((m (make-sparse-keymap)))
 (define-key m (kbd "C-c C-2 a") #'tne-add-n2-segment)
 (define-key m (kbd "C-c C-3 a") #'tne-add-n3-segment)
 (define-key m (kbd "C-c C-r") #'tne-redraw)
 (define-key m (kbd "C-c C-l") #'tne-layout-report)
 (define-key m (kbd "C-c C-w") #'tne-wrap-report)
 (define-key m (kbd "C-c C-2 d") #'tne-delete-n2-segment)
 (define-key m (kbd "C-c C-2 d") #'tne-delete-n2-segment)
 (define-key m (kbd "C-c C-3 d") #'tne-delete-n3-segment)
 (define-key m (kbd "C-c C-2 e") #'tne-edit-n2-segment)
 (define-key m (kbd "C-c C-3 e") #'tne-edit-n3-segment) m))

(defun tne-layout-record-report ()
  (interactive)

  (with-output-to-temp-buffer
      "*TNE Layout Records*"

    (dolist (r tne-layout-records)

      (princ
       (format
        "id=%s start=%s width=%s height=%s\n"

        (tne-layout-record-segment-id r)
        (tne-layout-record-start r)
        (tne-layout-record-width r)
        (tne-layout-record-height r)))

      (dolist (row
               (tne-layout-record-rows r))

        (princ
         (format
          "  %s\n"
          row)))

      (princ "\n"))))

(defun tne-edit-segment (n)
  (let* ((c (read-number "Edit segment at column: "))
         (segments
          (if (= n 2)
              (tne-document-n2-segments tne-current-document)
            (tne-document-n3-segments tne-current-document)))

         (segment
          (cl-find-if
           (lambda (s)
             (= (tne-segment-start-column s)
                c))
           segments)))

    (if segment

        (progn

          (setf (tne-segment-text segment)
                (read-string
                 "New text: "
                 (tne-segment-text segment)))
	  
          (tne-redraw))

      (message "No segment found."))))

(defun tne-edit-n2-segment ()
  (interactive)
  (tne-edit-segment 2))

(defun tne-edit-n3-segment ()
  (interactive)
  (tne-edit-segment 3))

(defun tne-redraw () (interactive)
  (let ((inhibit-read-only t))
  (setq tne-layout-records nil)

  (erase-buffer)
  (insert (tne-document-narrative-1 tne-current-document) "\n")
  (insert (tne-render-segments (tne-document-n2-segments tne-current-document)) "\n")
  (insert (tne-render-segments (tne-document-n3-segments tne-current-document)) "\n")))

(defun tne-delete-segment (n)
  (let ((c (read-number "Delete segment at column: ")))

    (if (= n 2)

        (setf (tne-document-n2-segments tne-current-document)
              (cl-remove-if
               (lambda (s)
                 (= (tne-segment-start-column s)
                    c))
               (tne-document-n2-segments
                tne-current-document)))

      (setf (tne-document-n3-segments tne-current-document)
            (cl-remove-if
             (lambda (s)
               (= (tne-segment-start-column s)
                  c))
             (tne-document-n3-segments
              tne-current-document))))

    (tne-redraw)))

(defun tne-delete-n2-segment ()
  (interactive)
  (tne-delete-segment 2))

(defun tne-delete-n3-segment ()
  (interactive)
  (tne-delete-segment 3))

(defun tne-delete-n2-segment ()
  (interactive)

  (let ((c (read-number "Delete N2 segment at column: ")))

    (setf (tne-document-n2-segments tne-current-document)
          (cl-remove-if
           (lambda (s)
             (= (tne-segment-start-column s)
                c))
           (tne-document-n2-segments
            tne-current-document)))

    (tne-redraw)))

(defun tne-first-word-length (text)
(length (car (split-string text "[ \t]+" t))))

(defun tne-minimum-width (text)
(max 10 (tne-first-word-length text)))

(defun tne-compute-layout (segments)
  (let* ((sorted
          (sort (copy-sequence segments)
                (lambda (a b)
                  (< (tne-segment-start-column a)
                     (tne-segment-start-column b)))))
         (result nil))

    (while sorted
      (let* ((s (car sorted))
             (start (tne-segment-start-column s))
             (next (cadr sorted))
             (available-width
              (if next
                  (- (tne-segment-start-column next)
                     start)
                (- (window-width)
                   start
                   -1))))

        (push
         (list
          :segment s
          :start start
          :available-width available-width
          :minimum-width
          (tne-minimum-width
           (tne-segment-text s))
          :valid
          (>= available-width
              (tne-minimum-width
               (tne-segment-text s))))
         result))

      (setq sorted (cdr sorted)))

    (nreverse result)))

(defun tne-layout-report ()
  (interactive)

  (with-output-to-temp-buffer "*TNE Layout*"

    (princ "Narrative 2\n")
    (princ "-----------\n")

    (dolist (entry
             (tne-compute-layout
              (tne-document-n2-segments
               tne-current-document)))

      (princ
       (format
        "start=%s width=%s minimum=%s valid=%s\n"
        (plist-get entry :start)
        (plist-get entry :available-width)
        (plist-get entry :minimum-width)
        (plist-get entry :valid))))

    (princ "\nNarrative 3\n")
    (princ "-----------\n")

    (dolist (entry
             (tne-compute-layout
              (tne-document-n3-segments
               tne-current-document)))

      (princ
       (format
        "start=%s width=%s minimum=%s valid=%s\n"
        (plist-get entry :start)
        (plist-get entry :available-width)
        (plist-get entry :minimum-width)
        (plist-get entry :valid))))))

(defun tne-wrap-report ()
  (interactive)

  (let* ((txt (read-string "Text: "))
         (width (read-number "Width: "))
         (result (tne-wrap-text txt width)))

    (with-output-to-temp-buffer "*TNE Wrap*"

      (princ
       (format
        "height=%s\n"
        (plist-get result :height)))

      (princ
       (format
        "forced-splits=%s\n\n"
        (plist-get result :forced-splits)))

      (dolist (line
               (plist-get result :lines))

        (princ line)
        (princ "\n")))))

(defun tne-territory-overlap-p (start1 width1 start2 width2)
(let ((end1 (+ start1 width1 -1))
(end2 (+ start2 width2 -1)))
(not (or (< end1 start2)
(< end2 start1)))))

(defun tne-add-segment (n)
(let ((c (read-number "Start column: "))
(txt (read-string "Segment text: ")))

(let* ((collision nil)
       (segments (if (= n 2)
                     (tne-document-n2-segments tne-current-document)
                     (tne-document-n3-segments tne-current-document))))

;; V0.2.5 temporary:
;; allow insertion regardless of width.

;; Historical V0.2.2 territory-collision logic.
;;
;; Disabled in V0.2.5 because wrapped rendering changed
;; the meaning of width.
;;
;; Future anchor-overlap implementation may reuse some of
;; this reasoning, but the current algorithm is no longer
;; correct and must not be re-enabled as-is.
  
;;  (dolist (s segments)
;;    (let* ((existing-start
;;            (tne-segment-start-column s))
;;           (existing-width
;;            (tne-minimum-width
;;             (tne-segment-text s))))
;;
;;      (when (tne-territory-overlap-p
;;             c new-width
;;             existing-start existing-width)
;;        (setq collision t))))

  (if collision
      (message "Not enough space to add this segment.")

    (let ((s (make-tne-segment
	      :id (tne-generate-segment-id)
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
(defun tne-new-document ()
  (interactive)

  (switch-to-buffer "*TNE*")

  (erase-buffer)

  (tne-mode))
(provide 'tne-mode)
