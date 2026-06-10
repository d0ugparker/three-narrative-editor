(require 'cl-lib)
(cl-defstruct tne-segment id start-column text)
(cl-defstruct tne-document (narrative-1 "") (n2-segments nil) (n3-segments nil))
(cl-defstruct tne-layout-record segment-id start width height rows screen-row-start screen-row-end)
(defvar-local tne-current-document nil)
(defvar tne-next-segment-id 1)
(defvar tne-layout-records nil)
(defun tne-model-create-default () (make-tne-document :narrative-1 "Narrative 1"))
(provide 'tne-model)

(defun tne-generate-segment-id ()
  (prog1 tne-next-segment-id
    (setq tne-next-segment-id
          (1+ tne-next-segment-id))))
