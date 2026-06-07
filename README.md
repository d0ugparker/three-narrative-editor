# Three Narrative Editor

Version: 0.1.0

This is the first clean prototype package for the Three Narrative Editor major mode.

## What this version does

Version 0.1.0 proves the first architectural idea:

- Three independent narrative strings are stored separately.
- A renderer weaves them into a repeating visual pattern:

```text
Narrative 1 row
Narrative 2 row
Narrative 3 row

Narrative 1 row
Narrative 2 row
Narrative 3 row
```

- Editing is command-based in this version.
- Monospace layout is assumed.
- No relationships yet.
- No segments yet.
- No mouse support yet.
- No true direct editing of the rendered display yet.

This version is intentionally small. It proves the model and renderer before adding the hard interaction rules.

## Files

```text
tne-model.el
tne-render.el
tne-mode.el
README.md
TESTING.md
```

## Installation

Put all `.el` files in the same directory.

In Emacs, run:

```text
M-x load-file
```

Load:

```text
tne-mode.el
```

Then run:

```text
M-x tne-mode
```

## Commands

Inside `tne-mode`:

```text
C-c C-1   Set Narrative 1 text
C-c C-2   Set Narrative 2 text
C-c C-3   Set Narrative 3 text
C-c C-r   Re-render woven display
C-c C-s   Show stored narratives
```

## Recommended test text

Narrative 1:

```text
The tradeoff between brain and Nature can be understood through repeated observation of behavior over time.
```

Narrative 2:

```text
line two content can be entered independently
```

Narrative 3:

```text
line three content can also be entered independently
```

## Current limitation

This version is not yet the final editor behavior. It does not yet allow clicking into blank woven rows and typing directly. That comes later.

The purpose of this version is to confirm that the stored model and woven display are separated correctly.
