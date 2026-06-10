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
         (segment-data nil)
         (max-height 0))

    ;; Build wrapped rows for every segment.
    (let ((remaining sorted))

      (while remaining

        (let* ((s (car remaining))
               (start (tne-segment-start-column s))
               (text  (tne-segment-text s))
               (next  (cadr remaining))

               (width
                (if next
                    (- (tne-segment-start-column next)
                       start)
                  (- (window-width)
                     start
                     -1)))

               (wrap-result
                (tne-wrap-text text width))

               (rows
                (plist-get wrap-result :lines)))

	  (push
 (make-tne-layout-record
  :segment-id
  (tne-segment-id s)

  :start
  start

  :width
  width

  :height
  (length rows)

  :rows
  rows)

 tne-layout-records)

          (setq max-height
                (max max-height
                     (length rows)))

          (push
           (list
            :start start
            :rows rows)
           segment-data))

        (setq remaining (cdr remaining))))

    (setq segment-data
          (nreverse segment-data))

    ;; Build output row-by-row.
    (let ((output ""))

      (dotimes (row-index max-height)

        (let ((line "")
              (current-column 1))

          (dolist (segment segment-data)

            (let* ((start
                    (plist-get segment :start))

                   (rows
                    (plist-get segment :rows))

                   (row-text
                    (if (< row-index (length rows))
                        (nth row-index rows)
                      ""))

                   (padding
                    (max 0
                         (- start current-column))))

              (setq line
                    (concat line
                            (make-string padding ?\s)
                            row-text))

              (setq current-column
                    (+ start
                       (length row-text)))))

          (setq output
                (concat output line))

          (unless (= row-index
                     (1- max-height))
            (setq output
                  (concat output "\n")))))

      (setq tne-layout-records
      (nreverse tne-layout-records))

      output)))

(provide 'tne-render)
