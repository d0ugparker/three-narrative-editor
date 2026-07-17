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


-------------------------------------------------------------------------------

## 260715 — Live Narrative Reflow Started

Added post-command detection of differences between the visible N1 rows
and the canonical Narrative Display Block layout.

When ordinary editing changes the required wrapping, the editor now
re-renders N1 automatically after the editing command completes.

-------------------------------------------------------------------------------


-------------------------------------------------------------------------------

## 260716 — Projected Cursor Geometry

Implemented and verified non-textual cursor projection for canonically
empty narrative space.

Confirmed behavior:

- vertical movement preserves the intended horizontal column when N2 or
  N3 ends before that location,
- no buffer spaces are inserted,
- existing narrative content is not moved or destroyed,
- projected geometry does not become part of Range selection,
- vertical continuation preserves the projected column,
- return to real text restores ordinary Emacs point,
- mouse movement clears projected state,
- redraw clears the obsolete projection,
- redraw preserves canonical N2 Segment content,
- and redraw restores point to the correct narrative.

The next unresolved behavior is canonical character insertion from a
projected cursor location.

-------------------------------------------------------------------------------

-------------------------------------------------------------------------------

## 260717 — Continuous Projected-Segment Editing

Implemented and verified continued right-edge editing after projected
geometry receives its first canonical character.

Confirmed behavior:

- the first character creates one canonical Segment,
- subsequent characters extend that same Segment,
- Segment identity and starting geometry remain stable,
- redraw preserves the completed text and right-edge position,
- Escape ends the editing session,
- unmodeled N2/N3 insertion is rejected afterward,
- undo removes the uninterrupted Segment construction and restores the
  preceding Projected Cursor,
- and redo restores the completed Segment without restoring temporary
  editing state.

Testing also established that intermediate `eval-expression` commands
can divide undo-history operations and should not be placed inside an
undo-grouping test.

-------------------------------------------------------------------------------

-------------------------------------------------------------------------------

## 260717 — Backspace and Empty Active Entry

Implemented and verified right-edge Backspace during projected Segment
construction.

Confirmed behavior:

- Backspace at projected geometry cannot cross a physical line boundary,
- deleting one character shortens the existing canonical Segment,
- deleting the sole character removes the empty Segment,
- the projected origin is restored,
- the Segment-entry session remains active while empty,
- subsequent typing resumes at the same origin,
- repeated Backspace at the empty origin beeps without deleting unrelated
  content,
- and Escape explicitly ends the entry session.

-------------------------------------------------------------------------------
