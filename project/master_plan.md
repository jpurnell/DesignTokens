# DesignTokens Master Plan

**Purpose:** Source of truth for project vision, architecture, and goals.

---

## Project Overview

### Mission
Hold the design system's values (colour roles, type scale, spacing, rule weights, grid, radius, the chart
palette) once, as typed Swift, and generate them for every surface that cannot import Swift. A test fails
when a generated file differs from the checked-in copy.

### Target Users
- The owner's apps and libraries: SwiftGUIKit, BusinessMath-UI, BusinessMathCharts, WineTaster, Spinner.
- The Ignite site, which imports the package at build time.
- Tools that cannot import Swift (slide and spreadsheet generators, the Tumblr paste block), via JSON and CSS.

### Key Differentiators
- Swift is the source, so the compiler checks every value, and Foundation-only (a guard against SwiftUI imports in the core, not a
  commitment to a Linux GUI) means it builds on macOS, iOS and visionOS, and is expected to build on Linux, untested.
- The palette is validated for adjacency and colour-vision separation, not chosen by taste. It fails the dataviz lightness band for these slots (yellow in light; orange, green, yellow, cyan in dark) and 3:1 contrast for orange, green, yellow, cyan on light: Apple's system colours are kept by decision, the exact numbers are a ledger (`project/docs/technical/SwissConformanceLedger.md`), and those four slots need direct labels (`SwissLedger.directLabelSlots`, derived from the ledger). With Increase Contrast on in dark all eight series are above the dark band, so there every slot needs one (`SwissLedger.slotsNeedingDirectLabels(in:)`).
- It holds data, not `Color` values: Apple resolvers map the data to the system's own colours.

---

## Architecture

### Technology Stack
- **Language:** Swift 6.2+, strict concurrency
- **Build System:** Swift Package Manager
- **Testing:** Swift Testing
- **Dependencies:** none (Foundation only)

### Module Structure

```
Sources/DesignTokens/        library: typed tokens, palette, themes, validator, emitters (Foundation only)
Sources/DesignTokensSwiftUI/ library (0.6.0): Theme -> ChartStyle, fonts, environment; empty where SwiftUI is absent
Sources/design-tokens/       executable: writes the generated files (emit, list)
Tests/DesignTokensTests/     value tests, palette validation, golden-file tests
Tests/DesignTokensSwiftUITests/ macOS: colour resolution (@MainActor), structure, fonts
```

### Key Types

| Type | Purpose |
|------|---------|
| `ColorRole` | The role list, each with light, dark and increased-contrast values |
| `Palette` | The eight series colours (validated for adjacency and colour-vision separation; see the ledger), plus sequential and diverging ramps |
| `TypeRole` | The type scale: UI register and display register |
| `Rule`, `Grid`, `Radius`, `Space` | Rule weights (1, 3, 8), 12 columns with a 16 pt gutter, radii, 4 pt base |
| `Theme`, `Structure`, `ThemePalette`, `Adaptive`, `ColorValue`, `AppPalette`, `ThemeCodec` (0.4.0) | A theme is structure + palette; `Theme.swiss` is built from the constants above; canonical JSON codec |
| `ThemeValidator`, `Finding`, `Conformance`, `ValidationThresholds`, `Theme.all` (0.5.0) | The dataviz method as Swift; a theme's measured findings against its ledger; the nine registered themes |
| `ThemeCSSEmitter`, `ThemeJSONEmitter`, `Generator` (0.6.0) | One scoped CSS file and one canonical JSON file per theme in `Generated/themes/`; the CLI behind `design-tokens` |
| `ChartStyle`, `ChartText`, `FontPlan`, `ChartStyleReader` (0.6.0, `DesignTokensSwiftUI`) | A theme resolved for an appearance and contrast into SwiftUI colours, fonts, weights and flags; `\.theme` / `\.chartStyle` environment |
| `TumblrThemeEmitter`, `TumblrThemeParameters`, `TumblrDocument` (0.7.0) | The complete Tumblr theme document around the block; per-blog values are validated parameters, none in the package |
| `ThemeSlot`, `TerminalColour`, `ANSIEmitter`, `SlidesEmitter` (0.7.0) | The terminal role table (truecolor, 256 and 16-colour fallbacks) and the slide colour and font list with PowerPoint colour and font scheme XML (one colour scheme per appearance) |
| `AppPaletteSource`, `AppPaletteConformance`, `LabelRequirement`, `ChartRuleViolation`, `AppPalette.validate(on:)` (0.8.0) | Adopting an app palette: a marker protocol for the declared one-file palette, validation on Swiss with the palette's own ledger, chart rules as code |
| `AppPalette.textRoles`, `TextSurfaces`, `AppTextRole`, `NoTextRoles`, `AppPaletteSource.TextRoles` / `text(_:)`, `RGB.contrastRatio(with:)` / `meetsAA(on:)` (0.9.0) | App text roles validated as text on the app's own surfaces; a typed role enum cross-checked by `validate()`; public WCAG contrast |
| `UIRole`, `UITextSpec`, `SwissMetrics`, `SwissGrid`, `SwissCard`, `OutlinedChip`, `SwissSection`, `KeyValueRow`, `SwissSegmentedControl`, `StatusBanner`, `SwissTable`, `SwissToggleStyle`, `SwissFormStyle`, `SwissTextField`, `AppPalette.background` / `surface` (0.10.0) | The Swiss building blocks in `DesignTokensSwiftUI`, token-driven, with a gallery executable; an app palette that declares its own window and surfaces |
| `SwissEqualGrid`, `SwissFlowLayout`, `SwissTableColumn(sortBy:)`, `SwissTableSorting`, `SwissTableTree`, `SwissTableCopy`, `SwissSegmentedPresentation`, `SwissCardChrome`, `ChipShape`, `Adaptive.dynamicColor`, `UIRole.section` / `.cardTitle`, `UITextSpec.pointSize` (0.11.0) | The dashboard's gaps on 0.10.0: type hierarchy, equal-height borderless cards, a selectable, copyable, tree-capable table that stacks on phones, square chips, caution and warning, dynamic colour, the segmented fallback, a wrap layout |
| `swiss-gallery`, `SwissGalleryScenes` | The gallery executable (macOS) and the scenes it draws, shared with the iOS Simulator render test; `DesignTokensSwiftUI` and its tests build on iOS, visionOS and macOS |
| `TumblrEmitter`, `BlogStamp`, `BlogChecker`, `BlogFetching`, `ChromeBlogFetcher`, `TumblrCommand` (0.6.0) | The Tumblr paste-in block with its stamp; the staleness check of the live blog behind a fetcher protocol |

### Data Flow

```
Tokens (Swift) -> Emitter -> tokens.css / tokens.json  (committed, golden-tested, unchanged since 0.3.0)
Theme (Swift) -> ThemeCSSEmitter / ThemeJSONEmitter -> themes/<id>.css, themes/<id>.json  (0.6.0)
Theme (Swift) -> DesignTokensSwiftUI ChartStyle -> Color, Font, numbers  (0.6.0; system colours deferred to)
Theme (Swift) -> Tumblr block (0.6.0)
Theme (Swift) -> ThemeSlot -> ANSIEmitter / SlidesEmitter -> themes/<id>.ansi.txt, .slides.txt, .slides.fonts.xml, .slides.colors.<appearance>.xml  (0.7.0)
Theme (Swift) -> TumblrThemeEmitter -> themes/<id>.tumblr.html  (0.7.0; the block inside a complete Tumblr document)
Theme (Swift) -> SVG emitter  (not yet)
```

---

## Core Architectural Decisions

1. Own repository, so chart libraries and the site do not depend on a terminal kit.
2. Swift is the source; generated files are committed with a header and a regeneration test.
3. Apple platforms keep deferring to the system; the package's values are a labelled snapshot for places the
   system cannot reach, with the OS release recorded.
4. Hyrule's game palette and any app's artwork are out of scope.

---

## Current Status

### What's Working
- [x] Design accepted (project/plans/proposals/2026-11-07_DesignSystemSingleSource.md)
- [x] Phase 1: tokens, palette, CSS and JSON emitters, golden tests (tags 0.1.0 to 0.3.0)
- [x] Phase 1b: theme model (0.4.0), validator and nine themes (0.5.0), both tagged 2026-11-09 on `main`; emitters and `DesignTokensSwiftUI` plus the review fixes in 0.6.0 (untagged)
- [x] Chart alignment (0.6.0; branch `feature/chart-alignment-spec`): Swiss expresses the approved "Swiss and Apple" chart (neutral marks, accent for emphasis, rule above the title, hairline target line, halo, blue sequential and dark diverging ramps, opt-in card border); `ChartStyle` exposes it; every new field defaults to the old behaviour. Proposal `project/plans/proposals/2026-11-09_ChartAlignmentToApprovedDesign.md` ("Decisions 2026-11-09")
- [x] Review of 0.4.0 and 0.5.0 (independent, adversarial): findings fixed in 0.6.0, see CHANGELOG "Fixed"; the Node cross-check runs against the real `validate_palette.js`, located by `DATAVIZ_VALIDATOR` or the skill directories and verified against a SHA-256 pin; the script is not vendored (licence unclear; it was briefly, on unpushed branches only), so the cross-check runs only where it is present and skips visibly elsewhere (`fix/no-vendored-script`)

### What's Next
- [x] 0.6.0 tagged
- [x] Tag 0.7.0 (shipped 2026-11-10); then paste `themes/swiss.tumblr.html` into the blog
- [ ] BusinessMath-UI conversion on its own branch (proposal 6.1), now including the chart alignment's renderer and view work (`Emphasis`, `ReferenceLine`, grouped-bar direct labels, heatmap values and key, the 8 pt rule gap overlay), then Visual checkpoint 1
- [x] **Owner decision 2026-11-09, done:** Swiss `positive` / `negative` are the darker text-safe pair (light #268053 / #DB2C2C, at least 4.5:1 as text on the background and card surface), deliberately not system colours; `success` / `destructive` and `tokens.css` / `tokens.json` are unchanged. Princeton keeps the system pair. Branch `fix/swiss-text-safe-gain-loss`
- [ ] Phase 2: Ignite site adopts it
- [ ] Phase 3: EditorialTheme.swiss, SVGTheme and ChartThemeProviding read from it
- [ ] Princeton dark variant (see Roadmap)

---

## Quality Standards

- All code follows `coding_rules.md`; TDD; DocC on every public API; gate 0 errors, 0 warnings before every commit.

---

## Roadmap

### Phase 1: the package
- [x] Colour roles with light, dark, increased contrast (0.3.0: increased contrast measured for accent, success, destructive and the eight series; link, label, secondaryLabel, separator, surfaces absent, see CHANGELOG)
- [x] Palette with adjacency and colour-vision checks run as tests (the lightness band and 3:1 contrast are NOT met by the system colours: ledgered in 0.4.0, `ThemeValidator` in 0.5.0)
- [x] Type, space, rules, grid, radius
- [x] CSS and JSON emitters, golden files

### Phase 1b: the theme model (proposal `project/plans/proposals/2026-11-09_ThemeModel.md`, approved 2026-11-09)
- [x] 0.4.0 model: `Theme`, `Adaptive`, `ColorValue`, `Theme.swiss`, canonical JSON codec, numeric `TypeStyle`, Swiss conformance ledger (tagged 0.4.0 on `main`, 2026-11-09)
- [x] 0.5.0 validator and registry (tagged 0.5.0 on `main`, 2026-11-09): `ThemeValidator` cross-checked against `validate_palette.js`, `Theme.conformance` ledgers, House, FT and Economist with authored dark variants, Princeton on Swiss, the four legacy themes with a snapshotted Default marked legacy, `Theme.all`; Princeton is light only (the proposal's "dark values stay out until measured" kept)
- [ ] **Princeton dark variant (open, noted 2026-11-09).** `Theme.princeton` is light only: it shows on Swiss's light surfaces in a dark context. Dark reference values exist in BusinessMath-UI's source comments (#DF7105 and the rest) but have not been measured or authored. Author them (like FT and Economist), validate, add a ledger entry, and drop `appearances = .lightOnly`. Owner asked to keep moving, so this waits.
- [x] 0.6.0 review fixes (shipped in 0.6.0): strict `Theme` decoding and symmetric encoding, `composed(with:)` always valid (a light-only palette gives a light-only result; Princeton is built this way), `SwissLedger` slots derived from the ledger, vendored hash-pinned validator script, thresholds pinned at their edges, hex parsing strict, `measure(hexes:)` throws, stored `Theme.swiss`/`all`. ~~"ledger fails on any change"~~ reworded to what is pinned: findings at the validator's rounding; the golden `Generated/themes/` files pin every value (five single-value mutations that were green on 0.5.0 now fail)
- [x] 0.6.0 DesignTokens half (tagged 0.6.0 on `main`, 2026-11-09): per-theme scoped CSS and canonical JSON (`Generated/themes/`, 18 files), generator CLI, `DesignTokensSwiftUI` (`ChartStyle`, environment, fonts), additive fields BusinessMath-UI needs. `tokens.css` and `tokens.json` byte-identical.
- [x] Tumblr paste-in block emitter and `check-blog` (branch `feature/tumblr-emitter` from tag 0.5.0, merged into the 0.6.0 line on `merge/tumblr-into-0.6.0`, shipped in 0.6.0): shipped ahead of the proposal's 0.7.0 row, which listed them with the SVG emitter. Version and stamp now come from `DesignTokens.version` (one source). Still Swiss-only: `Generated/themes/swiss.tumblr.css`. Not shipped from that row: the computed-value drift check (it needs a Tumblr preview, never the live blog), SVG, the site re-pin. Nothing pasted or rendered yet; the live blog is unstamped
- [x] Chart alignment, DesignTokens side (branch `feature/chart-alignment-spec`, shipped in 0.6.0): structure fields, Swiss values, neutral `muted` grey and its ledger rows, blue sequential and dark diverging ramps, `ChartStyle` accessors. The renderer and view half is BusinessMath-UI's and is not started.
- [ ] **0.6.0 BusinessMath-UI half (open):** the conversion on its own branch, in the phases of proposal section 6.1, then Visual checkpoint 1. Not started; nothing in BusinessMath-UI was changed.
- [x] 0.7.0 (tagged 0.7.0 on `main`, 2026-11-10): terminal (ANSI) and slides emitters, the Tumblr full theme `themes/swiss.tumblr.html`, `emit --format`. Terminal and slides (proposal `project/plans/proposals/2026-11-09_TerminalAndSlidesEmitters.md`): `ANSIEmitter`, `SlidesEmitter`, `ThemeSlot`, `TerminalColour`; one colour scheme per appearance, glyphs up/down triangle; 40 + 1 generated files, 62 new tests). Not opened in Keynote, PowerPoint or Tumblr; no `.thmx`/`.potx`, no Keynote theme, no SVG emitter. Name clash with SwiftCLIKit/SwiftGUIKit (`Theme`, `ColorRole`, `TypeRole`): recommended fix is to rename the SwiftCLIKit side, see the proposal; not applied
- [x] 0.8.0 candidate (shipped 2026-11-10 as 0.8.0): app-palette adoption API, conformance report, `AppPaletteSource` marker for the drift checker, docs page. Proposal `project/plans/proposals/2026-11-10_AppPaletteAdoption.md`. No app adopted yet (WineTaster, FleetWatch, KEXPPower, narbis, HockeySimApp are other sessions')
- [x] 0.9.0 candidate (tagged 0.9.0 on `main`, 2026-11-10): text roles, host surfaces, typed role lookup, public contrast, Swiss as the `\.theme` default, from the dashboard's adoption report. Proposal `project/plans/proposals/2026-11-10_TextRolesAndPaletteSurfaces.md`. Declined with reasons: a `neverPlotted` series flag, renaming `RGB`. The dashboard itself has not been moved to it.
- [x] 0.10.0 candidate (tagged 0.10.0 on `main`, 2026-11-10): Swiss SwiftUI components (type roles, card, chip, section, key/value, segmented, banner, table, form styles), `AppPalette.background`/`surface`, the `swiss-gallery` executable, from the dashboard's checklist of upstream gaps. Proposal `project/plans/proposals/2026-11-10_SwissComponents.md`. Declined: a custom `PickerStyle` and a native-`Table` header restyle (SwiftUI offers neither); SwissTier stays in SwiftCLIKit and SwiftGUIKit adopts later (not modified).
- [x] 0.11.0 candidate (tagged 0.11.0 on `main`, 2026-11-10): the seven gaps the dashboard hit when it ported onto 0.10.0 (all built; none declined): type hierarchy (`section`, `cardTitle`, measured ordering), borderless equal-height card and `SwissEqualGrid`, `SwissTable` (empty cells, selection, copy, tree rows, sort path, stacked narrow layout), `Adaptive.dynamicColor`, square chips and caution vs warning, segmented menu fallback, `SwissFlowLayout`. Proposal `project/plans/proposals/2026-11-10_UIGaps0110.md`. Where it differs from what was asked: no new core `TypeStyle` (sizes come from Dynamic Type; the web scale already has heading 28), and `warning` changed meaning to the stronger orange while the existing yellow became `caution`.
- [ ] SVG emitter, then the rest of the proposal's release table (renumbered: 0.9.0 above is not the one the old table meant)

### Phase 2: the site
### Phase 3: the chart libraries
### Phase 4: SwiftGUIKit Swiss tier and terminal resolver (see SwiftCLIKit proposals)
### Phase 5: the drift checker

---

**Last Updated:** 2026-11-10 (0.11.1: `check-blog` treats a version-only difference as current; the roadmap rows that still said "branch" or "untagged" for 0.4.0 to 0.11.0 now say tagged on `main`; before that, 0.11.0: the UI gaps reconciled into the type table, Roadmap, CHANGELOG, README and SwissComponents.md; version 0.11.0, Generated/ regenerated; earlier: 0.10.0 on its branch: Swiss components, app-palette surfaces and the gallery reconciled into the type table, Roadmap, CHANGELOG, README and docs; version 0.10.0, Generated/ regenerated; earlier: 0.9.0 on its branch: text roles, host surfaces, typed roles, public contrast, Swiss environment default reconciled into the type table, Roadmap, CHANGELOG and README; version 0.9.0, Generated/ regenerated; earlier: 0.8.0 released: app-palette adoption reconciled into the type table, Roadmap, CHANGELOG and README; version bumped to 0.8.0, Generated/ regenerated; Tumblr full theme, --format, name-clash recommendation added; earlier: terminal and slides emitters added on a branch from 0.6.0: Data Flow, type table, Current Status, CHANGELOG [Unreleased], README; the 0.6.0 reconciliation stands)
