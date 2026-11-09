# Changelog

## [Unreleased]

## [0.4.0] - unreleased (branch `feature/theme-model-0.4.0`; not tagged)

Additive. `Generated/tokens.css` and `tokens.json` are byte-identical to 0.3.0 (asserted by test).

### Added
- `ColorValue` (RGB plus alpha, stored as `#RRGGBB` or `#RRGGBBAA`), `SystemColorName`, `Adaptive` (light,
  dark, increased-contrast light and dark, same fallback rule as `ColorToken`), `NamedAdaptive`, `Ramp`,
  `AppearanceSupport`.
- `ColorRole`, `ThemePalette`, `Structure` and its parts (`RuleSpec`, `TitleRule`, `LineSpec`, `TypeRoles`,
  `TextSpec`, `FontFamilyRef`, `LabelSpec`, `LayoutSpec`, `MarkSpec`, `NumberFormats`), `Theme`, `AppPalette`,
  `SeriesOrder`, `SeriesPair`, `Theme.composed(with:)`, `Theme.appearanceIssues`.
- `Theme.swiss`, built from `ColorToken`, `Palette`, `Rule`, `Grid`, `Radius` and `TypeStyle`.
- `ThemeCodec`: canonical JSON (sorted keys, fixed fields, `String`-keyed dictionaries only, trailing newline),
  `Fingerprint.fnv1a64`.
- `TypeStyle.points`, `.lineHeight`, `.trackingEm`, `.fluid` (`FluidSize`). The CSS strings are now written
  from the numbers.
- `SwissLedger` and tests that pin the exact Swiss measurements.

### Changed (wording only)
- "Validated" now reads "validated for adjacency and colour-vision separation; fails the dataviz lightness
  band for these slots": yellow in light (OKLCH L 0.865, band 0.43 to 0.77); orange 0.762, green 0.756, yellow
  0.885, cyan 0.808 in dark (band 0.48 to 0.67). Orange, green, yellow and cyan are also under 3:1 on the
  light surface (2.21, 2.13, 1.45, 2.07). Those slots need direct labels. Apple's system colours are kept.

## [0.3.0] - 2026-11-09

### Added
- `ColorToken.increasedContrastLight` / `.increasedContrastDark`, measured on macOS 27.2 from a real app
  with Increase Contrast on: accent #C55300 / #FFA056, success #008932 / #4AD968, destructive #E9152D /
  #FF6165. `ColorToken.value(in:increasedContrast:)` and `ColorToken.unmeasuredIncreasedContrast`.
- `Palette.seriesIncreasedContrast` and `.seriesIncreasedContrastDark`, the eight series measured the same
  way: light #C55300 #564ADE #008932 #B02FC2 #A16A00 #1E6EF4 #E9152D #007EAE; dark #FFA056 #A7AAFF #4AD968
  #EA8DFF #FEDF43 #5CB8FF #FF6165 #6DD9FF.
- CSS: `@media (prefers-contrast: more)` blocks for light, for dark nested with
  `prefers-color-scheme: dark`, and for the explicit dark selectors. JSON: `increasedContrastLight` and
  `increasedContrastDark` per colour where measured, and `palette.seriesIncreasedContrast[Dark]`.
- Tests: values equal the measurements; each increased-contrast series and status colour has at least the
  standard colour's contrast against the standard background; adjacent OKLab distance of at least 15.

### Not included
- `link`: measured (system link #0068DA light, #419CFF dark) but not adopted. This package's link has more
  contrast against the background (5.9 against 5.0 light, 7.7 against 6.7 dark), so the measured value
  would lower contrast. A test records this.
- `label`, `secondaryLabel`, `separator`: they carry alpha, which a hex readout loses.
- `background`, `secondaryBackground`, `onAccent`: this package's own values, not system colours (the system
  window background measured #FFFFFF / #202020, which is not this package's #FAFAFA / #101112).
- `warning`: no system colour.

## [0.2.0] - 2026-11-09

### Added
- `ColorToken.success.dark` (#30D158) and `.destructive.dark` (#FF4245), measured on macOS 27.2.
  `ColorToken.unmeasuredDark` is now empty.
- `Palette.seriesDark`: the eight system colours in the dark appearance, measured. Emitted as `--series-N`
  in the dark CSS block and as `palette.seriesDark` in the JSON.
- `Palette.sequentialDark`: the sequential ramp reversed (derived), emitted as `palette.sequentialDark`.

### Not included
- Increased-contrast values: they could not be measured from a command-line process (measured in 0.3.0
  from a real app).
- A dark diverging ramp: its tints would be invented.

## [0.1.0] - 2026-11-08

### Added
- `RGB`, `ColorToken`, `Palette`, `Rule`, `Grid`, `Radius`, `Snapshot`.
- `CSSEmitter` and `JSONEmitter`, and the `design-tokens` executable that writes `Generated/tokens.css`
  and `Generated/tokens.json`.
- Golden-file test: the committed generated files must equal a fresh emit.
- `ColorToken.onAccent`: ink in both appearances, for text and marks drawn on the accent (at least 4.5 to 1).
- `FontStack` (sans, mono, two serif options) and `TypeStyle` (label, caption, body, heading, title, display),
  emitted as `--font-*` and `--type-*` custom properties and in the JSON.
- CSS: the explicit dark selectors (`[data-theme="dark"]`, `[data-bs-theme="dark"]`) match any element, not only the root.
- CSS: every colour also emitted as an `-rgb` triple (Bootstrap builds link colours from them); the dark
  selectors honour Bootstrap's `data-bs-theme` as well as `data-theme`.
- Palette tests: fixed order (validated for adjacency and colour-vision separation; fails the lightness band for the slots listed under 0.4.0), adjacent OKLab distance of at least 15, contrast of label on background.

[Unreleased]: https://github.com/jpurnell/DesignTokens/compare/0.3.0...HEAD
[0.4.0]: https://github.com/jpurnell/DesignTokens/compare/0.3.0...0.4.0
[0.3.0]: https://github.com/jpurnell/DesignTokens/compare/0.2.0...0.3.0
[0.2.0]: https://github.com/jpurnell/DesignTokens/compare/0.1.0...0.2.0
[0.1.0]: https://github.com/jpurnell/DesignTokens/releases/tag/0.1.0
