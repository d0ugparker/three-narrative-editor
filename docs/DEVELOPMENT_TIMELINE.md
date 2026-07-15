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

