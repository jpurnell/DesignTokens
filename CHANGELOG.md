# Changelog

## [0.7.0] - 2026-11-10 (tag pending)

Branch `feature/terminal-slides-emitters` from 0.6.0. `DesignTokens.version` is 0.7.0, so every generated header and the Tumblr stamp (`swiss 0.7.0 t1 fnv1a64:106484b8f118e4c0`) say so. `tokens.css`, `tokens.json` and the per-theme CSS and JSON differ only in the header version.

### Added: Tumblr full theme (`TumblrThemeEmitter`, `themes/swiss.tumblr.html`)
The block alone is not a theme: Tumblr needs a whole document. `TumblrThemeEmitter.emit(_:parameters:)` writes the complete HTML (the
owner's working markup, with the generated block unchanged in its one `<style>` element). The wordmark, its link, a parent-site link, a
`rel="me"` link and the Google Tag Manager id are `TumblrThemeParameters`, validated, with placeholders by default (the wordmark is Tumblr's `{Title}`, no
analytics): none of the owner's values is in the package. `design-tokens tumblr --full [--wordmark ... --gtm ...]` writes it with the block.
`check-blog` still finds the stamp in it. Left out of the owner's markup: the ad-snippet comment, the commented-out `<h1>` and the unclosed
`{block:Following}` tail with its extra `</div>`. Not opened in Tumblr's editor or rendered. See the proposal's "Tumblr full theme".

### Added: `design-tokens emit --format`
`--format css|json|tumblr|ansi|slides` (repeatable or comma-separated) keeps only those kinds of file; an unknown name is refused before anything is written.

### Added: terminal (ANSI) and slides emitters
Proposal: `project/plans/proposals/2026-11-09_TerminalAndSlidesEmitters.md`. Pure functions from `Theme` to text, deterministic,
committed under `Generated/themes/`, golden-tested by the existing "every generated file equals a fresh emit, nothing else is in
`Generated`" test, and part of `Generator.files`, so `design-tokens emit` writes them. Every file carries the generated header
(theme id, `DesignTokens.version`, system snapshot, content hash). Additive: `tokens.*`, the CSS, JSON and Tumblr files are unchanged.
- **`ThemeSlot`**: the colour states a text emitter writes: `light`, `light-increased`, `dark`, `dark-increased` for a theme that
  declares both appearances, the light pair for light-only, the dark pair for fixed-dark (whose single stored slot it reads).
  A colour with alpha is composited over the slot's background.
- **`TerminalColour`**: nearest xterm 256-colour index (16 to 255: the 6x6x6 cube, then the 24 greys; never the user's own 0 to 15) and nearest of
  xterm's default sixteen, by squared RGB distance with ties to the lowest index. SGR codes 30-37 / 90-97 (40-47 / 100-107).
- **`ANSIEmitter`** -> `themes/<id>.ansi.txt`: a role table per slot with `role kind hex truecolor c256 c16 glyph ascii note`. Truecolor,
  256 and 16-colour are SGR parameter lists. Status is never colour alone: `positive` is `▲` (ASCII `+`), `negative` `▼` (`-`),
  `warning` `!`; an absent glyph, ASCII or note is `.`. There is no check or cross: the model has no `success` or `destructive` role. It is a role table, not a terminal theme: the terminal's own background is not set.
- **`SlidesEmitter`** -> `themes/<id>.slides.txt` (hex per slot, series, extras, then the fifteen type roles with font chain, size, weight,
  tracking, case, italic and line height), `themes/<id>.slides.colors.<appearance>.xml` (one per appearance, `light` and `dark`; a DrawingML `<a:clrScheme>`, the root of a PowerPoint
  Theme Colors file; no increased-contrast files, those slots are in the list and the ANSI table) and `themes/<id>.slides.fonts.xml` (an `<a:fontScheme>`, the root of a Theme Fonts file). Font chains drop the
  CSS-only names: SF Pro Text, SF Pro, Helvetica Neue, Helvetica, Arial for sans. Mapping documented in the type's DocC.
- **Generated files:** 40 added (per theme: ansi, slides list, slides fonts, and one colour scheme per appearance: 13 in all), plus `themes/swiss.tumblr.html`: `Generator.files` returns 62 files, was 21.
- Tests: 62 new (347 core, 42 SwiftUI). Expected values are hand-computed or enumerated (the xterm table built from its published
  construction; every one of its 240 entries maps to itself; a tie case; Swiss orange is 208 and SGR 33 by hand), not read back from the emitter.
- **Not built:** a `.thmx` / `.potx` package, a Keynote theme file, a slide-master colour map, an SVG emitter, ramps in the terminal table, a
  SVG emitter. Not verified: the XML and text have not been opened in Keynote or PowerPoint (checked for well-formedness and for the documented mapping only);
  the 256 and 16-colour approximations are not contrast-measured; Foundation-only and expected to build on Linux, untested (the XML tests use `FoundationXML` where it exists).

## [0.6.0] - 2026-11-09

### Princeton follows Swiss's ramps
Princeton's palette no longer defines sequential or diverging ramps, so it inherits Swiss's grey-to-orange ones (owner decision 2026-11-09); its blue-orange ramp is retired. Its ledger gains Swiss's inherited sequential light-end row (1.37 against 2.0).

### Reference script no longer vendored
Reverses the "vendored" half of the entry below: the repository is public and `validate_palette.js` has no licence of its own
(only an embedded Color.js MIT notice), so we cannot confirm we may redistribute it. Nothing was ever pushed with it (it was only on unpushed local branches).
- **Removed** `Tests/DesignTokensTests/Vendored/validate_palette.js`. `Vendored/README.md` is now a note: where the script comes from, the pin, `DATAVIZ_VALIDATOR`, why it is not vendored. (The directory stays, excluded from the test target, to hold that note.)
- **`ReferenceScript`** (test support) locates the script: `DATAVIZ_VALIDATOR` (authoritative when set), else `~/.claude/skills/dataviz/scripts/` and Claude Code's bundled-skills directory (bounded, sorted, first whose SHA-256 matches the pin). Absent or mismatching: never run.
- **The cross-check now runs only where the reference script is present and matches the pin.** Elsewhere `JavaScriptCrossCheckTests` and the thresholds-from-script tests are skipped with the reason (not found and where searched, or a hash mismatch with both hashes). The recorded-run test (`ValidationThresholdTests`, hard-coded numbers) still runs everywhere.
- **`ReferenceScriptTests`** (never skipped) asserts the locating and skip-reason logic: missing path reports absent, wrong hash reports mismatch, the variable is authoritative, the bundled search is sorted. `VendoredScriptTests` became `ReferenceScriptThresholdTests`; its hash-pin and "reads that file" tests were replaced by the above.

### Heatmaps and scatter grey to orange (owner decision 2026-11-09), unreleased
Same branch, `fix/princeton-follows-swiss`. This replaces the blue ramps the entry below says Swiss got a few hours earlier.
- **Swiss `palette.sequential`:** light #D6D8DB #F0B58B #FF8D28, dark #4E5053 #A6714A #FF9230 (neutral grey to the system orange; three steps so each OKLCH
  lightness gap is at least 0.06). **`palette.diverging`:** light #6A6D72 #A6A8AA #E8E8E8 #F7BD95 #FF8D28, dark #4E5053 #66686A #7E8082 #C78859 #FF9230
  (dark neutral at the negative pole, light neutral midpoint, orange at the positive pole). Dark variants exist for both.
- **Named alternates** in `palette.extraRamps`: `sequentialBlue` and `divergingBlueOrange` (the previous defaults, with dark versions).
  `ThemeValidator` validates an `extraRamps` key beginning `diverging` as a two-pole ramp. `Palette.sequential`, `Palette.diverging`, `tokens.css` and `tokens.json`
  are byte-identical.
- **Ledger:** Swiss gains one row, `rampLightEnd` light `sequential` 1.37 (2.0), failing: 29 findings, 15 failing (was 28 and 14). Princeton defines its own
  orange sequential and blue-orange diverging ramps and keeps them (its ledger is unchanged at 10); it inherits the two alternates, light only.
- **Scatter:** no field was needed. Points take `markFill` like bars (neutral, the emphasised point in the accent) and a third variable uses `sequential`.
- Regenerated: `themes/swiss.*`, `themes/princeton.*` (the inherited alternates) and nothing else. Tests: 285 core, 42 SwiftUI.

### Princeton follows Swiss fully; Swiss bars square; the halo rule (owner decisions 2026-11-09), unreleased
Branch `fix/princeton-follows-swiss` from 5ae1cbc.
- **Princeton:** the override that kept the system green and red is removed, so `Theme.princeton` inherits Swiss's text-safe `positive` and
  `negative` (light #268053 / #DB2C2C, Increase Contrast #0E6B3A / #B81D1D; no dark values, no system colour). It keeps only its own accent, series and
  ramps. Its ledger loses the four `positive` / `negative` text rows (14 to 10 findings, none failing); its accent and series rows (orange 2.9, sky 2.15,
  teal 2.09, periwinkle 2.27 on the background, sky 2.25, teal 2.18, periwinkle 2.37 on the surface, accent 2.9) are unchanged, and so are its colours.
  `Theme.systemPositive` and `Theme.systemNegative` are removed (unreleased API; nothing else used them). Regenerated: `themes/princeton.css` and
  `princeton.json`, and nothing else.
- **Swiss `marks.barCornerRadius`** was `Double(Radius.container)`, which is 0, so the value did not change: it is now the literal 0 with a comment, and a
  test pins it for Swiss and Princeton. The theme is the single source for square bars. Swiss's generated files are byte-identical.
- **Halo colour** (`DesignTokensSwiftUI`): `ChartStyle.valueHaloColor` is the theme's own background, which is right only where the chart paints that background.
  New `paintsOwnSurface` (true for a light-only or fixed-dark theme in a dark context), `valueHaloValue(over:)` and `valueHaloColor(over:)` (the surface the
  caller actually paints behind the text); the rule is documented on `valueHaloColor`. The white shadow on Princeton's standard SVG charts is
  BusinessMath-UI's: its standard SVG writes no background, and `StandardSVG.haloText` strokes `paperHex` (Princeton's light background) over whatever
  surface the page has. Not fixed here.
- Tests: 277 core and 42 SwiftUI (was 276 and 41).

### 0.6.0 grew: the chart alignment (owner decisions 2026-11-09), unreleased
0.6.0 is untagged, so this is added to it rather than renumbered; the section below it is no longer the whole of what 0.6.0 contains.
Written on branch `feature/chart-alignment-spec` from the 0.6.0 candidate (8e29e5c). Source:
`project/plans/proposals/2026-11-09_ChartAlignmentToApprovedDesign.md` ("Decisions 2026-11-09"). Marks are neutral by default; the accent is
reserved for emphasis.

**Added (every field defaults to today's behaviour, `decodeIfPresent`)**
- `MarkSpec.defaultFill` (`MarkFill`: `.series` | `.muted`), `defaultEmphasis` (`EmphasisDefault`: `.none` | `.latest`), `emphasisFill` (`ColorRole`).
- `TitleRule.gapAfter` (`Double?`, nil is `gaps.title`); `RuleSpec.baselineColour` (default `.rule`), `referenceColour` and
  `referenceLabelColour` (default `.secondaryInk`); `Gaps.referenceLabel` (3); `LayoutSpec.cardBorder` and `cardPadding` (0); `LabelSpec.valueHalo` (0);
  `NumberFormatSpec.maxDecimals` (`Int?`; with `decimals` nil it makes a minimal format: 41.2, 80, never 41.20).
- `Structure.withCardBorder(_:padding:)` and `Theme.withCardBorder(_:padding:)` (a variant with id `<id>+card`); `MarkSpec.defaultEmphasisIndex(count:isVertical:)`;
  `NumberFormatSpec.fractionDigits`.
- The validator checks `muted` for 3:1 mark contrast where `marks.defaultFill == .muted`.
- `DesignTokensSwiftUI` `ChartStyle`: `markFill(emphasised:emphasisNamed:series:)`, `markFillValue(...)`, `emphasisColour`, `emphasisValue`, `defaultMarkFill`,
  `defaultEmphasis`, `defaultEmphasisIndex(count:isVertical:)`, `neutralLadder(_:)`, `neutralLadderValue(_:)`, `titleRuleGap`, `TitleRule.gap`
  (`Rule.gap`), `baselineColor`, `referenceColor`, `referenceLabelColor`, `referenceLabelGap`, `valueHalo`, `hasValueHalo`, `valueHaloColor`,
  `cardBorderWeight`, `hasCardBorder`, `cardBorderColor`, `cardPadding`, `fractionDigits(_:)`.
- CSS variables for the new fields (`--rule-baseline-color`, `--rule-reference-color`, `--rule-reference-label-color`, `--rule-title-gap-after`
  when set, `--gap-reference-label`, `--card-border`, `--card-padding`, `--label-value-halo`, `--mark-default-fill`, `--mark-default-emphasis`, `--mark-emphasis-fill`).

**Changed: Swiss**
- Title rule above the title (gap 8, inferred and not confirmed by overlay); baseline 1.5 pt ink; bars 0.7 of the slot; margins 6/8/12/8; value halo 3;
  reference-label gap 5; the target line is a muted solid hairline with an ink label; `numbers.plain` minimal up to two decimals; neutral marks with the
  latest column emphasised. The card border is an option and is off (decision 8).
- `palette.muted` is the approved grey (#B9BBBD / #4E5053; Increase Contrast #8E9196 / #6F7176), no system colour.
- (Superseded the same day by grey to orange, see above.) Magnitude ramp: one-hue blue (light #6AB0FF #2E92F5 #0A74D6 #0757A6 #053C73; authored dark #064E8B #0167B8 #1382E1 #449FFA #7FBCFE) replaces the
  orange ramp. Diverging ramp: light unchanged, authored dark #0091FF #246BB1 #414344 #AB6224 #FF9230. Both pass the ramp checks in light and dark.
  `Palette.sequential`, `Palette.diverging` and `Generated/tokens.css` / `tokens.json` are byte-identical (hash pins pass).
- Ledger: four `muted` mark-contrast rows added (1.84 and 1.93 light, 2.34 and 2.20 dark) and the orange dark sequential row (1.99) removed: 25 findings
  become 28, 15 failing become 14.
- Princeton is composed on Swiss and **inherits the new structure** and the `muted` grey (its ledger gains the two light `muted` rows, 12 to 14); it keeps
  its own accent and orange ramps. (It first kept the system green and red; it now follows Swiss fully, see above.)

**Generated files (regenerated deliberately)**
- House, FT, Economist and the four legacy themes: `themes/<id>.json` gains the new defaulted keys and nothing else (a test pins that the JSON less those keys
  has the pre-change fingerprint); `themes/<id>.css` gains the new variables at their defaults; both fingerprints, and so the hash in each CSS header, change.
  Their behaviour is unchanged.
- Swiss and Princeton: values changed as above. `themes/swiss.tumblr.css`: the stamp only (`fnv1a64:6677d068491bb103` became `ef99641db9228157`); the Tumblr
  template is unchanged and does not use the chart structure, so a pasted block reports stale from `check-blog` until re-pasted.
- Tests: 244 core and 28 SwiftUI before; 276 core and 41 SwiftUI after. Red-first: `ChartAlignmentStructureTests`, `SwissPaletteAlignmentTests`,
  `ChartAlignmentHelpersTests`, `ChartStyleAlignmentTests`.

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


### Earlier 0.6.0 entries (emitters, SwiftUI target, review fixes)

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
- **Cross-check script** (the vendoring below was reversed the same day, see "Reference script no longer vendored"): `JavaScriptValidator.scriptPath()` searched a Claude session's temp directory. `validate_palette.js` is now
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

[Unreleased]: https://github.com/jpurnell/DesignTokens/compare/0.7.0...HEAD
[0.7.0]: https://github.com/jpurnell/DesignTokens/compare/0.6.0...0.7.0
[0.6.0]: https://github.com/jpurnell/DesignTokens/compare/0.5.0...0.6.0
[0.5.0]: https://github.com/jpurnell/DesignTokens/compare/0.4.0...0.5.0
[0.4.0]: https://github.com/jpurnell/DesignTokens/compare/0.3.0...0.4.0
[0.3.0]: https://github.com/jpurnell/DesignTokens/compare/0.2.0...0.3.0
[0.2.0]: https://github.com/jpurnell/DesignTokens/compare/0.1.0...0.2.0
[0.1.0]: https://github.com/jpurnell/DesignTokens/releases/tag/0.1.0
