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

(require 'cl-lib)
(cl-defstruct tne-segment
  id
  type
  owner
  start-column
  text)
(cl-defstruct tne-relationship
  id
  source-id
  target-id
  type)
(cl-defstruct tne-pair-history-entry

  pair-a-segment-id
  pair-b-segment-id

  relationship-id

  relationship-type

  document-id

  timestamp)
(cl-defstruct tne-document
  id
  (narrative-1 "")
  (n1-segments nil)
  (n2-segments nil)
  (n3-segments nil)
  (relationships nil))
(cl-defstruct tne-layout-record
  segment-id
  start
  width
  height
  rows
  screen-row-start
  screen-row-end)
(defvar-local tne-current-document nil)
(defvar tne-next-segment-id 1)
(defvar tne-next-relationship-id 1)
(defvar tne-next-document-id 1)
(defvar tne-layout-records nil)
(defvar tne-selected-segment-id nil)

(defun tne-generate-document-id ()

  (prog1
      tne-next-document-id

    (setq tne-next-document-id
          (1+ tne-next-document-id))))

(cl-defstruct tne-range
  owner
  start
  end
  text)

(defvar tne-range-a nil)
(defvar tne-range-b nil)

(defvar tne-range-a-segment-id nil)
(defvar tne-range-b-segment-id nil)

(defvar tne-current-pair-a-segment-id nil)
(defvar tne-current-pair-b-segment-id nil)

(defvar tne-pair-history nil)

(defvar tne-relationship-types
  '(unsure relates-to supports contradicts))

(defun tne-generate-segment-id ()
  (prog1 tne-next-segment-id
    (setq tne-next-segment-id
          (1+ tne-next-segment-id))))

(defun tne-generate-relationship-id ()
  (prog1 tne-next-relationship-id
    (setq tne-next-relationship-id
          (1+ tne-next-relationship-id))))

(defun tne-model-create-default ()
  (make-tne-document

   :id
   (tne-generate-document-id)

   :narrative-1
   "Narrative 1"))

(defun tne-segment-end-column (segment)
  (+ (tne-segment-start-column segment)
     (length (tne-segment-text segment))
     -1))

(provide 'tne-model)

