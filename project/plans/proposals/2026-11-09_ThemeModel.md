# Design Proposal: a Theme model hosted in DesignTokens

**Date:** 2026-11-09
**Status:** Approved with decisions 2026-11-09 (see "Decisions 2026-11-09" below). Release 0.4.0 is tagged; release 0.5.0 (validator, conformance ledgers and the nine themes) is tagged (see "Corrections found while implementing 0.5.0"); release 0.6.0, DesignTokens half (per-theme CSS and JSON emitters and the `DesignTokensSwiftUI` target), is implemented on branch `feature/emitters-swiftui-0.6.0` (untagged, see "Corrections found while implementing 0.6.0"); the BusinessMath-UI half of 0.6.0 is not started; sections 3 to 18 are otherwise as proposed, with the corrections listed under "Corrections found while implementing 0.4.0".
**Update 2026-11-09 (Tumblr block):** the Tumblr block emitter and `check-blog` (sections 5.3 and the 0.7.0 row) are implemented on branch `feature/tumblr-emitter` (cut from tag 0.5.0) and merged into the 0.6.0 line on `merge/tumblr-into-0.6.0`, unreleased, ahead of the 0.7.0 they were scheduled for. Outcomes that differ from the sketch: the stamp has a fourth field, the template revision (`swiss 0.6.0 t1 fnv1a64:...` on the 0.6.0 line), as 5.3 said it should; `check-blog` has two more exit codes (3 garbled stamp, 4 page unreadable) and `--html-file`; headless Chrome **does** return the real blog (home page and `/page/2`, 2026-11-09) but exits with status 2 after a complete `--dump-dom`, and the live blog's DOM contains the Swiss draft's CSS comment and variables intact, with no stamp, so it reports unstamped. `check-blog` reads the stamp from the `<style>` text of the dumped DOM, not from `getComputedStyle`. Not done: the computed-value drift check (needs a Tumblr preview), the `tumblrBlockHasNoLiterals` test is scoped to colour literals (layout pixel constants with no token stay in the template), and the block's links are ink in light and accent in dark, taken from the draft rather than from the theme's `link` role. Nothing rendered in Tumblr, nothing pasted; Linux untested.
**Author:** Claude (session with Justin Purnell)
**Supersedes:** `Playgrounds/Math/BusinessMath-UI/project/plans/proposals/2026-11-09_StructuralThemeLayer.md`
(branch `design/structural-theme-proposal`, commit `1a6c914`). That proposal kept `EditorialTheme` in
BusinessMath-UI as the structure model and treated DesignTokens as a colour source. The owner's decision
reverses the hosting: the theme lives here, and BusinessMath-UI becomes a consumer. What survives from it is
the vocabulary analysis (its section 3), the Swiss-versus-legacy structure comparison, and the phased view-by-view
tests; what does not is the optional `structure` bridge, the "legacy themes keep `nil` structure" gate, and the
"FT and Economist stay local" lean.
**Related:** `2026-11-07_DesignSystemSingleSource.md` (accepted 2026-11-08), whose decisions 2 and 3 this
proposal carries out: Swift is the source, and only this package plus declared app-palette files may define colours.

## Owner decisions this proposal takes as binding

1. One place holds the visual theme, and it reaches the whole portfolio: music, infrastructure, health, sports
   prediction, other apps, the site, the Tumblr blog, SVG and web, terminal, slides. Hyrule is out of scope.
2. DesignTokens (Foundation-only, expected to build on Linux, untested) hosts the model. Foundation-only guards against SwiftUI imports in the core; it is not a commitment to a Linux GUI.
3. Do it cleanly. Source-breaking changes in BusinessMath-UI are fine, there are no compatibility shims, and the
   result is a long-term foundation. Several small DesignTokens releases; the model first.
4. Standard chart views are themed. FT and Economist become real themes that exist to teach the design language
   and to expose gaps in the vocabulary; every gap is recorded (section 3.4).
5. The heavy title rule is a theme field. `showValues: Bool` becomes `Bool? = nil` so a theme can turn labels on.
6. Changing the default theme or default structure for existing users waits until the owner has seen visual
   before-and-after contact sheets.
7. Apps keep their own palettes on top of shared structure (WineTaster's wine colours). A theme is structure plus
   palette, and app palettes are validated, not suppressed.
8. The Tumblr blog is in scope and held to the same rule as everything else. Its mechanism is a generated block
   that the owner pastes into the Tumblr theme; it is not an external stylesheet. A theme change reaches the
   blog by regenerate, then manual re-paste, and a staleness check says when that has not happened.

---

## Decisions 2026-11-09

Owner decisions on the open questions of section 17. They are binding and override any wording below that conflicts.

1. **Swiss keeps Apple's system colours; the palette is not re-stepped.** The lightness-band failure is a ledger
   entry with exact measured values (`project/docs/technical/SwissConformanceLedger.md`, pinned by
   `SwissConformanceLedgerTests`, which fails on any change): light, yellow #FFCC00 L 0.865 (band 0.43 to 0.77);
   dark, orange 0.762, green 0.756, yellow 0.885, cyan 0.808 (band 0.48 to 0.67); light mark contrast under 3:1 for
   orange 2.21, green 2.13, yellow 1.45, cyan 2.07. **Direct labels (or printed values) are required on orange,
   green, yellow and cyan** (`SwissLedger.directLabelSlots`). The README, CHANGELOG and test wording changes from
   "validated" to "validated for adjacency and colour-vision separation; fails the dataviz lightness band for these
   slots", with the slots listed.
2. **The SwiftUI adapter is a second target `DesignTokensSwiftUI` in this package**, in a later release (0.6.0). Not built in 0.4.0.
3. **The legacy Default theme is snapshotted with the measurer in 0.5.0 and marked legacy.**
4. **FT and Economist get authored dark variants; they are not light-only.** Dark variants are authored by us as an
   interpretation of those houses, not taken from them. Where we diverge from what the houses do is a finding to
   record (in the 0.5.0 ledger and the contact-sheet notes). Section 3.3, gap G1, section 3.5 and the 0.5.0 release
   row are amended accordingly; `appearances: .lightOnly` stays in the model for themes that genuinely have no dark.
5. **A conformance ledger of exact measurements that fails on any change is accepted** for themes that fail checks
   (legacy themes, and Swiss for the slots above), instead of suppressions or annotations.

## Corrections found while implementing 0.4.0

- `RuleSpec` gains `page` (the 8 pt page-header weight). Section 3.2 left it out while the Tumblr block and the
  page-level rules need all three of 1, 3 and 8.
- `LabelSpec` has no `title: Alignment` field: gap G11 defers alignment, so the field would be one nobody reads.
- `ValueLabels` is flattened to `off | aboveOrEnd | insideEnd`, not `.onData(...)`, so every enum is a plain string.
- `ColorValue.alpha` is quantised to a byte at creation so every colour round-trips exactly as `#RRGGBBAA`.
- `LayoutSpec` also carries `baseUnit`, `containerRadius`, `controlRadius` (from `Grid` and `Radius`); `shadow` is
  deferred to 0.5.0 with the legacy themes that use it.
- `Theme.conformance` is not in 0.4.0: the ledger arrives with the validator in 0.5.0 and will be added with a
  decode default, so 0.4.0 JSON stays readable. Until then the Swiss ledger is `SwissLedger` plus tests.
- (Superseded 2026-11-09: Swiss `positive` and `negative` are now the text-safe pair, see the open items.) Swiss `positive` and `negative` were `ColorToken.success` and `.destructive`; BusinessMath-UI's Swiss uses darker
  local greens and reds for text (#1F9D55, #D64545), which the package does not hold. Swiss `muted` is the
  secondary ink, since there is no `muted` token and none was invented (BusinessMath-UI uses a local #B4B7BC).
  Both are findings for the 0.5.0 validator and for BusinessMath-UI's conversion.
- Swiss chart-role sizes and weights are BusinessMath-UI's current Swiss values; chart `lineHeight` (1.3), bar width
  ratio (0.6, seen in the line chart's band marks) and the reference line dash ([3, 3]) are not in any source of
  record and were set to the nearest existing value; the 0.6.0 spike should confirm them.
- Ramps are exempt from "a `.both` theme requires dark on every role": `Palette` has no dark diverging ramp and
  none is invented. A light-only theme must have no dark ramps.

## Corrections found while implementing 0.5.0

- **Deferred 0.4.0 item done:** `Theme.conformance` exists (`strict`, `ledger`, `legacy`), with a decode default so 0.4.0 JSON
  stays readable. `Finding` is the ledger entry; the ledger records exact measurements and `ThemeValidator.deviations(of:)`
  fails on a new, changed or vanished finding. `shadow` (deferred from 0.4.0) is `LayoutSpec.shadow`.
- **The conformance kinds are three, not two:** `strict`, `ledger` (the owner keeps a theme despite its findings: Swiss, House,
  Princeton, FT, Economist) and `legacy` (the four BusinessMath-UI themes). Section 4.3 had `.strict` and `.legacy` only; FT and
  Economist keep their own light colours, which fail the band and chroma checks, so a strict FT or Economist did not exist.
- **The legacy themes are not expressible in the 12 roles alone.** The 15-colour `ChartThemeProviding` protocol has
  `primary`, `info`, `highlight`, `subtle`, `emphasis`, `shadow` and `neutral` with no role. Added: `ThemePalette.extras`
  (String-keyed), `colourOverrides` and `rampOverrides` (the per-chart `color(forKey:)` and `gradient(forKey:)` mappings: section
  3.6 had said to drop them, but Accessible's orange-for-red tornado and Default's 70% Monte Carlo are theme behaviour, so
  they are data now; the library's standard mapping and `ChartGradient.gainLoss` are not carried).
- **`AppearanceSupport.fixedDark` added.** Legacy Dark has one appearance, a dark one. Declaring it `lightOnly` would
  measure it against the light band, which is wrong (the proposal's own 4.3 row measured it on #1A1A1F against the dark
  band). Its values live in the `light` slot and the validator measures it with the dark band.
- **`TextSpec.platformStyle` added.** Legacy views use `.headline`, `.caption` and so on, not numbers.
- **`SystemColorName` gained `pink`, `mint`, `gray`** (the Default palette has ten colours; Swiss's eight were the only names).
- **Editorial themes lack three roles the model requires** (`onAccent`, `link`, `warning`) and have `neutral`, which the model
  has no role for. They are authored (`link` is the accent, `warning` the orange or yellow series, `onAccent` white or the dark
  background) and `neutral` is `extras["neutral"]`. Chart `lineHeight`, bar width, series labelling, and the six UI type roles are
  not in any editorial theme; they take Swiss's values (section 3.4's gaps were claims about the houses, not code).
- **Princeton is light only.** Section 3.3 said Princeton's dark reference values stay out until measured; composing Princeton's
  series on Swiss (`.both`) would then leave dark series missing, a `missingDark` error. `Theme.princeton` is therefore the
  composition with every dark value stripped and `appearances = .lightOnly`, so it shows on Swiss's light surfaces in a dark
  context. If the owner would rather have the reference values (#DF7105 and the rest) authored in, it is one edit and a ledger.
  Its id is `princeton`, not `swiss+princeton`.
  **Open item (owner, 2026-11-09): Princeton has no dark variant yet.** Tracked in the master plan, Phase 1b; the owner chose to keep moving and revisit.
- **`composed(with:)` resets `conformance` to `strict`**: the receiver's ledger is about the receiver's colours.
- **Validator extensions beyond the JavaScript** (none is cross-checked against it): contrast on the card `surface` as well as
  the background; text roles (`ink`, `secondaryInk`, `link` fail under 4.5; `positive`, `negative` warn under 4.5; `accent`,
  `warning` warn under 3); `onAccent` on the accent at 4.5; a diverging ramp is checked arm by arm with its neutral midpoint left out
  of the hue spread and the outer step as the end that must clear the surface; chroma under 0.02 is left out of a ramp's hue
  spread (the JavaScript includes it: a pale tint such as #EBF8FF reads 26 degrees there and 20 here); series beyond eight.
  The ramp checks and the sequential cross-check against `validateOrdinal` agree where no step is achromatic.
- **Swiss's ledger grew from 3 rows to 31** (15 failing): the 0.4.0 tests measured the series only. See `SwissConformanceLedger.md`.
  The increased-contrast dark values are further outside the dark band than the standard ones.
- **The Machado port was verified by mutation:** changing one deutan coefficient fails the recorded-run test and the Node
  cross-check.

## Open items for the owner (read this first)

- ~~**Swiss `positive` and `negative` (open owner decision, raised by the 0.6.0 review; NOT changed).**~~ **Decided 2026-11-09 by the owner, and done on `fix/swiss-text-safe-gain-loss`.** The text kept for the record: `Theme.swiss` took `positive` and `negative` from `ColorToken.success` and `.destructive`, the system green and red; as text on the Swiss background (#FAFAFA) `positive` was **2.13:1** and `negative` 3.42:1, and BusinessMath-UI's Swiss used a darker `#1F9D55` (3.35:1 on #FAFAFA, 3.49 on white) and `#D64545` (4.19:1). The owner's decision: gain and loss, used as text and as marks, are the darker text-safe values, not the system colours; `success` and `destructive` stay the system colours. Chosen and measured with the package's own maths: light #268053 and #DB2C2C (4.68 and 4.56 on the background, 4.89 and 4.76 on the card surface), dark the system dark values #30D158 and #FF4245 (9.35 and 5.51), Increase Contrast light #0E6B3A and #B81D1D, dark #4AD968 and #FF6165. BusinessMath-UI's own values were not enough: #1F9D55 is under 4.5 and, darkened without moving the hue, sat 5.6 apart from the red under deutan (floor 6); the green is therefore a little bluer (OKLCH-nearest series still green). They name no system colour, so nothing defers them to Apple's. Princeton, composed on Swiss, keeps the system pair. The "status is never colour alone" rule still stands for the series colours.
- **Princeton has no dark variant** (see the Phase 1b item in the master plan).
- **0.4.0 theme JSON no longer decodes** (since the review fixes); nothing emitted theme JSON before 0.6.0, but say so if something stored it.

## Corrections found while fixing the 0.4.0/0.5.0 review (0.6.0)

- **`composed(with:)` is total over valid receivers.** An app palette without dark values on a `both` theme makes the result `lightOnly` with every
  dark value stripped (this is how Princeton was already built, now by the method itself). The 0.5.0 note "Princeton is the composition with every
  dark value stripped" describes the same result by a different path.
- **Decoding is strict and encoding is symmetric** (unknown keys, dangling references, negative weights, ramp length, strict with entries, appearance issues).
  The 0.4.0 note "`Theme.conformance` ... decode default, so 0.4.0 JSON stays readable" is superseded: the 0.5.0 fields are required again.
- **A ledger is not a golden file.** It pins findings at the validator's rounding; the committed `Generated/themes/` files pin every value.
- **`SwissLedger.directLabelSlots` is the light and standard-dark list** (orange, green, yellow, cyan); with Increase Contrast on in dark all eight series
  need labels. Derived from the ledger.

## Corrections found while implementing 0.6.0 (DesignTokens half)

- **The emitters cover what a stylesheet can use.** Value-label and series-label flags, axis placement and number formats are in the
  theme JSON, not the CSS. Chart text roles are `--chart-<role>-*`; the six UI roles keep `tokens.css`'s `--type-<name>-*` names
  (`uiTitle` is `--type-title-*`), so loading both files does not collide. A display role at the package's display size is written as the
  fluid `clamp(...)` (the numbers cannot carry a fluid range). `--rule-title-color` and `--mark-tag-color` are `var()` references to the
  role, and a colour reference at an opacity is `color-mix(in srgb, var(--x) P%, transparent)`.
- **`themes/<id>.json` is the canonical codec output with no header** (JSON has no comments). The version and fingerprint are in the CSS header.
- **`design-tokens emit --all` is the default** and the old `design-tokens <dir>` form still works; `validate` is not built (0.7.0 or later).
- **Four fields were added so BusinessMath-UI's literals have a home** (all with decode defaults, so 0.5.0 JSON stays readable):
  `MarkSpec.areaOpacity` (0.22) / `.fillOpacity` (0.35) / `.detailLineWidth` (1.5), the SVG renderer's area, box and detail-stroke literals;
  `LayoutSpec.annotationRadius` (8 for the legacy views' annotation cards, whose `containerRadius` is 0).
  Also `TypeRole`, `NumberKind`, `ColorValue.interpolated`, `Ramp.sample` (the Editorial `sequentialColor(t)` and `divergingColor(t)` walk).
- **Not added, because they are not theme values:** default plot heights (200, 250, 300 pt; 40 pt per category row), marker radii (the SVG draws
  3, 3.5 and 4; `pointSize` is square points), the annotation card's material and reduce-transparency behaviour, the tag block's 1 pt corner
  and 8 pt gap, the waterfall connector's `[4, 2]` dash (the theme has one reference-line dash). Formatting stays in the renderer
  (`NumberFormatSpec` to `NumberFormat` is a field-for-field map).
- **Decisions BusinessMath-UI must make, not made here:** `ChartThemeProviding` has `primary`, `info`, `highlight`, `subtle`, `emphasis`,
  which exist as `extras` only in the legacy themes. In Swiss, House, Princeton, FT and Economist `ChartStyle.extra("primary")` is `nil`. Pick the
  mapping (`primary` to accent, `subtle` to rule, and so on) once, in BusinessMath-UI. `FontToken.tracking` has no stated unit there; the theme's is em.
- **The environment default is `Theme.legacyDefault`**, not Swiss (decision 6, visual checkpoint 1).
- **`EnvironmentValues.colorSchemeContrast` is read-only**, so a test cannot put an environment into Increase Contrast. Stored colours are fixed
  by the style's own flag and are tested in all four modes; system-colour deferral is tested in light and dark only (and mutation-checked).
- **System deferral applies only to a theme that declares both appearances.** Princeton (light only) composes on Swiss and keeps `system: .green`
  on `positive`; deferring there would draw a dark system green on its light background. A test pins it.
- **Dynamic Type is not applied:** `ChartText` uses fixed point sizes (a platform text style for the legacy themes).

### Vocabulary gaps (section 3.4) after 0.5.0: filled by the model, or deferred

| # | Status | Detail |
|---|---|---|
| G1 | Filled | `appearances` exists; FT and Economist are `.both` with authored dark. `.fixedDark` added for Legacy Dark (G12) |
| G2 | Filled in the model; unconfirmed against any rendering | `TitleRule.position .aboveTitle` and `MarkSpec.tagMark` are used by Economist (1 pt red rule, 28 by 6 pt red tag). No renderer draws them yet |
| G3 | Filled (0.4.0), now exercised | Alpha on ink, rule, shadow, highlight in the legacy themes; the validator composites before measuring |
| G4 | Filled in the model; unconfirmed | Axis on the trailing edge for FT and Economist; labels above their gridline for Economist |
| G5 | Filled | Economist's `Econ Sans Cnd` carries `.sans` as its fallback (the type enforces it). 0.6.0: the CSS emitter writes `"Econ Sans Cnd", <sans stack>`, and `FontPlan` falls back to the declared family when the face is not installed |
| G6 | Filled | Economist bar width 0.45 (authored); corner radius 0 everywhere |
| G7 | Filled | Legacy themes `.autoGradient`, the rest `.flat` |
| G8 | Filled for the theme default; deferred for the per-spec override | FT and Swiss direct, the rest legend. A view's override is view behaviour, 0.6.0 |
| G9 | Filled in the model; unconfirmed | FT `lineEnd .dot` |
| G10 | Unchanged | Licensed faces are named with a fallback; no font files |
| G11 | Deferred | No theme needs title alignment other than leading |
| G12 | New, filled | A single dark appearance (`.fixedDark`) |
| G13 | New, filled | Named colours beyond the twelve roles (`extras`) |
| G14 | New, filled | Per-chart colour and gradient overrides (`colourOverrides`, `rampOverrides`) |
| G15 | New, filled | Platform text styles (`TextSpec.platformStyle`) |
| G16 | New, filled | Shadow (`LayoutSpec.shadow`; the radius 4 and offset (0, 2) are the literal in three of the six views that draw one) |
| G17 | New, deferred | Editorial themes have no `onAccent`, `link`, `warning`: authored here. Whether those roles are right for them is the owner's call |
| G18 | New, deferred | Disabled, pressed, focus and elevated states (adversarial point 2): no theme has them |

### Where our FT and Economist diverge from the houses (findings; nothing here was compared with the houses' own charts)

- **FT:** there is no FT dark palette that was consulted; the dark variant is ours. The title face is the system serif (New York),
  as BusinessMath-UI uses today, not the FT's licensed faces. Series names (blue, claret, teal, orange, purple, crimson) are ours.
  Dark series are the light hues moved into the dark band by search (claret #990F3D becomes #B83955, orange #FF8833 becomes
  #B65E02, crimson #9E2F50 becomes #ED446D): that changes how much the dark orange reads as the FT orange. Direct series labels, an
  end-of-line dot and a trailing axis are claims about the FT from general knowledge. The light palette fails the method (purple
  L 0.407, teal chroma 0.086, orange 2.15:1) and is kept as BusinessMath-UI has it.
- **Economist:** no dark Economist exists to follow; ours uses blue-grey near-blacks. The red rule above the title, the red tag and
  slim bars are ours from general knowledge, not in BusinessMath-UI's `economist` (which has no title rule or tag). Yellow becomes a
  dark amber (#865D00) and red an orange-red (#E35C42) in the dark so each sits in the band and keeps adjacent separation. The light
  palette fails the method (yellow L 0.80, green and plum chroma, cyan and yellow under 3:1) and is kept.
- Both dark variants have no failing finding; they have warnings that two or three series sit just under 3:1 on the card surface.

---

## 1. Objective

Make "the theme" one typed Swift value, `Theme`, defined in DesignTokens. A theme has a structure half (rule
weights including the title rule, gridline and baseline weights, type roles, label placement, layout, marks,
number formats) and a palette half (colour roles and series, each with light, dark and increased-contrast
values). Every surface reads it by import or by generated file. Adding or changing a theme is one edit in this
package, and an automated check refuses a theme or app palette that fails the same validation the dataviz
method uses.

## 2. Motivation: what exists, measured today

### 2.1 What DesignTokens holds (0.3.0, read from `Sources/`)

| Piece | Today | Fits the theme model? |
|---|---|---|
| `ColorToken` (11 roles) | One fixed value set: light, optional dark, optional increased-contrast, in `RGB` (no alpha) | Yes, as the Swiss palette's source data. It is an enum of values, not a type a second theme can instantiate, so the model needs a value type, `Adaptive`, with the same four slots |
| `Palette` | Static: one eight-colour series, dark, two increased-contrast variants, one sequential and one diverging ramp, `princetonAccent` | Same: it is Swiss's series. Not instantiable for another theme |
| `Rule` | Three weights, `Int` points (1, 3, 8) | Partly. Themes need `Double` weights and more than three named roles (title rule, gridline, baseline, reference line) |
| `Grid`, `Radius` | Constants | Yes, as the default layout fields |
| `TypeStyle` (6 UI roles), `FontStack` | `size` is a CSS `String` (`"clamp(64px, 13vw, 168px)"`), no chart roles | Partly. Chart text needs numeric sizes and 9 roles; see 3.2 |
| `CSSEmitter`, `JSONEmitter`, golden test | One theme only, hard-wired to the static enums | The mechanism is right; the input has to become a `Theme` |
| `Colorimetry` (`Contrast`, `OKLab.distance`) | Internal. No CVD simulation, no lightness band, no chroma floor | The seed of the validator (section 4) |

### 2.2 What the consumers hold (read, not rendered)

- **BusinessMath-UI** reads DesignTokens in exactly two files, `Editorial/EditorialTheme.swift` and
  `Theme/Themes/SwissTheme.swift`, and only colours. `Package.resolved` pins **0.2.0** (the earlier proposal left
  this unchecked). Two theme models coexist: `ChartThemeProviding` (SwiftUI `Color`, 15 colour properties, a
  palette, 5 gradients, `color(forKey:)`, no structure) and `EditorialTheme` (`TokenColor` = one hex per token,
  no appearance variants; typography, layout, number formats, marks). FT, Economist and house exist only as
  local hex literals inside `EditorialTheme` with one hex per token, so there is no dark mode for them.
  `showValues` is `Bool = false` on `CategoricalChart` and `Bool = true` on `WaterfallChart`, so an unset value
  cannot be told from an explicit one, and the two views disagree on the default.
- **BusinessMathCharts** `SVGTheme` (`BusinessMathChartsSVG/SVGModel.swift`): seven colour strings plus
  `useCSSVariables`, presets `slate` and `cssVariables` (blue `#4aa3e0`), and `swiss` / `swissDark` that already
  read `ColorToken`. Its CSS-variable mode emits `var(--success, var(--good))`-style fallbacks, so it names the
  package's custom properties. No structure.
- **justinpurnell.com** serves `Assets/css/tokens.css` and a test, `tokensAreCurrent`, asserts it equals
  `CSSEmitter.emit()`; further tests forbid colour literals in `main.css` and in Swift. This is the enforcement
  pattern section 7 generalises.
- **SwiftGUIKit** (inside `Tools/SwiftCLIKit`) reads only `.accent`, in `TerminalTokenResolver`. The Swiss tier
  proposal (2026-11-08) plans rule weights, a grid and a display role; the theme model is what it should read.
- **The Tumblr blog** (blog.justinpurnell.com) has a hand-written theme, draft at `~/Desktop/tumblr-swiss.html`
  (501 lines, 28 KB): one `<style>` block with `:root` variables for light and dark (`--bg --fg --muted --hair
  --accent --link --face --mono`) typed as hex literals, a 12-column grid, rule weights 8, 3 and 1 px, a display
  register, and Tumblr-specific selectors (`div.npf-link-block`, `.tumblr_video_container`), plus Tumblr
  `{block:...}` markup. Nothing links it to DesignTokens.

### 2.3 Two findings that change the design

**Finding A: the shipped Swiss palette does not pass the dataviz validator.** The validator in the dataviz skill
(`scripts/validate_palette.js`) was run on every palette named here, today, against each theme's own surface
(output kept in the session scratchpad, not committed). Swiss, light, against #FAFAFA: lightness band FAIL
(yellow #FFCC00 is OKLCH L 0.865, band 0.43 to 0.77), chroma floor pass, CVD pass (worst adjacent ΔE 22.4),
normal-vision floor pass (37.8), contrast WARN (orange 2.21, green 2.13, yellow 1.45, cyan 2.07, all under 3:1).
Swiss, dark, against #101112: lightness band FAIL for four of eight (orange 0.762, green 0.756, yellow 0.885,
cyan 0.808; dark band 0.48 to 0.67), contrast pass. The package's own tests check only adjacent OKLab distance
>= 15 and dark contrast >= 3, and its README says the palette "is validated" and the order "was validated for
neighbour separation, lightness band and colour-blind separation". The order is validated for neighbours; the
lightness band is not met by Apple's system colours. The honest claim is "validated for adjacency and colour-vision separation; fails the dataviz lightness band for these slots" (listed). Decision 1 above settles it: the system colours stay and the finding is ledgered. This is a result of running the method, not an opinion.

**Finding B: a dictionary keyed by an enum does not encode deterministically.** In the scratch prototype
(section 10) a model with `[Role: Adaptive]` round-tripped equal but re-encoded to different bytes with
`.sortedKeys` (Swift encodes non-`String`-keyed dictionaries as an array in unspecified order). Everything the
design promises about golden files and the Tumblr stamp depends on byte-stable output. The model therefore uses
fixed-field structs, or `String`-keyed dictionaries, and a test asserts `encode(decode(encode(t))) == encode(t)`.
With `String` keys the same prototype re-encoded identically.

## 3. The Theme data model

### 3.1 Layering

```
                 owner edits ONE file per theme (Swift, in DesignTokens)
                                     |
                                     v
  +----------------------------------------------------------------------+
  |  Theme  =  Structure  +  Palette                 (Foundation only)   |
  |    Structure: rules, type roles, layout, marks, labels, number fmts  |
  |    Palette:   colour roles + series + ramps, each Adaptive           |
  |               (light | dark | increased-contrast light | dark)       |
  |  AppPalette  --composed(with:)-->  Theme  (accent/series replaced,   |
  |                                            structure + surfaces kept) |
  +-----------------------------+----------------------------------------+
                                |
        ThemeValidator (tests, and an API apps call on their own palettes)
                                |
      +-------------+-----------+-----------+------------+-------------+
      v             v           v           v            v             v
   JSON         CSS vars     SVG        ANSI/terminal  Slides      Tumblr block
   (themes/     (themes/     style      table +        palette +   (paste-in, stamped
   <id>.json)   <id>.css)    block      rule glyphs    fonts json  with version+hash)
      |             |           |           |             |             |
      |       justinpurnell   BusinessMath  SwiftGUIKit  Keynote /     blog.justin-
      |       .com (Ignite)   Charts        Terminal     PowerPoint    purnell.com
      |                       SVG exports   resolver     templates     (manual re-paste)
      v
  Swift consumers import the model directly (no generated file):
  DesignTokensSwiftUI adapter -> ChartStyle -> BusinessMath-UI (standard views,
  Editorial charts), WineTaster, KEXPPower, FleetWatch, narbis, HockeySimApp, ...
```

Swift consumers import the model. Only surfaces that cannot import Swift get a generated file, and every
generated file is committed with a header and golden-tested, as `tokens.css` and `tokens.json` are today.

### 3.2 Types (signatures only; the prototype in section 10 compiled a reduced form of these)

```swift
// Colour ---------------------------------------------------------------
public struct ColorValue: Codable, Sendable, Hashable { var rgb: RGB; var alpha: Double }   // alpha: see gap G3
public struct Adaptive: Codable, Sendable, Hashable {
    var light: ColorValue
    var dark: ColorValue?              // nil = theme is light-only for this role (see 3.5)
    var lightIncreased: ColorValue?    // nil = standard value carries through (today's ColorToken rule)
    var darkIncreased: ColorValue?
    var system: SystemColorName?       // Apple adapters defer to Color.orange etc. when set (HIG)
    func value(in: Appearance, increasedContrast: Bool) -> ColorValue
}
public struct ThemePalette: Codable, Sendable, Hashable {
    var ink, secondaryInk, background, surface, rule: Adaptive       // the surfaces and text
    var accent, onAccent, link: Adaptive
    var positive, negative, warning, muted: Adaptive                 // chart/status meanings
    var series: [NamedAdaptive]                                      // ordered, named ("orange", ...)
    var sequential: Ramp                                             // Ramp: light [ColorValue], dark [ColorValue]?
    var diverging: Ramp
    var extraRamps: [String: Ramp]                                   // legacy 3D gradients: volatility, sharpe
}
// Structure ---------------------------------------------------------
public struct RuleSpec: Codable, Sendable, Hashable {
    var title: TitleRule        // weight (pt, Double), position (.none/.aboveTitle/.belowTitle), colour role, inset
    var section: Double         // new-section rule
    var hairline: Double
    var gridline: Double        // today hard-coded 1 in SVGChartRenderer
    var baseline: Double
    var reference: LineSpec     // weight + dash
    var plotBorder: Double      // 0 = none
}
public struct TextSpec: Codable, Sendable, Hashable {
    var family: FontFamilyRef   // .sans | .mono | .serifNewYork | .serifGaramond | .named(String, fallback: FontFamilyRef)
    var size: Double; var weight: Int; var tracking: Double
    var italic: Bool; var uppercase: Bool; var lineHeight: Double
}
public struct TypeRoles: Codable, Sendable, Hashable {
    var title, subtitle, axisTitle, axisLabel, seriesLabel, annotation, source, note, tag: TextSpec   // chart roles (today's 9)
    var label, caption, body, heading, uiTitle, display: TextSpec                                    // TypeStyle's six, numeric
}
public struct LabelSpec: Codable, Sendable, Hashable {
    var values: ValueLabels     // .off | .onData(.aboveOrEnd) | .onData(.insideEnd)   (marks.valueLabels today, Bool)
    var series: SeriesLabeling  // .legend | .direct | .both
    var axisSide: Side          // .leading | .trailing          (gap G4)
    var axisLabelPlacement: AxisLabelPlacement  // .besideAxis | .aboveGridline   (gap G4)
    var sourceLine: Bool; var title: Alignment  // .leading (the only value used today)
}
public struct LayoutSpec: Codable, Sendable, Hashable { var margins: Insets; var gaps: Gaps; var gutter: Double; var columns: Int; var gridlines: GridlineStyle }
public struct MarkSpec: Codable, Sendable, Hashable {
    var lineWidth, pointSize, bandOpacity, selectedLineWidth: Double
    var barFill: BarFill        // .flat | .autoGradient            (gap G7: legacy views use gradients)
    var barWidthRatio: Double; var barCornerRadius: Double          // gaps G6
    var lineEnd: LineEnd        // .none | .dot                     (gap G9)
    var tagMark: TagMark?       // Economist's chart-top block      (gap G2)
}
public struct Structure: Codable, Sendable, Hashable { var rules: RuleSpec; var type: TypeRoles; var labels: LabelSpec; var layout: LayoutSpec; var marks: MarkSpec; var numbers: NumberFormats }
// The theme ----------------------------------------------------------
public struct Theme: Codable, Sendable, Hashable, Identifiable {
    var id: String; var name: String
    var structure: Structure; var palette: ThemePalette
    var appearances: AppearanceSupport      // .both | .lightOnly   (declared, validated; see 3.5)
    var conformance: Conformance            // .strict | .legacy(ledger)   (see 4.3)
    func composed(with: AppPalette) -> Theme
}
public struct AppPalette: Codable, Sendable, Hashable {
    var id: String; var accent: Adaptive?; var series: [NamedAdaptive]?
    var seriesOrder: SeriesOrder     // .validatedOrder | .entityOrder(labelRequired: [Pair])   (section 4.2)
}
```

What changes in the existing types:

- `ColorToken` and `Palette` **stay** and stay public through 0.x. `Theme.swiss` is built from them, so Swiss is
  still defined once and the existing `tokens.css` is byte-identical (asserted by the existing golden test). At
  1.0 they can become internal. `ColorToken.value(in:increasedContrast:)` is the same rule as `Adaptive.value`,
  and a test asserts the two agree for all eleven roles.
- `Rule` gains no cases; the theme's weights are `Double` and Swiss builds them from `Rule` (`title = Rule.section`
  = 3 pt, hairline = `Rule.hairline`). `Rule.page` (8 pt) stays the page-header weight, not a chart weight.
- `TypeStyle` keeps its CSS-string fields for the CSS emitter and gains numeric accessors, because a chart renderer
  cannot read `"clamp(64px, 13vw, 168px)"`. The display role gets a `fluid(min:vw:max:)` description so one source
  produces both.
- `RGB` gets no alpha. `ColorValue` carries it, which is what lets `label`, `secondaryLabel` and `separator`
  (documented as unmeasurable because they carry alpha) be stored as `#RRGGBBAA` in a theme, and what the
  DarkTheme borders (`white` at 0.15) need.
- `GridlineStyle`, `NumberFormat`, `FormatTokens`, `FontWeightToken` move here as data types (they are Codable
  and platform-free). Their formatting behaviour stays in the renderer: `NumberFormatter` output is locale- and
  platform-dependent, so DesignTokens holds the specification (style, decimals, abbreviation thresholds) and never
  the formatted string.

### 3.3 How each variant is expressed

| Theme | Palette half | Structure half | Appearances | Notes |
|---|---|---|---|---|
| **Swiss** | `ColorToken` + `Palette` (system colours, `system:` set so Apple adapters defer) | Rule: title 3 pt below title (`Rule.section`), gridline and baseline 1 pt; value labels above bars; SF; flat fills; direct series labels | both, plus increased contrast | The only theme with measured dark and increased-contrast values |
| **House** | Local hexes become the `Theme.house` palette (blue #2B6CB0 ...). The package's earlier list shows SVGTheme's `#4AA3E0` differs from it; both disappear | Neutral: no title rule, value labels off, hairline grid | light only until dark values are authored (House: owner may author dark later) | Replaces `EditorialTheme.house` and `SVGTheme.slate` |
| **Princeton** | An `AppPalette` (accent #E77500 = `Palette.princetonAccent`, its eight series, its ramps) composed onto Swiss | Swiss | both: dark reference values exist in the source comments (#DF7105 ...) but are not measured, so they stay out until measured (section 4.2) | Becomes the model's first composition example |
| **FT** | Paper #FFF1E5 background, claret/teal/blue series, salmon ramps | Serif title (named face, serif fallback), no title rule, horizontal faint grid, sans for data | both: authored dark variant (decision 4); the light paper #FFF1E5 is FT's own | Gaps G1, G2, G4, G5, G8, G9 |
| **Economist** | Blue/red series, #F3F2F0 surface | Condensed named face (`Econ Sans Cnd`, sans fallback), red tag block and title rule above the title, labels above gridlines, axis on the trailing side | both: authored dark variant (decision 4) | Gaps G2, G4, G6, G10 |
| **Legacy Default** | SwiftUI system colours (`.blue .green ...`, dynamic) | Platform-automatic axes, gradient bars, hover annotations | system dynamic | Partly inexpressible: section 3.6 |
| **Legacy Dark** | Hexes plus white/black at alpha | Same legacy structure | dark | Needs `ColorValue.alpha` |
| **Legacy Financial** | Hexes | Same legacy structure | light | Fully expressible once `extraRamps` exists |
| **Legacy Accessible** | Hexes (six-colour, "colour-blind safe" by its own claim) | Same legacy structure | light | See Finding in 4.3: the claim does not survive the validator |

### 3.4 What FT and Economist expose: the vocabulary gaps

The current model has 9 text roles, 10 layout numbers, 7 mark numbers and a flat `Bool`. Writing FT and Economist
as full themes (not just recolours) exposes these. FT and Economist details below come from general knowledge of
those houses' chart styles, not from fetching their charts; treat each as a hypothesis the first rendering must
confirm, and the owner may correct me.

| # | Gap | Exposed by | What the model gains | Decided |
|---|---|---|---|---|
| G1 | No appearance support. FT's identity is its paper; a dark FT is our interpretation | FT, Economist | `appearances` (`.both` or `.lightOnly`). **Decision 4: FT and Economist get authored dark variants.** They are authored by us as an interpretation of those houses; where we diverge is a finding to record. `.lightOnly` stays for themes with no dark | Yes (amended) |
| G2 | A mark in the chart's top-left corner (Economist's red tab) and a rule **above** the title; today's `ChartFrame` has neither | Economist | `TitleRule.position` (`aboveTitle`/`belowTitle`/`none`) and optional `MarkSpec.tagMark` | Yes |
| G3 | Alpha. Borders, shadows, highlights are colour-at-opacity in the legacy themes and in `ColorToken`'s own unmeasured roles | Legacy Dark, `ColorToken` | `ColorValue.alpha`; validator composites over the surface before measuring contrast | Yes |
| G4 | Axis side and label placement. Economist sets value labels above their gridline on one side; FT puts them at the trailing edge. Today they are renderer constants | FT, Economist | `LabelSpec.axisSide`, `axisLabelPlacement` | Yes |
| G5 | Named typefaces have no fallback. `FontToken.Family.named` falls back to system silently, so a missing `Econ Sans Cnd` changes the look unannounced | Economist, FT | `FontFamilyRef.named(name, fallback:)`; validator requires a fallback; CSS emitter writes a full stack | Yes |
| G6 | Bar width ratio and corner radius are not tokens | Economist (slim bars), Swiss (radius 0) | `MarkSpec.barWidthRatio`, `barCornerRadius` | Yes |
| G7 | Fill treatment: legacy views use `.gradient` bars; Swiss is flat | Swiss vs legacy | `MarkSpec.barFill` | Yes |
| G8 | Series naming: direct labels versus a legend is today a per-spec property | FT (direct labels) | `LabelSpec.series` as the theme's default; a spec may override | Yes |
| G9 | End-of-line marker (a dot at the last point) | FT | `MarkSpec.lineEnd` | Yes |
| G10 | Licensed faces. Real FT and Economist faces cannot be shipped; the theme names them and depends on a fallback | both | G5 covers it; the proposal does not add font files to the package | Decided |
| G11 | Title alignment other than leading | none found | not added | Deferred: no theme needs it; adding it now is a field nobody reads |

This is a list of what I expect to find. The visual checkpoint (section 6) is where gaps G2, G4 and G9 are
confirmed or struck, because they are claims about how two publishers draw charts.

### 3.5 Appearance rule

Every `Adaptive` resolves by one rule, the rule `ColorToken` already has: increased contrast uses its measured
value when present and otherwise the standard value; dark uses its dark value when present. A theme declares
`appearances` (FT and Economist declare `.both` with authored dark values, decision 4). If `.both`, a missing `dark` on a role is a validation error (not a silent light fallback, which is
what an unmeasured `ColorToken.dark` does today, guarded by a test). If `.lightOnly`, `dark` must be `nil` and
the theme renders on its own `background` in a dark context. No theme derives a dark value from a light one
(consistent with `sequentialDark`, which is called out as derived and not measured).

### 3.6 What in the legacy four cannot be expressed, and the decision

| Legacy feature | Expressible? | Decision |
|---|---|---|
| `DefaultTheme` colours are SwiftUI system colours (`.blue`, `.green`, `.red`, `.orange`, dynamic, system-version-dependent) | Not as constants: there is no hex to store | Snapshot them once with the same measurer used for the 0.2.0 and 0.3.0 values (macOS 27.2, light, dark, increased contrast) and set `Adaptive.system` so Apple adapters still call the system colour. The snapshot is labelled, like every other value. Open question 3 |
| `DefaultTheme.border`, `.shadow`, `.chartBackground` via `PlatformColors` | Not as constants | Same snapshot treatment, or drop the role: it is only used by the legacy views |
| Opacity-based colours (DarkTheme `border` white 0.15, `subtle` white 0.05, `highlight` yellow 0.25; Default `highlight` yellow 0.3) | Yes, with `ColorValue.alpha` | G3 |
| Five named 3D gradients (`correlation`, `volatility`, `sharpe`, `distribution`, `heatmap`) | `correlation`/`heatmap` map to `diverging`/`sequential`. `volatility` and `sharpe` are multi-hue rainbow ramps (blue, cyan, green, yellow, red) | `extraRamps["volatility"]`, `["sharpe"]`. They violate the method's rule (one hue sequential, never rainbow). They are carried, flagged `legacy`, and fail validation by design (section 4.3) |
| Palette length 10 (Default, Dark), 8, 6 | Yes | The validator reports series beyond 8 as a finding (the method forbids a ninth hue) |
| `color(forKey:)` / `gradient(forKey:)` per-chart overrides (`waterfallIncrease`, `tornadoLow`, ...) | These are role mappings, not colours | They become a fixed mapping table in the BusinessMath-UI adapter (`waterfallIncrease = positive`, ...), defined once there. Only legacy themes override them today. Overrides are dropped; no theme needs them (verify by grep before 0.6.0) |
| Automatic Swift Charts axes and gridlines (`AxisMarks(preset: .automatic)`) | Not as a `GridlineStyle` case without a lie | `GridlineStyle.platformAutomatic`, honest and named. Legacy themes use it; Swiss and the others do not |
| Hover annotations, selection behaviour, accessibility labels | Not theme data. They are view behaviour | Stay in the views. Themes style them (`annotation` role, `selectedLineWidth`), they do not specify them |
| `shadow` and elevation (Default, Dark, Financial, Accessible each set `shadow`) | Not in the vocabulary | `LayoutSpec.shadow: ShadowSpec?`, nil for Swiss (flat). Added because four themes use it, not speculatively |

## 4. Validation

### 4.1 The method (from the dataviz skill, run, not paraphrased)

Thresholds in `validate_palette.js`: OKLCH lightness band 0.43 to 0.77 (light), 0.48 to 0.67 (dark); chroma floor
0.10; CVD: ΔE (OKLab ×100) between adjacent series, minimum over protanopia and deuteranopia simulated with
Machado-Oliveira-Fernandes 2009 at severity 1.0, target >= 8, floor 6 (legal only with secondary encoding);
normal-vision floor >= 15 on the active pair list (a hard gate); contrast vs surface >= 3:1 for marks (below is a
WARN that obliges visible labels or a table view). Adjacent pairs for bars, lines and stacks; all pairs
(`--pairs all`) for scatter, heatmap and small multiples. Sequential and diverging ramps use the ordinal check
(one hue, monotone lightness, step gap >= 0.06, lightest step vs surface >= 2:1).

### 4.2 How the package tests it

DesignTokens ports the checks to Swift, in the package, so a test can call them and an app can too. The package
has `Contrast` and `OKLab.distance` already (internal); it lacks OKLCH conversion, CVD simulation (the three
Machado matrices), the band and the floor. New public API, tests in Swift Testing:

```swift
public enum ThemeValidator {
    public static func validate(_ theme: Theme) -> [Finding]            // every appearance the theme declares
    public static func validate(_ palette: AppPalette, on theme: Theme) -> [Finding]
    public struct Finding { severity: .fail/.warn; check: Check; appearance; subject: String; measured: Double; threshold: Double }
}
```

What it checks, for each of {light, dark, increased-contrast light, increased-contrast dark} that the theme
declares:

1. **Series (categorical)**: lightness band, chroma floor, adjacent CVD ΔE, adjacent normal-vision ΔE, contrast
   against `background` and against `surface`.
2. **Ramps**: ordinal check on `sequential` and `diverging` (the existing hand-checked claim in `EditorialTheme.swiss`
   docs, "passes the dataviz `validateOrdinal` check", becomes a test).
3. **Text roles**: `ink`, `secondaryInk`, `link`, `positive`, `negative` against `background` and `surface` at
   >= 4.5:1 (text), `accent` at >= 3:1 only for large type, rules and marks (the Swiss rule that orange is never
   small text, enforced as `accent` failing the 4.5:1 text check *by design* and the theme declaring it
   `accentUse: .marksAndLargeType`).
4. **Structure sanity**: a `.both` theme has every `dark`; every named font has a fallback; weights are >= 0;
   a title rule position is set when its weight is > 0.
5. **Round trip and determinism**: `encode(decode(encode(t))) == encode(t)` (Finding B).
6. **Cross-check against the shipped constants**: `Theme.swiss` equals `ColorToken` / `Palette` / `Rule`
   (`swissIsBuiltFromTokens`), the CSS emitted for Swiss equals today's `tokens.css`.

To keep the port honest, a **conformance test runs the JavaScript validator** on each theme's series and compares
its verdicts to the Swift port. It needs Node, so it runs on the owner's Mac under a tag that any future Linux CI would skip; the
Swift tests do not need Node. Cross-checking against a second implementation catches a wrong matrix more
reliably than a hand-picked expected value. (Silence is not a result, so the test
also asserts it found at least one finding on a deliberately bad palette.)

**App palettes.** An `AppPalette` is validated on a theme (its surfaces decide contrast). Two ordering modes:

- `.validatedOrder`: the adjacent-pair method above.
- `.entityOrder(labelRequired:)` for palettes where series stand for entities (WineTaster's wine types, hockey
  teams): the order is the entity's, so the check runs on **every pair** and every pair below the normal-vision or
  CVD floor must be listed in `labelRequired`. Listed pairs are not suppressed: `ThemeValidator.requiresDirectLabels`
  returns them, and the chart adapters turn on direct labels for any chart that plots both. An unlisted failing
  pair is a test failure. This implements the memo's rule ("Light White + Full White never unlabelled") as data.
  Palette files have a maximum of five entity colours per chart recorded as `maxPerChart`.

### 4.3 Measured results the tests would produce on day one

Run today with the real validator (surfaces: each theme's `background`). Verdicts, not interpretation:

| Theme (series count) | Band | Chroma | CVD adj ΔE | Normal adj ΔE | Contrast < 3:1 |
|---|---|---|---|---|---|
| Swiss light (8) | FAIL: #FFCC00 L .865 | pass | 22.4 | 37.8 | orange 2.21, green 2.13, yellow 1.45, cyan 2.07 |
| Swiss dark (8) | FAIL: 4 of 8 above .67 | pass | 24.1 | 36.1 | none |
| House (6) | pass | pass | 8.6 | 19.2 | #00A3C4 2.98 |
| Princeton (8) | pass | pass | 18.7 | 30.9 | orange 2.9, #03b9fc 2.15, #03c4bb 2.09, #98a1ff 2.27 |
| Economist (6) | FAIL: #EBB434 L .80 | FAIL: #379A8B .094, #9A607F .086 | 13.5 | 23.9 | #3EBCD2 2.25, #EBB434 1.89 |
| FT (6, on #FFF1E5) | FAIL: #593380 L .407 | FAIL: #0D7680 .086 | 10.5 | 16.2 | #FF8833 2.15 |
| Legacy Financial (8) | FAIL: #004C99 L .424 | FAIL: #996633, #4C4C80 | 13.7 | 20.2 | #CC9933 2.57 |
| Legacy Accessible (6) | FAIL: #000099 L .309 | FAIL: #666666 (C 0), #008080 | 9.6 | 19.1 | #B2B200 2.27 |
| Legacy Dark (10, on #1A1A1F) | FAIL: all 10 above .67 | pass | **FAIL 3.6** (#FFB24C vs #4CE666, deutan) | 22.7 | none |

Reading: FT and Economist as they exist today are not palettes the method would accept, even though the code
comments call them stress tests, and the "Accessible" legacy theme, which advertises colour-blind safety, passes
the CVD gate but fails the band and chroma checks. Legacy Default is not in the table: it has no hex values to
measure until it is snapshotted (3.6). Every palette except Legacy Dark passes the CVD and normal-vision floors;
the failures are band, chroma and contrast. Everything here is a measurement of a set of hexes against a method;
whether the method's bands are right for Apple's own colours is the owner's call (open question 1).

**Decision.** A theme declares `conformance`:

- `.strict`: every finding is a failing test. Required for any theme the owner marks "supported" (House, FT,
  Economist after re-stepping, app palettes).
- `.legacy(ledger:)`: findings are reported, not hidden: the theme carries the **exact measured values** and the
  test fails if any finding appears that is not in the ledger, if a ledgered finding changes, or if a ledgered
  finding disappears without the ledger being updated. It is a ratchet in data, in the theme file, visible in
  review. It is not an annotation that silences a checker, and the four legacy themes plus Swiss (if the owner
  keeps system colours) are the only users. A theme cannot move from `.strict` to `.legacy` without a diff in
  the theme file, which review sees.

This distinction is a judgement call. A stricter reading of "no suppression" would say a ledger is one; my
reasoning is that a ledger records a measurement and fails on change, where a suppression records nothing and
passes silently. If the owner disagrees, the alternative is that Swiss and the legacy four fail CI until they
are re-stepped, which blocks the whole package on a palette decision (section 8, adversarial review).

## 5. Authoring and emitters

### 5.1 Source of truth

Swift. A theme is one file in `Sources/DesignTokens/Themes/<Id>.swift` returning a `Theme`, registered in one
list, `Theme.all`. JSON is an output and an *input only for tools* (a theme JSON can be decoded and validated
with `design-tokens validate theme.json`), never the authoring format; this keeps decision 2 of the accepted
proposal.

### 5.2 Generated targets

| Target | Output (committed under `Generated/`) | Consumer | Golden test |
|---|---|---|---|
| JSON | `themes/<id>.json` (full model, canonical) and `tokens.json` (unchanged) | tools that cannot import Swift; slide and spreadsheet generators | generated == committed; round-trip determinism |
| CSS | `tokens.css` (the default theme, byte-identical to today until the default decision) and `themes/<id>.css`: custom properties for light, dark, increased contrast, scoped by `[data-theme-name="<id>"]` so several themes can coexist on a page | justinpurnell.com | generated == committed; site test `tokensAreCurrent` |
| SVG | `themes/<id>.svg.css`: a `<style>` block of the same custom properties with static fallbacks, and an `SVGStyle` Swift value for in-process SVG | BusinessMathCharts, BusinessMath-UI SVG exporters | generated == committed |
| ANSI | `themes/<id>.ansi.json`: role to 24-bit and nearest-256 value in each appearance, and a rule-weight to glyph table (1 pt light line, 3 pt heavy line, 8 pt double heavy, per the Swiss tier proposal's open question 1) | SwiftGUIKit terminal resolver | generated == committed; every role present; the terminal mapping tested with exact values |
| Slides | `themes/<id>.slides.json`: colour list, font names and fallbacks for the Keynote and PowerPoint templates. Template files themselves are not generated here | slide generators (not built yet) | generated == committed |
| **Tumblr block** | `themes/<id>.tumblr.css`: one self-contained `<style>` body, see 5.3 | blog.justinpurnell.com, by manual paste | generated == committed; block contains no `{block:}` or `{Tag}` text; stamp parses; no literal outside generated values |

Each file starts with a header: theme id and name, DesignTokens version, snapshot release, and a content hash.
The existing `design-tokens` executable gains `design-tokens emit --all` and `design-tokens validate`.

### 5.3 The Tumblr paste-in block

Decision (owner, binding): paste, not an external stylesheet. (Tumblr themes can link an external stylesheet, which the
owner has confirmed, so a hosted stylesheet on www.justinpurnell.com is a possible later option that would remove
the re-paste. It is not the design and nothing here depends on it. Its hosting URL, caching and CORS behaviour
from Tumblr's renderer, and any Tumblr-specific selectors a stylesheet must target, are unverified.)

**What the block is.** The content of the theme's `<style>` element, delimited by sentinel comments so the owner
replaces exactly one region of the theme HTML:

```css
/* >>> design-tokens block begin */
/* theme: swiss | DesignTokens 0.7.0 | snapshot macOS 27.2 | hash fnv1a64:9f3c... | generated, do not edit */
:root { --theme-stamp: "swiss 0.7.0 9f3c..."; color-scheme: light dark; --bg: ...; --fg: ...; }   /* light */
@media (prefers-color-scheme: dark) { :root { ... } }
@media (prefers-contrast: more) { :root { ... } }
/* structure: rules 8/3/1, grid 12 x 16, type roles, display register */
/* Tumblr-specific selectors (fixed template, variables substituted) */
/* >>> design-tokens block end */
```

**Starting reference:** `~/Desktop/tumblr-swiss.html` (draft, never pasted). Of its 501 lines, its single
`<style>` block splits into three parts:

1. **Generated (becomes the emitter's output):** the `:root` colour and type variables (currently typed hex
   literals and font stacks), the dark and contrast blocks, the 12-column grid, the rule weights (8, 3, 1),
   and the type roles' sizes, weights and tracking. These come from `Theme`.
2. **Tumblr-specific template (fixed text in the emitter, parameterised by variables):** selectors that target
   Tumblr's own markup and exist for no other surface: `div.npf-link-block` and its `.title`, `.bottom`,
   `.site-name`; `.tumblr_video_container iframe` with its `!important` aspect-ratio rules; the caption and
   `figure + p` treatment. The block's CSS uses `var(--...)` only, never a literal.
3. **Stays hand-owned, outside the block:** everything that is theme *markup*, not style: the `{Title}`,
   `{block:Posts}`, `{PostTitle}` and similar Tumblr tags; the Google Tag Manager snippet; `<link rel=...>`
   elements (RSS, `rel="me"`); the class names (`.header`, `.nav`, `.post`, `.newday`, `.datetime`, ...) the HTML
   assigns. The block's selectors depend on those class names, so they are a **contract** the owner must keep:
   a list in the proposal's appendix and in the block's header comment.

**The stamp.** A `--theme-stamp` custom property and the header comment both carry `theme id`, DesignTokens
version and the hash of the *canonical theme JSON* (not of the emitted CSS, so a template-only change is a
separate `template` revision field). Hash is FNV-1a 64-bit over the canonical bytes: Foundation-only and
expected to be byte-stable on Linux, untested (CryptoKit is not available there). It is a staleness check, not a security control; it is
not collision-resistant against an adversary, and does not need to be. If the owner later wants SHA-256 it can
be added in-package.

**Staleness check (sketch; nothing run against the blog).**

```
design-tokens check-blog --theme swiss --url https://blog.justinpurnell.com/
  1. load the page in headless Chrome (see "verified" below), read getComputedStyle(documentElement)
     .getPropertyValue('--theme-stamp')
  2. compute the stamp for the current theme (id, version, hash)
  3. equal            -> "blog is current (swiss 0.7.0 9f3c...)", exit 0
     different        -> "blog is stale: re-paste  (blog has swiss 0.6.0 11aa..., current is swiss 0.7.0 9f3c...)", exit 1
     stamp missing    -> "blog has no design-tokens stamp: paste the block", exit 2
```

Verified today (2026-11-09): a plain `curl` of `https://blog.justinpurnell.com/` returns **HTTP 403 and a
"Checking your browser" hashcash JavaScript challenge page**, not the blog. So the check cannot be a plain HTTP
fetch: it must run in a real browser that executes the challenge (headless Chrome; the claude-in-chrome tool
exists on the owner's Mac). Whether a headless run passes the challenge reliably, whether Tumblr serves the
theme's CSS comment intact, and whether the challenge is Tumblr's or the owner's own front door are all
unverified; the stamp lives in a custom property as well as a comment for that reason. Scheduling: a nightly or
pre-release run on the owner's Mac, because the site's CI should not depend on a bot-challenged page.

**Computed-value drift check for the blog (sketch).** Beyond the stamp, the same headless session emulates
`prefers-color-scheme: light`, then `dark`, then `prefers-contrast: more`, and compares `getComputedStyle` of a
small probe set to the theme: `body` background and colour, `h1` font size at a known width, `.post.newday`
border-top width and colour, `a` underline colour, `.header` border-top width (the heavy rule), plus that no
element's computed `color` is a value outside the theme's palette for that appearance. A mismatch prints
the property, expected and actual. This catches a hand-edited paste, which the stamp cannot (the owner could
edit the pasted block and leave the stamp). Verification step to schedule: run it once against a Tumblr
**preview** of the draft theme, never against the live blog, and not publish anything.

### 5.4 The "add or change a theme" workflow

Adding a new theme `nord` (or changing Swiss's title rule from 3 pt to 8 pt):

| Step | File | Who |
|---|---|---|
| 1. Define the theme | `Sources/DesignTokens/Themes/Nord.swift` (or edit `Swiss.swift`) | owner |
| 2. Register | `Sources/DesignTokens/Themes/ThemeRegistry.swift` (`Theme.all`) | owner |
| 3. Validate | `swift test` runs `ThemeValidatorTests` for the new theme automatically (it iterates `Theme.all`); fix or ledger findings | automatic |
| 4. Regenerate | `swift run design-tokens emit --all` writes `Generated/themes/nord.*` | owner |
| 5. Commit and tag | `Generated/**`, `CHANGELOG.md` (and its link references), `README.md` status lines, `project/master_plan.md`; tag | owner |

What happens next, by surface:

| Surface | Propagates how | Needs |
|---|---|---|
| Swift apps and libraries (BusinessMath-UI, WineTaster, ...) | **Release plus re-pin**: bump the DesignTokens version in `Package.swift`/`Package.resolved`, rebuild. A theme in the registry is visible to every consumer on that version, with no consumer edit | re-pin |
| justinpurnell.com | Regenerate `Assets/css/tokens.css` (or `themes/<id>.css`) from the pinned version; the site's `tokensAreCurrent` test fails until it is re-copied | re-pin, copy, deploy |
| BusinessMathCharts SVG | Re-pin | re-pin |
| SwiftGUIKit terminal | Re-pin; the resolver reads the theme | re-pin |
| Slides | Regenerate the slides json; the template files are updated by hand once, then read it | manual |
| **Blog** | **Regenerate, then manual re-paste**; the staleness check reports when it has not happened | manual re-paste |
| Anything that copied a hex | Nothing: that is the drift section 7 prevents |

Nothing propagates without a release and a re-pin, except Swift consumers that depend on a branch or path; the
fleet convention is tags over HTTPS, so that does not happen. A semantic-version rule keeps this safe:
`Theme`'s Codable output is additive-only within a minor; a removed or retyped field is a major.

## 6. Consumers and their adapters

### 6.1 BusinessMath-UI (standard views, Editorial charts, SVG exporters)

**Recommendation: replace both `ChartThemeProviding` and `EditorialTheme`; do not keep them as projections.**
A thin projection would keep two names for one thing, keep `TokenColor` (one hex, no appearances) alive and
invite the drift this whole proposal exists to end. Breaking is allowed and is the cheaper long-term path.

| Today | After |
|---|---|
| `ChartThemeProviding` (15 colour properties, palette, 5 gradients, `color(forKey:)`) | Deleted. Views read a `ChartStyle`, below |
| `EditorialTheme`, `ColorTokens`, `TypographyTokens`, `LayoutTokens`, `MarkTokens`, `FormatTokens`, `TokenColor` | Deleted. `Theme` (DesignTokens) replaces them; `TokenColor.color` is replaced by the adapter's `Color(theme:role:)` |
| `SwissTheme`, `DefaultTheme`, `DarkTheme`, `FinancialTheme`, `AccessibleTheme` | Deleted as types; `Theme.swiss`, `Theme.legacyDefault`, ... in DesignTokens |
| `@Environment(\.chartTheme)`, `.swissChartTheme()`, `.chartTheme(_)` | `@Environment(\.chartStyle)`; `.chartTheme(_ theme: Theme)` kept as the modifier name, taking a `Theme` |
| `showValues: Bool` (Categorical `false`, Waterfall `true`) | `showValues: Bool? = nil`; `nil` means the theme's `LabelSpec.values`; each view's historical default only applies to `.legacy`-structured themes, so no view disagrees with another again |
| `source:` absent from standard views | Optional `source: String? = nil` on every standard view (title block parity) |
| `*+SVG.swift` exporters call `DefaultTheme()` 9 times and hard-code `#000000` / `#666666` / `x: 20` | `theme: Theme` parameter, no default constant: the environment's theme or an explicit one |

`ChartStyle` is a small value in a SwiftUI adapter (see 6.6) that resolves a `Theme` for the current
`colorScheme` and `colorSchemeContrast`: `ink`, `series(i)`, `rule(.title)`, `font(.title)`, `labels`, ... Colours
use `Adaptive.system` first (so Swiss still defers to `Color.orange`), else a dynamic `NSColor`/`UIColor` provider,
which is the code `SwissTheme.adaptive` already has, moved once.

Phase view order (carried over from the earlier proposal, with the Swift Charts spike first): bar and grouped
bar, time series, heatmap, then waterfall, histogram, box plot, tornado, proportional, Monte Carlo. Rendering is
verified through pure resolve functions (`CategoricalChartStructure.resolve(style:showValues:)`) so tests do not
need screenshots, as `NiceTicks` is tested today.

Not verified: that Swift Charts can draw a title rule, flat fills and a custom gridline weight under
`AxisMarks(preset: .automatic)`; the 0.6.0 spike answers it on the bar chart before the other views are touched.

### 6.2 BusinessMathCharts `SVGTheme`

Replaced by a value derived from `Theme` (`SVGStyle`). Mapping of the seven slots: `accent` to `accent`, `good`
to `positive`, `over` to `negative`, `ink` to `ink`, `inkMute` to `secondaryInk`, `hairline` to `rule`, `surface`
to `surface`; the struct also gains the rule weights (so SVG output has a title rule and gridline weight) and the
series. `useCSSVariables` mode emits the package's custom property names only; the old `--good`, `--over`,
`--ink-mute` fallbacks in `cssExpression` go, which is a breaking change for anyone with a page defining the
old names (none known; grep before 0.7.0). `slate` and the `#4aa3e0` blue are deleted: there is no reason for a
second house blue.

### 6.3 justinpurnell.com (Ignite)

Already reads `tokens.css` and already enforces it by test. Adapter: none until the default decision. After 0.7.0
the site may link `themes/<id>.css` for a themed page; `tokens.css` keeps its custom property names (`--series-N`,
`--rule-*`, `--font-*`, `--type-*`): they are public API for `main.css`, so a rename is a site release. The site's
tests stay as they are and gain `themeCSSIsCurrent` for any `themes/*.css` it serves.

### 6.4 The blog (blog.justinpurnell.com)

The Tumblr block, section 5.3. Adapter: the owner pastes the block into the theme's `<style>` region. It is held
to the same rule as everything else: the block has no literal that is not generated, the stamp says whether it is
current, and the drift check compares computed values. The previous "best effort, unenforced" position is dropped.

### 6.5 SwiftGUIKit resolvers

`TerminalTokenResolver` reads `Theme` ANSI data (roles, rule glyphs, accent) instead of `Theme.dark` constants,
and the Apple resolver reads rule weights and the grid only; it keeps deferring to system colours (the HIG rule
the accepted proposal already states). The Swiss tier proposal's open question 4 (should status colours come from
the package) is answered by this: they do. Parked until its own proposal: terminal background detection.

### 6.6 SwiftUI adapter: where it lives

DesignTokens must stay Foundation-only. Resolving `Adaptive` into a dynamic `Color` is needed by BusinessMath-UI,
SwiftGUIKit and every app. Recommendation: a second library target `DesignTokensSwiftUI` in this package, guarded
with `#if canImport(SwiftUI)`, so the base product stays Foundation-only (expected to build on Linux, untested) and the dynamic-colour code exists once.
Alternative: each consumer writes it (the duplication that exists now). Open question 2.

### 6.7 A non-chart app adopts a theme with its own palette

Real projects found in the workspace by name and a quick grep (SwiftUI file counts and files containing a hex or
`Color(red:)` literal; I did not open them, and a project's category is from its name):

| Domain | Projects found | SwiftUI files / files with literal colours |
|---|---|---|
| Music streaming | `KEXPPower` (Spinner), `KEXPPower-tvos`, `KEXPPowerKit`, `StationKit`, `StationKitAdapterKEXP`, `SummerJams` (CLI), `Subsonic` | KEXPPower 40 / 5; KEXPPowerKit, StationKit, SummerJams 0 / 0 |
| Infrastructure management | `FleetWatch`, `quality-gate-dashboard`, `panLAN`, `SwiftPushInbox`, `roseclub-ops`, `ControlRoom` (not opened; name only) | FleetWatch 49 / 0; quality-gate-dashboard 23 / 1; panLAN 3 / 1; SwiftPushInbox 12 / 0; ControlRoom 41 / 1 |
| Health management | `narbis`, `BioFeedbackKit` (+ `-HealthKit`, `-HRBLE`, `-Polar`), `HRVKit`, `PelotonReader` | narbis 103 / 7; PelotonReader 2 / 0; the Kits 0 / 0 |
| Sports prediction | `HockeySim`, `HockeySimApp`, `HockeySimMCP` | HockeySimApp 6 / 0; the others 0 / 0 |
| Other apps | `WineTaster 4` (wine colours), `iconquer` (a game; counted as an app, not Hyrule), `Shelfmark`, `SwiftMate` | WineTaster 4 83 / 2 |

A sports-prediction app is the best second example, because its palette is entity-ordered (teams), like WineTaster's.
The adoption pattern, for `WineTaster 4`:

```swift
// WineTaster/Sources/WinePalette.swift  — the declared palette file (the only place colours may be defined)
import DesignTokens

public enum WinePalette {
    public static let palette = AppPalette(
        id: "winetaster",
        accent: Adaptive(light: "#7F0017", dark: "#E0788A", system: nil),          // dark value: measured or authored, validated
        series: [named("red", "#7F0017"), named("rosé", "#E58AA0"), named("light white", "#E9D98B"),
                 named("full white", "#C8A93A"), named("sparkling", "#9CC3D5"), named("orange", "#D9772B")],
        seriesOrder: .entityOrder(labelRequired: [Pair("light white", "full white")]))   // listed, not suppressed
    public static let theme = Theme.swiss.composed(with: palette)
}
// Any view: WineTaster's own structure comes from Swiss, its colours from WinePalette
ContentView().environment(\.theme, WinePalette.theme)        // DesignTokensSwiftUI
// WineTasterTests
@Test func winePaletteValidates() { #expect(ThemeValidator.validate(WinePalette.palette, on: .swiss).filter(\.isFailure).isEmpty) }
```

The hex values in that sketch are illustrative: the real ones are WineTaster's, and the validator would decide
whether they pass; I have not measured them (the one pair I ran, #7F0017 against #B8860B, fails the lightness band
only: #7F0017 is L 0.377). A hockey app does the same with team colours, `entityOrder`, and `labelRequired` for
teams whose colours collide under CVD. An infrastructure app such as FleetWatch uses a theme with **no palette
override** and reads `positive`, `negative`, `warning` and the status-glyph rule (the Swiss "status never colour
alone" rule): `Theme.swiss` through `DesignTokensSwiftUI`, no hex in the app. A music app (KEXPPower) is the same.

## 7. Enforcement and drift (sketch only)

Today's enforcement is one site's tests (`mainCSSHasNoLiterals`, `swiftSourcesHaveNoLiterals`). Generalise it as
a quality-gate checker, `design-token-drift`, opt-in per project (as the accepted proposal's decision 5 says),
configured in `.quality-gate.yml`:

```yaml
designTokens:
  paletteFiles: [Sources/WineTaster/WinePalette.swift]   # declared: may define colours; must contain an AppPalette that the test validates
  tokenSources: [DesignTokens]                           # imports that may define colours
  rules:
    swiftLiterals: error          # #RRGGBB / #RRGGBBAA strings, Color(red:...), NSColor/UIColor(red:...), .init(white:)
    fixedFonts: error             # .system(size:), .custom(...) outside TextSpec
    ruleWeights: warning          # numeric literals in .lineWidth(), .stroke(lineWidth:), .frame(height: 1|3|8) in chart code
    css: error                    # colour literals and font-family names in .css/.html not from a generated file
```

Mechanics, kept inside what the project's other SwiftSyntax auditors already do: walk the syntax tree, flag
string literals matching the hex regex and the `Color`/`NSColor` initialisers, skip files in `paletteFiles` and
in the DesignTokens sources, and for each declared palette file require that a test target references
`ThemeValidator.validate` on its palette (the checker greps for the call; a palette file with no validating test
is itself a finding). No override comments, per the standing rule. Known weaknesses: `ruleWeights` is a
heuristic and will false-positive on layout code (hence `warning`, and the owner decides whether warnings count);
colour derived at runtime (`Color.opacity`, `mix`) is not caught; an asset catalogue colour is not seen at all.
For the blog the equivalent is the computed-value check in 5.3, since there is no source to scan.

## 8. Release sequence

Each release is small, red-first, ends with `quality-gate` 0 errors and 0 warnings, and updates CHANGELOG (with
its link references), README, `project/master_plan.md` and a session summary, per the doc-housekeeping rule. No
release changes any default look. Test names are red-first names; written before the code.

| Version | Ships | Red-first tests (named) | Consumer change that lands with it |
|---|---|---|---|
| **0.4.0** Model | `ColorValue`, `Adaptive`, `ThemePalette`, `Structure` and its parts, `Theme`, `AppPalette`; `Theme.swiss` built from `ColorToken`/`Palette`/`Rule`; canonical JSON codec; numeric `TypeStyle` accessors; the `Theme` file layout | `swissIsBuiltFromTokens`, `adaptiveAgreesWithColorTokenForAllRoles`, `themeRoundTripsDeterministically` (Finding B), `dictionaryKeysAreStringsNotEnums`, `lightOnlyThemeRejectsDarkValue`, `bothThemeRequiresDarkOnEveryRole`, `existingTokensCSSUnchanged`, `alphaColourRoundTripsAsRRGGBBAA` | None. Additive; existing consumers on 0.2.0 or 0.3.0 are unaffected |
| **0.5.0** Validator and registry (implemented on `feature/themes-validator-0.5.0`, untagged) | `ThemeValidator` (band, chroma, CVD via Machado matrices, normal floor, contrast, ordinal ramps, structure sanity); `Theme.house`, `.ft` and `.economist` (each with an authored dark variant, decision 4), `.princeton` (as `AppPalette` on Swiss), the four legacy themes (Default snapshotted and marked legacy, decision 3), `Theme.all`; `conformance`/ledger | `validatorMatchesJavaScriptOnAllPalettes` (Node, tagged), `validatorFindsFailureOnBadPalette` ("silence is not a result"), `swissLightBandFindingIsLedgered` (measured 0.865), `ftAndEconomistFindingsAreExactlyTheLedger`, `legacyDarkCVDFailureIsRecorded` (ΔE 3.6), `entityOrderRequiresEveryFailingPairListed`, `princetonComposesOnSwissKeepingStructure`, `everyRegisteredThemeValidates` | None. Gaps G1 to G11 become the field list the three new themes force |
| **0.6.0** Emitters I: JSON, CSS (DesignTokens half implemented on `feature/emitters-swiftui-0.6.0`, untagged; the BusinessMath-UI conversion in the last column is not started) | `design-tokens emit --all`; `themes/<id>.json` and `.css` (scoped, with light, dark, contrast); `tokens.css` still byte-identical; DesignTokensSwiftUI target (`Color(theme:role:)`, `ChartStyle`) if question 2 is yes | `themeCSSMatchesCommitted`, `themeJSONMatchesCommitted`, `tokensCSSStillEqualsToday`, `cssHasNoLiteralOutsideGenerated`, `scopedSelectorsDoNotLeakAcrossThemes` | **BusinessMath-UI converts** (the large change, on its own branch, in the phases of 6.1): pin 0.6.0; delete `ChartThemeProviding`, `EditorialTheme`, `TokenColor`, the five themes; views read `ChartStyle`; `showValues: Bool?`; `source:`; per-view `...resolve` tests; legacy themes render via `.platformAutomatic`. `swissThemeStructureHonouredByBarChart` etc. |
| **Visual checkpoint 1** | **Not a release; a gate.** Contact sheets, produced by a test target in BusinessMath-UI: every theme (Swiss, House, Princeton, FT, Economist, the four legacy) x every standard view and Editorial archetype x {light, dark, increased contrast} x {SwiftUI standard views, Editorial, SVG}, each **before (BusinessMath-UI `main` at the pre-change commit) beside after (the branch)**, as PNG and an HTML index. Plus a second sheet: gaps G2, G4, G9 as drawn | `contactSheetCoversEveryThemeViewAppearance` (the sheet generator fails if a cell is missing: a blank cell is not a pass) | The owner looks. **No default theme or default structure changes, in BusinessMath-UI, the site or anywhere, before the owner has seen this** and says so. `design/swiss-default-theme` stays unmerged |
| **0.7.0** Emitters II: SVG, web, blog | SVG emitter and `SVGStyle`; **Tumblr block emitter** with stamp (version, hash, template revision); `design-tokens check-blog` (stamp check and computed-value check, headless Chrome); site gains `themes/<id>.css` use if wanted | `svgStyleMatchesCommitted`, `tumblrBlockMatchesCommitted`, `tumblrBlockContainsNoTumblrTags`, `tumblrBlockHasNoLiterals`, `stampParsesAndRoundTrips`, `staleStampIsReported`/`missingStampIsReported`/`currentStampIsAccepted` (against fixture HTML, no network), `tumblrBlockCoversEveryRoleTheDraftUses` (compares to `~/Desktop/tumblr-swiss.html`'s variable names) | **BusinessMathCharts** replaces `SVGTheme` with `SVGStyle`; BusinessMath-UI SVG exporters take `theme:`; **the blog**: owner pastes the first generated block (after the verification on a Tumblr preview, section 9); the site re-pins |
| **0.8.0** Emitters III: ANSI, slides | ANSI table and rule glyph mapping; slides json | `ansiCoversEveryRoleInBothAppearances`, `ruleGlyphMappingIsExact`, `slidesJSONMatchesCommitted` | SwiftGUIKit terminal resolver reads `Theme`; Apple resolver reads rule weights and grid; Swiss tier work resumes on it |
| **0.9.0** Apps and the drift checker | `AppPalette` public API stabilised; `design-token-drift` checker (in quality-gate, its own repo) | `driftCheckerFlagsSeededHexLiteral`, `driftCheckerQuietOnCorrectProject` (run on FleetWatch, KEXPPower first: they have 0 or few literals), `paletteFileWithoutValidatingTestIsFinding` | WineTaster adopts `WinePalette` (its two files with literals go to one declared file); then FleetWatch, KEXPPower, narbis, HockeySimApp in turn, each its own small change |
| **Visual checkpoint 2** | Gate. Contact sheets of each adopting app and the blog preview, light, dark, increased contrast, before and after | `contactSheetCoversEveryApp` | Owner decides whether Swiss structure becomes the **default** theme (BusinessMath-UI environment default, site default). Only then is `design/swiss-default-theme`'s change, or its successor, considered |
| **1.0.0** | API freeze; `ColorToken`/`Palette` possibly internal; drift checker on by default in the fleet template | `publicAPISurfaceIsFrozen` (a non-`@testable` use of every public symbol) | Re-pin everywhere |

Notes: BusinessMath-UI's change lands in 0.6.0 and not later because the Editorial charts and standard views are the
largest consumer, and a model with no consumer for three releases would be designed in a vacuum (the failure the
earlier proposal's recoloured-theme gaps illustrate). Release 0.6.0 is also the largest risk; if the Swift Charts spike
fails, only the standard-view part slips, and the model stays. Because BusinessMath-UI's `Package.swift` uses
`from: "0.2.0"`, SwiftPM would float to a new 0.x on the next resolve for any consumer whose `Package.resolved` is
refreshed; that is acceptable only because 0.4.0 to 0.9.0 are additive. Any release that is not additive must say so
at the top of its CHANGELOG entry and bump the minor *and* be called out to consumers.

## 9. Constraints and compliance

- Swift 6.2 tools, strict concurrency: every model type is a `Sendable` value type; no `@unchecked`.
- No force unwraps; no division without a zero check (validator, ramp sampling); every public symbol has DocC.
- Foundation only in the base product (no `CryptoKit`, no `Accelerate`): `pow` and `cbrt` come from Foundation as
  `Colorimetry.swift` already uses; the stamp hash is FNV-1a for this reason.
- No magic numbers (the no-hardcoded-constants rule): thresholds (0.43 / 0.77 / 0.10 / 8 / 15 / 3) are named
  constants in one `ValidationThresholds` with a comment citing the method, so a change to the method is one edit.
- Quality gate: not run on code, because none was written; the proposal's own commit runs it (section 12).

## 10. What I ran to check this (prototype and measurements)

- **Scratch prototype (not committed):** a SwiftPM package outside the repo that depends on DesignTokens by path
  and defines a reduced `Theme` (`ColorValue`, `Adaptive`, `RuleSpec`, `FontRef`, `Structure`, a palette and
  `composed(with:)`), builds `Theme.swiss` from `ColorToken`, `Palette` and `Rule`, and derives FT by editing
  Swiss. It **compiled and ran** (Swift 6.4 on this Mac). Results: Swiss and FT each decode back equal to the
  original; Swiss's light series equal `Palette.series`; composing a WineTaster accent (#7F0017) onto Swiss kept
  Swiss's rules; a `String`-keyed role dictionary re-encodes byte-identically and an enum-keyed one did not
  (Finding B). It did **not** exercise the full type list, the emitters, the validator in Swift, or anything on
  Linux.
- **Validator runs:** the dataviz skill's `validate_palette.js` run (Node) on the series of Swiss (light and
  dark), House, Economist, FT, Princeton, Legacy Financial, Accessible and Dark. That is the source of the table
  in 4.3 and of Finding A. It is a measurement of the listed hexes against the listed surfaces.
- **Blog:** `curl` of blog.justinpurnell.com returned 403 and a browser-challenge page (5.3). The draft theme in
  `~/Desktop/tumblr-swiss.html` was read for its structure; it was not rendered.
- Everything else here is read from source (the three packages named) and not run.

## 11. Source and API compatibility

- DesignTokens 0.4.0 to 0.9.0 are additive. `tokens.css` and `tokens.json` are byte-identical until the default
  decision, asserted by test.
- BusinessMath-UI breaks, deliberately, in the 0.6.0 conversion; no shims, and its own CHANGELOG carries the
  list. BusinessMathCharts breaks at 0.7.0 (`SVGTheme`). The old `--good`/`--over`/`--ink-mute` CSS variable
  names go with it.
- `ColorToken`, `Palette`, `Rule`, `Grid`, `Radius`, `TypeStyle`, `FontStack`, `Snapshot` keep their public API
  through 0.x, so the site, SwiftGUIKit and BusinessMathCharts, which read them today, are not forced to move early.
- Library evolution is not enabled in the package (no setting in `Package.swift`), so binary compatibility is not
  claimed; this is a source package.

## 12. Architecture Decision Review

- Supersedes the StructuralThemeLayer proposal named above, and its recommended Option C (hybrid with optional
  `structure`). Carries out decisions 2 and 3 of the accepted single-source proposal; it **amends** its invariant
  list by adding structure to the things held once, and it amends the README claim "The palette is validated"
  (Finding A).
- No ADR log was found under `project/decisions/` (only `.gitkeep`). If approved, ADRs to write: "Theme = Structure
  + Palette, hosted in DesignTokens"; "Legacy conformance is a measured ledger, not an annotation"; "Blog
  mechanism: generated paste-in block with a stamp".

## 13. Adversarial review of this design

**Strongest case against it.** A package that holds a whole theme model, six emitters and a validator is no
longer "design tokens"; it is a design-system engine, and every consumer now depends on a large API whose first
users (FT, Economist) are stress tests. A smaller design would keep `Theme` to colours plus four rule weights, leave
structure in each renderer, and accept some drift. The reply: the structure fields are exactly what drifts today
(the title rule exists nowhere, the SVG gridline weight is a literal 1, `showValues` defaults disagree across two
views), and the owner has chosen the larger design. The cost is real, and the release sequence is built so each
step can stop.

**Where it is most likely wrong.**

1. *The vocabulary is derived from three houses and nine charts.* G2, G4 and G9 are claims about FT and Economist
   from memory; a real rendering may show different needs. The first checkpoint is where they are tested.
2. *`Adaptive` with four optional slots misses states* (disabled, pressed, focus, the system's elevated
   background). The package has none today; a UI app adopting the theme (FleetWatch) will ask for them. I deliberately
   did not add roles with no consumer.
3. *The validator port can disagree with the JavaScript.* The Machado matrices are the main risk, which is why the
   conformance test cross-runs both; but the test needs Node, and anything not run on the owner's Mac is unrun.
4. *A ledger can become a dumping ground.* Mitigation: it records exact numbers, fails on any change, and a theme
   entering `.legacy` shows in the diff. If it grows, that is a signal, not a feature.
5. *(Superseded by decision 4: FT and Economist get authored dark variants; the remaining risk is that our dark is an interpretation of the houses. Original text follows, for the light-only case.)* *Light-only themes in a dark app* render as a bright card, which may look worse than a
   derived dark would. I preferred that to an invented palette; a rendering decides.
6. *A paste-in block re-introduces the problem of the original drift:* a person edits the block in Tumblr's
   editor. The stamp does not catch a hand edit; the computed-value check does. If the headless check is flaky
   (the bot challenge), the guard is weaker than it reads here.
7. *Three-way coupling by class name:* the Tumblr block depends on class names in HTML the package does not own.
8. *The size of the BusinessMath-UI conversion (release 0.6.0)*: deleting two theme systems at once, with a Swift
   Charts capability that is unverified, is the highest-risk step. Splitting it (standard views first behind the
   model, Editorial second) is the fallback.
9. *Apple deference versus a single source.* `Adaptive.system` lets Swiss defer to `Color.orange`, whose value is
   not the stored hex; the contact sheets and validator measure the stored hex, not what the OS paints.

**What an experienced critic would say.** "You found that your own flagship palette fails the validator you cite,
and your answer is a ledger." Yes; the alternative is either re-stepping Apple's colours (against the HIG deferral
the project chose) or failing CI on day one. The ledger makes the finding permanent and visible instead of fixing
it, and open question 1 puts that choice with the owner.

## 14. Alternatives considered

- **Keep `EditorialTheme` as the model and bridge (the superseded proposal).** Rejected by the owner's decision;
  it also leaves one hex per token and no dark mode.
- **JSON as the authoring format.** Easier for non-Swift tools; loses compiler checks and the shared-constant
  construction of Swiss. Rejected (accepted decision 2).
- **A hosted stylesheet for the blog.** Removes the re-paste. The owner prefers paste. Kept as a later option.
- **A theme per package** (one package per house). More isolation, many more pins. Rejected: the registry is one list.
- **SwiftUI adapter in each consumer.** No new target; duplicated dynamic-colour code. Open question 2.
- **Derive dark values from light for light-only themes.** Invented colours, contrary to the package's own rule.

## 15. Test strategy summary

TDD, Swift Testing. Per release: the red tests named in section 8 first, then the code. Guard tests: byte-identical
existing `tokens.css`/`tokens.json`, round-trip determinism, JavaScript conformance for the validator, per-target
golden files, a public (non-`@testable`) use of every new symbol, and in each consumer the "no literal outside a
declared palette file" test the site already has. Visual correctness is established by the contact-sheet gates, not
by assertions on pixels.

## 16. Not verified

- **No package code was changed, and no DesignTokens test or gate was run on a change** (this is a document).
  Nothing in the model, validator, emitters or checker exists beyond the scratch prototype of section 10, which
  covers a reduced model only.
- Whether Swift Charts can draw a title rule, flat fills and custom gridline weights under `AxisMarks(preset:
  .automatic)`.
- Whether the full model (all nine chart type roles, layout, formats) builds on Linux: expected, never built there.
- FT and Economist structural details (G2, G4, G9): general knowledge, not looked up and not rendered.
- (Done in 0.5.0) The Swift port of the CVD simulation against the JavaScript: ported and cross-checked under Node on the owner's Mac, and verified by mutation. Not run where Node or the script is absent (the test is skipped with a reason).
- (Done in 0.5.0) Legacy `DefaultTheme`'s colours as hex: snapshotted on macOS 27.2 as `NSColor` system colours with Increase Contrast off; the named high-contrast appearances returned the standard values in a command-line-launched `NSApplication`, so increased-contrast values for it are the 0.3.0 ones where the colour is the same, and absent otherwise. SwiftUI's own `Color.blue` and the `NSColor` values were assumed to coincide, not compared.
- The blog: the live page returns a bot challenge to `curl`; how Tumblr stores and serves the pasted block, whether
  comments survive, whether a headless run passes the challenge, and the Tumblr-specific selectors the block must
  target are all unverified. The draft `~/Desktop/tumblr-swiss.html` was not rendered or pasted. The external
  stylesheet route (owner-confirmed possible) is not designed: its hosting URL, caching and CORS behaviour are unverified.
- The WineTaster hex values in 6.7 are illustrative and not measured; the project categories in 6.7 come from names
  and file counts, not from opening the projects (`ControlRoom` in particular).
- The `quality-gate` checker in section 7 is a sketch: I did not read the existing auditors' APIs.
- BusinessMath-UI conformers outside that repo (BusinessMathDemo, Adapters), and external `switch`es on
  `GridlineStyle`, were not searched.
- Consumers' `Package.resolved` other than BusinessMath-UI's (0.2.0) were not checked.

## 17. Open questions for the owner (five) — all answered 2026-11-09, see "Decisions 2026-11-09"

1. **Swiss fails the lightness band (Finding A). Keep Apple's system colours and ledger the finding, or re-step the
   palette?** *Lean: keep, ledger the measured values, and require direct labels or printed values for the slots
   that fail contrast (yellow, orange, green, cyan), which the Swiss docs already say. Correct the README wording
   from "validated" to "validated for adjacency and colour-blind separation; system colours sit outside the
   lightness band".*
2. **Where does the SwiftUI adapter live?** A second target `DesignTokensSwiftUI` in this package, or duplicated in
   each consumer. *Lean: the second target; the base product stays Foundation-only (expected to build on Linux, untested).*
3. **Legacy Default theme uses SwiftUI system colours with no hex. Snapshot it with the measurer (and keep
   `Adaptive.system`), or drop it?** *Lean: snapshot it and keep it as `legacy`, since it is today's default and the
   before-and-after sheets need it; drop it only if the owner decides the default is going away.*
4. **FT and Economist in dark: light-only themes that render as a card, or authored dark variants?** *Lean (overruled): light-only. **Decided: authored dark variants**, flagged as our interpretation.*
5. **Is a ledger acceptable for legacy conformance** (section 4.3), given the standing "no suppression" rule?
   *Lean: yes, because it records a measurement and fails on any change, and a theme entering it is a visible diff;
   if not, the four legacy themes have to be re-stepped before 0.5.0 can merge.*

## 18. Documentation strategy

DocC on every public symbol, with a `Themes.md` article (how to add a theme, the workflow of 5.4, the validation
method and its thresholds) and an `AppPalettes.md` article (the WineTaster example). README status line and the
"Palette" paragraph corrected per Finding A. CHANGELOG per release with its link references. `master_plan.md`:
the Key Types table, Current Status and Roadmap updated per release (this proposal adds Phases 3 to 5's detail and
a Phase 6 for apps), with completed items struck through, not deleted. A session summary per release.

---

## Appendix A: Swiss versus legacy bar chart, structure (target, not rendered)

```
 SWISS (Theme.swiss)                               LEGACY (CategoricalChart, today, any colour set)

 Quarterly revenue          <- title, ink, 17 bold      Quarterly revenue          <- .headline
 ======================== <- title rule, 3 pt (Rule.section),   In thousands, FY2026    <- .subheadline
 In thousands, FY2026        theme field, below title
                                                         140 |                     <- automatic Swift Charts axes
   130 ------------------- <- gridline, 1 pt, faint       120 |      [~~~~]   [~~~~]   (platformAutomatic grid)
        100   120   115  130   <- value labels above bars 100 | [~~~]                [~~~]
       +---+ +---+ +---+ +---+   (labels.values on)       0  +----------------------
       |###| |###| |###| |###|  <- flat fill (barFill)       Q1     Q2     Q3     Q4   <- values on hover only
   0 --+---+-+---+-+---+-+---+-- <- baseline, 1 pt         (no title rule, no source line, gradient fills)
        Q1    Q2    Q3    Q4
 Source: Finance            <- source line, 11, left
```

Fields that make the left column: `rules.title` (weight 3, `.belowTitle`), `rules.gridline`, `rules.baseline`,
`labels.values`, `marks.barFill == .flat`, `layout.gridlines == .horizontalFaint`, `labels.sourceLine`. The right
column is `layout.gridlines == .platformAutomatic`, `marks.barFill == .autoGradient`, no title rule.

## Appendix B: the Tumblr block's contract with the theme HTML

Class names the generated block's selectors assume (from the draft; the owner keeps them in the theme HTML):
`.header`, `.nav`, `.post`, `.post.newday`, `.datetime`, `.day`, `.my`, `.type`, `.row`/`.k`, `.caption`,
`.video`, `.short_quote`/`.medium_quote`/`.long_quote`, plus Tumblr's own `div.npf-link-block` and
`.tumblr_video_container`. The check in 5.3 probes a subset of these on the live page; a class that has been
renamed in the HTML shows up there as a missing element.
