# The reference script is not vendored

The Swift validator (`ThemeValidator`) is a port of the dataviz skill's `validate_palette.js`. Two kinds of test compare
it with that script: `JavaScriptCrossCheckTests` (runs the script under Node on the same palettes) and
`ReferenceScriptThresholdTests` (reads the method's constants out of the script's text). The script is **not in this
repository**, because it carries no licence of its own: its header only embeds the Color.js MIT notice for the colour-space
code it adapts, so the licence of the script as a whole, and our right to redistribute it, cannot be confirmed.

| | |
|---|---|
| File | `validate_palette.js` (353 lines) |
| SHA-256 pin | `25df43beb77674dad34348b9fe338d5a47f568e08bcf51b38780e51386cf866e` (`ReferenceScript.pinnedSHA256`) |
| Provenance | `dataviz/scripts/validate_palette.js` in the dataviz skill bundled with Claude Code 2.1.311 |

## Pointing the tests at it

- Set `DATAVIZ_VALIDATOR` to the script's absolute path. When it is set it is the only candidate: a missing file or a
  different hash skips the tests; it never falls back to another copy.
- Otherwise `ReferenceScript` looks, with no recursive search, at `~/.claude/skills/dataviz/scripts/validate_palette.js`
  and at `/tmp/claude-<uid>/bundled-skills/<version>/<hash>/dataviz/scripts/validate_palette.js` (the directory Claude Code
  unpacks its bundled skills into). Candidates are sorted by path and the first whose SHA-256 matches the pin is used.
- The cross-check also needs Node (`NODE`, `/opt/homebrew/bin/node`, `/usr/local/bin/node` or `/usr/bin/node`).

## When it is absent

The cross-check and threshold-from-script tests are **skipped, and the skip is reported with its reason** (script not
found and where it was searched, or a SHA-256 mismatch with both hashes). They are never a silent pass. What always runs:
the recorded-run test (`ValidationThresholdTests`, numbers recorded from the script) and `ReferenceScriptTests`, which
tests the locating and skip logic itself. So the live comparison with the script happens only where the script is present
and matches the pin.

## Updating the pin

If the upstream script changes: run the whole suite against the new file, update `ReferenceScript.pinnedSHA256` and the
hash above, and say in the commit what changed upstream. Do not add the script to this repository unless its licence is
confirmed to permit it.

This directory holds only this note (the test target excludes it from its resources).
