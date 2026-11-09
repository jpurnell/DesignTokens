# Session summary 2026-11-09: validator, ledgers and themes, 0.5.0

Branch `feature/themes-validator-0.5.0` (from `main` at tag 0.4.0), untagged, unpushed.

- `ThemeValidator`: Swift port of the dataviz `validate_palette.js`, cross-checked against the script under Node
  (all shipped palettes, a deliberately bad one, ordinal ramps) and verified by mutation of a Machado coefficient.
- `Theme.conformance` and exact-measurement ledgers (`strict` / `ledger` / `legacy`); `deviations(of:)` fails on a
  new, changed or vanished finding. Swiss's ledger went from 3 rows to 31.
- Nine themes in `Theme.all`: Swiss, House, Princeton (on Swiss, light only), FT and Economist (authored dark
  variants), and the four legacy themes. Legacy Default is a labelled snapshot (macOS 27.2, Increase Contrast off).
- `entityOrder` app palettes: every pair needing a secondary encoding must be listed; listed pairs stay reported.
- Fields added so values fit: `fixedDark`, `extras`, `colourOverrides`, `rampOverrides`, `shadow`, `platformStyle`.
- Docs: proposal (corrections, gap table G1 to G18, divergences), `ThemeConformance.md`, `SwissConformanceLedger.md`,
  README, CHANGELOG, master plan.

Open: Linux unbuilt; nothing rendered; FT and Economist structure (G2, G4, G9) unconfirmed against any rendering;
Princeton is light only (owner may want authored dark); Default's increased-contrast values are partly absent.
Next: 0.6.0 emitters (JSON, CSS) and the BusinessMath-UI conversion.
