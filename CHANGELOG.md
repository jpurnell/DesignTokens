# Changelog

## [Unreleased]

Written on branch `feature/tumblr-emitter` (from tag 0.5.0) and merged into the 0.6.0 line on `merge/tumblr-into-0.6.0`. Kept
under Unreleased, not under 0.6.0: the release it ships in is the owner's call. Additive; `Generated/tokens.css`, `tokens.json`
and the other `Generated/themes/` files are unchanged by the merge.

### Changed: Swiss `positive` and `negative` are text-safe (owner decision 2026-11-09)
- `Theme.swiss.palette.positive` and `.negative` (gain and loss, printed as text and used as marks) are no longer
  `ColorToken.success` and `.destructive`. They are deliberately **not system colours**: they name no `SystemColorName`, so
  `ChartStyle` never defers them to Apple's green and red. Light #268053 and #DB2C2C (4.68 and 4.56 on the background, 4.89
  and 4.76 on the card surface; were 2.13 and 3.42); dark #30D158 and #FF4245 (the system dark values, 9.35 and 5.51);
  Increase Contrast light #0E6B3A and #B81D1D (6.32 and 6.23; the 0.3.0 values #008932 and #E9152D measure 4.35 and 4.36, under
  4.5), dark #4AD968 and #FF6165. Colour-vision separation of the pair is 9.7 deutan and 9.7 protan in light (the same hue as
  BusinessMath-UI's #1F9D55 would have been 5.6 deutan, under the method's floor of 6). Each role is still nearest its own series
  colour (green, red) in normal vision.
- `ColorToken`, `Generated/tokens.css` and `Generated/tokens.json` are byte-identical (FNV-1a 64 `e369026e87dc1c4e` and
  `1212e00e2d6ae09c`, pinned by a test). The series, accent and every other Swiss role are unchanged.
- Swiss's ledger drops its six `positive` / `negative` rows (31 findings become 25; the 15 failing are unchanged), and
  `SwissConformanceLedger.md` and `ThemeConformance.md` say so. Nothing is suppressed: the rows went because the measurements pass.
- Princeton is composed on Swiss and **keeps the system green and red** (`Theme.systemPositive` / `systemNegative`, set in
  `Theme.princeton`), so its generated files and ledger do not change. Following Swiss instead is a two-line removal; say so if wanted.
- Regenerated deliberately: `Generated/themes/swiss.css` (the `--positive` and `--negative` values in light and in the
  `prefers-contrast: more` block), `swiss.json` (those values, and the shorter ledger) and `swiss.tumblr.css` (stamp only; the block
  uses no gain or loss colour): `swiss 0.6.0 t1 fnv1a64:e0b8ece8b01ecf01` became `swiss 0.6.0 t1 fnv1a64:6677d068491bb103`. No other
  generated file moved. A blog that pasted the old block reports stale from `check-blog` until the new one is pasted.
- Tests: `SwissTextSafeStatusTests` (14), one `ChartStyle` deferral test; two existing tests were corrected to say the new truth
  (`Adaptive` agrees with `ColorToken` for nine of eleven roles; Princeton equals Swiss composed, with the system pair).

### Changed by the merge into 0.6.0
- `TumblrEmitter.packageVersion` is no longer a literal (`"0.5.0"`): it reads `DesignTokens.version`, so the stamp has one
  source of truth. The stamp is therefore `swiss 0.6.0 t1 fnv1a64:...`.
- `Generated/themes/swiss.tumblr.css` regenerated deliberately: stamp `swiss 0.5.0 t1 fnv1a64:0b29fca8ff936a4b` became
  `swiss 0.6.0 t1 fnv1a64:e0b8ece8b01ecf01` (the version moved, and Swiss's canonical JSON, hence its fingerprint, gained the four
  0.6.0 fields). Only those two lines of the file changed; no colour value moved.
- `Generator.files()` now includes `themes/swiss.tumblr.css`, so `design-tokens emit` regenerates it and the generated-files test
  (which fails on any unexpected file in `Generated/`) knows it. The Tumblr block remains Swiss-only in the committed set;
  `design-tokens tumblr --theme <id>` can emit any registered theme's block on request (not committed, not golden-tested).
- Tests adapted: stamp-shaped fixtures say 0.6.0, and a test asserts the stamp version equals `DesignTokens.version`.

### Added
- `TumblrEmitter.emit(_:)`: the Tumblr paste-in block for a `Theme`, committed as `Generated/themes/swiss.tumblr.css`
  (golden-tested). CSS only, between sentinel comments: colour variables from each `Adaptive` for light,
  `prefers-contrast: more`, dark and dark with `prefers-contrast: more` (in cascade order; a light-only theme has no dark
  block), rule weights, gutter, columns, type roles and font stacks, then a fixed Tumblr template (`TumblrTemplate`)
  ported from the owner's draft that reads only those variables and has no colour literal. No Tumblr tags, no markup.
- `BlogStamp` (`swiss 0.5.0 t1 fnv1a64:...`: theme id, DesignTokens version, template revision, FNV-1a hash of the canonical
  theme JSON), written to the header comment and to `--theme-stamp`. `TumblrEmitter.packageVersion` and
  `templateRevision` feed it.
- `design-tokens tumblr [--theme ID] [--out DIR]` writes the block; `design-tokens check-blog [--theme ID] [--url URL]
  [--html-file PATH]` prints `blog is current`, `blog is stale: re-paste` (both stamps), `blog is unstamped`, a garbled-stamp
  message or `blog could not be checked`, and exits 0, 1, 2, 3 or 4 (usage errors 64).
- `BlogChecker` (pure comparison, reads only `<style>` elements, requires the property and the comment to agree),
  `BlogFetching` (protocol) and `ChromeBlogFetcher` (headless Chrome; needs a local Google Chrome; accepts Chrome's exit
  status 2 after a complete dump, which is what it returns on this machine).
- Tests: `TumblrEmitterTests`, `BlogCheckTests` (comparison covered for current, stale, unstamped and garbled stamps, plus the
  challenge page and fetch failures, against a fake fetcher; no network).

### Not verified
- Nothing has been rendered in Tumblr and nothing has been pasted; `check-blog` has never seen a stamped page except
  fixtures. Linux is untested. The block's look against the draft is reasoned from the CSS, not compared on screen.


## [0.6.0] - unreleased (not tagged; carries the review fixes below)

Mostly additive. `Generated/tokens.css` and `tokens.json` are byte-identical to 0.5.0 (SHA-256 `7f64d385...0342` and
`9c770feb...0056`, pinned by test). **Not strictly source-compatible with 0.5.0**, because of the review fixes: `ThemeValidator.measure(hexes:...)`
and `measureRamp(hexes:...)` now `throws`; `Theme.composed(with:)` can change `appearances` (see Changed);
`Theme`'s `Decodable` and `Encodable` refuse inputs 0.5.0 accepted; `Theme.swiss` and `Theme.all` are stored `static let`s (a
use site does not change). Theme JSON written by 0.5.0's `ThemeCodec` still decodes (the four fields added to `MarkSpec` and
`LayoutSpec` take their current BusinessMath-UI values when absent); JSON written by 0.4.0 does not (see Changed).

### Fixed (review of 0.4.0 and 0.5.0; each has a test that failed first)
- **Hex parsing:** `RGB(hex:)` and `ColorValue(hex:)` accepted a sign (`"#+12345"`, `"#-00000"`, `"#112233+F"`) because
  `UInt32(_, radix: 16)` does. Every character must now be an ASCII hex digit.
- **`Theme.composed(with:)` returned invalid themes** (`Theme.swiss.composed(with: .princetonPalette)` had nine appearance issues) and
  `ThemeCodec.encode` wrote what `decode` refused. Composition now always yields a valid theme: an app palette (accent or any
  series) without a dark value on a `both` receiver gives a `lightOnly` result with every dark value stripped; a `lightOnly` or
  `fixedDark` receiver drops dark values the palette brings. `Theme.princeton` is now built by exactly this path.
  `ThemeCodec.encode` (and any `JSONEncoder`) throws `ThemeError.invalid` or `EncodingError.invalidValue` for any theme `decode` would refuse.
- **Decoding was lenient.** `Theme`'s own `Decodable` now refuses (so a plain `JSONDecoder` is as strict as `ThemeCodec.decode`): an unknown
  key anywhere in the tree (a misspelt `conformence` was a silent default), a colour override, ramp override or shadow colour that names no
  role/extra/ramp, an opacity outside 0 to 1, a negative or NaN rule weight, a ramp whose dark and light steps differ in number, a
  `strict` theme carrying ledger entries, and dark values that contradict `appearances` (`ThemeError.invalid`). Defaults remain only for
  fields added after 0.5.0 (`annotationRadius`, `areaOpacity`, `fillOpacity`, `detailLineWidth`) and for the genuinely optional ones.
- **`SwissLedger.directLabelSlots`** said it held the slots that fail "in some appearance", but the ledger also has `darkIncreased` band
  rows for all eight series, and its test compared the list with itself. It is now derived from `swissConformance` and documented as the
  light and standard-dark list; `SwissLedger.slotsNeedingDirectLabels(in:)` answers for any appearance (all eight for `.darkIncreased`).
- **Cross-check script:** `JavaScriptValidator.scriptPath()` searched a Claude session's temp directory. `validate_palette.js` is now
  vendored under `Tests/DesignTokensTests/Vendored/` (README: provenance, licence note) with a SHA-256 pin, and the cross-check runs against it
  only. `VendoredScriptTests` pins the hash and reads the method's thresholds out of the script's text (no Node needed).
- **Weak tests:** thresholds are pinned at their edges (`ValidationThresholdTests`: both lightness bands, `rampMinStep`, and the
  Swift-only `achromaticChroma`, the deviation from the JavaScript documented); the `entityOrder` stale/unknown assertion had an operator
  precedence bug (`a && b || c`); the legacy Default's shadow was compared with its own source; the canonical-format test claimed stability
  under reordering and tested none (it now decodes reversed-key JSON and re-encodes it byte-identically); the legacy test claimed values
  "equal the BusinessMath-UI sources" and checked three series arrays (retitled; the rest is pinned by the `Generated/themes/` files).
- **`ThemeValidator.measure(hexes:...)` and `measureRamp(hexes:...)`** measured a bad hex as black. They throw `ValidationInputError.invalidHex`.
- **Registry:** `Theme.swiss`, `Theme.all` and `Theme.named(_:)` are built once instead of on every access.
- **Wording:** a ledger pins each finding's value at the validator's rounding; it does not pin colours that move no finding. The ledger
  claim "fails on any change" in 0.5.0's README and notes was overstated: on 0.5.0 five single-value mutations (FT dark ink, FT light muted,
  legacy Financial `info`, FT `marks.lineWidth`, House `surface`) left every test green. On 0.6.0 all five fail
  `ThemeEmitterTests.generatedFilesMatchCommitted`, because the committed `Generated/themes/` files pin every value; that is a golden-file
  guarantee (regenerating deliberately makes it pass), not a ledger one.
- **Docs:** the FT and Economist notes said `warning` is a series colour without saying it is so in light only (FT dark `warning` #FF9A52 vs
  the dark orange series #B65E02; Economist dark `warning` #F0C04A vs the dark yellow series #865D00).

### Changed
- **Breaking, decoding:** `conformance`, `palette.extras`, `colourOverrides` and `rampOverrides` are required in theme JSON again (they were
  added in 0.5.0 with a default so 0.4.0 JSON stayed readable). JSON written by 0.4.0's codec no longer decodes. Nothing emitted theme JSON before 0.6.0.
- `Theme.composed(with:)` may change `appearances` (to `lightOnly`) and strips dark values; see Fixed.
- `ThemeValidator.validate(_:on:)` for an `AppPalette` measures the composed theme in the appearances it now declares: a palette without
  dark values on a `both` theme is measured in light only instead of reporting missing-dark findings.

### Owner decision 2026-11-09 (raised by the 0.6.0 review, decided the same day; shipped in the next section)
- Swiss `positive` and `negative` were the system green and red, 2.13:1 and 3.42:1 as text on the background. The owner decided they must be the
  darker text-safe values. See "Changed: Swiss positive and negative are text-safe" under Unreleased.

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

## [0.5.0] - 2026-11-09

Mostly additive. `Generated/tokens.css` and `tokens.json` are byte-identical to 0.3.0 (asserted by test). **Not strictly source-compatible
with 0.4.0**: the new enum cases `AppearanceSupport.fixedDark` and `SystemColorName.pink` / `.mint` / `.gray` break an exhaustive `switch`
over those enums; `Theme.composed(with:)` now resets `conformance` to `strict`; and `Theme` JSON now carries `conformance` and
`ThemePalette` JSON carries `extras`, `colourOverrides` and `rampOverrides` (they decoded to empty or `strict` when absent in 0.5.0, which
0.6.0 no longer allows).

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

## [0.4.0] - 2026-11-09

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

[Unreleased]: https://github.com/jpurnell/DesignTokens/compare/0.5.0...HEAD
[0.6.0]: https://github.com/jpurnell/DesignTokens/compare/0.5.0...0.6.0
[0.5.0]: https://github.com/jpurnell/DesignTokens/compare/0.4.0...0.5.0
[0.4.0]: https://github.com/jpurnell/DesignTokens/compare/0.3.0...0.4.0
[0.3.0]: https://github.com/jpurnell/DesignTokens/compare/0.2.0...0.3.0
[0.2.0]: https://github.com/jpurnell/DesignTokens/compare/0.1.0...0.2.0
[0.1.0]: https://github.com/jpurnell/DesignTokens/releases/tag/0.1.0
