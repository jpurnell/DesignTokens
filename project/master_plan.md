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
- Swift is the source, so the compiler checks every value, and Foundation-only means it builds on macOS, iOS,
  visionOS and Linux.
- The palette is validated for adjacency and colour-vision separation, not chosen by taste. It fails the dataviz lightness band for these slots (yellow in light; orange, green, yellow, cyan in dark) and 3:1 contrast for orange, green, yellow, cyan on light: Apple's system colours are kept by decision, the exact numbers are a ledger (`project/docs/technical/SwissConformanceLedger.md`), and those slots need direct labels.
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
Sources/DesignTokens/        library: typed tokens, palette, emitters
Sources/design-tokens/       executable: writes the generated files
Tests/DesignTokensTests/     value tests, palette validation, golden-file tests
```

### Key Types

| Type | Purpose |
|------|---------|
| `ColorRole` | The role list, each with light, dark and increased-contrast values |
| `Palette` | The eight series colours (validated for adjacency and colour-vision separation; see the ledger), plus sequential and diverging ramps |
| `TypeRole` | The type scale: UI register and display register |
| `Rule`, `Grid`, `Radius`, `Space` | Rule weights (1, 3, 8), 12 columns with a 16 pt gutter, radii, 4 pt base |
| `Theme`, `Structure`, `ThemePalette`, `Adaptive`, `ColorValue`, `AppPalette`, `ThemeCodec` (0.4.0) | A theme is structure + palette; `Theme.swiss` is built from the constants above; canonical JSON codec |
| `Emitter` | Turns the tokens into CSS, JSON or SVG |

### Data Flow

```
Tokens (Swift) -> Emitter -> tokens.css / tokens.json / svg theme  (committed, golden-tested)
Tokens (Swift) -> Apple resolver -> Color (system values, not hard-coded)
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

### What's Next
- [ ] Phase 1: tokens, palette, CSS and JSON emitters, golden tests, tag 0.1.0
- [ ] Phase 2: Ignite site adopts it
- [ ] Phase 3: EditorialTheme.swiss, SVGTheme and ChartThemeProviding read from it

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
- [ ] 0.5.0 validator and registry (house, FT and Economist with authored dark variants, Princeton, legacy themes with a snapshotted Default marked legacy)
- [ ] 0.6.0 emitters I, then `DesignTokensSwiftUI` (second target in this package); 0.7.0 to 0.9.0 per the proposal's release table

### Phase 2: the site
### Phase 3: the chart libraries
### Phase 4: SwiftGUIKit Swiss tier and terminal resolver (see SwiftCLIKit proposals)
### Phase 5: the drift checker

---

**Last Updated:** 2026-11-09 (0.4.0 on branch: theme model added, Phase 1b checklist added, "validated" wording corrected to adjacency and colour-vision separation with the failing slots listed)
