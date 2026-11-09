# Session summary 2026-11-09: Theme model 0.4.0

Branch `feature/theme-model-0.4.0` (from `design/theme-model-proposal`), untagged, unpushed.

- Implemented the 0.4.0 row of the proposal's release table: `ColorValue`, `Adaptive`, `ThemePalette`, `Structure`,
  `Theme`, `AppPalette`, `Theme.swiss` (built from the existing constants), canonical JSON codec, numeric `TypeStyle`.
- `Generated/tokens.css` and `tokens.json` are byte-identical to 0.3.0 (tested, plus FNV-1a fingerprints).
- Owner decisions recorded in the proposal ("Decisions 2026-11-09"); Swiss conformance ledger added with exact
  measurements (matched the proposal's JavaScript-validator numbers).
- Next: 0.5.0 validator and registry. Open: Linux build is unverified.
