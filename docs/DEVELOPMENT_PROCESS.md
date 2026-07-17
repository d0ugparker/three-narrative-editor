
-------------------------------------------------------------------------------

## Archiving Knowledge

Development conversations are temporary.

The repository is permanent.

Any observation, architectural discovery, design principle, or
implementation decision expected to benefit future contributors shall be
archived in the appropriate project document before the session
concludes.

Nothing important should remain only in the development conversation.

-------------------------------------------------------------------------------


-------------------------------------------------------------------------------

## Session Knowledge Capture

Every development session shall conclude by archiving any observations,
design decisions, glossary additions, specifications, questions, or
development-process improvements discovered during the session.

The conversation is the workshop.

The repository is the permanent project.

Nothing expected to benefit future programmers shall remain only in the
development conversation.

-------------------------------------------------------------------------------


-------------------------------------------------------------------------------

## Principle Before Mechanism

When a new behavior is proposed, first determine whether it expresses a
more general architectural principle.

If such a principle exists, record the principle before specifying the
individual mechanism.

Mechanisms should be derivable from principles whenever practical.

-------------------------------------------------------------------------------


-------------------------------------------------------------------------------

## Mixed-Boundary Navigation Test Matrix

Boundary-navigation testing shall cover both boundaries and both editing
domains.

For the left shared boundary, verify:

- horizontal arrival establishes no domain,
- Up initially selects Range,
- Down initially selects non-Range,
- repeated Up or Down toggles the domain,
- Left and Right move only as permitted by the selected enclosure,
- Up and Down beep after point enters the chosen domain,
- point remains on the same narrative line,
- and Escape restores ordinary navigation.

For the right shared boundary, verify the same behaviors independently.

Testing shall also verify:

- navigation inside the complete Range,
- navigation inside the adjacent non-Range domain,
- attempted crossing of each enclosing boundary,
- audible warning and explanatory message,
- state persistence during permitted horizontal navigation,
- Escape termination,
- unrestricted boundary crossing after Escape,
- mixed-boundary flash after Escape,
- and preservation of the current horizontal column during ordinary
  vertical movement between narrative lines.

A test of one boundary shall not be treated as proof that the opposite
boundary behaves correctly.

-------------------------------------------------------------------------------


-------------------------------------------------------------------------------

## Undo Testing Without Intermediate Commands

Emacs evaluation commands participate in the command sequence being
tested.

Running `M-:` evaluations between characters may interrupt editing
coalescence, trigger command-boundary processing, and cause RE history
checkpoints to occur at intermediate construction states.

Undo and redo tests shall therefore:

1. construct the complete intended edit without diagnostic commands,
2. end the temporary editing state when required,
3. perform undo or redo,
4. and evaluate the resulting state afterward.

Diagnostic evaluations may be used at explicit checkpoints, but shall
not be inserted inside an operation whose undo grouping is under test.

-------------------------------------------------------------------------------

-------------------------------------------------------------------------------

## Pretty-Printed Diagnostic Results

Diagnostic expressions whose expected results are shown as structured
Lisp data shall be run with:

    M-x pp-eval-expression

rather than ordinary `M-:` evaluation.

This provides stable indentation and line breaks, making the observed
result directly comparable with the expected result supplied in the
test instructions.

-------------------------------------------------------------------------------
