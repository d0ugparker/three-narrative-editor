(require 'tne-model)

(defun tne-render-segments (segments)
(let* ((sorted
(sort (copy-sequence segments)
(lambda (a b)
(< (tne-segment-start-column a)
(tne-segment-start-column b)))))
(result "")
(current-column 1))

(dolist (s sorted)

  (let* ((start (tne-segment-start-column s))
         (text  (tne-segment-text s))
         (padding (max 0 (- start current-column))))

    (setq result
          (concat result
                  (make-string padding ?\s)
                  text))

    (setq current-column
          (+ start (length text))))

  (unless (eq s (car (last sorted)))
    (setq result
          (concat result " | "))
    (setq current-column
          (+ current-column 3))))

result))

(provide 'tne-render)
