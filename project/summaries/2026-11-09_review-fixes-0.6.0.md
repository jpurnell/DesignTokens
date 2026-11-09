# Session summary 2026-11-09: fixes from the independent review of 0.4.0 and 0.5.0 (0.6.0)

Branch `fix/review-findings` (from `feature/emitters-swiftui-0.6.0`), untagged, unpushed. Nothing was merged, tagged or pushed; the
BusinessMath-UI and Tumblr worktrees were not touched. No theme colour value changed (the committed `Generated/` files are unchanged).

Fixed, each with a test that failed first (red logs kept in the scratch directory): F1 ledger wording and the five mutations, F2 derived
Swiss label slots, F3 `composed(with:)` valid and `encode` symmetric, F4 vendored hash-pinned validator script, F5/F9 weak tests, F6 strict
`Theme` decoding, F7 strict hex, F10 stored registry and throwing `measure(hexes:)`, F8 docs drift. Details: CHANGELOG 0.6.0 "Fixed".

Verified: `swift test` 179 core + 27 SwiftUI tests; gate 0/0; the five F1 mutations (FT dark ink, FT light muted, legacy Financial `info`,
FT `marks.lineWidth`, House `surface`) each fail `generatedFilesMatchCommitted`; band, `rampMinStep` and `achromaticChroma` mutations each fail
`ValidationThresholdTests`.

Open: the Swiss `positive`/`negative` owner decision (2.13:1 against BusinessMath-UI's 3.49:1), recorded in the proposal's "Open items"; the
vendored script's licence as a whole is unstated (README in `Tests/DesignTokensTests/Vendored/`), confirm before publishing; a test cannot
observe that `Theme.all` is stored rather than recomputed (it is covered by behaviour tests only); Linux still unbuilt.
