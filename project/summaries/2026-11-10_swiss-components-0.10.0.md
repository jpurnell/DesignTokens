# Session summary: DesignTokens 0.10.0 (Swiss components, app-palette surfaces, gallery)

Branch `feature/swiss-components-0.10.0` (worktree `Tools/DesignTokens-0.10.0`), from 0.9.0 `7dc690a`. Not pushed, tagged or merged.

## Done
- Proposal first (`project/plans/proposals/2026-11-10_SwissComponents.md`), then red/green per family: `AppPalette.background`/`surface`; type
  roles, metrics, grid and rules; card, chip, banner, section, key/value, segmented, toggle, form, text field; `SwissTable`; the
  dashboard-shaped re-expression and the `swiss-gallery` executable; release commit (version, Generated/, docs).
- Table and form investigation by rendering a native `Table` and a custom `FormStyle` through `NSHostingView.cacheDisplay`: the evidence is in
  `SwissComponents.md`. Declined: custom `PickerStyle` (sealed), native `Table` header restyle (title is a string, chrome is AppKit's).
- Gallery looked at and fixed: banner text ignored the measured colour (SwiftUI's innermost foreground wins), so `UIInk` was added; chip
  text, card description, footer names and segmented text had the same cause. An early commit had `.build/` in it; amended before any other commit and
  `.gitignore` fixed.
- Tests: 397 core, 75 SwiftUI. Quality gate 0 errors, 0 warnings per commit, no suppressions.

## Not done / next
- The dashboard on 0.10.0 (read only): delete the files listed in `SwissComponents.md`.
- SwiftCLIKit / SwiftGUIKit adoption (not modified; the mapping is written down).
- Nothing was run in an iOS or visionOS simulator (both build); no Linux build (no toolchain).
- Increased-contrast rendering is covered by measured tests, not by gallery images (`colorSchemeContrast` is not settable in a window).
