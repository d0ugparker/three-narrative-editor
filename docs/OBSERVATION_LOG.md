## 2026-06-22

Observation

Ranges are temporary.
Segments are persistent.

Result

The architecture became simpler.

Lesson

Workspace objects and document objects should remain separate.

## 260712

Observation:
User behavior descriptions should precede functional specifications.

The implementation should be derived from the specification rather than
the specification being written after the code.

Observation:
A displayed N1 line, together with its corresponding N2, N3, and divider
lines, forms a single Narrative Display Block.

This provides a useful conceptual unit for renderer design and discussion.


-------------------------------------------------------------------------------

## 260714

Observation:
Linear language often contains more relational structure than it can
explicitly display.

A single sentence may legitimately support multiple conceptual
interpretations while remaining grammatically correct.

Readers use surrounding context to choose the interpretation they
believe the author intended.

The Relationship Editor provides a representation in which multiple
simultaneously valid interpretations may coexist without requiring one
interpretation to overwrite or replace another.

The editor therefore does not resolve ambiguity.

It represents ambiguity explicitly.

This observation provides one of the strongest demonstrations of the
Relationship Editor's purpose.

-------------------------------------------------------------------------------


-------------------------------------------------------------------------------

## 260714

Observation:
The Relationship Editor does not create multidimensional thought.

Thought is already multidimensional.

Conventional writing serializes that thought into a single linear
narrative.

The Relationship Editor allows additional relational structure already
present in the author's thinking to remain visible without disrupting
the readability of the primary narrative.

-------------------------------------------------------------------------------


-------------------------------------------------------------------------------

## 260714

Observation:
The Relationship Editor is not an ambiguity resolver.

It is an ambiguity representer.

When multiple interpretations of the same source material are
recognized by the user, the editor provides a representation in which
those interpretations may coexist without forcing one to replace the
others.

Resolution, if any, remains the responsibility of the user.

-------------------------------------------------------------------------------


-------------------------------------------------------------------------------

## 260714

Observation:
Conceptual distinctions are determined by role rather than physical
implementation.

Two concepts are distinct when one may change while the other remains
constant.

Examples include:

- Representation versus Presentation
- Representation versus Relationship
- Layout versus Relationship

A reliable design question is therefore:

    "Can one change while the other remains constant?"

If yes, they represent different concepts and should remain distinct.

-------------------------------------------------------------------------------


-------------------------------------------------------------------------------

## 260714

Observation:
A Range identifies content but does not store an independent duplicate
of that content.

The owning narrative remains the authoritative source of text.

The Range contributes stable identity, boundaries, geometry, and
Relationship membership.

This distinction prevents editing from creating competing copies of the
same represented text.

Observation:
Relationships connect stable Range identities rather than text strings
or temporary display coordinates.

A Range may therefore move, resize, wrap, or change presentation without
losing its identity or its Relationships.

-------------------------------------------------------------------------------


-------------------------------------------------------------------------------

## 260714

Observation:
A boundary and a margin are not the same concept.

A Range owns boundaries.

The Layout Manager projects those boundaries into displayed margins.

Boundaries belong to representation.

Margins belong to presentation.

-------------------------------------------------------------------------------


-------------------------------------------------------------------------------

## 260714

Observation:
For ordinary editing, the left boundary of a Range functions primarily
as an anchor.

The right boundary functions primarily as the adaptive boundary that
responds to changes in represented phrase length.

This asymmetry simplifies editing while preserving the user's intended
identification of the represented content.

-------------------------------------------------------------------------------


-------------------------------------------------------------------------------

## 260715

Observation:
A Range boundary has one geometric position but two possible editing
contexts.

Cursor position alone cannot determine whether an edit belongs to the
Range or to adjacent non-Range content.

The renderer must therefore expose boundary-side focus and allow the
user to toggle that focus explicitly.

Observation:
A boundary is not merely a coordinate.

During editing, it is an interface between two separately editable
content domains.

-------------------------------------------------------------------------------


-------------------------------------------------------------------------------

## 260715

Observation:
Deleting all represented text from an existing Range is categorically
different from editing the wording inside that Range.

Ordinary editing preserves Range identity and Relationships.

Confirmed wholesale deletion retires the Range and removes its
Relationships while preserving the former source text as strikethrough
historical evidence.

Observation:
Removing a Relationship does not imply removing either participant's
text.

Formerly related content remains intact and in place after the
Relationship is broken.

Observation:
Wholesale Range deletion must be implemented as one atomic transaction.

Text formatting, Range identity, geometry, and Relationships must be
removed and restored together so that undo can never expose an
internally inconsistent document state.

-------------------------------------------------------------------------------


-------------------------------------------------------------------------------

## 260715

Observation:
Strikethrough preservation after wholesale Range deletion is both
historical and geometric.

Keeping the former characters in place avoids disruptive reflow across
narratives, margins, and Narrative Display Blocks.

Observation:
A deleted Range leaves the active relationship structure but does not
lose its historical identity.

A deleted-Range record preserves its former content location, geometry,
and Relationships for inspection and undo.

Observation:
Active relationships and historical relationships must be visibly and
structurally distinct.

Clicking struck-through former Range content may reveal its archived
relationships without reactivating them.

-------------------------------------------------------------------------------


-------------------------------------------------------------------------------

## 260715

Observation:
The same inspection gesture applies to active and retired Ranges, while
presentation distinguishes their states.

Shift-clicking an active Range reveals its immediate active
Relationships through ordinary highlighting.

Shift-clicking a deleted struck-through Range reveals its immediate
historical Relationships in red.

The interaction remains consistent while color communicates whether the
revealed Relationship belongs to the present or the recorded past.

-------------------------------------------------------------------------------


-------------------------------------------------------------------------------

## 260715

Observation:
Relationship cardinality, direction, and semantic type are separate
properties.

One-to-one, one-to-many, many-to-one, and many-to-many structures
describe participation.

They do not establish whether the participating content supports,
contradicts, equals, explains, or otherwise semantically relates.

Observation:
The existence of an explicitly created Relationship is complete evidence
that the user recognized a relationship.

Semantic classification is optional and may remain unspecified.

Requiring premature classification would force interpretation into a
system intended to preserve the user's representation faithfully.

-------------------------------------------------------------------------------


-------------------------------------------------------------------------------

## 260715

Observation:
The Relationship Editor stores stable objects rather than transient
editing state.

Presentation may change continuously while the underlying object graph
remains unchanged.

Rendering is therefore a projection of the object graph rather than the
object graph itself.

-------------------------------------------------------------------------------


-------------------------------------------------------------------------------

## 260715

Observation:
The document stores persistent knowledge.

The renderer stores temporary attention.

Persistent objects describe what the user has recognized.

Presentation state describes what the user is currently examining.

The two shall remain independent.

-------------------------------------------------------------------------------


-------------------------------------------------------------------------------

## 260715

Observation:
Rendering is projection.

Editing changes the model.

Rendering reflects those changes but does not become an independent
source of truth.

-------------------------------------------------------------------------------


-------------------------------------------------------------------------------

## 260715

Observation:
The Relationship Editor consists of four conceptual layers.

Reality

↓

Representation

↓

Layout

↓

Presentation

Reality exists outside the editor.

Representation stores persistent document knowledge.

Layout computes deterministic spatial arrangement from that
representation.

Presentation displays the current interactive view produced from the
layout.

Keeping these four layers independent simplifies implementation,
testing, maintenance, and future extension.

-------------------------------------------------------------------------------


-------------------------------------------------------------------------------

## 260715

Observation:
Layout is deterministic.

Presentation is interactive.

The Layout Manager computes where objects belong.

The renderer computes how those objects are displayed.

-------------------------------------------------------------------------------


-------------------------------------------------------------------------------

## 260715

Observation:

Viewfinder windows are not additional document structures.

They are an alternative presentation of existing narratives.

Every editing rule applying to N1, N2, and N3 therefore applies
unchanged within a viewfinder.

The viewfinder changes visibility, not behavior.

-------------------------------------------------------------------------------


-------------------------------------------------------------------------------

## 260715

Observation:

The Relationship Editor has one editing model.

Presentation determines where a narrative is displayed.

It does not determine how that narrative behaves.

Directly displayed narratives and viewfinder narratives therefore obey
the same editing rules.

-------------------------------------------------------------------------------


-------------------------------------------------------------------------------

## 260715

Observation:

Only one viewfinder expands at any time.

Expansion identifies the user's current area of concentrated work.

All remaining viewfinders stay collapsed, preserving screen space while
maintaining awareness of additional narratives.

-------------------------------------------------------------------------------


-------------------------------------------------------------------------------

## 260715

Observation:

The Relationship Editor guides attention through progressively smaller
neighborhoods.

The user works at three simultaneous scales:

- the complete document,
- one expanded viewfinder,
- one recognized Range.

Each scale reveals only the information immediately surrounding the
user's current focus.

The editor therefore supports exploration without overwhelming the
user's attention.

-------------------------------------------------------------------------------


-------------------------------------------------------------------------------

## 260715

Observation:

The Relationship Editor does not attempt to maximize visible
information.

It attempts to maximize comprehensible information.

Information becomes visible according to the user's current attention.

The amount of displayed information therefore follows the user's focus
rather than the total amount of stored information.

-------------------------------------------------------------------------------


-------------------------------------------------------------------------------

## 260715

Observation:

Focus identifies the current destination of user intent.

The editor's behavior follows focus.

The document's structure does not.

-------------------------------------------------------------------------------


-------------------------------------------------------------------------------

## 260715

Observation:

The Relationship Editor is fundamentally recognition-centric.

Its persistent objects are records of what the user has explicitly
recognized rather than interpretations produced by the software.

-------------------------------------------------------------------------------


-------------------------------------------------------------------------------

## 260715

Observation:

The Relationship Editor performs three fundamental functions.

Recognize.

Preserve.

Present.

Recognition creates persistent structure.

Preservation maintains that structure.

Presentation allows the user to interact with that structure without
changing it unless explicitly requested.

-------------------------------------------------------------------------------


-------------------------------------------------------------------------------

## 260715

Observation:

The Relationship Editor has gradually shifted from feature discovery to
architectural discovery.

Earlier development identified individual capabilities.

Current development identifies governing principles from which many
capabilities naturally follow.

This transition indicates increasing architectural maturity.

-------------------------------------------------------------------------------


-------------------------------------------------------------------------------

## 260715

Observation:

The Relationship Editor must preserve recognized structure between
sessions, not merely preserve visible text.

A saved document therefore includes stable Range identities,
Relationships, deleted-Range records, and persistent policies in
addition to narrative content.

Observation:

The document file is authoritative.

Layout and presentation are reconstructed projections and shall not
become hidden sources of persistent state.

Observation:

A database is not required for Alpha 0.1.

Database infrastructure becomes justified only when document-independent
capabilities such as cross-document Relationships, global indexes, or
concurrent access are required.

-------------------------------------------------------------------------------


-------------------------------------------------------------------------------

## 260715

Observation:

Architectural maturity is reached when development shifts from
discovering new concepts to verifying that existing concepts explain all
legal behaviors.

At that point, implementation becomes the primary remaining activity.

-------------------------------------------------------------------------------


-------------------------------------------------------------------------------

## 260715

Observation:

Restoring text without restoring its expected insertion-point location
does not fully restore the user's editing state.

Undo and redo must therefore restore the conceptual operation rather
than only its visible character changes.

-------------------------------------------------------------------------------


-------------------------------------------------------------------------------

## 260715

Observation:

A rendered editable buffer cannot safely serve as both presentation and
persistent storage.

Ordinary N1 editing now updates the canonical document model, while
redraw reconstructs the presentation from that model without losing
user changes.

Observation:

Undo and redo are complete only when they restore both represented text
and the insertion-point consequence of the conceptual operation.

-------------------------------------------------------------------------------


-------------------------------------------------------------------------------

## 260715

Observation:

Large architectural changes should be implemented as sequences of
behavior-preserving refactorings followed by small behavioral changes.

Keeping each intermediate state working simplifies debugging, testing,
and future maintenance.

-------------------------------------------------------------------------------


-------------------------------------------------------------------------------

## 260715

Observation:

Narrative continuation must be controlled by the Relationship Editor
rather than by Emacs visual line wrapping.

Emacs visual continuations create screen rows that resemble document
structure without belonging to the canonical Narrative Display Block
layout.

Observation:

Available narrative width must account for display elements such as line
numbers that may consume columns without being excluded from Emacs's
reported window text width.

-------------------------------------------------------------------------------


-------------------------------------------------------------------------------

## 260715

Observation:

Correct wrapping was achieved only after distinguishing between the
physical window width, the usable narrative width, and the canonical
Relationship Editor wrap width.

The renderer intentionally reserves one additional column beyond the
usable display width so that canonical block boundaries always precede
any editor-generated visual continuation.

-------------------------------------------------------------------------------


-------------------------------------------------------------------------------

## 260715

Observation:

Canonical buffer reconstruction from inside `after-change-functions'
breaks ordinary undo grouping.

The originating character edit and the renderer's reconstruction can
become separate operations, producing a partially undone word even
though the visible document appears correct before undo.

The after-change hook shall update the persistent model only.

Canonical reflow shall occur after the originating command has
completed.

-------------------------------------------------------------------------------


-------------------------------------------------------------------------------

## 260715

Observation:

The introduction of Narrative Display Blocks changed the editor from an
editable text buffer into a rendered projection.

Once presentation geometry diverges from representation geometry,
position-based editor history becomes unreliable.

Undo and redo therefore become properties of the representation rather
than of the rendered presentation.

-------------------------------------------------------------------------------


-------------------------------------------------------------------------------

## 260715

Observation:

A mixed Range boundary cannot be resolved from cursor coordinates alone.

Mouse repetition, navigation direction, and explicit keyboard toggling
provide the additional state required to identify which editing domain
owns the next operation.

Observation:

Word-navigation commands are especially important because their normal
landing positions coincide with the mixed positions immediately before
and after words.

The Relationship Editor must normalize behavioral results across
platforms rather than assume that one modifier-key sequence is universal.

-------------------------------------------------------------------------------


-------------------------------------------------------------------------------

## 260715

Observation:

Arriving at an ambiguous boundary is not equivalent to resolving it.

Horizontal navigation remains free and stateless.

The renderer exposes the ambiguity, while an intentional vertical or
mouse gesture establishes which editing domain receives subsequent
intent.

Observation:

The current Range A and Range B objects are temporary selection state.

Mixed-boundary editing must be attached to the persistent segment
created from a selection rather than to the temporary selection itself.

-------------------------------------------------------------------------------


-------------------------------------------------------------------------------

## 260715

Observation:

Resolving an ambiguous boundary establishes editing intent that must
survive ordinary cursor movement.

Clearing that intent merely because point moved would make navigation
silently override an explicit user decision.

Observation:

Escape provides an explicit transition from a temporary editing state
back to ordinary stateless navigation.

This pattern may be reused by future interaction states, but each use
must be specified as it is encountered.

-------------------------------------------------------------------------------


-------------------------------------------------------------------------------

## 260715

Observation:

Resolving a mixed boundary does more than identify editing intent.

It establishes a temporary editing enclosure.

The enclosure prevents ordinary navigation or editing from silently
crossing into the domain the user deliberately excluded.

Escape removes the enclosure and restores unrestricted navigation.

-------------------------------------------------------------------------------


-------------------------------------------------------------------------------

## 260716

Observation:

Ordinary Emacs vertical navigation may retain a temporary goal column
from an earlier cursor operation.

After mixed-boundary interaction, that remembered position can cause
point to return unexpectedly to a segment boundary instead of preserving
its actual current column.

Relationship Editor vertical navigation therefore uses point's current
horizontal position explicitly whenever no editing-domain enclosure is
active.

-------------------------------------------------------------------------------


-------------------------------------------------------------------------------

## 260716

Observation:

A Segment may flow through several Narrative Display Blocks while
remaining one canonical object.

Opening a Segment window does not gather or split windows across those
blocks. The window opens locally in the block where the user activated
the Segment and displays as much content as its available width permits.

Overflow arrows communicate hidden Segment content beyond the window
edges.

Result:

Canonical continuity and local presentation are independent.

The activation location determines where the window appears, but does
not alter the Segment or divide its identity.

-------------------------------------------------------------------------------

-------------------------------------------------------------------------------

## 260716 — Navigable Geometry Without Text

Observation:

Emacs ordinarily treats a visible cursor location and a buffer position
as the same thing.

The Relationship Editor cannot always do so.

A user may move vertically into a valid narrative location whose
horizontal geometry is inherited from another narrative even though the
destination narrative contains no characters extending to that column.

Literal padding failed because Emacs treated the padding as selectable,
editable, wrappable buffer content.

Result:

The real Emacs point remains at the canonical row end while a temporary
overlay displays a projected cursor at the intended column.

This preserves navigation without manufacturing false narrative
content.


Observation:

Two cursor positions may look identical while possessing different
internal foundations.

One is supported by canonical characters.

The other is supported by narrative ownership, computed layout, and
projected geometry.


Observation:

Redraw must preserve narrative ownership, not merely an N1-relative
offset.

The old projection, including projected cursor state, is disposable.
The canonical Segment remains authoritative and is rendered again.

-------------------------------------------------------------------------------

-------------------------------------------------------------------------------

## 260717 — Segment Construction Across Keystrokes

Observation:

The first character typed in canonically empty projected geometry creates
a new Segment.

Later characters may look like ordinary Emacs insertion, but they extend
the same canonical Segment under a temporary Segment-editing session.

Result:

A visible string assembled character by character remains one persistent
Segment rather than becoming several Segments or unmodeled buffer text.


Observation:

Diagnostic evaluation is not observationally neutral within Emacs
command history.

An `eval-expression` command inserted between editing commands can divide
the operation being tested and alter where history checkpoints occur.

Result:

Undo grouping must be tested with an uninterrupted editing sequence.

-------------------------------------------------------------------------------

-------------------------------------------------------------------------------

## 260717 — Entry Persists Through Temporary Emptiness

Observation:

The existence of a Segment and the existence of an entry session are
different facts.

A user may delete the first or final remaining character because it was
mistyped and then continue typing from the same starting location.

Result:

The empty Segment is removed from the canonical model, while the
Segment-entry session remains active at its projected origin.

The representation does not preserve a meaningless empty object, but the
interaction preserves the user's unfinished act of entry.

This separates object lifecycle from interaction lifecycle.

-------------------------------------------------------------------------------

-------------------------------------------------------------------------------

## 260718 — Segment Identity and Mutable Geometry

Observation:

Segment identity and Segment geometry are distinct.

A Segment may remain the same recognized object even when later editing
changes where its canonical content begins.

Alpha 0.1 keeps the starting column fixed during entry.

Beta and later versions must allow the starting column to move through
available projected geometry while remaining bounded by neighboring
Segments and layout separators.


Observation:

The visible string `" | "` separates Segments but belongs to neither
Segment.

Its existence is determined by Segment adjacency:

- no separator for one Segment,
- one separator between two Segments,
- and two separators around a Segment inserted between two others.

Result:

Separators belong to computed layout rather than canonical Segment text.

-------------------------------------------------------------------------------

-------------------------------------------------------------------------------

## 260719 — Editing Territory Is Not Current Text Width

Observation:

A Segment's current character width does not define its complete editing
territory.

During entry, its canonical text may expand and contract within territory
bounded by the N1 narrative extent and neighboring Segment geometry.

Result:

The Segment's present right edge is mutable, while its available
territory is computed from surrounding representation and layout rules.


Observation:

A separator is produced by adjacency, not stored history.

When two Segments become adjacent, `" | "` appears. When one is removed,
the separator disappears.

Result:

The separator is a projection of current Segment relationships in
display geometry, not canonical Segment content.


Observation:

Projected canonical geometry and physical buffer reachability are
different facts.

Renderer-owned padding may make a column physically reachable without
making it canonical narrative content.

Result:

Projected status must be preserved independently from whether Emacs can
place physical point at the same display column.

-------------------------------------------------------------------------------

-------------------------------------------------------------------------------

## 260720 — Adjacency Is Recomputed From Canonical Segments

Observation:

Creating a Segment between two existing Segments changes one adjacency
relationship into two.

Deleting that middle Segment changes the two adjacency relationships
back into one.

Result:

Separators cannot be retained as historical display artifacts. They must
be recomputed from the current ordered canonical Segment set every time
the narrative is rendered.


Observation:

An empty active entry between existing Segments is not itself a
canonical Segment.

Result:

The surrounding Segments become directly adjacent while the entry
session separately preserves the projected origin from which a new
Segment may later be created.

-------------------------------------------------------------------------------
