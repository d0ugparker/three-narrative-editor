(require 'tne-model)

(defun tne-wrap-text (text width)

  (when (< width 1)
    (setq width 1))
  
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
  "Render SEGMENTS with layout-owned separators between neighbors.

Each adjacent Segment pair receives exactly one visible ` | ` separator.
The separator occupies the three display columns immediately preceding
the Segment to its right.  It belongs to neither Segment's canonical
text and does not change either Segment's assigned starting column."
  (let* ((sorted
          (sort
           (copy-sequence segments)

           (lambda (left right)
             (<
              (tne-segment-start-column left)
              (tne-segment-start-column right)))))

         (segment-data nil)
         (max-height 0))

    ;; Build wrapped rows for every Segment.  A Segment with a neighbor
    ;; to its right must leave three columns for the layout separator.
    (let ((remaining sorted))
      (while remaining
        (let* ((segment
                (car remaining))

               (start
                (tne-segment-start-column segment))

               (text
                (tne-segment-text segment))

               (next
                (cadr remaining))

               (width
                (if next
                    (-
                     (tne-segment-start-column next)
                     start
                     3)

                  (-
                   (window-width)
                   start
                   -1))))

          (when (< width 1)
            (user-error
             "Insufficient territory between Segments %s and %s for ` | `"
             (tne-segment-id segment)
             (tne-segment-id next)))

          (let* ((wrap-result
                  (tne-wrap-text text width))

                 (rows
                  (plist-get wrap-result :lines)))

            (push
             (make-tne-layout-record
              :segment-id
              (tne-segment-id segment)

              :start
              start

              :width
              width

              :height
              (length rows)

              :rows
              rows)

             tne-layout-records)

            (setq
             max-height
             (max
              max-height
              (length rows)))

            (push
             (list
              :start start
              :rows rows)
             segment-data)))

        (setq remaining
              (cdr remaining))))

    (setq segment-data
          (nreverse segment-data))

    ;; Assemble each rendered row without changing assigned starts.
    (let ((output ""))
      (dotimes (row-index max-height)
        (let ((line "")
              (current-column 1)
              (first-segment-p t))

          (dolist (segment segment-data)
            (let* ((start
                    (plist-get segment :start))

                   (rows
                    (plist-get segment :rows))

                   (row-text
                    (if
                        (< row-index
                           (length rows))

                        (nth row-index rows)

                      ""))

                   (available-gap
                    (- start current-column)))

              (if first-segment-p
                  (progn
                    (when (< available-gap 0)
                      (user-error
                       "Segment begins before the available rendered position"))

                    (setq line
                          (concat
                           line
                           (make-string available-gap ?\s)
                           row-text))

                    (setq first-segment-p nil))

                (when (< available-gap 3)
                  (user-error
                   "Insufficient rendered territory for ` | ` separator"))

                (setq line
                      (concat
                       line
                       (make-string
                        (- available-gap 3)
                        ?\s)

                       " | "
                       row-text)))

              (setq current-column
                    (+
                     start
                     (length row-text)))))

          (setq output
                (concat output line))

          (unless
              (=
               row-index
               (1- max-height))

            (setq output
                  (concat output "\n")))))

      (setq tne-layout-records
            (nreverse tne-layout-records))

      output)))
(provide 'tne-render)
