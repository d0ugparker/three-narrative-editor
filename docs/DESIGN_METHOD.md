# Design Method

This document records how this project is being developed.

It is not a design specification.

It is an observation log describing the development methodology itself.

---

## 2026-06-22

Observation:

Perfectly reasonable software abstractions were discarded because they failed to survive repeated observation.

Rather than forcing the software to fit the abstraction, the abstraction was abandoned.

Candidate Principle:

Observation precedes abstraction.

## Functional Specification First

New editor behavior should be developed in the following order:

User Behavior
→ Functional Specification
→ Implementation
→ Testing
→ Documentation
→ Git Commit

The specification describes observable behavior rather than
implementation details whenever possible.


## Progressive Relationship Exploration

Relationship visualization is intentionally local.

The editor reveals only the first level of relationships surrounding the
currently recognized range.

Subsequent levels become visible only when the user's attention moves to
those newly revealed ranges.

This keeps exploration predictable while preventing uncontrolled visual
expansion.


-------------------------------------------------------------------------------

## Model–Renderer Separation

The renderer shall be a projection mechanism.

It shall not become an additional source of document state.

The renderer is responsible for presenting the document.

The model is responsible for preserving the document.

Whenever uncertainty exists, new persistent information belongs in the
model rather than in the renderer.

-------------------------------------------------------------------------------


-------------------------------------------------------------------------------

## Layout Manager

The Layout Manager computes spatial arrangement from the persistent
representation.

The renderer displays that arrangement.

The Layout Manager performs no drawing.

The renderer performs no layout calculations beyond those required for
displaying the computed layout.

-------------------------------------------------------------------------------


-------------------------------------------------------------------------------

## Progressive Architectural Refinement

Architectural subsystems should not be specified until the underlying
abstractions upon which they depend have been defined.

Representation precedes Layout.

Layout precedes Presentation.

Presentation precedes user interaction.

This ordering minimizes architectural revision while allowing later
sections to build naturally upon earlier ones.

-------------------------------------------------------------------------------


-------------------------------------------------------------------------------

## Persistence Architecture

Persistent document objects shall be serialized independently of layout
and renderer state.

Loading follows this direction:

Saved representation
→ reconstructed object graph
→ computed layout
→ presentation

Saving follows this direction:

Persistent object graph
→ validation
→ serialization
→ durable document file

Layout and presentation shall not become substitute storage formats.

Alpha 0.1 shall prefer a self-contained document format over a separate
database.

-------------------------------------------------------------------------------


-------------------------------------------------------------------------------

## Hierarchical Rendering

Rendering proceeds hierarchically.

Document

↓

Narrative Display Blocks

↓

Narratives

↓

Ranges

Each rendering function should normally be responsible for exactly one
level of this hierarchy.

This minimizes coupling and simplifies future renderer extensions.

-------------------------------------------------------------------------------


-------------------------------------------------------------------------------

## Canonical Narrative Reflow

Narrative wrapping shall be computed by the Relationship Editor.

Emacs visual line wrapping shall not create substitute continuation
rows.

The renderer divides complete narrative representations into physical
Narrative Display Blocks while preserving exact text and model offsets.

-------------------------------------------------------------------------------

