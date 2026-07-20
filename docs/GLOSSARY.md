# Glossary

## Representation

A user-created external expression of an observation.

---

## Projection

A structural presentation of the same underlying representation without changing its content.

---

## Recognition

A human event in which previously unrecognized structure becomes recognized.

## Narrative Display Block

A displayed N1 line together with its associated N2 line,
N3 line, and divider line.

Narrative Display Blocks are the repeating visual units used
by the renderer.


## Boundary

The logical left or right extent of a Range within its owning narrative.

Boundaries identify represented content.

They are projected by the Layout Manager into displayed margins.

## Margin

The visible left or right editing limit presented to the user.

Margins are the presentation of Range boundaries.


## Boundary-Side Focus

The temporary editing state that determines which side of a Range
boundary owns the next edit.

Repeated clicking at the same boundary toggles focus between the Range
and the adjacent non-Range content.


## Wholesale Range Deletion

The confirmed retirement of an existing Range after all of its
represented characters have been selected for deletion.

The former text remains as strikethrough content, while the Range
definition and its Relationships are removed.

## Unlinked Content

Narrative content that remains after a former Relationship has been
removed.

Unlinked content retains its text, narrative ownership, geometry, and
display location.


## Deleted-Range Record

A persistent historical record created when an existing Range is
retired through confirmed wholesale deletion.

It preserves the former Range identity, geometry, content reference, and
Relationship information without participating in the active
Relationship structure.

## Deleted-Range List

The inspectable collection of deleted-Range records retained by the
document.

## Historical Relationship

A former Relationship preserved in a deleted-Range record for reference,
inspection, and undo.

A historical Relationship is not part of the active Relationship graph.


## Historical Relationship Highlighting

Red highlighting displayed when the user Shift-clicks a deleted
struck-through Range.

It identifies the former Range and its immediately related archived
Ranges without restoring the removed Relationships.


## Relationship Cardinality

The number and structural arrangement of Ranges participating in a
Relationship, including one-to-one, one-to-many, many-to-one, and
many-to-many.

Cardinality does not determine semantic meaning.

## Relationship Direction

An optional structural orientation among participating Ranges.

Direction does not inherently mean support, causation, agreement,
contradiction, or hierarchy.

## Relationship Type

Optional descriptive metadata that classifies a Relationship according
to a user-defined or domain-defined vocabulary.

A Relationship does not require a type to be valid.


## Mixed Boundary

A Range boundary position at which the same cursor coordinate may address
either the Range or adjacent non-Range content.

## Boundary Flash

Temporary visual feedback shown when keyboard navigation enters a mixed
boundary whose editing domain must be made explicit.


## Boundary-Edit Session

A temporary editing state begun when the user resolves a mixed Range
boundary in favor of either Range or non-Range content.

The session survives ordinary cursor movement and ends explicitly with
Escape.


-------------------------------------------------------------------------------

## Projected Cursor

A temporary visual representation of an intended horizontal position
that has no corresponding canonical buffer character.

The real Emacs point remains at the end of the narrative's existing
content while the projected cursor displays the inherited geometric
position.

A Projected Cursor is presentation state. It is not text, padding,
Range content, or a second canonical insertion point.


## Projected Column

The temporary horizontal coordinate preserved while the cursor occupies
canonically empty narrative geometry.

The Projected Column is cleared when a real buffer position can represent
the location or when the current projection is discarded.


## Canonically Empty Narrative Space

A valid location in computed narrative geometry at which no canonical
narrative character presently exists.

Its existence is established by layout and narrative ownership rather
than by preceding spaces stored in the text.

-------------------------------------------------------------------------------

-------------------------------------------------------------------------------

## Segment-Editing Session

A temporary editing state established when character input at a
Projected Cursor creates a canonical Segment.

While point remains at the Segment's right edge, subsequent character
input extends that same Segment.

The session is presentation and interaction state. It is not part of the
persistent Segment representation.

Escape, history restoration, or departure from the permitted editing
position ends the session.

-------------------------------------------------------------------------------

-------------------------------------------------------------------------------

## Empty Active Segment Entry

A Segment-entry session that remains active at its Projected Column after
all of its canonical characters have been deleted.

No empty Segment is stored in the representation.

The entry retains its narrative owner, Narrative Display Block, and
projected origin so that subsequent typing may resume naturally.

Escape ends the entry.

-------------------------------------------------------------------------------

-------------------------------------------------------------------------------

## Segment-Entry Enclosure

The insertion-position territory owned by an active Segment-entry
session.

Within the enclosure, ordinary Left, Right, insertion, and Backspace
behavior applies to the same canonical Segment.

Movement or deletion does not cross into layout, separators, neighboring
Segments, or another narrative.

-------------------------------------------------------------------------------

## Layout-Owned Separator

The visible three-character string:

    " | "

placed between adjacent Segments on the same narrative line.

It is computed presentation and belongs to neither Segment's canonical
text.

Its presence follows current adjacency rather than historical placement.

-------------------------------------------------------------------------------

## Projected Geometry on Rendered Padding

A canonically empty insertion location that coincides with a physical
buffer column containing disposable renderer-owned spacing.

The physical point may occupy the column while
`tne-projected-column` preserves its canonical projected status.

-------------------------------------------------------------------------------
