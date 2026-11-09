# Changelog

## [Unreleased]

## [0.6.0] - unreleased (branch `feature/emitters-swiftui-0.6.0`; not tagged)

Additive. `Generated/tokens.css` and `tokens.json` are byte-identical to 0.5.0 (SHA-256 `7f64d385...0342` and
`9c770feb...0056`, pinned by test). Source-compatible with 0.5.0. Theme JSON written before 0.6.0 still decodes:
the four fields added to `MarkSpec` and `LayoutSpec` take their current BusinessMath-UI values when absent.

### Added
- `ThemeCSSEmitter.emit(_:)`: one stylesheet per theme, every selector scoped to `[data-theme-name="<id>"]` (no
  `:root`), with the light block and structure (rules, layout, marks, type), `prefers-contrast: more`, dark
  (`prefers-color-scheme` unless pinned light, and the explicit `data-theme` / `data-bs-theme` dark selectors, on the
  element or any ancestor) and the two increased-contrast dark blocks, in cascade order. Dark blocks exist only for a
  theme that declares both appearances; a light-only theme says `color-scheme: light`, a fixed-dark one `dark`.
  Increased-contrast blocks carry only colours with a measured increased value. Header: id, version, snapshot, FNV-1a hash.
- `ThemeJSONEmitter.emit(_:)`: the canonical `ThemeCodec` bytes.
- `Generator` and the `design-tokens` CLI: `design-tokens [emit] [--all | --theme <id>] [dir]`, `design-tokens list`
  (the old `design-tokens Generated` still works). Arguments are checked before anything is written.
- `Generated/themes/<id>.css` and `<id>.json` for all nine themes (18 files), golden-tested, with a test that nothing
  else is in `Generated/`.
- `DesignTokensSwiftUI`, a second library target (guarded by `canImport(SwiftUI)`; the core stays Foundation-only):
  `ChartStyle` (colours, series, ramps, per-chart overrides, rules incl. the title rule, type roles, value-label and
  series-label flags, layout, marks, shadow, tag, number-format specs), `FontPlan` / `ChartText`,
  `EnvironmentValues.theme` (default `Theme.legacyDefault`: no default look changes before the visual checkpoint) and
  `.chartStyle`, `ChartStyleReader`, `View.chartTheme(_:)`, `View.chartText(_:in:)`, `Color(theme:role:appearance:)`.
- Model: `MarkSpec.areaOpacity` (0.22), `.fillOpacity` (0.35), `.detailLineWidth` (1.5); `LayoutSpec.annotationRadius`
  (8 for the legacy themes, 0 otherwise); `TypeRole` and `TypeRoles[role]`; `NumberKind` and `NumberFormats[kind]`;
  `ColorValue.interpolated(to:fraction:)`; `Ramp.sample(_:dark:)`; `DesignTokens.version`.
- Tests: `ThemeEmitterTests`, `ThemeAdditionsTests` (compile-red first), `ChartStyleColourTests`,
  `ChartStyleStructureTests` (macOS; `@MainActor` where they resolve colours).

### Changed
- Theme JSON now carries the four new fields, so every `Generated/themes/*.json` and each theme's fingerprint differs
  from what 0.5.0 would have produced. Nothing in 0.5.0 emitted theme JSON.

### Not included
- SVG, Tumblr, ANSI and slides emitters (0.7.0, 0.8.0). Value-label, series-labelling, axis and number-format settings
  are in the theme JSON but not in the CSS.
- Linux was not built (the SwiftUI target is empty there by construction). The SwiftUI target was built, not run, for
  iOS, iOS Simulator, visionOS, visionOS Simulator, tvOS and watchOS (`xcodebuild`); its tests ran on macOS only.
- Increase Contrast under system-colour deferral is untested: `EnvironmentValues.colorSchemeContrast` is read-only.
- Fixed point sizes: no Dynamic Type scaling in `ChartText` yet.

## [0.5.0] - unreleased (branch `feature/themes-validator-0.5.0`; not tagged)

Additive. `Generated/tokens.css` and `tokens.json` are byte-identical to 0.3.0 (asserted by test). Source-compatible
with 0.4.0 except that `Theme` JSON now carries `conformance` and `ThemePalette` JSON carries `extras`,
`colourOverrides` and `rampOverrides` (all decode to empty or `strict` when absent, so 0.4.0 JSON stays readable).

### Added
- `ThemeValidator`: `validate(_:)`, `validate(_:on:)` for an `AppPalette`, `requiresDirectLabels(_:on:)`,
  `deviations(of:)`, `measure(series:on:dark:pairs:)`, `measure(hexes:...)`, `measureRamp(hexes:...)`, `resolved(_:over:)`.
  `Finding`, `Severity`, `Check`, `ValidationAppearance`, `ValidationThresholds` (every threshold in one place),
  `SeriesMeasurement`, `RampMeasurement`, `PairSelection`, `CVDState`. Checks: OKLCH lightness band, chroma floor,
  colour-vision separation (Machado 2009, severity 1.0), normal-vision floor, mark contrast on the background and the
  card surface, text contrast, ramps (one-hue ordinal; each arm of a diverging ramp), series count, structure.
  Light, dark, and each increased-contrast appearance where the theme holds increased values.
- `Conformance` (`strict`, `ledger`, `legacy`) and `Theme.conformance`; `Finding` is the ledger entry.
- `SeriesOrder.entityOrder`: checked on every pair; a pair that needs a secondary encoding must be in `labelRequired`
  (an unlisted one is a failing `labelRequired` finding; a stale or unknown entry is reported); listed pairs are not
  suppressed.
- `Theme.house`, `.ft`, `.economist`, `.princeton` (`Theme.princetonPalette` composed on Swiss, light only),
  `.legacyDefault`, `.legacyDark`, `.legacyFinancial`, `.legacyAccessible`, `Theme.all` (stable order) and
  `Theme.named(_:)`.
- Fields added so the legacy and editorial values fit the model: `AppearanceSupport.fixedDark`, `ThemePalette.extras`,
  `.colourOverrides`, `.rampOverrides`, `ColourReference`, `LayoutSpec.shadow` (`ShadowSpec`), `TextSpec.platformStyle`
  (`PlatformTextStyle`), `SystemColorName.pink` / `.mint` / `.gray`.
- Tests: `ThemeValidatorTests`, `ConformanceTests`, `ThemeRegistryTests`, `JavaScriptCrossCheckTests`.
- `project/docs/technical/ThemeConformance.md`; `SwissConformanceLedger.md` extended with the rows first measured in 0.5.0.

### Changed
- `Theme.composed(with:)` returns a theme whose `conformance` is `strict`: the receiver's ledger describes its own colours.
- `Theme.swiss` carries its ledger (31 findings), including rows the 0.4.0 tests did not measure.

### Not included
- Emitters for themes (0.6.0). Nothing was rendered. Linux was not built.

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

[Unreleased]: https://github.com/jpurnell/DesignTokens/compare/0.6.0...HEAD
[0.6.0]: https://github.com/jpurnell/DesignTokens/compare/0.5.0...0.6.0
[0.5.0]: https://github.com/jpurnell/DesignTokens/compare/0.4.0...0.5.0
[0.4.0]: https://github.com/jpurnell/DesignTokens/compare/0.3.0...0.4.0
[0.3.0]: https://github.com/jpurnell/DesignTokens/compare/0.2.0...0.3.0
[0.2.0]: https://github.com/jpurnell/DesignTokens/compare/0.1.0...0.2.0
[0.1.0]: https://github.com/jpurnell/DesignTokens/releases/tag/0.1.0
