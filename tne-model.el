(require 'cl-lib)
(cl-defstruct tne-segment id type owner start-column text)
(cl-defstruct tne-relationship
  id
  source-id
  target-id
  type)
(cl-defstruct tne-document (narrative-1 "") (n2-segments nil) (n3-segments nil) (relationships nil))
(cl-defstruct tne-layout-record segment-id start width height rows screen-row-start screen-row-end)
(defvar-local tne-current-document nil)
(defvar tne-next-segment-id 1)
(defvar tne-next-relationship-id 1)
(defvar tne-layout-records nil)
(defvar tne-selected-segment-id nil)
(defvar tne-relationship-types
  '(relates-to
    supports
    contradicts))
(defun tne-generate-segment-id ()
  (prog1 tne-next-segment-id
    (setq tne-next-segment-id
          (1+ tne-next-segment-id))))
(defun tne-generate-relationship-id ()
  (prog1 tne-next-relationship-id
    (setq tne-next-relationship-id
          (1+ tne-next-relationship-id))))
(defun tne-model-create-default () (make-tne-document :narrative-1 "Narrative 1"))
(defun tne-segment-end-column (segment)
  (+ (tne-segment-start-column segment)
     (length (tne-segment-text segment))
     -1))
(provide 'tne-model)

