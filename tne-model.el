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
  text
  aperture-width)
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

(cl-defstruct tne-insertion-point
  owner
  column
  reason)

(cl-defstruct tne-placement-choice
  status
  requested-owner
  anchor-owner
  column
  options
  reason)

(defvar tne-range-a nil)
(defvar tne-range-b nil)
(defvar tne-current-insertion-point nil)
(defvar tne-current-placement-choice nil)
(defvar tne-current-placement-decision 'stack-in-viewfinder
  "Current user-selected placement display mode.

Possible values:

stack-in-viewfinder
  Display additional narrative layers through a stacked viewfinder
  anchored in the last visible narrative owner.

add-narrative-line
  Display additional narrative layers as full standalone Nx lines.

This value is a user preference. It should not be reset merely
because a collision occurs. A collision should consult this value,
not overwrite it.")

(defvar tne-current-display-mode tne-current-placement-decision
  "Current user-selected RE display mode.

Possible values:

stack-in-viewfinder
  Display additional narrative layers through a stacked viewfinder
  anchored in the last visible narrative owner.

add-narrative-line
  Display additional narrative layers as full standalone Nx lines.

This is the broader display preference used by the RE.
The older name `tne-current-placement-decision' remains temporarily
as a compatibility alias during migration.")

(defvar tne-segment-entry-active-p nil
  "Non-nil when the user is actively entering segment text.

Future TAB behavior should only toggle placement display mode when
this value is non-nil. Outside segment entry, TAB should retain its
ordinary Emacs behavior.")

(defvar tne-range-a-segment-id nil)
(defvar tne-range-b-segment-id nil)

(defvar tne-current-pair-a-segment-id nil)
(defvar tne-current-pair-b-segment-id nil)

(defvar tne-pair-history nil)

(defvar tne-relationship-types
  '(unsure relates-to supports contradicts))

(defvar tne-visible-narrative-owners
  '(n1 n2 n3)
  "Narrative owners currently rendered as standalone visible lines.

N1 is the primary narrative.
N2 and N3 are the default commentary narrative lines.

Future owners such as N4, N5, and beyond may be displayed either
as standalone narrative lines or through viewfinder projections.")

(defvar tne-default-commentary-narrative-owners
  '(n2 n3)
  "Default commentary narrative owners available beneath N1.")

(defun tne-narrative-owner-p (owner)
  "Return non-nil if OWNER is a narrative owner symbol such as n1, n2, n3, n4."
  (and
   (symbolp owner)
   (string-match-p
    "\\`n[0-9]+\\'"
    (symbol-name owner))))

(defun tne-narrative-owner-number (owner)
  "Return numeric part of OWNER.

Example:
n3 returns 3."
  (when (tne-narrative-owner-p owner)
    (string-to-number
     (substring
      (symbol-name owner)
      1))))

(defun tne-narrative-owner-from-number (number)
  "Return narrative owner symbol for NUMBER.

Example:
4 returns n4."
  (intern
   (format "n%s" number)))

(defun tne-next-narrative-owner (owner)
  "Return the next narrative owner after OWNER.

Example:
n3 returns n4."
  (let ((number
         (tne-narrative-owner-number owner)))
    (when number
      (tne-narrative-owner-from-number
       (1+ number)))))

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

