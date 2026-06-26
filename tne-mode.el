;;; TNE Architectural Direction
;;;
;;; TNE is evolving toward a range-centric relationship editor.
;;;
;;; The primary user interaction model is:
;;;
;;;     Awareness
;;;         ↓
;;;       Range
;;;         ↓
;;;      Segment
;;;         ↓
;;;   Relationship
;;;         ↓
;;;      History
;;;
;;; Segments and relationships are persistent.
;;;
;;; Ranges are temporary.
;;;
;;; The user ultimately interacts through typing,
;;; selection, and mouse operations rather than
;;; direct command invocation.
;;;
;;; Some SID-based (segment ID) relationship functions remain
;;; from earlier development stages and may be
;;; retained for debugging, inspection, or
;;; compatibility purposes.
;;;
;;;DID document ID, SID segment ID, RID range ID

;;; Current development direction:
;;;
;;; Range-based relationship creation is the
;;; preferred architecture.
;;;
;;; SID-based relationship creation predates
;;; the range subsystem.

(add-to-list 'load-path (file-name-directory (or load-file-name buffer-file-name)))
(require 'seq)
(require 'tne-model)
(require 'tne-render)
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
 (define-key m (kbd "C-c C-3 e") #'tne-edit-n3-segment)
 (define-key m (kbd "C-c C-a m") #'tne-set-range-a-manual)
 (define-key m (kbd "C-c C-b m") #'tne-set-range-b-manual)
 (define-key m (kbd "C-c C-a s") #'tne-set-range-a-from-selection)
 (define-key m (kbd "C-c C-b s") #'tne-set-range-b-from-selection)
 (define-key m (kbd "C-c C-s") #'tne-show-range-status)
 m))

(defun tne-list-all-segments ()

  (interactive)

  (with-output-to-temp-buffer
      "*TNE All Segments*"

    (dolist
        (s
         (append

          (tne-document-n1-segments
           tne-current-document)

          (tne-document-n2-segments
           tne-current-document)

          (tne-document-n3-segments
           tne-current-document)))

      (princ
       (format

        "SID=%s  Type=%s  Owner=%s  Start=%s  Text=\"%s\"\n"

        (tne-segment-id s)
        (tne-segment-type s)
        (tne-segment-owner s)
        (tne-segment-start-column s)
        (tne-segment-text s))))))

(defun tne-show-document-segment-counts ()
  (interactive)

  (message
   "N1=%s N2=%s N3=%s"

   (length
    (tne-document-n1-segments
     tne-current-document))

   (length
    (tne-document-n2-segments
     tne-current-document))

   (length
    (tne-document-n3-segments
     tne-current-document))))

(defun tne-load-lorem-ipsum ()

  (interactive)

  (setf
   (tne-document-narrative-1
    tne-current-document)

   "Lorem ipsum dolor sit amet consectetur adipiscing elit sed do eiusmod tempor incididunt")

  (tne-redraw)

  (message
   "Lorem ipsum loaded into Narrative 1."))

(defun tne-show-document-info ()
  (interactive)

  (if (null tne-current-document)

      (message "No current document.")

    (with-output-to-temp-buffer "*TNE Document Info*"

      (princ
       (format "DID=%s\n\n"
               (tne-document-id
                tne-current-document)))

      (princ "N1 Range Segments\n")
      (princ "-----------------\n")

      (if (null (tne-document-n1-segments
                 tne-current-document))

          (princ "(none)\n")

        (dolist (s
                 (tne-document-n1-segments
                  tne-current-document))

          (princ
           (format
            "SID=%s  Start=%s  Text=\"%s\"\n"
            (tne-segment-id s)
            (tne-segment-start-column s)
            (tne-segment-text s)))))

      (princ "\n")

      (princ "N2 Segments\n")
      (princ "-----------\n")

      (if (null (tne-document-n2-segments
                 tne-current-document))

          (princ "(none)\n")

        (dolist (s
                 (tne-document-n2-segments
                  tne-current-document))

          (princ
           (format
            "SID=%s  Start=%s  Text=\"%s\"\n"
            (tne-segment-id s)
            (tne-segment-start-column s)
            (tne-segment-text s)))))

      (princ "\n")

      (princ "N3 Segments\n")
      (princ "-----------\n")

      (if (null (tne-document-n3-segments
                 tne-current-document))

          (princ "(none)\n")

        (dolist (s
                 (tne-document-n3-segments
                  tne-current-document))

          (princ
           (format
            "SID=%s  Start=%s  Text=\"%s\"\n"
            (tne-segment-id s)
            (tne-segment-start-column s)
            (tne-segment-text s)))))

      (princ "\n")

      (princ "Relationships\n")
      (princ "-------------\n")

      (if (null (tne-document-relationships
                 tne-current-document))

          (princ "(none)\n")

        (dolist (r
                 (tne-document-relationships
                  tne-current-document))

          (princ
           (format
            "RID=%s  Source SID=%s ↔ Target SID=%s  Type=%s\n"
            (tne-relationship-id r)
            (tne-relationship-source-id r)
            (tne-relationship-target-id r)
            (tne-relationship-type r)))))

      (princ "\n")

      (princ
       (format
        "Current Pair: SID=%s ↔ SID=%s\n"
        tne-current-pair-a-segment-id
        tne-current-pair-b-segment-id))

      (princ
       (format
        "Pair History Count=%s\n"
        (length tne-pair-history))))))

(defun tne-find-segment-by-id (id)

  (or

   (seq-find
    (lambda (s)
      (= (tne-segment-id s)
         id))
    (tne-document-n1-segments
     tne-current-document))

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

(defun tne-show-relationship-types ()

  (interactive)

  (with-output-to-temp-buffer
      "*TNE Relationship Types*"

    (dolist (type
             tne-relationship-types)

      (princ
       (format "%s\n"
               type)))))

(defun tne-add-relationship-type ()

  (interactive)

  (let ((type
         (intern
          (read-string
           "New relationship type: "))))

    (unless
        (memq type
              tne-relationship-types)

      (setq tne-relationship-types
            (append
             tne-relationship-types
             (list type))))

    (message
     "Relationship type added: %s"
     type)))

(defun tne-remove-relationship-type ()

  (interactive)

  (let* ((type-name
          (read-string
           "Relationship type to remove: "))

         (type
          (intern type-name)))

    (if (memq type
              tne-relationship-types)

        (progn

          (setq tne-relationship-types
                (delete type
                        tne-relationship-types))

          (message
           "Relationship type removed: %s"
           type))

      (message
       "Relationship type not found."))))

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

(defun tne-change-relationship-type ()

  (interactive)

  (let ((id
         (read-number
          "Relationship ID: "))

        (new-type
         (intern
          (read-string
           "New relationship type: "))))

    (let ((r
           (tne-find-relationship-by-id
            id)))

      (if (null r)

          (message
           "Relationship not found.")

        (setf
         (tne-relationship-type r)
         new-type)

        (message
         "Relationship updated.")))))

(defun tne-show-selected-segment-relationship-info ()

  (interactive)

  (if (null tne-selected-segment-id)

      (message
       "No segment selected.")

    (let ((id
           (read-number
            "Relationship ID: ")))

      (let ((r
             (tne-find-relationship-by-id
              id)))

        (if (null r)

            (message
             "Relationship not found.")

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

	    (let ((source
       (tne-find-segment-by-id
        (tne-relationship-source-id r)))

      (target
       (tne-find-segment-by-id
        (tne-relationship-target-id r))))

  (when source

    (princ
     (format
      "Source Text=%s\n"
      (tne-segment-text source))))

  (when target

    (princ
     (format
      "Target Text=%s\n"
      (tne-segment-text target)))))

            (princ
             (format
              "Type=%s\n"
              (tne-relationship-type r)))))))))

(defun tne-show-related-segments ()

  (interactive)

  (if (null tne-selected-segment-id)

      (message
       "No segment selected.")

    (with-output-to-temp-buffer
        "*TNE Related Segments*"

      (dolist
          (s
           (tne-related-segments
            tne-selected-segment-id))

        (princ
         (format
          "ID=%s\n"
          (tne-segment-id s)))

        (princ
         (format
          "Owner=%s\n"
          (tne-segment-owner s)))

        (princ
         (format
          "Type=%s\n"
          (tne-segment-type s)))

        (princ
         (format
          "Text=%s\n\n"
          (tne-segment-text s)))))))


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
	    (completing-read
	     "Relationship type: "
	     (mapcar
	      #'symbol-name
	      tne-relationship-types)
	     nil
	     t))))

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


(defun tne-range-valid-owner-p (owner)
  (memq owner '(n1 n2 n3)))

(defun tne-normalize-range-owner (owner)
  (cond
   ((symbolp owner) owner)
   ((stringp owner) (intern (downcase owner)))
   (t owner)))

(defun tne-read-range-owner ()
  (intern
   (completing-read
    "Owner: "
    '("n1" "n2" "n3")
    nil
    t)))

(defun tne-normalize-range-boundaries (start end)
  (let ((a (min start end))
        (b (max start end)))
    (cons a b)))

(defun tne-make-range-checked (owner start end &optional text)
  (let* ((normalized-owner
          (tne-normalize-range-owner owner))
         (bounds
          (tne-normalize-range-boundaries start end))
         (range-start
          (car bounds))
         (range-end
          (cdr bounds)))

    (unless (tne-range-valid-owner-p normalized-owner)
      (error "Invalid range owner: %s" owner))

    (unless (and (integerp range-start)
                 (integerp range-end)
                 (>= range-start 1)
                 (>= range-end range-start))
      (error "Invalid range boundaries: %s-%s" start end))

    (make-tne-range
     :owner normalized-owner
     :start range-start
     :end range-end
     :text text)))

(defun tne-projection-owner-for-range-a (range)
  "Return the owner line where Range A should project next."
  (pcase (tne-range-owner range)
    ('n1 'n2)
    ('n2 'n3)
    ('n3 'n3)
    (_ nil)))

(defun tne-compute-insertion-point-for-range-a ()
  "Compute the transient insertion point created by Range A."
  (when tne-range-a
    (let ((projection-owner
           (tne-projection-owner-for-range-a tne-range-a)))
      (when projection-owner
        (make-tne-insertion-point
         :owner projection-owner
         :column (tne-range-start tne-range-a)
         :reason 'range-a-projection)))))

(defun tne-set-range-a (owner start end &optional text)
  (setq tne-range-a
        (tne-make-range-checked owner start end text))
  (setq tne-range-a-segment-id nil)
  (setq tne-current-insertion-point
        (tne-compute-insertion-point-for-range-a))
  (message "Range A set: %s %s-%s"
           (tne-range-owner tne-range-a)
           (tne-range-start tne-range-a)
           (tne-range-end tne-range-a)))

(defun tne-set-range-b (owner start end &optional text)
  (setq tne-range-b
        (tne-make-range-checked owner start end text))
  (setq tne-range-b-segment-id nil)
  (message "Range B set: %s %s-%s"
           (tne-range-owner tne-range-b)
           (tne-range-start tne-range-b)
           (tne-range-end tne-range-b)))

(defun tne-set-range-a-manual ()
  (interactive)
  (let ((owner (tne-read-range-owner))
        (start (read-number "Start column: "))
        (end (read-number "End column: "))
        (text (read-string "Selected text: ")))
    (tne-set-range-a owner start end text)))

(defun tne-set-range-b-manual ()
  (interactive)
  (let ((owner (tne-read-range-owner))
        (start (read-number "Start column: "))
        (end (read-number "End column: "))
        (text (read-string "Selected text: ")))
    (tne-set-range-b owner start end text)))

(defun tne-owner-at-buffer-line (line-number)
  (cond
   ((= line-number 1) 'n1)
   ((= line-number 2) 'n2)
   ((= line-number 3) 'n3)
   (t nil)))

(defun tne-selection-to-range-data ()
  (unless (use-region-p)
    (error "No active region."))

  (let* ((beg (region-beginning))
         (end (region-end))
         (beg-line
          (line-number-at-pos beg))
         (end-line
          (line-number-at-pos end))
         (owner
          (tne-owner-at-buffer-line beg-line)))

    (unless (= beg-line end-line)
      (error "Range selection must be on one rendered line for now."))

    (unless owner
      (error "Only rendered lines 1, 2, and 3 map to n1, n2, and n3 for now."))

    (save-excursion
      (goto-char beg)
      (let ((start-column
             (1+ (current-column)))
            (text
             (buffer-substring-no-properties beg end)))
        (goto-char end)
        (let ((end-column
               (max start-column (current-column))))
          (list owner start-column end-column text))))))

(defun tne-set-range-a-from-selection ()
  "Set Range A from the current single-line selection."
  (interactive)
  (pcase-let ((`(,owner ,start ,end ,text)
               (tne-selection-to-range-data)))
    (tne-set-range-a owner start end text)))

(defun tne-set-range-b-from-selection ()
  "Set Range B from the current single-line selection."
  (interactive)
  (pcase-let ((`(,owner ,start ,end ,text)
               (tne-selection-to-range-data)))
    (tne-set-range-b owner start end text)))

(defun tne-range-display-text (range label)
  (or (tne-range-text range)
      (format "[%s %s:%s-%s]"
              label
              (tne-range-owner range)
              (tne-range-start range)
              (tne-range-end range))))

(defun tne-add-segment-to-document (segment)
  (pcase (tne-segment-owner segment)
    ('n1
     (setf (tne-document-n1-segments tne-current-document)
           (cons segment
                 (tne-document-n1-segments tne-current-document))))
    ('n2
     (setf (tne-document-n2-segments tne-current-document)
           (cons segment
                 (tne-document-n2-segments tne-current-document))))
    ('n3
     (setf (tne-document-n3-segments tne-current-document)
           (cons segment
                 (tne-document-n3-segments tne-current-document))))
    (_
     (error "Invalid segment owner: %s"
            (tne-segment-owner segment))))
  segment)

(defun tne-show-range-a ()

  (interactive)

  (if (null tne-range-a)

      (message
       "Range A is not set.")

    (with-output-to-temp-buffer
        "*TNE Range A*"

      (princ
       (format
        "Owner=%s\n"
        (tne-range-owner
         tne-range-a)))

      (princ
       (format
        "Start=%s\n"
        (tne-range-start
         tne-range-a)))

      (princ
       (format
        "End=%s\n"
        (tne-range-end
         tne-range-a))))))

(defun tne-show-range-b ()

  (interactive)

  (if (null tne-range-b)

      (message
       "Range B is not set.")

    (with-output-to-temp-buffer
        "*TNE Range B*"

      (princ
       (format
        "Owner=%s\n"
        (tne-range-owner
         tne-range-b)))

      (princ
       (format
        "Start=%s\n"
        (tne-range-start
         tne-range-b)))

      (princ
       (format
        "End=%s\n"
        (tne-range-end
         tne-range-b))))))

(defun tne-clear-range-a ()

  (interactive)

  (setq tne-range-a nil)

  (message
   "Range A cleared."))

(defun tne-clear-range-b ()

  (interactive)

  (setq tne-range-b nil)

  (message
   "Range B cleared."))

(defun tne-show-ranges ()

  (interactive)

  (with-output-to-temp-buffer
      "*TNE Ranges*"

    (princ "Range A\n")
    (princ "-------\n")

    (if tne-range-a

        (progn

          (princ
           (format
            "Owner=%s\n"
            (tne-range-owner
             tne-range-a)))

          (princ
           (format
            "Start=%s\n"
            (tne-range-start
             tne-range-a)))

          (princ
           (format
            "End=%s\n\n"
            (tne-range-end
             tne-range-a))))

      (princ
       "Not set.\n\n"))

    (princ "Range B\n")
    (princ "-------\n")

    (if tne-range-b

        (progn

          (princ
           (format
            "Owner=%s\n"
            (tne-range-owner
             tne-range-b)))

          (princ
           (format
            "Start=%s\n"
            (tne-range-start
             tne-range-b)))

          (princ
           (format
            "End=%s\n"
            (tne-range-end
             tne-range-b))))

      (princ
       "Not set.\n"))))

(defun tne-ranges-ready-p ()

  (and tne-range-a
       tne-range-b))

(defun tne-ranges-same-owner-p ()

  (and tne-range-a
       tne-range-b

       (eq
        (tne-range-owner tne-range-a)
        (tne-range-owner tne-range-b))))

(defun tne-ranges-different-owners-p ()

  (and tne-range-a
       tne-range-b

       (not
        (eq
         (tne-range-owner tne-range-a)
         (tne-range-owner tne-range-b)))))

(defun tne-range-a-to-segment ()

  (interactive)

  (if (null tne-range-a)

      (message
       "Range A is not set.")

    (let ((s
           (make-tne-segment
            :id (tne-generate-segment-id)
            :type 'segment
            :owner (tne-range-owner tne-range-a)
            :start-column (tne-range-start tne-range-a)
            :text (tne-range-display-text tne-range-a "RANGE-A"))))

      (setq tne-range-a-segment-id
            (tne-segment-id s))

      (tne-add-segment-to-document s)

      (when (memq (tne-segment-owner s) '(n2 n3))
        (tne-redraw))

      (message
       "Segment %s created from Range A."
       (tne-segment-id s)))))

(defun tne-range-b-to-segment ()

  (interactive)

  (if (null tne-range-b)

      (message
       "Range B is not set.")

    (let ((s
           (make-tne-segment
            :id (tne-generate-segment-id)
            :type 'segment
            :owner (tne-range-owner tne-range-b)
            :start-column (tne-range-start tne-range-b)
            :text (tne-range-display-text tne-range-b "RANGE-B"))))

      (setq tne-range-b-segment-id
            (tne-segment-id s))

      (tne-add-segment-to-document s)

      (when (memq (tne-segment-owner s) '(n2 n3))
        (tne-redraw))

      (message
       "Segment %s created from Range B."
       (tne-segment-id s)))))

(defun tne-show-range-segment-ids ()

  (interactive)

  (with-output-to-temp-buffer
      "*TNE Range Segment IDs*"

    (princ
     (format
      "Range A Segment ID=%s\n"
      tne-range-a-segment-id))

    (princ
     (format
      "Range B Segment ID=%s\n"
      tne-range-b-segment-id))))

(defun tne-relate-range-segments ()

  (interactive)

  (if (or (null tne-range-a-segment-id)
          (null tne-range-b-segment-id))

      (message
       "Range segment IDs are not available.")

    (let ((type
           (intern
            (completing-read
             "Relationship type: "
             (mapcar
              #'symbol-name
              tne-relationship-types)
             nil
             t))))

      (let ((r
	     (tne-create-relationship
              tne-range-a-segment-id
              tne-range-b-segment-id
              type)))

	(setq tne-current-pair-a-segment-id
              tne-range-a-segment-id)

	(setq tne-current-pair-b-segment-id
              tne-range-b-segment-id)

	(setq tne-pair-history

              (cons

               (make-tne-pair-history-entry

		:pair-a-segment-id
		tne-range-a-segment-id

		:pair-b-segment-id
		tne-range-b-segment-id

		:relationship-id
		(tne-relationship-id r)

		:relationship-type
		type

		:document-id
		(tne-document-id
		 tne-current-document)

		:timestamp
		(current-time-string))

               tne-pair-history))

	(message
	 "Relationship created."))

      (setq tne-current-pair-a-segment-id
      tne-range-a-segment-id)

      (setq tne-current-pair-b-segment-id
      tne-range-b-segment-id)

      (message
       "Relationship created."))))

(defun tne-show-pair-history ()

  (interactive)

  (with-output-to-temp-buffer
      "*TNE Pair History*"

    (if (null tne-pair-history)

        (princ
         "No pair history.\n")

      (dolist (h tne-pair-history)

        (princ
         (format
          "A=%s  B=%s  Rel=%s  Type=%s\n"
          (tne-pair-history-entry-pair-a-segment-id h)
          (tne-pair-history-entry-pair-b-segment-id h)
          (tne-pair-history-entry-relationship-id h)
          (tne-pair-history-entry-relationship-type h)))

        (princ
         (format
          "Time=%s\n\n"
          (tne-pair-history-entry-timestamp h)))))))

(defun tne-clear-ranges ()

  (interactive)

  (setq tne-range-a nil)

  (setq tne-range-b nil)

  (message
   "Ranges cleared."))

(defun tne-range-summary ()

  (interactive)

  (with-output-to-temp-buffer
      "*TNE Range Summary*"

    (if tne-range-a

        (princ
         (format
          "A: %s %s-%s\n"

          (tne-range-owner
           tne-range-a)

          (tne-range-start
           tne-range-a)

          (tne-range-end
           tne-range-a)))

      (princ
       "A: not set\n"))

    (if tne-range-b

        (princ
         (format
          "B: %s %s-%s\n"

          (tne-range-owner
           tne-range-b)

          (tne-range-start
           tne-range-b)

          (tne-range-end
           tne-range-b)))

      (princ
       "B: not set\n"))))

(defun tne-ranges-to-segments ()

  (interactive)

  (if (not (tne-ranges-ready-p))

      (message
       "Both ranges must be set.")

    (progn

      (tne-range-a-to-segment)

      (tne-range-b-to-segment)

      (message
       "Segments created from both ranges."))))

(defun tne-show-range-status ()

  (interactive)

  (with-output-to-temp-buffer
      "*TNE Range Status*"

    (princ
     (format
      "Range A: %s\n"
      (if tne-range-a
          "set"
        "not set")))

    (when tne-range-a
      (princ
       (format
        "  Owner=%s Start=%s End=%s Text=\"%s\"\n"
        (tne-range-owner tne-range-a)
        (tne-range-start tne-range-a)
        (tne-range-end tne-range-a)
        (or (tne-range-text tne-range-a) ""))))

    (princ
     (format
      "Range B: %s\n"
      (if tne-range-b
          "set"
        "not set")))

    (when tne-range-b
      (princ
       (format
        "  Owner=%s Start=%s End=%s Text=\"%s\"\n"
        (tne-range-owner tne-range-b)
        (tne-range-start tne-range-b)
        (tne-range-end tne-range-b)
        (or (tne-range-text tne-range-b) ""))))

    (princ
     (format
      "Ready for linking: %s\n"
      (if (tne-ranges-ready-p)
          "yes"
        "no")))

    (princ
     (format
      "Same owner: %s\n"
      (if (tne-ranges-same-owner-p)
          "yes"
        "no")))

    (princ
     (format
      "Different owners: %s\n"
      (if (tne-ranges-different-owners-p)
          "yes"
        "no")))

    (princ
     (if tne-current-insertion-point
         (format
          "Insertion point: set\n  Owner=%s Column=%s Reason=%s\n"
          (tne-insertion-point-owner tne-current-insertion-point)
          (tne-insertion-point-column tne-current-insertion-point)
          (tne-insertion-point-reason tne-current-insertion-point))
       "Insertion point: not set\n"))))

(defun tne-show-insertion-point ()
  "Show the current transient insertion point."
  (interactive)
  (if tne-current-insertion-point
      (message
       "Insertion point: Owner=%s Column=%s Reason=%s"
       (tne-insertion-point-owner tne-current-insertion-point)
       (tne-insertion-point-column tne-current-insertion-point)
       (tne-insertion-point-reason tne-current-insertion-point))
    (message
     "Insertion point: not set")))

(defun tne-select-segment ()

  (interactive)

  (let ((id
         (read-number
          "Segment ID: ")))

    (if (tne-find-segment-by-id id)

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

(defun tne-list-segments ()

  (interactive)

  (with-output-to-temp-buffer
      "*TNE Segments*"

    (dolist (s
             (append
	      (tne-document-n1-segments
		tne-current-document)

              (tne-document-n2-segments
               tne-current-document)

              (tne-document-n3-segments
               tne-current-document)))

      (princ
       (format
        "SID=%s  Type=%s  Owner=%s  Start=%s  Text=\"%s\"\n"

        (tne-segment-id s)
	(tne-segment-type s)
        (tne-segment-owner s)
        (tne-segment-start-column s)
        (tne-segment-text s))))))

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

  (setq tne-range-a nil)
  (setq tne-range-b nil)
  (setq tne-range-a-segment-id nil)
  (setq tne-range-b-segment-id nil)
  (setq tne-current-insertion-point nil)

  (switch-to-buffer "*TNE*")

  (erase-buffer)

  (tne-mode))

(provide 'tne-mode)
