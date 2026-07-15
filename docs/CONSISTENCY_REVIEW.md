# Relationship Editor
## Alpha 0.1 Consistency Review

Purpose

Verify that every feature described in the specification is internally
consistent and derived from the project's governing principles.

The review asks:

1. Is the feature necessary?
2. Does it duplicate another concept?
3. Does it violate an axiom?
4. Does it introduce hidden state?
5. Can it be derived from an existing principle?
6. Does it belong in Alpha 0.1?
7. Has it already been implemented?

Status values:

[ ] Not reviewed
[P] Partial
[X] Complete


-------------------------------------------------------------------------------

Persistent Objects

[X] Document
[X] Narrative
[X] Range
[X] Relationship
[X] Deleted-Range Record

Review:

Each persistent object possesses:

- stable identity,
- ownership,
- lifecycle,
- persistence,
- and presentation independence.

No duplicate persistent object concepts identified.

-------------------------------------------------------------------------------


-------------------------------------------------------------------------------

Presentation State

[X] Cursor
[X] Highlight
[X] Inspection
[X] Boundary-side Focus
[X] Window Expansion
[X] Scroll Position

Review:

All presentation state is temporary.

No presentation state presently violates the Representation/Layout/
Presentation separation.

-------------------------------------------------------------------------------


-------------------------------------------------------------------------------

Editing

[X] Character insertion

[X] Character deletion

[X] Replace

[X] Undo

[X] Geometry propagation

[X] Margin policy

[X] Boundary-side focus

Outstanding review:

Determine whether any edit operation can produce an undefined Range
state.

-------------------------------------------------------------------------------

