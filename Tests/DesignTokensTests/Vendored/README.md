# Vendored: `validate_palette.js`

A byte-for-byte copy of the dataviz skill's palette validator, kept so the cross-check
(`JavaScriptCrossCheckTests`) runs against one known script and not against whatever a machine happens to have.

| | |
|---|---|
| File | `validate_palette.js` (353 lines) |
| SHA-256 | `25df43beb77674dad34348b9fe338d5a47f568e08bcf51b38780e51386cf866e` (pinned by `VendoredScriptTests`) |
| Provenance | `dataviz/scripts/validate_palette.js` in the dataviz skill bundled with Claude Code 2.1.311, copied 2026-11-09 from the bundled-skills directory on the author's machine. Its Python twin (`validate_palette.py`) was not vendored. |
| Licence | The skill ships no separate licence file for the script. The script's own header says its colour-space code is adapted from Color.js under the MIT licence (Copyright (c) 2021 Lea Verou, Chris Lilley) and carries that notice (lines 89 to 110); that notice is kept intact in this copy. The licence of the script as a whole is not stated anywhere this repository could read, so **before this repository is published, confirm that redistributing the file is permitted**, or replace it with a pointer and a download step. |

## Rules

- Do not edit the file. A test fails if its hash changes.
- To update it deliberately: replace the file, update the hash here and in `VendoredScriptTests.pinnedSHA256`, re-run
  the whole suite with Node installed (the cross-check compares the Swift validator's numbers with this script's, and
  `VendoredScriptTests.thresholdsMatchTheScript` compares the constants), and say in the commit what changed upstream.
- Nothing in `Sources/` reads this file. It is test data (the target excludes the directory from its resources).
- The cross-check needs Node (`NODE`, `/opt/homebrew/bin/node`, `/usr/local/bin/node` or `/usr/bin/node`). Without it the
  cross-check tests are reported as skipped with the reason; the hash and threshold tests do not need Node.
