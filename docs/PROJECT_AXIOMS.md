# Project Axioms

This document contains the principles that have survived repeated observation during the development of the Three Narrative Editor (TNE) and the Relationship Editor (RE). These axioms are intended to be stable over time and should only be changed when substantial evidence demonstrates that they are incomplete or incorrect.

## Current Axioms

1. The Relationship Editor stores representations, not reality.

2. The Relationship Editor stores relationships explicitly recognized by the user, not relationships inferred by the software.

3. The Relationship Editor preserves representations faithfully.

4. The Relationship Editor presents multiple projections of the same underlying representation.

5. The Relationship Editor performs no interpretation.

6. Recognition occurs in the human, not in the Relationship Editor.

## Notes

Implementation details are expected to evolve.

These axioms are intended to outlive any particular implementation.


## Progressive Relationship Exploration

The Relationship Editor reveals relationships one level of recognition
at a time.

The editor never expands the complete relationship graph
automatically.

The user's attention determines which neighborhood of the graph is
revealed.


-------------------------------------------------------------------------------

## User Intent

The Relationship Editor continuously represents the destination of the
user's current intent.

Presentation exists to communicate that destination clearly.

-------------------------------------------------------------------------------


-------------------------------------------------------------------------------

## Recognition

The fundamental persistent act performed within the Relationship Editor
is recognition.

Ranges represent recognized portions of narratives.

Relationships represent recognized connections among those Ranges.

The editor preserves recognition.

It neither discovers nor infers recognition on the user's behalf.

-------------------------------------------------------------------------------


-------------------------------------------------------------------------------

## Canonical History

Undo and redo operate on the canonical representation rather than the
current presentation.

The rendered editor is a projection of the underlying representation.
Once projection geometry differs from representation geometry, history
can no longer be maintained reliably from rendered buffer positions.

Canonical history therefore belongs to the representation layer and is
projected into the editor in the same manner as any other document
state.

-------------------------------------------------------------------------------

