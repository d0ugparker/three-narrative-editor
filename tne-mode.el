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

(defun tne-find-segment-by-id (id)

  (or

   (seq-find
    (lambda (s)
      (= (tne-segment-id s)
         id))
    (tne-document-n2-segments
     tne-current-document))

   (seq-find
    (lambda (s)
      (= (tne-segment-id s)
         id))
    (tne-document-n3-segments
     tne-current-document))))

(defun tne-find-relationship-by-id (id)

  (seq-find
   (lambda (r)
     (= (tne-relationship-id r)
        id))
   (tne-document-relationships
    tne-current-document)))

(defun tne-find-relationships-for-segment (segment-id)

  (seq-filter
   (lambda (r)

     (or
      (= (tne-relationship-source-id r)
         segment-id)

      (= (tne-relationship-target-id r)
         segment-id)))

   (tne-document-relationships
    tne-current-document)))

(defun tne-related-segments (segment-id)

  (mapcar

   (lambda (r)

     (if (= (tne-relationship-source-id r)
            segment-id)

         (tne-find-segment-by-id
          (tne-relationship-target-id r))

       (tne-find-segment-by-id
        (tne-relationship-source-id r))))

   (tne-find-relationships-for-segment
    segment-id)))

(defun tne-related-segment-texts (segment-id)

  (mapcar
   #'tne-segment-text
   (tne-related-segments
    segment-id)))

(defun tne-relationship-types-for-segment (segment-id)

  (mapcar
   #'tne-relationship-type

   (tne-find-relationships-for-segment
    segment-id)))

(defun tne-relationship-summary-for-segment (segment-id)

  (mapcar

   (lambda (r)

     (let ((other

            (if (= (tne-relationship-source-id r)
                   segment-id)

                (tne-find-segment-by-id
                 (tne-relationship-target-id r))

              (tne-find-segment-by-id
               (tne-relationship-source-id r)))))

       (list

        (tne-relationship-type r)

        (tne-segment-text other))))

   (tne-find-relationships-for-segment
    segment-id)))

(defun tne-show-relationship-summary ()

  (interactive)

  (let ((id
         (read-number
          "Segment ID: ")))

    (with-output-to-temp-buffer
        "*TNE Relationships*"

      (dolist (item
               (tne-relationship-summary-for-segment
                id))

        (princ
         (format
          "%s -> %s\n"

          (car item)
          (cadr item)))))))

(defun tne-show-selected-segment-relationships ()

  (interactive)

  (if (null tne-selected-segment-id)

      (message
       "No segment selected.")

    (with-output-to-temp-buffer
        "*TNE Relationships*"

      (dolist (item
               (tne-relationship-summary-for-segment
                tne-selected-segment-id))

        (princ
         (format
          "%s -> %s\n"

          (car item)
          (cadr item)))))))

(defun tne-show-selected-segment-relationship-ids ()

  (interactive)

  (if (null tne-selected-segment-id)

      (message
       "No segment selected.")

    (with-output-to-temp-buffer
        "*TNE Relationship IDs*"

      (dolist (r
               (tne-find-relationships-for-segment
                tne-selected-segment-id))

        (princ
         (format
          "Relationship ID=%s\n"
          (tne-relationship-id r)))))))

(defun tne-delete-selected-segment-relationship ()

  (interactive)

  (if (null tne-selected-segment-id)

      (message
       "No segment selected.")

    (let ((id
           (read-number
            "Relationship ID: ")))

      (tne-delete-relationship-by-id
       id)

      (message
       "Relationship %s deleted."
       id))))

(defun tne-relationship-source-segment (relationship)

  (tne-find-segment-by-id
   (tne-relationship-source-id
    relationship)))

(defun tne-relationship-target-segment (relationship)

  (tne-find-segment-by-id
   (tne-relationship-target-id
    relationship)))

(defun tne-relationship-valid-p (source-id
                                 target-id)

  (and
   (tne-find-segment-by-id source-id)
   (tne-find-segment-by-id target-id)))

(defun tne-add-relationship (relationship)

  (setf
   (tne-document-relationships
    tne-current-document)

   (cons relationship
         (tne-document-relationships
          tne-current-document)))

  relationship)

(defun tne-delete-relationship-by-id (id)

  (setf
   (tne-document-relationships
    tne-current-document)

   (seq-remove
    (lambda (r)
      (= (tne-relationship-id r)
         id))
    (tne-document-relationships
     tne-current-document))))

(defun tne-delete-relationship ()

  (interactive)

  (let ((id
         (read-number
          "Relationship ID: ")))

    (tne-delete-relationship-by-id
     id)

    (message
     "Relationship %s deleted."
     id)))

(defun tne-create-relationship (source-id
                                target-id
                                type)

  (let ((r
         (make-tne-relationship
          :id
          (tne-generate-relationship-id)

          :source-id
          source-id

          :target-id
          target-id

          :type
          type)))

    (tne-add-relationship r)))

(defun tne-create-segment-relationship (source-id
                                        target-id
                                        type)

  (when
      (tne-relationship-valid-p
       source-id
       target-id)

    (tne-create-relationship
     source-id
     target-id
     type)))

(defun tne-create-relationship-command ()

  (interactive)

  (let ((source-id
         (read-number
          "Source segment ID: "))

        (target-id
         (read-number
          "Target segment ID: "))

        (type
         (intern
          (read-string
           "Relationship type: "
           "relates-to"))))

    (if
        (tne-create-segment-relationship
         source-id
         target-id
         type)

        (message
         "Relationship created.")

      (message
       "Relationship creation failed."))))

(defun tne-relate-selected-segment ()

  (interactive)

  (if (null tne-selected-segment-id)

      (message
       "No segment selected.")

    (let ((target-id
           (read-number
            "Target segment ID: "))

          (type
           (intern
            (read-string
             "Relationship type: "
             "relates-to"))))

      (if
          (tne-create-segment-relationship
           tne-selected-segment-id
           target-id
           type)

          (message
           "Relationship created.")

        (message
         "Relationship creation failed.")))))

(defun tne-selected-segment-info ()
  (interactive)

  (if (null tne-selected-segment-id)

      (message "No segment selected.")

    (let* ((segment
            (tne-find-segment-by-id
             tne-selected-segment-id))

           (record
            (tne-find-layout-record-by-id
             tne-selected-segment-id)))

      (if (null segment)

          (message "Selected segment not found.")

        (with-output-to-temp-buffer
            "*TNE Selected Segment*"

          (princ
           (format "ID=%s\n"
                   (tne-segment-id segment)))

          (princ
           (format "Owner=%s\n"
                   (tne-segment-owner segment)))

	  (princ
	   (format "Type=%s\n"
		   (tne-segment-type segment)))

          (princ
           (format "Start=%s\n"
                   (tne-segment-start-column segment)))

          (princ
           (format "Text=%s\n\n"
                   (tne-segment-text segment)))

          (if record

              (progn
                (princ
                 (format "Width=%s\n"
                         (tne-layout-record-width record)))

                (princ
                 (format "Height=%s\n\n"
                         (tne-layout-record-height record)))

                (dolist (row
                         (tne-layout-record-rows record))
                  (princ row)
                  (princ "\n")))

            (princ "No layout record found.\n")))))))

(defun tne-show-selected-segment ()

  (interactive)

  (if tne-selected-segment-id

      (message
       "Selected segment: %s"
       tne-selected-segment-id)

    (message
     "No segment selected.")))

(defun tne-select-segment ()

  (interactive)

  (let ((id
         (read-number
          "Segment ID: ")))

    (if (tne-find-layout-record-by-id id)

        (progn

          (setq tne-selected-segment-id id)

          (message
           "Selected segment %s"
           id))

      (message
       "Segment not found."))))

(defun tne-segment-info ()

  (interactive)

  (let* ((id
          (read-number "Segment ID: "))

         (r
          (tne-find-layout-record-by-id id)))

    (if (null r)

        (message "Segment not found.")

      (with-output-to-temp-buffer
          "*TNE Segment Info*"

        (princ
         (format
          "ID=%s\n"
          (tne-layout-record-segment-id r)))

        (princ
         (format
          "Start=%s\n"
          (tne-layout-record-start r)))

        (princ
         (format
          "Width=%s\n"
          (tne-layout-record-width r)))

        (princ
         (format
          "Height=%s\n\n"
          (tne-layout-record-height r)))

        (dolist (row
                 (tne-layout-record-rows r))

          (princ row)
          (princ "\n"))))))

(defun tne-relationship-info ()

  (interactive)

  (let* ((id
          (read-number "Relationship ID: "))

         (r
          (tne-find-relationship-by-id id)))

    (if (null r)

        (message "Relationship not found.")

      (with-output-to-temp-buffer
          "*TNE Relationship Info*"

        (princ
         (format
          "ID=%s\n"
          (tne-relationship-id r)))

        (princ
         (format
          "Source=%s\n"
          (tne-relationship-source-id r)))

        (princ
         (format
          "Target=%s\n"
          (tne-relationship-target-id r)))

        (princ
         (format
          "Type=%s\n"
          (tne-relationship-type r)))))))

(defun tne-list-relationships ()

  (interactive)

  (with-output-to-temp-buffer
      "*TNE Relationships*"

    (dolist (r
             (tne-document-relationships
              tne-current-document))

      (princ
       (format
        "ID=%s  Source=%s  Target=%s  Type=%s\n"

        (tne-relationship-id r)
        (tne-relationship-source-id r)
        (tne-relationship-target-id r)
        (tne-relationship-type r))))))

(defun tne-find-layout-record-by-id (id)

  (catch 'found

    (dolist (r tne-layout-records)

      (when (= (tne-layout-record-segment-id r)
               id)

        (throw 'found r)))

    nil))

(defun tne-show-layout-records ()
  (interactive)

  (message "%S"
           tne-layout-records))

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
	      :type 'segment
	      :owner
	      (if (= n 2)
		  'n2
		'n3)
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
