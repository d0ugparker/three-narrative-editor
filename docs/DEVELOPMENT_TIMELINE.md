V0.3

Segment IDs introduced.

---

V0.4

Relationships become first-class objects.

---

V0.5

Transient workspace objects separated from persistent document objects.

---

V0.6

Interaction workflow replaces manual commands.

-------------------------------------------------------------------------------

## 260715 — Model-Backed N1 Editing

Implemented the first Alpha 0.1 vertical slice.

Confirmed behavior:

- new documents begin with blank N1 content,
- N1 receives the insertion point,
- ordinary text entry works,
- visible N1 edits synchronize into the document model,
- redraw preserves entered text,
- undo and redo synchronize the visible buffer and model,
- and RE-specific redo restores the expected insertion-point position.

This establishes the editing bridge required before Narrative Display
Block wrapping can be implemented.

-------------------------------------------------------------------------------


-------------------------------------------------------------------------------

## 260715 — Narrative Display Block Rendering

Implemented the first canonical Narrative Display Block renderer.

Confirmed behavior:

- each block contains N1, N2, N3, and a blank divider row,
- long N1 text wraps through physical N1 rows on lines 1, 5, 9, and
  subsequent block positions,
- wrapping occurs at word boundaries when possible,
- line-number display width is accounted for,
- Emacs visual continuation rows are suppressed,
- redraw preserves the complete N1 text,
- and the insertion point returns to its corresponding N1 position.

Live reblocking during ordinary typing remains the next implementation
step.

-------------------------------------------------------------------------------

