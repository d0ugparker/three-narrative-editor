(require 'tne-model)

(defun tne-wrap-text (text width)
  (let ((words (split-string text " "))
        (lines nil)
        (current "")
        (forced-splits 0))

    (while words
      (let ((word (car words)))

        (cond

         ;; long word on empty line
         ((and (string= current "")
               (> (length word) width))

          (push (substring word 0 width) lines)

          (setq words
                (cons (substring word width)
                      (cdr words)))

          (setq forced-splits
                (1+ forced-splits)))

         ;; word fits
         ((<= (+ (length current)
                 (if (string= current "") 0 1)
                 (length word))
              width)

          (setq current
                (if (string= current "")
                    word
                  (concat current " " word)))

          (setq words (cdr words)))

         ;; wrap
         (t

          (push current lines)
          (setq current "")))))

    (unless (string= current "")
      (push current lines))

    (setq lines (nreverse lines))

    (list
     :lines lines
     :height (length lines)
     :forced-splits forced-splits)))

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
