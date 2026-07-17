Three-Narrative Editor
## Alpha 0.1 Functional Specification

### Scope

Alpha 0.1 establishes the first complete editing experience for the
Three-Narrative Editor (TNE).

Its purpose is to demonstrate that the editor behaves as a conventional
word processor while introducing the three-narrative display model and
the first relationship editing behaviors.

Only plain text is supported.

Future releases may introduce additional data types without changing the
editing model described here.

---

# 1. Startup

## Initial State

When a new document is created:

- N1 receives keyboard focus.
- The insertion point is positioned at the beginning of N1.
- N2 is empty.
- N3 is empty.
- The divider line is displayed.
- No relationships exist.
- No ranges exist.
- No highlights are visible.

The editor is immediately ready for typing.

---

# 2. Writing

The editor behaves as a conventional word processor.

The user may:

- type characters
- delete characters
- replace characters
- paste text
- move the insertion point

These operations affect only the edited narrative.

No relationships are created automatically.

---

# 3. Narrative Display Blocks

The display consists of repeating Narrative Display Blocks.

Each Narrative Display Block contains:

N1
N2
N3
Divider

The renderer maintains this structure throughout the document.

---

# 4. Continuous Narrative Wrapping

When an N1 display line becomes full:

- the renderer performs normal word wrapping,
- the remaining text continues on the next available N1 display line,
- a new Narrative Display Block is created,
- blank N2 and N3 lines accompany the wrapped N1 line,
- the insertion point remains at the end of the entered text.

The editor shall not:

- wrap onto an N2 line,
- wrap onto an N3 line,
- remove blank narratives,
- disturb existing related narratives.


---

# 5. Cursor Movement

The insertion point may be moved using either the keyboard or the mouse.

Supported keyboard navigation:

- Left Arrow
- Right Arrow
- Up Arrow
- Down Arrow
- Home
- End

Supported mouse navigation:

- Single click

Moving the insertion point shall never modify the document.

Moving the insertion point may update highlighting when the insertion
point enters or leaves an existing originating range or related segment.

---

# 6. Mouse Operations

Unless modified by a keyboard modifier, mouse behavior follows
conventional word processor expectations.

## Single Click

Moves the insertion point.

If the clicked location is editable, the editor enters normal text editing.

---

## Click and Drag

Selects text one character at a time.

---

## Double Click

Selects the word beneath the mouse cursor.

Dragging after a double click extends the selection by complete words.

---

## Triple Click

Selects the current sentence.

Dragging after a triple click extends the selection by complete
sentences.

Future releases may redefine sentence boundaries if required.

---

# 7. Modifier Keys

Modifier keys alter the meaning of a mouse click without changing the
underlying editing model.

## Shift-Click (⇧)

Shift-click requests relationship inspection.

If the clicked location belongs to an existing originating range or
related segment:

- the selected range is highlighted,
- first-level related ranges are highlighted,
- collapsed windows expand temporarily if required.

If no relationship exists, Shift-click behaves as a normal selection.

Shift-click never modifies the document.

---

## Command-Click (⌘)

Within the windowing system, Command-click changes the display lock.

If the clicked narrative is not currently the display representative,
Command-click moves the window lock to that narrative.

If the clicked narrative already owns the display lock,
Command-click toggles that lock according to the current window state.

Command-click affects presentation only.

It never alters relationships or text.


-------------------------------------------------------------------------------

# Transition to Relationship Editing

Everything above could almost be mistaken for an advanced word processor.

Beginning with the following section, the editor continues behaving as
a conventional word processor while introducing the behaviors unique to
the Three-Narrative Relationship Editor.

From this point forward, the editor begins responding not only to text,
but also to relationships explicitly recognized by the user.

The following sections describe the behavior that distinguishes the
Relationship Editor from a conventional editor.

-------------------------------------------------------------------------------


---

# 8. Range Recognition

## Purpose

Range recognition is the mechanism through which the editor determines
whether the user's current attention corresponds to an existing
representation.

The editor never recognizes relationships on its own.

It responds only to relationships previously created by the user.

---

## Cursor Entry

Whenever the insertion point enters an existing originating range or
related segment, the editor shall recognize that event.

Recognition occurs regardless of whether the insertion point arrived by:

- keyboard navigation,
- mouse click,
- mouse selection,
- search,
- or any future navigation mechanism.

---

## Cursor Exit

When the insertion point leaves the recognized range, the editor shall
remove any temporary highlighting associated with that range unless the
highlighting is being maintained by another active operation.

---

## Recognition Does Not Modify The Document

Recognition shall never:

- create a relationship,
- delete a relationship,
- alter text,
- alter layout,
- alter document history.

Recognition affects only temporary presentation.

---

# 9. Relationship Highlighting

If the recognized range participates in one or more relationships, the
editor shall reveal those relationships.

The originating range shall always be highlighted.

Every first-level related segment shall also be highlighted.

Highlighting exists only while the relationship remains recognized.

Removing the highlighting shall never modify the document.

---

## Highlight Propagation

Relationship highlighting propagates only one level.

If:

N1 → N2

and

N2 → N4

Placing the insertion point inside N1 highlights N1 and N2.

N4 is not highlighted unless N2 becomes the recognized range.

This behavior prevents uncontrolled visual expansion while allowing the
user to progressively explore the relationship graph.

In the example above, after placing the insertion point inside N1 and
observing that N2 becomes highlighted, the user may then place the
insertion point inside N2. Doing so makes N2 the newly recognized range,
causing N2 and N4 to become highlighted.

The user progressively explores the relationship graph by moving their
attention from one recognized range to another rather than by expanding
the entire relationship graph simultaneously.

---

## Visibility

If a highlighted related segment exists inside a collapsed windowed
narrative, the editor shall temporarily expand that window sufficiently
to reveal every highlighted segment.

When highlighting ends, the window returns to its previous presentation
state unless modified by the user.

---

# 10. Relationship Construction

Relationship construction always begins with an originating range.

The originating range defines the horizontal geometry used when creating
the related segment.

The editor never creates relationships without an explicitly selected
originating range.


-------------------------------------------------------------------------------

## Progressive Relationship Exploration

Relationship highlighting is a visual mechanism used to support
relationship exploration.

The editor reveals only the first level of relationships surrounding the
currently recognized range.

Additional relationship levels are revealed only after the user shifts
their attention to one of those newly recognized related ranges.

The editor never automatically expands the complete relationship graph.

The relationship graph itself remains unchanged throughout this process.

Only the user's current viewpoint changes.

-------------------------------------------------------------------------------


---

# 11. Relationship Geometry

Relationship Geometry is the mechanism that preserves the spatial
correspondence between related narratives.

Everything preceding this section could almost be mistaken for an
advanced word processor.

Beginning with this section, the editor continues behaving as a
conventional word processor while introducing the behaviors unique to
the Three-Narrative Relationship Editor.

From this point forward the editor responds not only to text, but also
to relationships explicitly recognized by the user.

The following sections describe the behavior that distinguishes the
Relationship Editor from conventional editors.

## Originating Geometry

Every related segment inherits its initial horizontal geometry from its
originating range.

The left and right margins inherited from the originating range
establish the default editing boundaries for the newly created related
segment.

The inherited geometry defines the visible editing window through which
the related segment is viewed and edited.

The inherited geometry does not define the length of the represented
segment.

A represented segment may contain more text than can be displayed within
its inherited geometry.

When this occurs, the represented segment remains unchanged while the
presentation scrolls horizontally within the inherited editing window.

Representation is therefore independent of presentation.

Inherited geometry constrains presentation, not representation.


## Geometry Propagation

Geometry propagation preserves horizontal correspondence among all
narratives when N1 text or the available display width changes.

The edit is local. The geometry propagates.

Only the text representation directly edited by the user shall change.
Spacing introduced or removed in other narratives for alignment is
layout geometry and shall not become part of their stored text.

### Editing N1 Outside an Originating Range

Text inserted into or deleted from N1 outside a previously defined range
shall flow through successive Narrative Display Blocks according to
conventional word-processing behavior.

Each character inserted into N1 shall introduce an equivalent unit of
display geometry into every other narrative.

Each character deleted from N1 shall remove an equivalent unit of
display geometry from every other narrative.

All narratives shall therefore remain horizontally aligned.

If the resulting reflow moves text from one Narrative Display Block to
another, every affected range margin shall move with the reflow.

Left and right margins shall move in unison across all narratives so
that the membership of every defined range remains unambiguous.

### Editing Within an Originating N1 Range

When text is inserted within an originating N1 range, the represented
phrase changes locally.

If the established editing policy permits the range to follow its
phrase length:

- the originating range's right margin shall expand by one display unit
  for each inserted character,
- every associated range shall inherit the adjusted right margin,
- narratives without associated ranges shall receive equivalent layout
  expansion,
- all following ranges and content shall shift equally,
- and all narrative rows shall remain aligned.

When text is deleted within an originating N1 range, the represented
phrase changes locally.

The editor shall then apply the user's established margin policy.

### Phrase Shorter Than Its Range

If deletion makes an N1 phrase shorter than the width between its
existing margins, and no default policy has yet been established, the
editor shall ask whether to:

1. shrink the right margin to follow the phrase length, or
2. preserve the existing margin width.

If the right margin is reduced:

- every associated range shall inherit the reduced geometry,
- corresponding margin definitions and layout spacing in every narrative
  shall contract equally,
- no stored narrative text shall be altered,
- all following ranges and displayed content shall shift left equally,
- and horizontal alignment shall remain intact.

The user's choice shall become the default behavior for future edits of
the same kind.

### Phrase Longer Than Its Range

If editing makes an N1 phrase longer than the width between its existing
margins, and no default policy has yet been established, the editor
shall ask whether to:

1. expand the right margin to follow the phrase length, or
2. preserve the existing margins and display the longer phrase through
   the smaller presentation window.

If the right margin expands:

- every associated range shall inherit the expanded geometry,
- all affected narratives shall expand equally,
- all following ranges and content shall shift right equally,
- and horizontal alignment shall remain intact.

If the existing margins are preserved:

- the complete phrase representation shall remain intact,
- only the portion fitting within the inherited presentation window
  shall be immediately visible,
- and indicators shall show that additional content exists beyond the
  left or right visible boundary.

The user's choice shall become the default behavior for future edits of
the same kind.

### Changing the Margin Policy

The user may reopen the margin-policy control by:

- clicking unused space between a short phrase and its right margin,
- clicking the left overflow indicator, or
- clicking the right overflow indicator.

The control shall allow the user to choose between:

- margins that follow the owner's phrase length, and
- margins that preserve their established width and display excess text
  through a presentation window.

Changing this policy shall affect subsequent qualifying edits.

### Block Reflow

If any left or right margin crosses from one Narrative Display Block
into another during text reflow, its corresponding margins in every
narrative shall cross the block boundary in unison.

A range may therefore occupy different display blocks over time without
losing its identity, ownership, represented text, or relationships.

### Window Resizing

Changing the editor window width shall reflow all narratives according
to conventional word-processing expectations.

Narrative text, ranges, and margins shall move between Narrative Display
Blocks as required.

Corresponding margins shall remain aligned across every narrative.

Window resizing changes presentation and layout only.

It shall not change represented text or relationships.

### Notification

When an edit changes established range margins, the editor shall display
a non-modal notification identifying that the geometry changed.

The notification shall not interrupt typing or require confirmation
unless the user has not yet established the applicable margin policy.

### Undo

Undo shall restore the complete state that existed before the operation,
including:

- the edited text,
- the originating range geometry,
- associated range geometry,
- propagated spacing,
- Narrative Display Block placement,
- overflow presentation state,
- and affected highlighting or display state.

A propagated geometry change and its originating text edit shall be one
undoable operation.


### Rightward Geometry Propagation

All text edits and margin modifications have a point of origin.

The geometric consequences of an edit shall propagate only from that
point toward the right through the remainder of the document.

Nothing positioned before the point of origin shall move as a
consequence of that edit.

Everything geometrically downstream may be repositioned, including:

- characters,
- words,
- ranges,
- right margins,
- following left margins,
- displayed lines,
- Narrative Display Blocks,
- paragraphs,
- and windowed narratives.

Propagation changes layout geometry only.

It shall not alter the stored text of narratives that were not directly
edited by the user.

When an edit changes the width of an originating range, its right margin
shall move first.

That change shall then propagate rightward through all corresponding
narrative geometry so that every narrative remains aligned and every
range boundary continues to identify the same intended portion of its
owner's text.

The governing direction is therefore:

Point of edit
→ affected right margin
→ following geometry
→ remainder of the document


-------------------------------------------------------------------------------

## Range Identity

A range is a persistent document object.

A range is not defined solely by its displayed position or by the text
currently visible within its margins.

A range owns:

- an originating narrative,
- represented text,
- left and right margin geometry,
- inherited geometry,
- relationship membership,
- and presentation state.

The identity of a range remains unchanged as its represented text wraps,
moves between Narrative Display Blocks, or is repositioned by geometry
propagation.

The editor therefore preserves the identity of the range independently
of its current presentation.

-------------------------------------------------------------------------------


## Range Properties

A Range is a persistent identification of a bounded portion of content
within one narrative.

A Range shall have:

- a stable Range ID,
- an owning document,
- an owning narrative,
- a left boundary,
- a right boundary,
- an originating or inherited geometry role,
- relationship membership,
- and any persistent margin policy assigned by the user.

A Range identifies represented content through its boundaries.

It shall not maintain an independent duplicate of that content.

The owning narrative remains the authoritative source of its text.

### Stable Identity

A Range shall retain the same identity when:

- text before it is inserted or removed,
- its represented phrase grows or shrinks,
- its margins move,
- it wraps between Narrative Display Blocks,
- the editor window is resized,
- or its presentation changes.

Movement and resizing shall not create a replacement Range.

### Ownership

Every Range shall belong to exactly one narrative.

A Range may originate in N1, N2, N3, or a later narrative.

Ownership identifies where the represented content exists.

Ownership does not determine how many Relationships the Range may
participate in.

### Boundaries

A Range shall have a left boundary and a right boundary.

The boundaries determine:

- which content belongs to the Range,
- the Range's current width,
- its projected geometry,
- and the point from which rightward geometry propagation begins.

The boundaries shall track edits to the owning narrative.

### Originating and Inherited Geometry

An originating Range receives its geometry from an explicit user
selection.

A related Range initially inherits its left and right geometry from the
Range from which it was created.

Inherited geometry establishes spatial correspondence.

It does not make the originating Range the owner of the related Range's
text.

### Relationship Membership

Relationships connect Range identities.

They shall not depend on matching text strings or fixed display
coordinates.

A Range may participate in more than one Relationship.

Editing, wrapping, or repositioning a Range shall not alter its
Relationship membership.

### Margin Policy

A Range may have a persistent margin policy selected by the user.

The policy shall determine whether:

- its right margin follows the length of its represented phrase, or
- its established margins remain fixed while excess content is viewed
  through a presentation window.

A related Range shall inherit applicable geometry changes from its
originating Range while preserving its own represented content.

### Presentation State

Cursor position, temporary highlighting, and temporary expansion caused
by relationship inspection are not intrinsic properties of a Range.

They are ephemeral presentation state.

Only presentation choices explicitly made persistent by the user, such
as an applicable margin policy or window display lock, shall be stored
with the document.


-------------------------------------------------------------------------------

## Boundary-Side Focus

A cursor positioned at a Range boundary may represent either side of
that boundary.

At the left boundary, the active editing side may be:

- the Range immediately to the right, or
- the non-Range content immediately to the left.

At the right boundary, the active editing side may be:

- the Range immediately to the left, or
- the non-Range content immediately to the right.

Cursor position alone is therefore insufficient to determine which
content an edit affects.

The editor shall maintain an explicit boundary-side focus.

### Initial Boundary Click

The first click at either boundary shall give focus to the Range.

The renderer shall provide visible feedback identifying the focused
side.

When the Range has focus:

- Range text remains normally readable,
- adjacent non-Range text is greyed,
- inserted characters become part of the Range,
- removed characters are removed from the Range,
- and the Range's right boundary and propagated geometry are adjusted
  according to the established margin policy.

### Repeated Boundary Click

Clicking the same boundary position again shall toggle focus from the
Range side to the adjacent non-Range side.

Clicking again shall toggle focus back to the Range.

When the non-Range side has focus:

- adjacent non-Range text remains normally readable,
- Range text is greyed,
- inserted characters become non-Range narrative text,
- removed characters are removed only from the focused non-Range side,
- and all following geometry is repositioned accordingly.

### Left Boundary Editing

When the Range side of the left boundary has focus:

- inserted characters shall be added to the beginning of the Range,
- Backspace shall not cross into the non-Range content to the left,
- and Backspace shall produce an audible warning when no Range character
  exists to the left of the insertion point.

When the non-Range side of the left boundary has focus:

- inserted characters shall be added immediately before the Range,
- deleted characters shall be removed from the non-Range content,
- both Range boundaries shall move as required,
- and all following geometry shall remain aligned.

### Right Boundary Editing

When the Range side of the right boundary has focus:

- inserted characters shall be added to the end of the Range,
- deleted Range characters shall reduce the represented phrase,
- and the right boundary shall be recalculated according to the
  established margin policy.

When the non-Range side of the right boundary has focus:

- inserted characters shall be added immediately after the Range,
- those characters shall not become part of the Range,
- and all following geometry shall move rightward as required.

If Delete is pressed while the non-Range side has focus and no
non-Range character exists to the right of the insertion point:

- no text shall be removed,
- no boundary shall be crossed,
- and the editor shall produce an audible warning.

### Boundary Feedback

The renderer shall always make boundary-side focus visible.

The user shall not be required to infer from cursor position whether an
edit will affect the Range or adjacent non-Range content.

Boundary-side focus is temporary presentation state.

It shall not alter Range identity or Relationship membership.

-------------------------------------------------------------------------------


-------------------------------------------------------------------------------

## Wholesale Range Deletion

Wholesale Range deletion occurs when the user selects every character
identified by an existing Range and requests deletion.

This operation is distinct from ordinary editing within a Range.

Small insertions, deletions, replacements, and wording changes shall
continue to use the ordinary Range-editing and geometry-propagation
rules.

### Confirmation

Before performing a wholesale Range deletion, the editor shall display
a modal confirmation dialog.

The dialog shall clearly state that proceeding will:

- retire the selected Range,
- remove its Range definition,
- break its Relationships,
- and preserve its former text as strikethrough content.

If the user cancels, no part of the document shall change.

### Confirmed Deletion

If the user confirms the operation:

- every character formerly identified by the Range shall remain in the
  owning narrative,
- those characters shall be displayed with strikethrough formatting,
- the Range shall be removed from the active Range collection,
- every Relationship connected to that Range shall be removed from the
  active Relationship collection,
- a deleted-Range record shall preserve the former Range identity,
  boundaries, content reference, and Relationship information,
- related content in other narratives shall remain unchanged,
- related content shall remain in its existing location,
- and no related narrative text shall be deleted or repositioned merely
  because the Relationship was removed.

Strikethrough shall be applied only for confirmed wholesale deletion of
a previously defined Range.

Ordinary edits within a Range shall not automatically produce
strikethrough text.

### Formerly Related Content

Content formerly related to the deleted Range becomes actively
unlinked content.

Its text, position, geometry, and narrative ownership shall remain
unchanged.

Its former connection to the deleted Range shall remain available
through the deleted-Range record.

The absence of the former Relationship shall not be interpreted as an
instruction to remove or relocate that content.

### Atomic Undo

Wholesale Range deletion shall be recorded as one atomic undoable
operation.

Undo shall restore:

- the original text formatting,
- the Range definition,
- the Range ID,
- its boundaries,
- its geometry and margin policy,
- every removed Relationship,
- the position and geometry of all affected narratives,
- and the presentation state required to display the restored Range.

Redo shall reapply the complete confirmed deletion as one operation.

The editor shall not expose a partially restored state in which only
some of the Range, formatting, or Relationships have been recovered.

### Strategic State Capture

Before executing the confirmed deletion, the editor shall capture the
complete state necessary to reconstruct the Range and its Relationships.

The captured undo state shall include stable object identities rather
than relying only on text matching or current display coordinates.

-------------------------------------------------------------------------------


### Geometry Preservation Through Strikethrough

The former Range text shall remain present as strikethrough content
after confirmed wholesale deletion.

Preserving the characters in place preserves the established horizontal
geometry of every narrative.

The editor shall not close the deleted Range's width merely because the
Range is no longer active.

Deleting those characters from only one narrative would require
potentially disruptive reflow across all narratives, margins, and
Narrative Display Blocks.

Strikethrough therefore serves two purposes:

- it displays that the former Range has been retired, and
- it preserves the document geometry that existed immediately before
  retirement.

### Deleted-Range Record

Before removing the Range and its Relationships from their active
collections, the editor shall create a deleted-Range record.

The record shall preserve sufficient information to identify and inspect:

- the former Range ID,
- the owning narrative,
- the former boundaries,
- the former represented content,
- the strikethrough text location,
- the former margin policy,
- every formerly connected Range,
- every former Relationship ID and type,
- and the geometry existing immediately before deletion.

The deleted-Range record shall not participate in ordinary active
Relationship traversal.

It shall remain available for historical inspection and undo.

### Deleted-Range List

The editor shall maintain a discoverable list of deleted-Range records.

The list shall allow the user to inspect retired Ranges and their former
Relationships without restoring them to the active document structure.

The list is historical reference, not an active Relationship collection.

### Inspecting Strikethrough Content

When the user Shift-clicks within text belonging to a deleted-Range
record:

- the complete struck-through former Range shall be highlighted in red,
- every formerly related Range still present in another narrative shall
  be highlighted in red,
- collapsed windowed narratives shall temporarily expand when necessary
  to display those formerly related Ranges,
- and the red highlighting shall indicate that the displayed
  Relationships were previously removed.

This inspection shall not reactivate the deleted Range or recreate its
Relationships.

Moving attention away shall remove the temporary historical
highlighting unless another inspection operation maintains it.

### Historical Relationship Visibility

Formerly related Ranges shall retain their active text and location.

During deleted-Range inspection, they may be highlighted according to
the archived Relationship information.

This historical highlighting reveals what was connected immediately
before deletion.

It shall not imply that the Relationship remains active.


### Shift-Click Relationship Inspection

Shift-click is the explicit gesture for inspecting Relationship
membership.

When the user Shift-clicks an active Range:

- the clicked Range shall be highlighted,
- every immediately related active Range shall be highlighted,
- and active Relationship highlighting shall use the editor's ordinary
  relationship-highlight presentation.

When the user Shift-clicks struck-through text belonging to a
deleted-Range record:

- the former Range shall be highlighted in red,
- every immediately related Range recorded in its archived Relationship
  information shall be highlighted in red,
- and the red presentation shall indicate that those Relationships are
  historical rather than active.

In both cases, highlighting shall propagate only one Relationship level.

Shift-click inspection changes presentation only.

It shall not modify text, Range identity, active Relationships, or
historical Relationship records.


-------------------------------------------------------------------------------

# 12. Relationship Lifecycle

Relationships are persistent document objects connecting two existing
Ranges.

The editor never creates a Relationship automatically.

Every Relationship originates from an explicit user action.

### Preconditions

Before a Relationship may be created:

- both participating Ranges shall already exist,
- both Ranges shall possess stable Range identities,
- both Ranges shall belong to the same document,
- and the user shall explicitly request Relationship creation.

### Relationship Creation

Creating a Relationship shall:

- assign a stable Relationship ID,
- record the participating Range IDs,
- record any structural direction explicitly established by the user,
- optionally record a Relationship type,
- preserve each Range's independent ownership,
- and leave the represented text of every participating Range unchanged.

A Relationship type shall not be required.

The existence of a Relationship records that the user explicitly
recognized a relationship among the participating Ranges.

It shall not require the editor or the user to classify the meaning of
that relationship.

Creating a Relationship shall not:

- duplicate text,
- move text,
- alter geometry,
- or change either Range's identity.

-------------------------------------------------------------------------------


### Relationship Cardinality

The Relationship model shall permit:

- one-to-one,
- one-to-many,
- many-to-one,
- and many-to-many Relationships.

Cardinality identifies the number and structural arrangement of the
participating Ranges.

Cardinality shall not determine semantic meaning.

A one-to-one Relationship does not necessarily mean equality, support,
agreement, or equivalence.

A one-to-many Relationship does not necessarily mean that the single
Range supports or explains the many Ranges.

The represented language and the user's recognition determine whatever
meaning exists.

### Direction

A Relationship may record direction when the user explicitly establishes
a source and destination structure.

Direction shall describe structural orientation only.

Direction shall not by itself mean:

- support,
- causation,
- explanation,
- agreement,
- contradiction,
- hierarchy,
- or dependency.

A Relationship may also remain structurally undirected when no direction
has been explicitly established.

### Optional Relationship Type

Relationship type is optional metadata.

A user may leave the type unspecified.

Future users or future program forks may define and assign types such as:

- supports,
- contradicts,
- explains,
- qualifies,
- depends-on,
- or other domain-specific classifications.

Alpha 0.1 shall not require those classifications to create, preserve,
display, navigate, or inspect a Relationship.

The absence of a Relationship type shall not make the Relationship
incomplete or invalid.

### Represented Content

Each participating Range shall continue identifying its represented
content through its owning narrative and boundaries.

The Relationship shall reference stable Range identities.

It shall not replace, summarize, interpret, or independently rewrite the
participating Range content.


-------------------------------------------------------------------------------

# 13. Canonical Object Model

The document consists of a persistent object graph.

Rendering, layout, highlighting, scrolling, and windowing are temporary
projections of that object graph.

The object graph is the authoritative representation of the document.

The renderer shall never become the authoritative source of document
state.

### Persistent Objects

Alpha 0.1 defines the following persistent object types:

- Document
- Narrative
- Range
- Relationship
- Deleted-Range Record

Future releases may introduce additional persistent object types.

### Object Identity

Every persistent object shall possess a stable identifier.

Presentation changes shall never alter object identity.

Object identity shall survive:

- editing,
- wrapping,
- scrolling,
- geometry propagation,
- window resizing,
- relationship inspection,
- highlighting,
- and rendering.

### References

Persistent objects reference one another by stable identifiers.

Objects shall not depend upon current screen position or temporary
display coordinates.

The object graph therefore remains valid independently of any renderer.

-------------------------------------------------------------------------------


### Non-Persistent Presentation State

The following are presentation state rather than document state:

- cursor position,
- insertion point,
- temporary highlighting,
- temporary window expansion,
- current scroll position,
- temporary boundary-side focus,
- temporary relationship inspection,
- and other transient renderer state.

These shall not become part of the document representation unless the
user explicitly requests persistence.

-------------------------------------------------------------------------------


-------------------------------------------------------------------------------

# 14. Renderer Responsibilities

The renderer is responsible for presenting the persistent object graph
to the user.

It shall not become an authoritative source of document information.

### Renderer Responsibilities

The renderer shall:

- display narratives,
- project Range boundaries into visible margins,
- display Relationships,
- display highlighting,
- manage Narrative Display Blocks,
- manage window expansion and collapse,
- display temporary inspection state,
- display temporary boundary-side focus,
- display scrolling,
- and display cursor position.

### Renderer Limitations

The renderer shall not:

- create persistent objects,
- delete persistent objects,
- modify represented text,
- modify Relationship membership,
- assign Range identities,
- assign Relationship identities,
- or interpret document meaning.

### Projection

Rendering is the process of projecting persistent document objects into
a temporary presentation.

Changing the presentation shall not modify the persistent object graph.

-------------------------------------------------------------------------------


-------------------------------------------------------------------------------

# 15. Layout Manager

The Layout Manager computes the spatial arrangement of every persistent
object.

Layout is a deterministic transformation from Representation to
Presentation.

Given the same Representation and the same display dimensions, the
Layout Manager shall always produce the same layout.

### Responsibilities

The Layout Manager shall compute:

- Narrative Display Blocks,
- line wrapping,
- projected Range boundaries,
- inherited geometry,
- horizontal alignment,
- geometry propagation,
- block transitions,
- window geometry,
- collapsed viewfinder geometry,
- expanded viewfinder geometry,
- and overflow presentation windows.

### Inputs

The Layout Manager receives:

- the persistent object graph,
- current display dimensions,
- user-configurable layout preferences,
- and persistent layout policies.

### Outputs

The Layout Manager produces:

- display coordinates,
- Narrative Display Block assignments,
- projected margins,
- visible presentation windows,
- and other deterministic layout information.

The Layout Manager shall not modify the persistent object graph.

-------------------------------------------------------------------------------


-------------------------------------------------------------------------------

# 16. Viewfinder Windows

Viewfinder windows provide additional presentation space for narratives
that extend beyond N3.

A viewfinder is a presentation mechanism.

It is not a persistent document object.

The document stores narratives.

The Layout Manager determines their presentation.

The renderer displays that presentation.

### Purpose

Viewfinder windows permit additional related narratives to remain
accessible without permanently consuming vertical display space.

The objective is to preserve context while minimizing visual clutter.

### Collapsed Presentation

When collapsed, a viewfinder displays one representative narrative.

The representative narrative is determined by:

- a user-selected display lock, if one exists,
- otherwise the most recently created narrative having the highest
  canonical narrative number.

The representative narrative is presentation only.

Changing the representative shall not modify the document.

### Expanded Presentation

When expanded, every narrative belonging to that viewfinder shall become
visible.

Each narrative shall retain its own:

- Range identities,
- Relationships,
- geometry,
- presentation window,
- and editing behavior.

Expansion changes presentation only.

-------------------------------------------------------------------------------


### Expansion

A viewfinder may expand because:

- the user explicitly expands it,
- the user begins editing within it,
- relationship inspection requires additional narratives to become
  visible,
- or another presentation rule temporarily requires expansion.

Only one viewfinder shall be expanded at any time.

Expanding one viewfinder shall automatically collapse any previously
expanded viewfinder.

The expanded viewfinder becomes the user's active working area while all
other viewfinders remain collapsed.

### Collapse

When a viewfinder collapses:

- its user-selected display lock, if any, determines its representative
  narrative,
- otherwise the automatically selected representative narrative is
  displayed,
- and any temporary presentation state associated with expansion is
  discarded.

Collapsing a viewfinder shall not modify:

- narratives,
- Ranges,
- Relationships,
- geometry,
- or persistent presentation policies.

-------------------------------------------------------------------------------


### Representative Narrative

Each viewfinder may possess a display lock.

The display lock identifies which narrative shall be shown while the
viewfinder remains collapsed.

If no display lock exists, the representative narrative is determined
automatically.

### Display Lock

Command-clicking a narrative within an expanded viewfinder shall assign
or remove the display lock.

The display lock changes collapsed presentation only.

It does not alter:

- narrative ownership,
- Range identities,
- Relationships,
- geometry,
- or represented content.

-------------------------------------------------------------------------------


### Editing

Narratives displayed within a viewfinder are edited using the same
editing model defined for N1, N2, and N3.

Range creation,

Range editing,

Relationship inspection,

Relationship creation,

Geometry propagation,

Boundary-side focus,

and Wholesale Range deletion

shall behave identically regardless of the narrative's presentation
inside or outside a viewfinder.

The viewfinder changes presentation only.

It shall not introduce a different editing model.

-------------------------------------------------------------------------------


-------------------------------------------------------------------------------

# 17. Attention Model

The Relationship Editor manages the user's attention rather than simply
displaying the maximum amount of available information.

Persistent document information and currently displayed information are
therefore intentionally different.

The user's current focus determines which neighborhood of the document
is emphasized.

### Attention Hierarchy

The editor maintains four simultaneous levels of awareness.

Document

↓

Viewfinder

↓

Narrative

↓

Range

Each level provides additional detail while preserving awareness of the
larger structure.

### Progressive Disclosure

The editor progressively reveals information.

The user is never required to absorb the complete document structure
simultaneously.

Additional detail appears only as the user's attention moves toward that
portion of the document.

### Stable Context

Changing attention shall not alter the document.

Only presentation changes.

Persistent objects remain unchanged.

-------------------------------------------------------------------------------


### Focus

Focus identifies the object currently receiving the user's intent.

Only one primary focus shall exist at any time.

Primary focus may belong to:

- a narrative,
- a Range,
- a boundary side,
- a viewfinder,
- or another explicitly editable object.

Presentation shall clearly indicate primary focus.

Changing focus alters presentation only.

It shall not alter persistent document information.

-------------------------------------------------------------------------------


-------------------------------------------------------------------------------

# 18. Recognition Model

Recognition is the act through which the user explicitly identifies
structure within the document.

The editor preserves acts of recognition.

It does not generate them.

### Range Recognition

Creating a Range records that the user has recognized a bounded portion
of a narrative as a persistent object worthy of future reference.

The editor shall not create Ranges automatically.

### Relationship Recognition

Creating a Relationship records that the user has recognized a
relationship among participating Ranges.

The editor shall not infer Relationships from text similarity,
proximity, semantics, statistics, or machine learning.

### Preservation

Once recognized, a Range or Relationship becomes part of the persistent
representation until explicitly modified or retired by the user.

Recognition therefore survives presentation changes,
layout changes,
window resizing,
editing,
and renderer state.

-------------------------------------------------------------------------------


-------------------------------------------------------------------------------

# 19. Persistence

The Relationship Editor shall preserve persistent document state between
editing sessions.

Closing and reopening a document shall reconstruct the same canonical
object model that existed when the document was saved.

### Persistent State

Alpha 0.1 shall preserve:

- document identity and metadata,
- narrative text,
- active Range identities and boundaries,
- active Relationships,
- deleted-Range records,
- archived historical Relationships,
- persistent margin policies,
- persistent viewfinder display locks,
- and other state explicitly defined as persistent by this
  specification.

### Ephemeral State

Alpha 0.1 shall not require preservation of:

- temporary highlighting,
- temporary relationship inspection,
- temporary boundary-side focus,
- temporary viewfinder expansion,
- current cursor position,
- current selection,
- or current scroll position.

Future releases may optionally preserve selected session state without
changing the canonical document representation.

### Document Authority

The saved Relationship Editor document shall be the authoritative source
of persistent document state.

Opening the document shall reconstruct its persistent objects and then
derive layout and presentation from those objects.

The renderer shall not be used as the source from which persistent state
is recovered.

### Storage Method

Alpha 0.1 shall use a self-contained document file.

A separate database shall not be required.

The storage format shall preserve stable object identities and shall be
sufficient to reconstruct:

- narratives,
- Ranges,
- Relationships,
- deleted-Range records,
- geometry policies,
- and persistent presentation policies.

The exact serialization format is an implementation decision and shall
be documented before persistence code is committed.

### Saving

Saving shall serialize one internally consistent document state.

The editor shall not write a partially updated combination of text,
Ranges, Relationships, and deleted-Range records.

If saving fails, the previously saved document shall remain recoverable
whenever practical.

### Loading

Loading shall:

- validate the document format,
- reconstruct persistent objects,
- restore stable identifiers,
- verify object references,
- compute current layout,
- and render the resulting presentation.

Missing or invalid references shall be reported rather than silently
discarded.

### Future Database Support

A future database may provide:

- cross-document Relationships,
- collection-wide search,
- indexes,
- concurrent access,
- external queries,
- or other repository-scale capabilities.

Unless explicitly changed by a future specification, such a database
shall remain an index or projection of authoritative document files
rather than silently replacing them.

-------------------------------------------------------------------------------


### Undo and Redo Insertion-Point Restoration

Undo and redo shall restore the complete conceptual editing state.

That state includes:

- represented text,
- persistent model state,
- affected geometry,
- and the insertion point associated with the restored operation.

When redo restores inserted text, the insertion point shall return to the
position immediately following that restored insertion.

The user shall not be left at the former insertion boundary when the
restored operation would ordinarily have placed the insertion point at
the end of the inserted text.

Complex Relationship Editor operations shall restore their expected
final insertion-point location as part of the same atomic undo or redo
operation.


-------------------------------------------------------------------------------

## Mixed-Boundary Navigation

A Range boundary occupies one geometric position while supporting two
editing domains:

- the Range, and
- the adjacent non-Range content.

The editor shall therefore track boundary-side focus independently of
cursor position.

### Left Boundary Mouse Behavior

Clicking the first character position at the left boundary shall
initially give focus to the Range.

Clicking that same position again shall toggle focus to the non-Range
content immediately to the left.

Further clicks at the same position shall continue toggling between the
two editing domains.

### Right Boundary Mouse Behavior

The mixed position at the right boundary is the character position
immediately beyond the final character currently belonging to the
Range.

Clicking that position shall initially give focus to the Range.

Clicking that same position again shall toggle focus to the non-Range
content immediately to the right.

Further clicks at the same position shall continue toggling between the
two editing domains.

### Keyboard Arrival at a Mixed Boundary

When keyboard navigation places point at a mixed-boundary position, the
renderer shall visibly flash or otherwise emphasize that the position
has more than one possible editing domain.

The user shall not be required to infer the ambiguity.

The initial editing domain shall be determined by the navigation
direction and the rules below.

### Vertical Toggle

While point remains at a mixed-boundary position:

- Up Arrow shall toggle between Range and non-Range focus,
- Down Arrow shall toggle between the same two states,
- and the two commands shall begin from opposite default states when no
  boundary-side focus has yet been established.

The exact initial mapping shall remain consistent throughout the editor
and shall be communicated visually.

Neither command shall move point away from the mixed-boundary position
while performing this toggle.

### Word Navigation

Platform-standard word-navigation commands frequently land directly on
mixed-boundary positions.

On macOS, these normally include:

- Option-Right Arrow, which lands after the final character of a word,
- Option-Left Arrow, which lands before the first character of a word.

The Relationship Editor shall detect the actual word-navigation commands
delivered by the current Emacs and operating-system configuration.

When such a command lands at a Range boundary, the editor shall establish
or expose boundary-side focus according to the same mixed-boundary rules
used for mouse navigation.

The specification defines the resulting behavior rather than requiring
one physical modifier key on every platform.

### Visual Feedback

Range focus and non-Range focus shall be visually distinguishable.

When the Range has focus:

- Range content remains normally readable,
- adjacent non-Range content is subdued.

When the non-Range has focus:

- adjacent non-Range content remains normally readable,
- Range content is subdued.

A mixed-boundary flash is temporary presentation state.

Boundary-side focus remains active until:

- the user toggles it,
- point leaves the boundary,
- or another object receives primary focus.

-------------------------------------------------------------------------------


### Stateless Horizontal Boundary Navigation

Ordinary horizontal navigation shall remain stateless.

Moving point left or right through a mixed-boundary position shall not
confine the user to either the Range or non-Range editing domain.

Repeated Left Arrow, Right Arrow, platform word-left, or platform
word-right commands may cross either boundary freely.

When horizontal navigation lands on a mixed-boundary position:

- point shall remain at that position,
- the renderer shall briefly indicate that the position is shared,
- and no boundary-side focus shall yet be established.

A flash indicates available choice.

It does not make that choice.

Boundary-side focus becomes active only after an intentional resolving
gesture, including:

- Up Arrow,
- Down Arrow,
- or a mouse click at the shared boundary position.

### Vertical Boundary Resolution

When point occupies a mixed boundary without an established
boundary-side focus:

- Up Arrow shall establish one editing domain,
- Down Arrow shall establish the opposite editing domain,
- and neither command shall move point vertically.

Once boundary-side focus exists, either Up Arrow or Down Arrow shall
toggle between Range and non-Range focus while point remains at the same
shared coordinate.

Leaving the mixed boundary by ordinary horizontal navigation shall clear
the temporary boundary-side focus.

### Persistent Editing Target

Temporary Range A and Range B selections shall not own mixed-boundary
focus.

After a selection becomes a persistent document segment, that persistent
segment supplies the boundaries used for mixed-boundary detection and
editing focus.

Temporary selections exist to create persistent structure.

They are not the long-term editing structure.


### Boundary-Edit Session

Resolving a mixed boundary begins a boundary-edit session.

A boundary-edit session records:

- the persistent segment receiving attention,
- the boundary through which the session was entered,
- and whether Range or non-Range content is active.

Once established, this state shall not be cleared merely because point
moves horizontally away from the shared boundary.

The user may navigate and edit within the chosen domain while the
renderer continues to distinguish:

- the active editing domain, and
- the inactive editing domain.

Horizontal movement remains unrestricted.

It does not silently reverse, replace, or terminate the user's explicit
choice.

### Ending Boundary Editing

Escape shall end the active boundary-edit session.

When Escape is pressed:

- boundary-side focus shall be cleared,
- temporary Range/non-Range presentation shall be removed,
- ordinary stateless navigation shall resume,
- and no persistent document content shall be changed merely because
  the session ended.

A click on a neutral editor area or another explicit focus-changing
operation may later be defined as an additional way to end the session.

Alpha 0.1 shall use Escape as the canonical keyboard command.

### Escape as State Exit

Escape may become the common exit command for other temporary
Relationship Editor interaction states.

Each future state shall define explicitly:

- what Escape ends,
- what temporary presentation is removed,
- what persistent information remains,
- and where point or primary focus remains afterward.

Those applications shall be added only as the relevant states are
implemented.


### Editing-Domain Confinement

A boundary-edit session confines editing and navigation to the domain
explicitly selected by the user.

When Range focus is active:

- point shall remain within the selected Range,
- edits shall affect only that Range,
- horizontal navigation shall stop at its boundaries,
- and attempts to cross into adjacent non-Range content shall produce
  an audible warning without moving point.

When non-Range focus is active:

- point shall remain within the selected adjacent non-Range domain,
- edits shall affect only that non-Range content,
- navigation shall not cross into the Range,
- and attempts to cross the shared boundary shall produce an audible
  warning without moving point.

Escape shall end the boundary-edit session.

After Escape:

- editing-domain confinement is removed,
- ordinary horizontal navigation becomes unrestricted,
- and point may cross Range boundaries normally.


### Selection Replacement

Typing while narrative text is actively selected shall replace the
selected text.

The selected text shall be removed and the typed character or text
inserted at the beginning of the former selection.

Typing shall not merely deactivate the selection and append text beside
it.

The replacement shall be recorded as one conceptual undo operation.


### Boundary Navigation After Escape

Escape ends editing-domain confinement and restores stateless horizontal
navigation.

Point may then cross Range boundaries freely.

Whenever navigation lands exactly on a mixed-boundary position, the
renderer shall flash or otherwise emphasize that shared position.

The flash communicates that Range and non-Range editing choices are
available.

It does not establish either choice.


### Narrative-Line Confinement

A boundary-edit session remains confined to the narrative line on which
the editing domain was selected.

After Range or non-Range focus is established:

- Left Arrow and Right Arrow navigate within the selected editing domain,
- Up Arrow and Down Arrow shall not move point to another narrative line,
- attempts at vertical movement shall produce an audible warning,
- and Escape shall end the editing session.

After Escape, ordinary navigation among narrative lines resumes.


### Ordinary Vertical Column Preservation

Outside a boundary-edit session, vertical navigation shall preserve
point's actual current horizontal position.

The editor shall not reuse a stale goal column established by an earlier
mixed-boundary operation.

When point moves from one narrative line to another:

- its destination column shall match its current source column whenever
  that destination position exists,
- prior Range boundaries shall not pull point back to their columns,
- and shorter destination lines may clamp point only as required by the
  available content or editing geometry.

During an active boundary-edit session, vertical navigation remains
blocked until Escape ends the session.


-------------------------------------------------------------------------------

## Segment Window Placement and Overflow

A Segment remains one continuous canonical object even when its ordinary
projection flows through multiple Narrative Display Blocks.

A Segment window is never split across blocks.

When the user activates a Segment from a particular block:

- the window opens in that block,
- that block becomes the temporary display location for the Segment,
- the activated visible portion begins at the left edge of the window,
- the window uses the greatest width available in that context,
- and overflow arrows indicate Segment content beyond the visible edges.

When activation begins at the first visible portion of the Segment:

- no left-overflow arrow is displayed,
- and a right-overflow arrow is displayed when additional Segment content
  exists beyond the window.

If the same Segment is activated from another block, the window opens in
that block instead. The canonical Segment is unchanged.

A screen boundary may divide the ordinary projection of a Segment, but it
does not divide the Segment's identity and does not create multiple
windows.

-------------------------------------------------------------------------------

-------------------------------------------------------------------------------

## Navigation Through Canonically Empty Narrative Space

A narrative display location may exist even when no canonical character
exists at that horizontal position.

When vertical movement enters a narrative row that ends before the
intended horizontal column:

- the canonical Emacs point remains at the real end of the row,
- the intended horizontal column is retained as temporary presentation
  state,
- a non-textual projected cursor is displayed at that column,
- no spaces are inserted into the narrative,
- and existing narrative content remains unchanged.

Vertical movement through other canonically empty narrative rows
preserves the projected column.

When movement reaches a row containing a real buffer position at that
column:

- the projected cursor is removed,
- the projected column is cleared,
- and ordinary Emacs point resumes at the real position.

Mouse movement, consumed selection, Escape where applicable, and redraw
remove obsolete projected-cursor state.

Projected cursor geometry is not selectable text, canonical content, or
part of a Range.

-------------------------------------------------------------------------------

## Redraw Position Preservation

Redraw preserves narrative ownership as well as canonical position.

An N1 position is restored through its canonical N1 offset.

An N2 or N3 position is restored within the same narrative. When the
pre-redraw position occupied projected empty geometry, redraw resolves
point to the end of the narrative's real canonical rendered content.

Projected cursor state belongs to the discarded projection and shall not
survive redraw.

-------------------------------------------------------------------------------

-------------------------------------------------------------------------------

## Continuous Segment Construction from Projected Geometry

Typing the first character at a Projected Cursor creates one canonical
Segment at the projected narrative location.

After that first character:

- a temporary Segment-editing session begins,
- subsequent right-edge character input extends the same Segment,
- each character becomes part of the canonical Segment text,
- the Segment retains one stable identity and starting column,
- redraw preserves the Segment and the insertion point at its right edge,
- and no padding spaces are added to the canonical narrative.

Escape ends the Segment-editing session without changing the Segment.

After the session ends, ordinary unmodeled insertion into N2 or N3 is
rejected.

Undo removes the complete uninterrupted Segment-construction operation
and restores the preceding Projected Cursor location.

Redo restores the complete Segment and its post-edit insertion position
without silently restoring the temporary Segment-editing session.

-------------------------------------------------------------------------------

-------------------------------------------------------------------------------

## Empty Active Segment Entry

A Segment-entry session belongs to the user's continuing act of entry,
not to the temporary presence of canonical characters.

When Backspace deletes the only character of a newly constructed
Segment:

- the empty Segment is removed from the canonical model,
- the projected origin is restored,
- the Segment-entry session remains active,
- and subsequent typing creates a new Segment at the same origin within
  the same continuing entry operation.

While the active entry contains no characters:

- Backspace shall beep,
- no surrounding content shall be deleted,
- and the entry session shall remain active.

Escape explicitly ends the Segment-entry session.

Temporary emptiness alone does not end entry.

-------------------------------------------------------------------------------
