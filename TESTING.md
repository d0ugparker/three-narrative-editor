# Three Narrative Editor Testing

## Version 0.1.0

Status: Ready for testing

## Added in this version

- Three independent narrative strings
- Woven display renderer
- Monospace row wrapping
- Major mode shell
- Command-based editing
- Stored model separated from rendered display

## Known limitations

- No mouse support
- No direct typing into woven display rows
- No relationships
- No segments
- No editable spacing between segments
- No file save/load format yet
- No Option-click behavior

## Test checklist

### Test 1 — Load mode

Steps:

1. Open Emacs.
2. Run `M-x load-file`.
3. Load `tne-mode.el`.
4. Run `M-x tne-mode`.

Expected result:

- Buffer enters `TNE` mode.
- A default woven display appears.

Result:

- PASS:
- FAIL:
- Notes:

---

### Test 2 — Set Narrative 1

Steps:

1. Press `C-c C-1`.
2. Enter:

```text
The tradeoff between brain and Nature can be understood through repeated observation of behavior over time.
```

Expected result:

- Narrative 1 appears woven across row 1 positions.
- Narrative 2 and 3 placeholder rows remain present.

Result:

- PASS:
- FAIL:
- Notes:

---

### Test 3 — Set Narrative 2

Steps:

1. Press `C-c C-2`.
2. Enter:

```text
line two content can be entered independently
```

Expected result:

- Narrative 2 appears only on Narrative 2 rows.
- Narrative 1 does not change.

Result:

- PASS:
- FAIL:
- Notes:

---

### Test 4 — Set Narrative 3

Steps:

1. Press `C-c C-3`.
2. Enter:

```text
line three content can also be entered independently
```

Expected result:

- Narrative 3 appears only on Narrative 3 rows.
- Narrative 1 and 2 do not change.

Result:

- PASS:
- FAIL:
- Notes:

---

### Test 5 — Wrapping

Steps:

1. Set Narrative 1 to a long sentence.
2. Set Narrative 2 to a shorter sentence.
3. Set Narrative 3 to an even shorter sentence.

Expected result:

- Each narrative wraps independently.
- Display is woven row group by row group.

Result:

- PASS:
- FAIL:
- Notes:

---

## Summary

Overall result:

- PASS:
- FAIL:
- Continue to Version 0.2.0:
