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
| `TumblrEmitter`, `BlogStamp`, `BlogChecker`, `BlogFetching`, `ChromeBlogFetcher`, `TumblrCommand` (unreleased) | The Tumblr paste-in block with its stamp; the staleness check of the live blog behind a fetcher protocol |

### Data Flow

```
Tokens (Swift) -> Emitter -> tokens.css / tokens.json  (committed, golden-tested, unchanged since 0.3.0)
Theme (Swift) -> ThemeCSSEmitter / ThemeJSONEmitter -> themes/<id>.css, themes/<id>.json  (0.6.0)
Theme (Swift) -> DesignTokensSwiftUI ChartStyle -> Color, Font, numbers  (0.6.0; system colours deferred to)
Theme (Swift) -> SVG / Tumblr / ANSI / slides emitters  (0.7.0, 0.8.0, not yet)
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
- [x] Review of 0.4.0 and 0.5.0 (independent, adversarial): findings fixed in 0.6.0, see CHANGELOG "Fixed"; the Node cross-check runs against a vendored, hash-pinned `validate_palette.js`

### What's Next
- [ ] Tag 0.6.0 after the owner reviews the review-fix branch (nothing is tagged or pushed by the fixes)
- [ ] BusinessMath-UI conversion on its own branch (proposal 6.1), then Visual checkpoint 1
- [ ] **Owner decision (open):** Swiss `positive` / `negative` are the system green and red. `positive` text is 2.13:1 on the background (ledgered), while BusinessMath-UI's Swiss uses a darker `#1F9D55` at 3.49:1. Not changed; decide before the BusinessMath-UI conversion
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
- [x] 0.4.0 model: `Theme`, `Adaptive`, `ColorValue`, `Theme.swiss`, canonical JSON codec, numeric `TypeStyle`, Swiss conformance ledger (branch `feature/theme-model-0.4.0`, untagged)
- [x] 0.5.0 validator and registry (branch `feature/themes-validator-0.5.0`, untagged): `ThemeValidator` cross-checked against `validate_palette.js`, `Theme.conformance` ledgers, House, FT and Economist with authored dark variants, Princeton on Swiss, the four legacy themes with a snapshotted Default marked legacy, `Theme.all`; Princeton is light only (the proposal's "dark values stay out until measured" kept)
- [ ] **Princeton dark variant (open, noted 2026-11-09).** `Theme.princeton` is light only: it shows on Swiss's light surfaces in a dark context. Dark reference values exist in BusinessMath-UI's source comments (#DF7105 and the rest) but have not been measured or authored. Author them (like FT and Economist), validate, add a ledger entry, and drop `appearances = .lightOnly`. Owner asked to keep moving, so this waits.
- [x] 0.6.0 review fixes (branch `fix/review-findings`, untagged): strict `Theme` decoding and symmetric encoding, `composed(with:)` always valid (a light-only palette gives a light-only result; Princeton is built this way), `SwissLedger` slots derived from the ledger, vendored hash-pinned validator script, thresholds pinned at their edges, hex parsing strict, `measure(hexes:)` throws, stored `Theme.swiss`/`all`. ~~"ledger fails on any change"~~ reworded to what is pinned: findings at the validator's rounding; the golden `Generated/themes/` files pin every value (five single-value mutations that were green on 0.5.0 now fail)
- [x] 0.6.0 DesignTokens half (branch `feature/emitters-swiftui-0.6.0`, untagged): per-theme scoped CSS and canonical JSON (`Generated/themes/`, 18 files), generator CLI, `DesignTokensSwiftUI` (`ChartStyle`, environment, fonts), additive fields BusinessMath-UI needs. `tokens.css` and `tokens.json` byte-identical.
- [x] Tumblr paste-in block emitter and `check-blog` (branch `feature/tumblr-emitter` from tag 0.5.0, merged into the 0.6.0 line on `merge/tumblr-into-0.6.0`, unreleased): shipped ahead of the proposal's 0.7.0 row, which listed them with the SVG emitter. Version and stamp now come from `DesignTokens.version` (one source). Still Swiss-only: `Generated/themes/swiss.tumblr.css`. Not shipped from that row: the computed-value drift check (it needs a Tumblr preview, never the live blog), SVG, the site re-pin. Nothing pasted or rendered yet; the live blog is unstamped
- [ ] **0.6.0 BusinessMath-UI half (open):** the conversion on its own branch, in the phases of proposal section 6.1, then Visual checkpoint 1. Not started; nothing in BusinessMath-UI was changed.
- [ ] 0.7.0 to 0.9.0 per the proposal's release table

### Phase 2: the site
### Phase 3: the chart libraries
### Phase 4: SwiftGUIKit Swiss tier and terminal resolver (see SwiftCLIKit proposals)
### Phase 5: the drift checker

---

**Last Updated:** 2026-11-09 (Tumblr emitter and `check-blog` merged into the 0.6.0 line on `merge/tumblr-into-0.6.0`: Key Types and Phase 1b reconciled, golden regenerated; earlier: review fixes on `fix/review-findings`: Current Status and What's Next reconciled (they still said "tag 0.1.0"), ledger wording corrected, the Swiss `positive`/`negative` owner decision recorded; earlier: 0.6.0 on branch: emitters and `DesignTokensSwiftUI` added, Phase 1b 0.6.0 item split into the done DesignTokens half and the open BusinessMath-UI half, module structure, Key Types and Data Flow reconciled; earlier: 0.5.0 on branch: validator, conformance ledgers and the nine themes added, Phase 1b 0.5.0 item moved to done, Key Types table extended; earlier: 0.4.0 on branch: theme model added, Phase 1b checklist added, "validated" wording corrected to adjacency and colour-vision separation with the failing slots listed)
