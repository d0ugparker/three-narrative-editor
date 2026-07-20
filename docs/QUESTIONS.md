
-------------------------------------------------------------------------------

Post Alpha 0.1 / Beta / Pre-Version 1.0

Create a canonical "Hello World" document that uses the Relationship
Editor to explain the architecture and operation of the Relationship
Editor itself.

The document should serve as the editor's self-describing demonstration.

N1 should contain the primary architectural narrative.

N2, N3, and subsequent narratives should progressively expose the
design rationale, implementation decisions, historical evolution,
and relationship structure that produced the editor.

The objective is for the Relationship Editor to demonstrate its own
capabilities by expressing itself using its own editing model.

-------------------------------------------------------------------------------


-------------------------------------------------------------------------------

Relationship Editor Self-Demonstration Candidate

Use the following sentence as a canonical demonstration of how the
Relationship Editor represents multiple simultaneously valid
interpretations of the same text.

Example sentence:

    "Those didn't emerge because I wanted three layers."

Possible interpretation A:

    The emphasis is on "I wanted three layers."

    The sentence is understood as stating that a personal preference for
    three layers existed, but that preference was not the reason the
    three layers emerged.

Possible interpretation B:

    The emphasis is on the causal phrase "didn't emerge because."

    The sentence is understood as explaining that the emergence of the
    three layers resulted from an objective architectural distinction
    rather than from personal preference.

Observation:

Both interpretations are grammatically supported.

The reader uses surrounding context to determine which conceptual parse
was intended.

Future "Hello World" Example:

Use the Relationship Editor itself to demonstrate how multiple
simultaneously valid interpretations of a single sentence can coexist
without requiring one interpretation to overwrite the other.

This example should become one of the canonical demonstrations of the
Relationship Editor's ability to represent parallel interpretations of
the same source text.

-------------------------------------------------------------------------------


-------------------------------------------------------------------------------

Future Relationship Classification

Relationship type remains optional.

Future users and programmers may investigate whether useful,
domain-specific systems of Relationship classification can be developed
without forcing interpretation or reducing complex relationships to
premature categories.

Questions include:

- Which Relationship types are broadly reusable?
- Which types should remain domain-specific?
- Can several types apply to one Relationship?
- Can type assignments change historically without replacing the
  Relationship itself?
- How should typed and untyped Relationships be displayed together?
- Does direction belong to the Relationship, to individual participants,
  or to a particular projection?

Alpha 0.1 shall not require answers to these questions.

-------------------------------------------------------------------------------


-------------------------------------------------------------------------------

Persistence Format

Choose the Alpha 0.1 serialization format after comparing the
specification with the current Emacs Lisp model and save/load code.

Candidate formats include:

- readable Emacs Lisp data,
- JSON,
- or a project-specific structured text format.

The selected format must preserve stable identities, object references,
deleted-Range records, and persistent policies without depending on
renderer coordinates.

Questions to resolve before implementation:

- Should the saved file remain directly human-readable?
- Should narrative text and model metadata occupy one file or a
  coordinated pair of files?
- How should format versions and migrations be identified?
- How should interrupted or failed saves be recovered?
- Should automatic backup files use ordinary Emacs conventions or a
  Relationship Editor-specific mechanism?

-------------------------------------------------------------------------------


-------------------------------------------------------------------------------

## Deferred Segment-Origin Editing

Beta or a later release shall permit an active Segment's starting column
to change without changing its identity.

Required future behavior includes:

- deleting backward through all existing Segment characters,
- continuing through projected empty geometry where permitted,
- preventing movement across a layout separator or neighboring Segment,
- typing new content at a different permitted position,
- and updating the same Segment's starting column to the new content
  origin.

Example:

A Segment containing `ABXC` may be emptied. If the entry position then
moves four available projected columns to the right and `Y` is typed,
the same Segment begins at the new `Y` position.

The Segment identity remains stable while its geometry changes.

The permitted movement territory must account for neighboring Segments
and the three display columns required by each `" | "` separator.

-------------------------------------------------------------------------------
