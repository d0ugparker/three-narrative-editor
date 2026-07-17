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
(defvar tne-mode-map nil)

(setq tne-mode-map
      (let ((m (make-sparse-keymap)))
	(define-key m (kbd "C-c C-2 a") #'tne-add-n2-segment)
	(define-key m (kbd "C-c C-3 a") #'tne-add-n3-segment)
	(define-key m (kbd "C-c C-r")   #'tne-redraw)
	(define-key m (kbd "C-c C-l")   #'tne-layout-report)
	(define-key m (kbd "C-c C-w")   #'tne-wrap-report)
	(define-key m (kbd "C-c C-2 d") #'tne-delete-n2-segment)
	(define-key m (kbd "C-c C-3 d") #'tne-delete-n3-segment)
	(define-key m (kbd "C-c C-2 e") #'tne-edit-n2-segment)
	(define-key m (kbd "C-c C-3 e") #'tne-edit-n3-segment)
	(define-key m (kbd "C-c C-a m") #'tne-set-range-a-manual)
	(define-key m (kbd "C-c C-b m") #'tne-set-range-b-manual)
	(define-key m (kbd "C-c C-a s") #'tne-set-range-a-from-selection)
	(define-key m (kbd "C-c C-b s") #'tne-set-range-b-from-selection)
	(define-key m (kbd "C-c C-s")   #'tne-show-range-status)
	(define-key m (kbd "C-c C-g")   #'tne-goto-insertion-point)
	(define-key m (kbd "C-c C-n")   #'tne-add-segment-at-insertion-point)
	(global-set-key (kbd "C-c C-v 1")  'tne-new-document)
	(global-set-key (kbd "C-c C-v 2")  'tne-load-lorem-ipsum)
	m))

(defun tne-self-insert-command (n)
  "Insert the typed character, replacing an active selection.

N is the numeric prefix argument supplied to `self-insert-command'."
  (interactive "p")

  (when (use-region-p)
    (delete-region
     (region-beginning)
     (region-end)))

  (self-insert-command n))


(defvar-local tne-boundary-edit-session nil
  "Current mixed-boundary editing session.

The value is nil or a plist containing:

:segment-id
:boundary
:domain

BOUNDARY is `left' or `right'.
DOMAIN is `range' or `non-range'.")


(defvar-local tne-projected-column nil
  "Intended horizontal display column in canonically empty space.

When non-nil, point remains at the physical end of the current
narrative row while the renderer displays the cursor at this column.")


(defvar-local tne-projected-cursor-overlay nil
  "Overlay used to display point in canonically empty narrative space.")


(defun tne-segment-aperture-width-effective (segment)
  "Return SEGMENT's established display aperture width."
  (max
   1
   (or
    (tne-segment-aperture-width segment)
    (length
     (tne-segment-text segment)))))


(defun tne-segment-left-offset (segment)
  "Return SEGMENT's zero-based left shared-boundary offset."
  (1-
   (tne-segment-start-column segment)))


(defun tne-segment-right-offset (segment)
  "Return SEGMENT's zero-based right shared-boundary offset."
  (+
   (tne-segment-left-offset segment)
   (tne-segment-aperture-width-effective segment)))


(defun tne-n1-segments-at-mixed-boundary (&optional offset)
  "Return N1 segment-boundary matches at OFFSET.

Each result has the form:

  (SEGMENT . BOUNDARY)

where BOUNDARY is `left' or `right'."
  (let ((position
         (or
          offset
          (tne-buffer-position-to-n1-offset)))

        (matches nil))

    (dolist
        (segment
         (tne-document-n1-segments
          tne-current-document))

      (when
          (= position
             (tne-segment-left-offset segment))

        (push
         (cons segment 'left)
         matches))

      (when
          (= position
             (tne-segment-right-offset segment))

        (push
         (cons segment 'right)
         matches)))

    (nreverse matches)))


(defun tne-current-mixed-boundary ()
  "Return the unique mixed boundary currently under point.

Return nil when point is not on a boundary.

Signal an error when several segment boundaries share the position,
because that later case requires an explicit chooser."
  (let ((matches
         (tne-n1-segments-at-mixed-boundary)))

    (cond
     ((null matches)
      nil)

     ((= (length matches) 1)
      (car matches))

     (t
      (user-error
       "Several segment boundaries share this position")))))


(defun tne-boundary-domain-opposite (domain)
  "Return the editing domain opposite DOMAIN."
  (pcase domain
    ('range 'non-range)
    ('non-range 'range)
    (_ nil)))


(defun tne-set-boundary-edit-session
    (segment boundary domain)
  "Begin or update a boundary-edit session."
  (setq
   tne-boundary-edit-session
   (list
    :segment-id
    (tne-segment-id segment)

    :boundary
    boundary

    :domain
    domain))

  (message
   "Boundary edit: SID=%s %s boundary, %s active"
   (tne-segment-id segment)
   boundary
   domain))


(defun tne-clear-projected-cursor ()
  "Remove the temporary cursor projection, if one exists."
  (when (overlayp tne-projected-cursor-overlay)
    (delete-overlay
     tne-projected-cursor-overlay))

  (setq tne-projected-cursor-overlay nil)
  (setq tne-projected-column nil))


(defun tne-display-projected-cursor (column)
  "Display the cursor at COLUMN without inserting buffer text.

Point must already be at the physical end of the destination narrative
row.  Existing narrative content is left untouched."
  (tne-clear-projected-cursor)

  (let* ((physical-column
          (current-column))

         (distance
          (1+
           (- column physical-column))))

    (when (> distance 0)
      (let ((display-string
             (make-string distance ?\s)))

        ;; The final projected character displays Emacs's cursor while
        ;; point itself remains at the canonical end of the row.
        (put-text-property
         (1- distance)
         distance
         'cursor
         t
         display-string)

        (setq
         tne-projected-cursor-overlay
         (make-overlay
          (point)
          (point)
          nil
          t
          t))

        (overlay-put
         tne-projected-cursor-overlay
         'after-string
         display-string)

        (setq tne-projected-column column)))))


(defun tne-current-effective-column ()
  "Return point's actual or projected horizontal column."
  (or tne-projected-column
      (current-column)))


(defun tne-move-vertical-from-current-column (lines)
  "Move vertically by LINES while preserving projected geometry.

When the destination narrative contains text through the intended
column, point moves there normally.  When the destination ends earlier,
point remains at its canonical end and a non-textual cursor projection
shows the intended horizontal location."
  (let ((column
         (tne-current-effective-column)))

    (tne-clear-projected-cursor)

    (forward-line lines)

    (move-to-column
     column)

    (when (< (current-column) column)
      (end-of-line)

      (tne-display-projected-cursor
       column))))


(defun tne-resolve-boundary-up ()
  "Resolve or toggle mixed-boundary focus using Up Arrow.

The first Up Arrow chooses Range focus."
  (interactive)

  (let ((match
         (tne-current-mixed-boundary)))

    (if (not match)
        (if tne-boundary-edit-session
            (progn
              (ding)
              (message
               "Boundary editing is active. Press Escape to leave it."))

          (tne-move-vertical-from-current-column
           -1))

      (let* ((segment
              (car match))

             (boundary
              (cdr match))

             (same-session-p
              (and
               tne-boundary-edit-session

               (=
                (plist-get
                 tne-boundary-edit-session
                 :segment-id)

                (tne-segment-id segment))

               (eq
                (plist-get
                 tne-boundary-edit-session
                 :boundary)

                boundary)))

             (domain
              (if same-session-p
                  (tne-boundary-domain-opposite
                   (plist-get
                    tne-boundary-edit-session
                    :domain))

                'range)))

        (tne-set-boundary-edit-session
         segment
         boundary
         domain)))))


(defun tne-resolve-boundary-down ()
  "Resolve or toggle mixed-boundary focus using Down Arrow.

The first Down Arrow chooses non-Range focus."
  (interactive)

  (let ((match
         (tne-current-mixed-boundary)))

    (if (not match)
        (if tne-boundary-edit-session
            (progn
              (ding)
              (message
               "Boundary editing is active. Press Escape to leave it."))

          (tne-move-vertical-from-current-column
           1))

      (let* ((segment
              (car match))

             (boundary
              (cdr match))

             (same-session-p
              (and
               tne-boundary-edit-session

               (=
                (plist-get
                 tne-boundary-edit-session
                 :segment-id)

                (tne-segment-id segment))

               (eq
                (plist-get
                 tne-boundary-edit-session
                 :boundary)

                boundary)))

             (domain
              (if same-session-p
                  (tne-boundary-domain-opposite
                   (plist-get
                    tne-boundary-edit-session
                    :domain))

                'non-range)))

        (tne-set-boundary-edit-session
         segment
         boundary
         domain)))))


(defun tne-end-boundary-edit-session ()
  "End boundary editing and restore stateless navigation."
  (interactive)

  (if tne-boundary-edit-session
      (progn
        (setq tne-boundary-edit-session nil)
        (message
         "Boundary editing ended."))

    (progn
      (tne-clear-projected-cursor)
      (keyboard-quit))))


(defun tne-show-boundary-edit-state ()
  "Report the current boundary-edit session."
  (interactive)

  (if tne-boundary-edit-session
      (message
       "SID=%s Boundary=%s Domain=%s"
       (plist-get
        tne-boundary-edit-session
        :segment-id)

       (plist-get
        tne-boundary-edit-session
        :boundary)

       (plist-get
        tne-boundary-edit-session
        :domain))

    (message
     "Boundary edit: inactive")))


(defun tne-install-keybindings ()
  "Install or refresh TNE mode keybindings.

This function exists because `defvar' does not rebuild
`tne-mode-map' after the variable has already been defined.
Calling this after load-file ensures newly added keybindings are
installed without restarting Emacs."
  (define-key tne-mode-map (kbd "C-c C-a s") #'tne-set-range-a-from-selection)
  (define-key tne-mode-map (kbd "C-c C-b s") #'tne-set-range-b-from-selection)
  (define-key tne-mode-map (kbd "C-c C-s") #'tne-show-range-status)

  ;; Mixed-boundary resolution and explicit state exit.
  (define-key tne-mode-map (kbd "<up>")
    #'tne-resolve-boundary-up)

  (define-key tne-mode-map (kbd "<down>")
    #'tne-resolve-boundary-down)

  (define-key tne-mode-map (kbd "<escape>")
    #'tne-end-boundary-edit-session)

  (define-key tne-mode-map (kbd "C-c C-e")
    #'tne-show-boundary-edit-state)

  ;; Typing replaces an active selection, matching ordinary
  ;; word-processing behavior.
  (define-key
   tne-mode-map
   [remap self-insert-command]
   #'tne-self-insert-command)

  ;; RE-specific undo and redo restore both model state and the
  ;; insertion-point consequences of the conceptual operation.
  (define-key tne-mode-map (kbd "C-/") #'tne-undo)
  (define-key tne-mode-map (kbd "C-?") #'tne-redo)

  ;; macOS Option-TAB arrives in Emacs as M-<tab>,
  ;; which Emacs translates to C-M-i.
  (define-key tne-mode-map (kbd "C-M-i") #'tne-toggle-placement-display-mode))

(tne-install-keybindings)

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

        "SID=%s  Type=%s  Owner=%s  Start=%s  Aperture=%s  Text=\"%s\"\n"

        (tne-segment-id s)
        (tne-segment-type s)
        (tne-segment-owner s)
        (tne-segment-start-column s)
	(or (tne-segment-aperture-width s) "none")
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

   "Lorem lorem ipsum ipsum dolor sit amet consectetur adipiscing elit sed do eiusmod tempor incididunt")

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

(defun tne-current-collapsed-collection ()
  "Return the current collapsed collection, if any."
  tne-current-collapsed-collection)

(defun tne-collapsed-collection-present-p ()
  "Return non-nil when a collapsed collection is present."
  (not (null (tne-current-collapsed-collection))))

(defun tne-set-collapsed-collection (collection)
  "Set the current collapsed COLLECTION."
  (setq tne-current-collapsed-collection collection))

(defun tne-clear-collapsed-collection-object ()
  "Clear the current collapsed collection object."
  (tne-set-collapsed-collection nil))

(defun tne-clear-collapsed-collection ()
  "Clear the current collapsed collection."
  (interactive)
  (tne-clear-collapsed-collection-object)
  (message
   "Collapsed collection cleared."))

(defun tne-show-collapsed-collection ()
  "Show the current collapsed collection state."
  (interactive)
  (let ((collection (tne-current-collapsed-collection)))
    (if collection
        (message
         (concat
          "Collapsed collection: "
          "Owners=%s Expanded=%s "
          "DefaultReturnMode=%s "
          "RegionCount=%s "
          "FocusedRegion=%s "
          "LatestSegment=%s "
          "FirstSegment=%s")
         (tne-collapsed-collection-owners collection)
         (tne-collapsed-collection-expanded-p collection)
         (tne-collapsed-collection-default-return-mode collection)
         (length
          (tne-collapsed-collection-regions collection))
         (tne-collapsed-collection-focused-region-id collection)
         (tne-collapsed-collection-latest-segment-id collection)
         (tne-collapsed-collection-first-segment-id collection))

      (message
       "Collapsed collection: none"))))

(defun tne-expand-collapsed-collection ()
  "Mark the current collapsed collection as expanded."
  (interactive)
  (let ((collection (tne-current-collapsed-collection)))
    (if collection
        (progn
          (setf (tne-collapsed-collection-expanded-p collection) t)
          (message
           "Collapsed collection expanded: Owners=%s"
           (tne-collapsed-collection-owners collection)))

      (message
       "Collapsed collection: none"))))

(defun tne-collapse-collapsed-collection ()
  "Mark the current collapsed collection as collapsed.

Collapsing the collection also clears the focused viewfinder
region, because no region remains actively focused after the
expanded collection closes."
  (interactive)
  (let ((collection (tne-current-collapsed-collection)))
    (if collection
        (progn
          (setf
           (tne-collapsed-collection-expanded-p collection)
           nil)
          (setf
           (tne-collapsed-collection-focused-region-id collection)
           nil)
          (message
           "Collapsed collection collapsed: Owners=%s FocusedRegion=nil"
           (tne-collapsed-collection-owners collection)))

      (message
       "Collapsed collection: none"))))

(defun tne-set-collapsed-collection-default-return-mode ()
  "Set the default return mode for the current collapsed collection."
  (interactive)
  (let ((collection (tne-current-collapsed-collection)))
    (if collection
        (let* ((choices
                '("follow-latest-entered"
                  "follow-first-entered"
                  "locked-to-selected"))

               (current
                (symbol-name
                 (tne-collapsed-collection-default-return-mode collection)))

               (selected
                (intern
                 (completing-read
                  "Default return mode: "
                  choices
                  nil
                  t
                  nil
                  nil
                  current))))

          (setf
           (tne-collapsed-collection-default-return-mode collection)
           selected)

          (message
           "Collapsed collection default return mode: %s"
           selected))

      (message
       "Collapsed collection: none"))))

(defun tne-add-viewfinder-region (region)
  "Add REGION to the current collapsed collection."
  (let ((collection (tne-current-collapsed-collection)))
    (if collection
        (setf
         (tne-collapsed-collection-regions collection)
         (append
          (tne-collapsed-collection-regions collection)
          (list region)))

      (message
       "Collapsed collection: none"))))

(defun tne-show-viewfinder-regions ()
  "Show the viewfinder regions in the current collapsed collection."
  (interactive)
  (let ((collection (tne-current-collapsed-collection)))
    (if collection
        (let ((regions
               (tne-collapsed-collection-regions collection)))
          (if regions
              (message
               "Viewfinder regions: %s"
               (mapconcat
                #'tne-format-viewfinder-region
                regions
                " | "))

            (message
             "Viewfinder regions: none")))

      (message
       "Collapsed collection: none"))))

(defun tne-format-viewfinder-region (region) ;;;
  "Return a readable summary string for REGION."
  (format
   (concat
    "ID=%s "
    "Column=%s "
    "Width=%s "
    "ReturnMode=%s "
    "Locked=%s "
    "LockedSegment=%s")
   (tne-viewfinder-region-id region)
   (tne-viewfinder-region-column region)
   (tne-viewfinder-region-width region)
   (tne-viewfinder-region-return-mode region)
   (if (tne-viewfinder-region-locked-p region)
       "yes"
     "no")
   (tne-viewfinder-region-locked-segment-id region)))

(defun tne-create-viewfinder-region ()
  "Create and add a viewfinder region to the current collapsed collection."
  (interactive)
  (let ((collection (tne-current-collapsed-collection)))
    (if collection
        (let* ((id
                (read-number
                 "Viewfinder region ID: "))

               (column
                (read-number
                 "Column: "))

               (width
                (read-number
                 "Width: "))

               (choices
                '("follow-latest-entered"
                  "follow-first-entered"
                  "locked-to-selected"))

               (return-mode
                (intern
                 (completing-read
                  "Return mode: "
                  choices
                  nil
                  t
                  nil
                  nil
                  (symbol-name
                   (tne-collapsed-collection-default-return-mode
                    collection)))))

               (locked-segment-id
                (if (eq return-mode 'locked-to-selected)
                    (read-number
                     "Locked segment ID: ")

                  nil))

               (region
                (make-tne-viewfinder-region
                 :id id
                 :column column
                 :width width
                 :return-mode return-mode
                 :locked-segment-id locked-segment-id)))

          (tne-add-viewfinder-region region)

          (message
           "Viewfinder region added: %s"
           (tne-format-viewfinder-region region)))

      (message
       "Collapsed collection: none"))))

(defun tne-find-viewfinder-region-by-id (id)
  "Return the viewfinder region with ID in the current collapsed collection."
  (let ((collection (tne-current-collapsed-collection)))
    (when collection
      (cl-find-if
       (lambda (region)
         (= (tne-viewfinder-region-id region)
            id))
       (tne-collapsed-collection-regions collection)))))

(defun tne-focused-viewfinder-region ()
  "Return the currently focused viewfinder region, if any."
  (let ((collection (tne-current-collapsed-collection)))
    (when collection
      (let ((focused-id
             (tne-collapsed-collection-focused-region-id
              collection)))
        (when focused-id
          (tne-find-viewfinder-region-by-id focused-id))))))

(defun tne-set-viewfinder-region-return-mode ()
  "Set the return mode for a viewfinder region."
  (interactive)
  (let* ((id
          (read-number
           "Viewfinder region ID: "))

         (region
          (tne-find-viewfinder-region-by-id id)))

    (if region
        (let* ((choices
                '("follow-latest-entered"
                  "follow-first-entered"
                  "locked-to-selected"))

               (current
                (symbol-name
                 (tne-viewfinder-region-return-mode region)))

               (return-mode
                (intern
                 (completing-read
                  "Return mode: "
                  choices
                  nil
                  t
                  nil
                  nil
                  current)))

               (locked-segment-id
                (if (eq return-mode 'locked-to-selected)
                    (read-number
                     "Locked segment ID: ")

                  nil)))

          (setf
           (tne-viewfinder-region-return-mode region)
           return-mode)

          (setf
           (tne-viewfinder-region-locked-segment-id region)
           locked-segment-id)

          (message
           "Viewfinder region updated: %s"
           (tne-format-viewfinder-region region)))

      (message
       "Viewfinder region not found: %s"
       id))))

(defun tne-lock-viewfinder-region-to-segment ()
  "Lock a viewfinder region to a selected segment ID."
  (interactive)
  (let* ((region-id
          (read-number
           "Viewfinder region ID: "))

         (region
          (tne-find-viewfinder-region-by-id region-id)))

    (if region
        (let ((segment-id
               (read-number
                "Segment ID to display when collapsed: ")))

          (tne-lock-viewfinder-region-object-to-segment
	   region
	   segment-id)

          (message
           "Viewfinder region locked: Region=%s Segment=%s"
           region-id
           segment-id))

      (message
       "Viewfinder region not found: %s"
       region-id))))

(defun tne-unlock-viewfinder-region ()
  "Unlock a viewfinder region.

Unlocked regions currently return to follow-latest-entered mode."
  (interactive)
  (let* ((region-id
          (read-number
           "Viewfinder region ID: "))

         (region
          (tne-find-viewfinder-region-by-id region-id)))

    (if region
        (progn
          (tne-unlock-viewfinder-region-object region)

          (message
           "Viewfinder region unlocked: Region=%s ReturnMode=follow-latest-entered"
           region-id))

      (message
       "Viewfinder region not found: %s"
       region-id))))

(defun tne-lock-viewfinder-region-object-to-segment
    (region segment-id)
  "Lock REGION to SEGMENT-ID for collapsed display."
  (setf
   (tne-viewfinder-region-return-mode region)
   'locked-to-selected)
  (setf
   (tne-viewfinder-region-locked-segment-id region)
   segment-id))


(defun tne-unlock-viewfinder-region-object (region)
  "Unlock REGION for collapsed display.

Unlocked regions currently return to follow-latest-entered mode."
  (setf
   (tne-viewfinder-region-return-mode region)
   'follow-latest-entered)
  (setf
   (tne-viewfinder-region-locked-segment-id region)
   nil))

(defun tne-lock-focused-viewfinder-region-to-segment ()
  "Lock the focused viewfinder region to a selected segment ID."
  (interactive)
  (let ((region
         (tne-focused-viewfinder-region)))
    (if region
        (let* ((region-id
                (tne-viewfinder-region-id region))

               (segment-id
                (read-number
                 "Segment ID to display when collapsed: ")))

          (tne-lock-viewfinder-region-object-to-segment
	   region
	   segment-id)

          (message
           "Focused viewfinder region locked: Region=%s Segment=%s"
           region-id
           segment-id))

      (message
       "No focused viewfinder region."))))

(defun tne-unlock-focused-viewfinder-region ()
  "Unlock the focused viewfinder region.

Unlocked regions currently return to follow-latest-entered mode."
  (interactive)
  (let ((region
         (tne-focused-viewfinder-region)))
    (if region
        (let ((region-id
               (tne-viewfinder-region-id region)))

          (tne-unlock-viewfinder-region-object region)

          (message
           (concat
            "Focused viewfinder region unlocked: "
            "Region=%s ReturnMode=follow-latest-entered")
           region-id))

      (message
       "No focused viewfinder region."))))

(defun tne-toggle-viewfinder-region-latest-lock (region)
  "Toggle REGION between following latest and locking the latest segment."
  (let ((latest-id
         (tne-latest-segment-id-for-collapsed-collection)))

    (cond

     ((not latest-id)
      (message
       "No latest segment is available."))

     ((and
       (eq (tne-viewfinder-region-return-mode region)
           'locked-to-selected)
       (equal
        (tne-viewfinder-region-locked-segment-id region)
        latest-id))
      (tne-unlock-viewfinder-region-object region)
      (message
       "Viewfinder region now follows latest: Region=%s LatestSegment=%s"
       (tne-viewfinder-region-id region)
       latest-id))

     ((tne-viewfinder-region-showing-latest-p region)
      (tne-lock-viewfinder-region-object-to-segment
       region
       latest-id)
      (message
       "Viewfinder region locked to latest: Region=%s Segment=%s"
       (tne-viewfinder-region-id region)
       latest-id))

     (t
      (message
       (concat
        "Viewfinder region is not showing latest; "
        "no toggle performed. Region=%s Representative=%s LatestSegment=%s")
       (tne-viewfinder-region-id region)
       (tne-viewfinder-region-collapsed-representative-id region)
       latest-id)))))

(defun tne-clear-viewfinder-regions ()
  "Clear all viewfinder regions from the current collapsed collection."
  (interactive)
  (let ((collection (tne-current-collapsed-collection)))
    (if collection
        (progn
          (setf
           (tne-collapsed-collection-regions collection)
           nil)
          (message
           "Viewfinder regions cleared."))

      (message
       "Collapsed collection: none"))))

(defun tne-toggle-viewfinder-region-latest-lock-by-id ()
  "Toggle a viewfinder region between locking and following latest."
  (interactive)
  (let* ((region-id
          (read-number
           "Viewfinder region ID: "))

         (region
          (tne-find-viewfinder-region-by-id region-id)))

    (if region
        (tne-toggle-viewfinder-region-latest-lock region)

      (message
       "Viewfinder region not found: %s"
       region-id))))

(defun tne-toggle-focused-viewfinder-region-latest-lock ()
  "Toggle the focused viewfinder region between locking and following latest."
  (interactive)
  (let ((region
         (tne-focused-viewfinder-region)))
    (if region
        (tne-toggle-viewfinder-region-latest-lock region)

      (message
       "No focused viewfinder region."))))

(defun tne-create-test-collapsed-collection ()
  "Create a test collapsed collection for N4 through N6.

This is a development helper. It does not yet affect rendering."
  (interactive)
  (tne-set-collapsed-collection
   (make-tne-collapsed-collection
    :owners '(n4 n5 n6)
    :expanded-p nil
    :default-return-mode 'follow-latest-entered
    :regions nil
    :focused-region-id nil
    :latest-segment-id nil
    :first-segment-id nil))
  (message
   "Test collapsed collection created: Owners=(n4 n5 n6) Expanded=nil DefaultReturnMode=follow-latest-entered Regions=nil"))

(defun tne-reset-test-collapsed-display-state ()
  "Reset test collapsed display state.

This is a development helper. It creates a test collapsed collection
for N4 through N6 and adds one default viewfinder region."
  (interactive)
  (tne-set-display-mode 'stack-in-viewfinder)
  (tne-clear-display-choice-object)
  (tne-set-collapsed-collection
   (make-tne-collapsed-collection
    :owners '(n4 n5 n6)
    :expanded-p nil
    :default-return-mode 'follow-latest-entered
    :regions nil
    :focused-region-id nil
    :latest-segment-id 23
    :first-segment-id 11))

  (tne-add-viewfinder-region
   (make-tne-viewfinder-region
    :id 1
    :column 19
    :width 12
    :return-mode 'follow-latest-entered
    :locked-segment-id nil))

  (tne-add-viewfinder-region
   (make-tne-viewfinder-region
    :id 2
    :column 45
    :width 12
    :return-mode 'locked-to-selected
    :locked-segment-id 17))

  (message
   (concat
    "Test collapsed display reset: "
    "Mode=stack-in-viewfinder "
    "Choice=none "
    "Owners=(n4 n5 n6) "
    "Expanded=nil "
    "FocusedRegion=nil "
    "FirstSegment=11 "
    "LatestSegment=23 "
    "Regions=2 "
    "Region1=follow-latest-entered "
    "Region2=locked-to-selected:17")))

(defun tne-verify-test-collapsed-display-state ()
  "Verify the development test collapsed display state."
  (interactive)
  (let* ((region-1
          (tne-find-viewfinder-region-by-id 1))

         (region-2
          (tne-find-viewfinder-region-by-id 2))

         (rep-1
          (when region-1
            (tne-viewfinder-region-collapsed-representative-id
             region-1)))

         (rep-2
          (when region-2
            (tne-viewfinder-region-collapsed-representative-id
             region-2))))

    (message
     (concat
      "Test collapsed display verification: "
      "Region1Representative=%s "
      "Region2Representative=%s "
      "ExpectedRegion1=23 "
      "ExpectedRegion2=17 "
      "Pass=%s")
     rep-1
     rep-2
     (if (and
          (equal rep-1 23)
          (equal rep-2 17))
         "yes"
       "no"))))

(defun tne-viewfinder-region-showing-latest-p (region)
  "Return non-nil when REGION is currently showing the latest segment."
  (let ((latest-id
         (tne-latest-segment-id-for-collapsed-collection))

        (representative-id
         (tne-viewfinder-region-collapsed-representative-id
          region)))
    (and latest-id
         representative-id
         (= latest-id representative-id))))

(defun tne-show-collapsed-display-state ()
  "Show the current collapsed display state."
  (interactive)
  (let ((collection (tne-current-collapsed-collection)))
    (if collection
        (let ((regions
               (tne-collapsed-collection-regions collection)))
          (message
           (concat
            "Collapsed display: "
            "Owners=%s Expanded=%s "
            "FocusedRegion=%s "
            "LatestSegment=%s "
            "FirstSegment=%s "
            "DefaultReturnMode=%s "
            "Regions=%s")
           (tne-collapsed-collection-owners collection)
           (tne-collapsed-collection-expanded-p collection)
           (tne-collapsed-collection-focused-region-id collection)
           (tne-collapsed-collection-latest-segment-id collection)
           (tne-collapsed-collection-first-segment-id collection)
           (tne-collapsed-collection-default-return-mode collection)
           (if regions
               (mapconcat
                #'tne-format-viewfinder-region
                regions
                " | ")
             "none")))

      (message
       "Collapsed display: none"))))

(defun tne-set-collapsed-collection-latest-segment ()
  "Set the latest segment ID for the current collapsed collection."
  (interactive)
  (let ((collection (tne-current-collapsed-collection)))
    (if collection
        (let ((id
               (read-number
                "Latest segment ID: ")))
          (setf
           (tne-collapsed-collection-latest-segment-id
            collection)
           id)
          (message
           "Collapsed collection latest segment: %s"
           id))

      (message
       "Collapsed collection: none"))))

(defun tne-set-collapsed-collection-first-segment ()
  "Set the first segment ID for the current collapsed collection."
  (interactive)
  (let ((collection (tne-current-collapsed-collection)))
    (if collection
        (let ((id
               (read-number
                "First segment ID: ")))
          (setf
           (tne-collapsed-collection-first-segment-id
            collection)
           id)
          (message
           "Collapsed collection first segment: %s"
           id))

      (message
       "Collapsed collection: none"))))

(defun tne-set-focused-viewfinder-region (id)
  "Set the focused viewfinder region to ID."
  (let ((collection (tne-current-collapsed-collection)))
    (if collection
        (setf
         (tne-collapsed-collection-focused-region-id collection)
         id)

      (message
       "Collapsed collection: none"))))

(defun tne-clear-focused-viewfinder-region ()
  "Clear the focused viewfinder region.

This does not collapse the collapsed collection. It only clears
which viewfinder region is currently focused."
  (interactive)
  (let ((collection (tne-current-collapsed-collection)))
    (if collection
        (progn
          (setf
           (tne-collapsed-collection-focused-region-id collection)
           nil)
          (message
           "Focused viewfinder region cleared."))

      (message
       "Collapsed collection: none"))))

(defun tne-focus-viewfinder-region ()
  "Focus a viewfinder region by ID.

Focusing a region marks that region as the local entry point.
It does not limit expansion to that region; expansion remains
collective for the collapsed collection."
  (interactive)
  (let* ((id
          (read-number
           "Viewfinder region ID: "))

         (region
          (tne-find-viewfinder-region-by-id id))

         (collection
          (tne-current-collapsed-collection)))

    (cond

     ((not collection)
      (message
       "Collapsed collection: none"))

     ((not region)
      (message
       "Viewfinder region not found: %s"
       id))

     (t
      (tne-set-focused-viewfinder-region id)
      (setf
       (tne-collapsed-collection-expanded-p collection)
       t)
      (message
       "Viewfinder region focused: %s; collection expanded."
       id)))))

(defun tne-latest-segment-id-for-collapsed-collection ()
  "Return the latest-entered segment ID for the current collapsed collection.

This is an early placeholder. Later this should be derived from
real segment creation order."
  (let ((collection (tne-current-collapsed-collection)))
    (when collection
      (tne-collapsed-collection-latest-segment-id collection))))

(defun tne-first-segment-id-for-collapsed-collection ()
  "Return the first-entered segment ID for the current collapsed collection.

This is an early placeholder. Later this should be derived from
real segment creation order."
  (let ((collection (tne-current-collapsed-collection)))
    (when collection
      (tne-collapsed-collection-first-segment-id collection))))

(defun tne-viewfinder-region-collapsed-segment-id
    (region)
  "Return the segment ID REGION should display while collapsed.

Current simplified rule:

If REGION has a locked segment ID, use it.

Otherwise, follow REGION's return mode.

For now, follow-first-entered uses the collection's first segment
placeholder, and follow-latest-entered uses the collection's
latest segment placeholder."
  (cond

   ((tne-viewfinder-region-locked-p region)
    (tne-viewfinder-region-locked-segment-id region))

   ((eq (tne-viewfinder-region-return-mode region)
        'follow-first-entered)
    (or
     (tne-first-segment-id-for-collapsed-collection)
     (tne-latest-segment-id-for-collapsed-collection)))

   (t
    (tne-latest-segment-id-for-collapsed-collection))))

(defun tne-viewfinder-region-collapsed-representative-id (region)
  "Return the segment ID REGION represents while collapsed."
  (tne-viewfinder-region-collapsed-segment-id region))

(defun tne-viewfinder-region-locked-p (region)
  "Return non-nil when REGION has a locked segment."
  (not
   (null
    (tne-viewfinder-region-locked-segment-id region))))

(defun tne-viewfinder-region-collapsed-representative-reason
    (region)
  "Return why REGION displays its collapsed representative."
  (cond

   ((tne-viewfinder-region-locked-p region)
    'locked-segment)

   ((eq (tne-viewfinder-region-return-mode region)
        'follow-first-entered)
    'first-segment)

   (t
    'latest-segment)))

(defun tne-format-viewfinder-region-collapsed-display
    (region)
  "Return a readable collapsed-display summary for REGION."
  (format
   (concat
    "ID=%s "
    "CollapsedRepresentative=%s "
    "RepresentativeReason=%s "
    "ReturnMode=%s "
    "LockedSegment=%s")
   (tne-viewfinder-region-id region)
   (tne-viewfinder-region-collapsed-representative-id region)
   (tne-viewfinder-region-collapsed-representative-reason
    region)
   (tne-viewfinder-region-return-mode region)
   (tne-viewfinder-region-locked-segment-id region)))

(defun tne-show-viewfinder-collapsed-displays ()
  "Show what each viewfinder region would display when collapsed."
  (interactive)
  (let ((collection (tne-current-collapsed-collection)))
    (if collection
        (let ((regions
               (tne-collapsed-collection-regions collection)))
          (if regions
              (message
               "Collapsed representatives: %s"
               (mapconcat
                #'tne-format-viewfinder-region-collapsed-display
                regions
                " | "))

            (message
             "Collapsed representatives: none")))

      (message
       "Collapsed collection: none"))))

(defun tne-show-viewfinder-collapsed-representatives ()
  "Show what each viewfinder region represents while collapsed."
  (interactive)
  (tne-show-viewfinder-collapsed-displays))

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
  (tne-narrative-owner-p owner))

(defun tne-normalize-range-owner (owner)
  (cond
   ((symbolp owner) owner)
   ((stringp owner) (intern (downcase owner)))
   (t owner)))

(defun tne-read-range-owner ()
  (intern
   (completing-read
    "Owner: "
    (mapcar
     #'symbol-name
     tne-visible-narrative-owners)
    nil
    nil)))

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

(defun tne-range-width (range)
  "Return the inclusive width of RANGE."
  (when range
    (1+ (- (tne-range-end range)
           (tne-range-start range)))))

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
	(tne-resolve-insertion-point
	 (tne-compute-insertion-point-for-range-a)))
  
  (if tne-current-insertion-point
      (message "Range A set: %s %s-%s"
               (tne-range-owner tne-range-a)
               (tne-range-start tne-range-a)
               (tne-range-end tne-range-a))
    (message
     "Range A set, but projected insertion positions are occupied. No insertion point assigned.")))

(defun tne-set-range-b (owner start end &optional text)
  (setq tne-range-b
        (tne-make-range-checked owner start end text))
  (setq tne-range-b-segment-id nil)
  (message "Range B set: %s %s-%s"
           (tne-range-owner tne-range-b)
           (tne-range-start tne-range-b)
           (tne-range-end tne-range-b)))

(defun tne-rendered-line-for-owner (owner)
  "Return the rendered buffer line number for OWNER.

Only owners currently listed in `tne-visible-narrative-owners'
have standalone rendered buffer lines."
  (let ((position
         (cl-position
          owner
          tne-visible-narrative-owners)))
    (when position
      (1+ position))))

(defun tne-buffer-position-for-insertion-point ()
  "Return the buffer position for `tne-current-insertion-point'."
  (when tne-current-insertion-point
    (let* ((owner
            (tne-insertion-point-owner
             tne-current-insertion-point))

           (column
            (tne-insertion-point-column
             tne-current-insertion-point))

           (line
            (tne-rendered-line-for-owner owner)))

      (when line
        (save-excursion
          (goto-char (point-min))
          (forward-line (1- line))
          (move-to-column (1- column) t)
          (point))))))

(defun tne-goto-insertion-point ()
  "Move point to the current transient insertion point."
  (interactive)
  (let ((position
         (tne-buffer-position-for-insertion-point)))

    (if position
        (progn
          (goto-char position)
          (message
           "Moved to insertion point: Owner=%s Column=%s"
           (tne-insertion-point-owner tne-current-insertion-point)
           (tne-insertion-point-column tne-current-insertion-point)))

      (message
       "Insertion point: not set"))))

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
  "Return narrative owner for rendered LINE-NUMBER.

This maps visible standalone lines only.
Future viewfinder lines should use a separate projection lookup."
  (nth
   (1- line-number)
   tne-visible-narrative-owners))

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
  "Set Range A from the current single-line selection.

Any projected cursor is presentation state and is removed before the
selection is interpreted.  The consumed region is then deactivated
before point moves to the insertion point."
  (interactive)

  (tne-clear-projected-cursor)

  (pcase-let ((`(,owner ,start ,end ,text)
               (tne-selection-to-range-data)))

    (tne-set-range-a
     owner
     start
     end
     text)

    (deactivate-mark)

    (tne-goto-insertion-point)))


(defun tne-set-range-b-from-selection ()
  "Set Range B from the current single-line selection.

Any projected cursor is presentation state and is removed before the
selection is interpreted.  The consumed region is deactivated after the
Range has been recorded."
  (interactive)

  (tne-clear-projected-cursor)

  (pcase-let ((`(,owner ,start ,end ,text)
               (tne-selection-to-range-data)))

    (tne-set-range-b
     owner
     start
     end
     text)

    (deactivate-mark)))

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

(defun tne-document-segments-for-owner (owner)
  "Return the document segment list for OWNER."
  (pcase owner
    ('n1
     (tne-document-n1-segments tne-current-document))
    ('n2
     (tne-document-n2-segments tne-current-document))
    ('n3
     (tne-document-n3-segments tne-current-document))
    (_
     nil)))

(defun tne-owner-below (owner)
  "Return the next visible narrative owner below OWNER, if any.

This only searches currently visible standalone narrative lines.
It does not create N4 and does not enter a viewfinder."
  (let* ((position
          (cl-position
           owner
           tne-visible-narrative-owners))

         (next-position
          (when position
            (1+ position))))

    (when next-position
      (nth
       next-position
       tne-visible-narrative-owners))))

(defun tne-last-visible-narrative-owner ()
  "Return the last currently visible standalone narrative owner."
  (car
   (last
    tne-visible-narrative-owners)))

(defun tne-last-visible-narrative-owner ()
  "Return the last currently visible standalone narrative owner."
  (car
   (last
    tne-visible-narrative-owners)))

(defun tne-clear-oplacement-choice ()
  "Clear the current blocked-placement choice state."
  (setq tne-current-placement-choice nil))

(defun tne-make-blocked-placement-choice (requested-point)
  "Create a blocked-placement choice for REQUESTED-POINT.

This does not ask the user anything yet.
It records the future decision point where the user may choose
to add another narrative line or use a viewfinder projection."
  (make-tne-placement-choice
   :status 'blocked
   :requested-owner
   (tne-insertion-point-owner requested-point)
   :anchor-owner
   (tne-last-visible-narrative-owner)
   :column
   (tne-insertion-point-column requested-point)
   :options
   '(add-narrative-line stack-in-viewfinder)
   :reason
   'visible-commentary-lines-occupied))

(defun tne-segments-at-position (owner column)
  "Return segments for OWNER that start at COLUMN."
  (seq-filter
   (lambda (segment)
     (= (tne-segment-start-column segment)
        column))
   (tne-document-segments-for-owner owner)))

(defun tne-insertion-point-occupied-p (insertion-point)
  "Return non-nil if INSERTION-POINT already has one or more segments."
  (when insertion-point
    (let ((owner
           (tne-insertion-point-owner insertion-point))

          (column
           (tne-insertion-point-column insertion-point)))

      (> (length
          (tne-segments-at-position owner column))
         0))))

(defun tne-resolve-insertion-point (insertion-point)
  "Return an available insertion point, moving downward once if needed.

If no visible insertion point is available, store a blocked
placement choice for future UI handling."
  (cond

   ((not insertion-point)
    (tne-clear-display-choice-object)
    nil)

   ((not (tne-insertion-point-occupied-p insertion-point))
    (tne-clear-display-choice-object)
    insertion-point)

   (t
    (let* ((owner
            (tne-insertion-point-owner insertion-point))

           (column
            (tne-insertion-point-column insertion-point))

           (below-owner
            (tne-owner-below owner))

           (below-point
            (when below-owner
              (make-tne-insertion-point
               :owner below-owner
               :column column
               :reason 'occupied-position-fallback))))

      (if (and below-point
               (not (tne-insertion-point-occupied-p below-point)))
          (progn
            (tne-clear-display-choice-object)
            below-point)

	(tne-set-display-choice
	 (make-tne-placement-choice
	  :status 'blocked
	  :requested-owner owner
	  :anchor-owner (tne-last-visible-narrative-owner)
	  :column column
	  :options '(add-narrative-line stack-in-viewfinder)
	  :reason 'visible-commentary-lines-occupied))

        nil)))))

(defun tne-show-segments-at-insertion-point ()
  "Show segments that already exist at the current insertion point."
  (interactive)
  (if tne-current-insertion-point
      (let* ((owner
              (tne-insertion-point-owner
               tne-current-insertion-point))

             (column
              (tne-insertion-point-column
               tne-current-insertion-point))

             (segments
              (tne-segments-at-position owner column)))

        (with-output-to-temp-buffer
            "*TNE Segments At Insertion Point*"

          (princ
           (format
            "Insertion point: Owner=%s Column=%s\n"
            owner
            column))

          (princ
           (format
            "Segments found: %s\n\n"
            (length segments)))

          (dolist (segment segments)
            (princ
             (format
              "SID=%s  Type=%s  Owner=%s  Start=%s  Aperture=%s  Text=\"%s\"\n"
              (tne-segment-id segment)
              (tne-segment-type segment)
              (tne-segment-owner segment)
              (tne-segment-start-column segment)
              (or (tne-segment-aperture-width segment) "none")
              (tne-segment-text segment))))))

    (message
     "Insertion point: not set")))

(defun tne-create-segment-at (owner column text &optional aperture-width)
  "Create a segment for OWNER at COLUMN containing TEXT."
  (let ((segment
         (make-tne-segment
          :id (tne-generate-segment-id)
          :type 'segment
          :owner owner
          :start-column column
          :text text
          :aperture-width aperture-width)))

    (tne-add-segment-to-document segment)
    segment))

(defun tne-add-segment-at-insertion-point ()
  "Add a segment at the current transient insertion point."
  (interactive)
  (if tne-current-insertion-point
      (let* ((owner
              (tne-insertion-point-owner
               tne-current-insertion-point))

             (column
              (tne-insertion-point-column
               tne-current-insertion-point))

             (text
              (read-string
               "Segment text: "))

             (segment
	      (tne-create-segment-at
	       owner
	       column
	       text
	       (tne-range-width tne-range-a))))

        (tne-redraw)

        (message
         "Added segment %s at %s column %s"
         (tne-segment-id segment)
         owner
         column))

    (message
     "Insertion point: not set")))

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
        "SID=%s  Type=%s  Owner=%s  Start=%s  Aperture=%s  Text=\"%s\"\n"

        (tne-segment-id s)
	(tne-segment-type s)
        (tne-segment-owner s)
        (tne-segment-start-column s)
	(or (tne-segment-aperture-width s) "none")
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

(defun tne-show-display-choice ()
  "Show the current blocked-placement choice, if one exists."
  (interactive)
  (let ((choice (tne-current-display-choice)))
    (if choice
        (message
         "Placement choice: Status=%s Requested=%s Anchor=%s Column=%s Options=%s DisplayMode=%s Reason=%s"
         (tne-placement-choice-status choice)
         (tne-placement-choice-requested-owner choice)
         (tne-placement-choice-anchor-owner choice)
         (tne-placement-choice-column choice)
         (tne-placement-choice-options choice)
         (tne-current-display-mode)
         (tne-placement-choice-reason choice))

      (message
       "Placement choice: none"))))

(defun tne-clear-display-choice ()
  "Clear the current blocked-placement display choice.

This does not change the current RE display mode."
  (interactive)
  (tne-clear-display-choice-object)
  (message
   "Display choice cleared. Display mode remains: %s"
   (tne-current-display-mode)))

(defun tne-reset-display-state ()
  "Reset the RE display state to its default startup values."
  (interactive)
  (tne-set-display-mode 'stack-in-viewfinder)
  (tne-clear-display-choice-object)
  (tne-clear-collapsed-collection-object)
  (message
   "Display state reset: Mode=stack-in-viewfinder Choice=none CollapsedCollection=none"))

(defun tne-show-placement-choice ()
  "Compatibility wrapper for `tne-show-display-choice'."
  (interactive)
  (tne-show-display-choice))

(defun tne-show-display-mode ()
  "Show the current RE display mode."
  (interactive)
  (if (tne-current-display-mode)
      (message
       "Display mode: %s"
       (tne-current-display-mode))

    (message
     "Display mode: none")))

(defun tne-show-display-state ()
  "Show the current RE display state."
  (interactive)
  (let ((choice (tne-current-display-choice))
        (collection (tne-current-collapsed-collection)))
    (message
     (concat
      "Display state: "
      "Mode=%s Choice=%s "
      "CollapsedCollection=%s "
      "Expanded=%s RegionCount=%s "
      "FocusedRegion=%s "
      "LatestSegment=%s "
      "FirstSegment=%s")
     (tne-current-display-mode)
     (if choice
         "present"
       "none")
     (if collection
         "present"
       "none")
     (if collection
         (tne-collapsed-collection-expanded-p collection)
       "n/a")
     (if collection
         (length
          (tne-collapsed-collection-regions collection))
       0)
     (if collection
         (tne-collapsed-collection-focused-region-id collection)
       "n/a")
     (if collection
         (tne-collapsed-collection-latest-segment-id collection)
       "n/a")
     (if collection
         (tne-collapsed-collection-first-segment-id collection)
       "n/a"))))

(defun tne-display-choice-present-p ()
  "Return non-nil when a blocked-placement display choice is present."
  (not (null (tne-current-placement-choice))))

(defun tne-current-display-choice ()
  "Return the current blocked-placement display choice object, if any."
  tne-current-placement-choice)

(defun tne-set-display-choice (choice)
  "Set the current blocked-placement display CHOICE object."
  (setq tne-current-placement-choice choice))

(defun tne-clear-display-choice-object ()
  "Clear the current blocked-placement display choice object."
  (tne-set-display-choice nil))

(defun tne-show-placement-decision ()
  "Compatibility wrapper for `tne-show-display-mode'."
  (interactive)
  (tne-show-display-mode))

(defun tne-toggle-placement-display-mode ()
  "Toggle the current RE display mode.

Option-TAB uses this command to switch between the compact
stacked viewfinder display and fully expanded narrative-line
display. For now, this changes stored state only; later it will
also trigger rerendering."
  (interactive)
  (pcase (tne-current-display-mode)

    ('stack-in-viewfinder
     (tne-set-display-mode 'add-narrative-line)
     (message
      "Display mode changed to: add-narrative-line"))

    ('add-narrative-line
     (tne-set-display-mode 'stack-in-viewfinder)
     (message
      "Display mode changed to: stack-in-viewfinder"))

    (_
     (tne-set-display-mode 'stack-in-viewfinder)
     (message
      "Display mode initialized to: stack-in-viewfinder"))))

(defun tne-set-display-mode (mode)
  "Set the current RE display MODE.

Also updates the older placement-decision variable during migration."
  (setq tne-current-display-mode mode)
  (setq tne-current-placement-decision mode))

(defun tne-current-display-mode ()
  "Return the current RE display mode.

During migration, keep the older placement-decision variable and
the newer display-mode variable synchronized."
  (unless (eq tne-current-display-mode
              tne-current-placement-decision)
    (setq tne-current-display-mode
          tne-current-placement-decision))
  tne-current-display-mode)

(defun tne-segment-entry-tab-dispatch ()
  "Handle future TAB behavior during segment entry.

When segment entry is active, TAB toggles between stacked
viewfinder display and fully expanded narrative-line display.

When segment entry is inactive, this function does not perform a
normal TAB. It only reports that ordinary TAB behavior should pass
through. This command is not yet globally bound."
  (interactive)
  (if tne-segment-entry-active-p
      (tne-toggle-placement-display-mode)

    (message
     "Segment entry inactive. Future TAB behavior: pass through to normal Emacs TAB.")))

(defun tne-handle-placement-choice ()
  "Handle the current blocked-placement choice."
  (interactive)
  (let ((choice (tne-current-display-choice)))
    (if (not choice)
        (message
         "No placement choice is currently pending.")

      (let* ((options
              (mapcar
               #'symbol-name
               (tne-placement-choice-options choice)))

             (selected
              (intern
               (completing-read
                "Display blocked placement as: "
                options
                nil
                t
                nil
                nil
                (symbol-name
                 (tne-current-display-mode))))))

        (pcase selected

          ('add-narrative-line
           (tne-set-display-mode 'add-narrative-line)
           (message
            "Display mode changed to: add-narrative-line"))

          ('stack-in-viewfinder
           (tne-set-display-mode 'stack-in-viewfinder)
           (message
            "Display mode changed to: stack-in-viewfinder"))

          (_
           (message
            "Unknown display mode: %s"
            selected)))))))

(defun tne-start-segment-entry ()
  "Enter segment-entry state.

This is a workflow hook. Future TAB behavior should become active
only while this state is non-nil."
  (interactive)
  (setq tne-segment-entry-active-p t)
  (message
   "Segment entry: active"))

(defun tne-end-segment-entry ()
  "Leave segment-entry state."
  (interactive)
  (setq tne-segment-entry-active-p nil)
  (message
   "Segment entry: inactive"))

(defun tne-show-segment-entry-state ()
  "Show whether segment-entry state is active."
  (interactive)
  (if tne-segment-entry-active-p
      (message
       "Segment entry: active")
    (message
     "Segment entry: inactive")))

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

(defvar-local tne--rendering-p nil
  "Non-nil while TNE is rebuilding the visible buffer.")

(defun tne-n1-buffer-text ()
  "Reconstruct N1 text from all rendered N1 display rows."
  (save-excursion
    (goto-char (point-min))

    (let ((parts nil))
      (while (not (eobp))
        (push
         (buffer-substring-no-properties
          (line-beginning-position)
          (line-end-position))
         parts)

        ;; Skip N2, N3, and the divider to reach the next N1 row.
        (forward-line 4))

      (apply #'concat
             (nreverse parts)))))

(defun tne-sync-n1-to-model (&rest _change)
  "Synchronize visible N1 text into the current document model.

This function runs from the buffer-local `after-change-functions' hook.
It shall not redraw the buffer, because rebuilding the presentation
inside an active buffer change interferes with ordinary undo grouping."
  (when (and
         (not tne--rendering-p)
         tne-current-document)

    (setf
     (tne-document-narrative-1 tne-current-document)
     (tne-n1-buffer-text))))

(defun tne-narrative-display-width ()
  "Return the usable narrative width in character columns.

Displayed line numbers consume columns that `window-text-width' may
still include.  Reserve those columns, plus one safety column, so an N1
row never soft-wraps inside a Narrative Display Block."
  (max 1
       (-
        (window-text-width)
        (line-number-display-width)
        2)))


(defun tne-wrap-narrative-text (text width)
  "Divide TEXT into display strings no wider than WIDTH.

Whitespace used at a wrap boundary remains in the preceding string so
concatenating the returned strings reproduces TEXT exactly."
  (if (string-empty-p text)
      (list "")

    (let ((start 0)
          (length (length text))
          (result nil))

      (while (< start length)
        (let* ((remaining (- length start))
               (maximum-end
                (min length (+ start width)))
               (end maximum-end))

          (when (< maximum-end length)
            (let ((search maximum-end)
                  (boundary nil))

              (while (and (> search start)
                          (not boundary))
                (when (memq (aref text (1- search))
                            '(?\s ?\t))
                  (setq boundary search))

                (setq search (1- search)))

              (when boundary
                (setq end boundary))))

          ;; A word longer than WIDTH is divided at WIDTH.
          (when (= end start)
            (setq end maximum-end))

          (push (substring text start end)
                result)

          (setq start end)))

      (nreverse result))))


(defun tne-n1-display-row-p ()
  "Return non-nil when point is on an N1 display row."
  (= (% (1- (line-number-at-pos)) 4)
     0))


(defun tne-buffer-position-to-n1-offset (&optional position)
  "Convert buffer POSITION to its zero-based N1 model offset.

POSITION defaults to point.  Positions outside an N1 row are clamped to
the nearest preceding N1 content offset."
  (save-excursion
    (goto-char (or position (point)))

    (let ((target-line (line-number-at-pos))
          (target-column (current-column))
          (offset 0)
          (line-number 1))

      (goto-char (point-min))

      (while (< line-number target-line)
        (when (= (% (1- line-number) 4) 0)
          (setq offset
                (+ offset
                   (- (line-end-position)
                      (line-beginning-position)))))

        (forward-line 1)
        (setq line-number (1+ line-number)))

      (when (= (% (1- target-line) 4) 0)
        (setq offset
              (+ offset
                 (min target-column
                      (- (line-end-position)
                         (line-beginning-position))))))

      offset)))


(defun tne-n1-offset-to-buffer-position (offset)
  "Return the buffer position representing zero-based N1 OFFSET."
  (save-excursion
    (goto-char (point-min))

    (let ((remaining (max 0 offset))
          (found nil)
          (position (point-min)))

      (while (and (not found)
                  (not (eobp)))
        (let ((row-length
               (- (line-end-position)
                  (line-beginning-position))))

          (if (<= remaining row-length)
              (progn
                (setq position
                      (+ (line-beginning-position)
                         remaining))
                (setq found t))

            (setq remaining
                  (- remaining row-length))

            ;; Move from this N1 row to the next block's N1 row.
            (forward-line 4))))

      (unless found
        (setq position
              (line-end-position)))

      position)))


(defun tne-current-n1-display-parts ()
  "Return the N1 strings currently displayed in all narrative blocks."
  (save-excursion
    (goto-char (point-min))

    (let ((parts nil))
      (while (< (point) (point-max))
        (push
         (buffer-substring-no-properties
          (line-beginning-position)
          (line-end-position))
         parts)

        ;; Move from this N1 row to the next block's N1 row.
        (forward-line 4))

      (nreverse parts))))


(defun tne-required-n1-display-parts ()
  "Return the canonical N1 display strings required by the model."
  (when tne-current-document
    (tne-wrap-narrative-text
     (tne-document-narrative-1
      tne-current-document)

     (tne-narrative-display-width))))


(defun tne-live-reflow-needed-p ()
  "Return non-nil when rendered N1 rows differ from canonical layout."
  (and
   tne-current-document
   (not tne--rendering-p)

   (not
    (equal
     (tne-current-n1-display-parts)
     (tne-required-n1-display-parts)))))


(defun tne-maybe-live-reflow ()
  "Restore canonical Narrative Display Blocks after an editing command.

The persistent model has already been updated by
`tne-sync-n1-to-model'.  Reflow occurs only after the originating
command and its undo record have completed."
  (when
      (and
       (derived-mode-p 'tne-mode)
       (tne-live-reflow-needed-p))

    (tne-redraw)))


(defun tne-render-display-block
    (n1-text n2-text n3-text &optional divider-p)
  "Insert one Narrative Display Block.

N1-TEXT, N2-TEXT, and N3-TEXT are the visible narrative rows.
When DIVIDER-P is non-nil, insert a blank divider row after N3."
  (insert n1-text "\n")
  (insert n2-text "\n")
  (insert n3-text "\n")

  (when divider-p
    (insert "\n")))


(defun tne-render-document (document)
  "Insert DOCUMENT as one or more Narrative Display Blocks."
  (let* ((width
          (tne-narrative-display-width))

         (n1-parts
          (tne-wrap-narrative-text
           (tne-document-narrative-1 document)
           width))

         (n2-text
          (tne-render-segments
           (tne-document-n2-segments document)))

         (n3-text
          (tne-render-segments
           (tne-document-n3-segments document)))

         (first-block-p t))

    (dolist (n1-part n1-parts)
      (tne-render-display-block
       n1-part
       (if first-block-p n2-text "")
       (if first-block-p n3-text "")
       t)

      (setq first-block-p nil))))


(defun tne-current-narrative-owner ()
  "Return the narrative owner of point's current display row."
  (pcase
      (% (1- (line-number-at-pos)) 4)

    (0 'n1)
    (1 'n2)
    (2 'n3)
    (_ nil)))


(defun tne-goto-narrative-row-end (owner)
  "Move point to the canonical end of OWNER in the current block.

This function restores only a real buffer position.  It does not
recreate projected cursor geometry."
  (goto-char (point-min))

  (pcase owner
    ('n1 nil)
    ('n2 (forward-line 1))
    ('n3 (forward-line 2))
    (_ nil))

  (end-of-line))


(defun tne-redraw ()
  "Rebuild the visible TNE buffer from the current document model.

N1 positions are preserved by canonical N1 offset.  Positions on N2 or
N3 resolve to the end of that narrative's canonical rendered content.
Projected cursor state is discarded because redraw creates a new
presentation."
  (interactive)

  (unless tne-current-document
    (user-error "No current TNE document"))

  (let* ((inhibit-read-only t)
         (tne--rendering-p t)

         (saved-owner
          (tne-current-narrative-owner))

         (n1-length
          (length
           (tne-document-narrative-1
            tne-current-document)))

         (saved-n1-offset
          (when (eq saved-owner 'n1)
            (min
             (tne-buffer-position-to-n1-offset)
             n1-length))))

    ;; The old overlay belongs to the old projection.
    (tne-clear-projected-cursor)

    (setq tne-layout-records nil)

    ;; Redrawing is a projection of model state.  It must not create
    ;; additional user-visible undo steps.
    (let ((buffer-undo-list t))
      (erase-buffer)

      (tne-render-document
       tne-current-document))

    (if (eq saved-owner 'n1)
        (goto-char
         (tne-n1-offset-to-buffer-position
          saved-n1-offset))

      (tne-goto-narrative-row-end
       saved-owner))))

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

    (let ((owner
	   (if (= n 2)
               'n2
             'n3)))

      (tne-create-segment-at owner c txt)
      (tne-redraw))))))

(defun tne-add-n2-segment()(interactive)(tne-add-segment 2))
(defun tne-add-n3-segment()(interactive)(tne-add-segment 3))
(defun tne--changed-text-region (before after)
  "Return the changed region between BEFORE and AFTER.

The result is a cons cell whose car is the zero-based beginning
offset and whose cdr is the zero-based ending offset in AFTER."
  (let* ((before-length (length before))
         (after-length (length after))
         (prefix-length 0)
         (maximum-prefix
          (min before-length after-length)))

    (while
        (and
         (< prefix-length maximum-prefix)
         (eq
          (aref before prefix-length)
          (aref after prefix-length)))

      (setq prefix-length
            (1+ prefix-length)))

    (let* ((before-remaining
            (- before-length prefix-length))

           (after-remaining
            (- after-length prefix-length))

           (suffix-length 0)

           (maximum-suffix
            (min before-remaining after-remaining)))

      (while
          (and
           (< suffix-length maximum-suffix)

           (eq
            (aref
             before
             (- before-length suffix-length 1))

            (aref
             after
             (- after-length suffix-length 1))))

        (setq suffix-length
              (1+ suffix-length)))

      (cons
       prefix-length
       (- after-length suffix-length)))))


(defvar-local tne--undo-stack nil
  "Model snapshots available to RE undo.")

(defvar-local tne--redo-stack nil
  "Model snapshots available to RE redo.")

(defvar-local tne--pending-before-snapshot nil
  "Model snapshot captured before the current command.")

(defvar-local tne--last-edit-kind nil
  "Kind of the most recently recorded consecutive edit.")

(defvar-local tne--restoring-history-p nil
  "Non-nil while RE history is restoring a snapshot.")


(defun tne-current-model-snapshot ()
  "Return the current N1 model text and insertion-point offset."
  (list
   :n1-text
   (tne-document-narrative-1
    tne-current-document)

   :n1-offset
   (tne-buffer-position-to-n1-offset)))


(defun tne-edit-command-kind (command)
  "Return the history grouping kind for COMMAND."
  (cond
   ((memq command
          '(self-insert-command
            tne-self-insert-command
            yank
            yank-pop))
    'insert)

   ((memq command
          '(delete-backward-char
            backward-delete-char-untabify
            delete-forward-char
            kill-region
            kill-word
            backward-kill-word))
    'delete)

   (t nil)))


(defun tne-history-before-command ()
  "Capture canonical model state before the next editing command."
  (if (or
       tne--restoring-history-p
       (memq this-command
             '(tne-undo tne-redo)))

      (setq tne--pending-before-snapshot nil)

    (setq
     tne--pending-before-snapshot
     (tne-current-model-snapshot))))


(defun tne-history-after-command ()
  "Record a completed model edit and restore canonical layout."
  (unless
      (or
       tne--restoring-history-p
       (memq this-command
             '(tne-undo tne-redo)))

    (when (tne-live-reflow-needed-p)
      (tne-redraw))

    (let* ((before
            tne--pending-before-snapshot)

           (after
            (tne-current-model-snapshot))

           (kind
            (tne-edit-command-kind
             this-command)))

      (if (and
           before
           (not
            (equal
             (plist-get before :n1-text)
             (plist-get after :n1-text))))

          (progn
            ;; Consecutive insertions form one undo unit.
            ;; Consecutive deletions form one undo unit.
            (unless (eq kind tne--last-edit-kind)
              (push before
                    tne--undo-stack))

            ;; A genuine new edit invalidates redo history.
            (setq tne--redo-stack nil)
            (setq tne--last-edit-kind kind))

        (unless kind
          (setq tne--last-edit-kind nil)))))

  (setq tne--pending-before-snapshot nil))


(defun tne-restore-model-snapshot (snapshot)
  "Restore N1 representation and point from SNAPSHOT."
  (let ((tne--restoring-history-p t))
    (setf
     (tne-document-narrative-1
      tne-current-document)

     (plist-get snapshot :n1-text))

    (tne-redraw)

    (goto-char
     (tne-n1-offset-to-buffer-position
      (plist-get snapshot :n1-offset)))))


(defun tne-undo ()
  "Restore the previous canonical RE model state."
  (interactive)

  (unless tne--undo-stack
    (user-error "No further RE undo information"))

  (let ((current
         (tne-current-model-snapshot))

        (previous
         (pop tne--undo-stack)))

    (push current
          tne--redo-stack)

    (setq tne--last-edit-kind nil)

    (tne-restore-model-snapshot
     previous)))


(defun tne-redo ()
  "Restore the next canonical RE model state."
  (interactive)

  (unless tne--redo-stack
    (user-error "No further RE redo information"))

  (let ((current
         (tne-current-model-snapshot))

        (next
         (pop tne--redo-stack)))

    (push current
          tne--undo-stack)

    (setq tne--last-edit-kind nil)

    (tne-restore-model-snapshot
     next)))


(define-derived-mode tne-mode text-mode "TNE"
  "Major mode for the Three-Narrative Relationship Editor."

  (setq buffer-read-only nil)

  ;; During the originating keystroke, allow Emacs to display a
  ;; temporary visual continuation rather than horizontally scrolling.
  ;; The post-command reflow then replaces that temporary presentation
  ;; with canonical Narrative Display Blocks.
  (setq-local truncate-lines nil)

  (unless tne-current-document
    (setq tne-current-document
          (tne-model-create-default)))

  (add-hook
   'after-change-functions
   #'tne-sync-n1-to-model
   nil
   t)

  ;; RE history records canonical model states rather than transient
  ;; physical buffer coordinates.
  (add-hook
   'pre-command-hook
   #'tne-history-before-command
   nil
   t)

  (add-hook
   'post-command-hook
   #'tne-history-after-command
   nil
   t)

  (tne-redraw)

  (goto-char (point-min))

  ;; Canonical RE history replaces position-based buffer undo because
  ;; live reflow changes physical buffer coordinates.
  (buffer-disable-undo)

  (setq tne--undo-stack nil)
  (setq tne--redo-stack nil)
  (setq tne--pending-before-snapshot nil)
  (setq tne--last-edit-kind nil)

  (setq tne-boundary-edit-session nil)
  (setq tne-projected-column nil)
  (setq tne-projected-cursor-overlay nil))
(defun tne-new-document ()
  
  (interactive)

  (setq tne-range-a nil)
  (setq tne-range-b nil)
  (setq tne-range-a-segment-id nil)
  (setq tne-range-b-segment-id nil)
  (setq tne-current-insertion-point nil)
  (setq tne-current-placement-choice nil)
  (setq tne-segment-entry-active-p nil)

  (switch-to-buffer "*TNE*")

  (erase-buffer)

  (tne-mode))

(provide 'tne-mode)
