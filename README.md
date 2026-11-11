# DesignTokens

The design system's values, held once as typed Swift and generated for every surface that cannot import Swift.

**Status:** pre-release (`0.x`, 0.13.0 on `feature/components-0.13.0`, untagged: the shell, prose, mark, item meta and columns, banner and hidden gaps, and the interaction states verified in Chrome; 0.12.0 (tagged, in `main`): `CardChrome` as a theme property, the `console` theme, and `components.css`, the web counterpart of the Swiss components; latest tag 0.11.2 (2026-11-10: the Tumblr stamp hashes the block's content, so a theme-model change the blog does not use no longer reads as stale), after 0.11.1 (`check-blog` treats a version-only difference as current) and 0.11.0 (the dashboard's gaps: type hierarchy, borderless equal-height cards, table selection and tree rows, dynamic colour, square chips, caution and warning, segmented fallback, flow), 0.10.0 (Swiss SwiftUI components, `AppPalette` window and surface, `swiss-gallery`), 0.9.0 (text roles, host surfaces, public contrast, Swiss as the environment default), 0.8.0 (app-palette adoption API and `AppPaletteSource`), 0.7.0 (terminal and slides emitters, the Tumblr full theme, `--format`) and 0.6.0 (the Tumblr block and `check-blog`); see `CHANGELOG.md`). Phase 1 and 1b of `project/master_plan.md`.

## What it holds

- **Colour roles** (`ColorToken`): the nine SwiftGUIKit roles plus `onAccent` and `link`, each with a light and a dark value.
  A dark value that has not been measured on the snapshot release is `nil` and listed in
  `ColorToken.unmeasuredDark`; it is not guessed. Today that list is empty.
  Increased-contrast values (`increasedContrastLight`, `increasedContrastDark`) are measured on macOS 27.2
  from a real app with Increase Contrast on, for `accent`, `success` and `destructive`. Everything else is
  `nil` (listed in `ColorToken.unmeasuredIncreasedContrast`), not guessed: `label`, `secondaryLabel` and
  `separator` carry alpha, which a hex readout loses; `background`, `secondaryBackground` and `onAccent` are
  this package's own values; `warning` has no system colour; and the measured system `link` has *less*
  contrast than this package's link, so it is deliberately not adopted.
- **Palette** (`Palette`): eight series colours in a fixed order, validated for adjacency and colour-vision separation (it fails the dataviz lightness band for yellow in light and for orange, green, yellow and cyan in dark, and orange, green, yellow and cyan are under 3:1 on the light surface, so those four slots need direct labels in the light and standard dark appearances: `SwissLedger.directLabelSlots`, derived from the Swiss ledger. With Increase Contrast on in dark all eight series are above the dark band, so there every slot needs one: `SwissLedger.slotsNeedingDirectLabels(in:)`), in light (`series`) and dark
  (`seriesDark`, measured) and with Increase Contrast on (`seriesIncreasedContrast`,
  `seriesIncreasedContrastDark`, measured); the sequential ramp, and `sequentialDark` (the same ramp reversed, derived, not
  measured); the diverging ramp (`Palette` has no dark ramp; Swiss's theme authors one, see "Chart alignment"); and Princeton
  orange as a custom accent.
- **Metrics** (`Rule`, `Grid`, `Radius`): rule weights 1, 3 and 8 pt; a 12-column grid with a 16 pt gutter
  and a 4 pt base; container radius 0, control radius 4 pt.

- **Typography** (`FontStack`, `TypeStyle`): SF with a Helvetica fallback as the default; New York and
  Garamond stacks as a switch; six type roles from label to display.

- **Theme model** (0.4.0, additive): `Theme` = `Structure` + `ThemePalette`; `Adaptive` colours (light, dark and
  an increased-contrast value for each); `ColorValue` with alpha; `Theme.swiss`, built from the constants
  above; `AppPalette` composed onto a theme; `ThemeCodec`, a canonical, byte-stable JSON form; numeric
  `TypeStyle` accessors. `Generated/tokens.css` and `tokens.json` are unchanged.

- **Validator and themes** (0.5.0, additive): `ThemeValidator`, a Swift port of the dataviz skill's
  `validate_palette.js` (OKLCH lightness band, chroma floor, colour-vision and normal-vision separation, mark
  and text contrast, ramps, structure), cross-checked under Node against the script itself, which is **not** in this repository (no licence of its own): the
  cross-check (`JavaScriptCrossCheckTests`) and a test that reads the thresholds out of the script's text run only where the script is present
  and its SHA-256 matches the pin (`DATAVIZ_VALIDATOR`, or the dataviz skill directories; see `Tests/DesignTokensTests/Vendored/README.md`),
  and are skipped with a visible reason otherwise (also when Node is absent). A recorded-run test (numbers taken from the script) runs everywhere. `Theme.conformance`:
  `strict`, or a `ledger` / `legacy` ledger of the exact findings (measured values at the validator's displayed rounding):
  a finding that appears, disappears or changes value fails a test; a ledger is not a suppression. A colour change that
  moves no finding is not caught by the ledger: it is caught by the committed `Generated/themes/` files (0.6.0), which a
  test compares with a fresh emit.
  `AppPalette` `entityOrder`: every failing pair must be listed in `labelRequired` and becomes a mandatory direct
  label (`ThemeValidator.requiresDirectLabels`). `Theme.all`: Swiss, House, Princeton, FT and Economist (with
  authored dark variants, our interpretation of those houses), and the four legacy BusinessMath-UI themes (the
  Default as a labelled snapshot of the system colours), each a `Theme` value that round-trips through
  `ThemeCodec`. Findings: `project/docs/technical/ThemeConformance.md`.
  Swiss's `positive` and `negative` (gain and loss, as text and marks) are the darker text-safe pair, at least 4.5:1 on the Swiss
  background and card surface in every appearance, and deliberately **not** system colours (owner decision 2026-11-09): they name no
  system colour, so `ChartStyle` never defers them to Apple's green and red. `ColorToken.success` and `.destructive`, and so
  `tokens.css`, stay the system colours. Princeton follows Swiss fully (owner decision 2026-11-09, `fix/princeton-follows-swiss`): it has the same text-safe pair, and keeps only its own accent, series and ramps.

- **Emitters and SwiftUI adapter** (0.6.0, additive): `ThemeCSSEmitter` and `ThemeJSONEmitter` write one scoped CSS file
  (`[data-theme-name="<id>"]`: light, `prefers-contrast: more`, dark, and the contrast-dark blocks) and one canonical JSON
  file per theme into `Generated/themes/`; `tokens.css` and `tokens.json` are byte-identical to 0.5.0. A second library,
  `DesignTokensSwiftUI` (`import DesignTokensSwiftUI`), turns a `Theme` into a `ChartStyle`: SwiftUI colours, fonts,
  rule weights (including the title rule), flags, layout, marks and number formats for the current appearance and
  Increase Contrast, with `EnvironmentValues.theme`, `ChartStyleReader` and `.chartTheme(_:)`. See "SwiftUI" below.

- **Review fixes** (0.6.0): `Theme` decoding is strict (an unknown or misspelt key, a dangling colour or ramp reference, a
  negative rule weight, a ramp whose dark and light steps differ in number, a strict theme with ledger entries and dark values that
  contradict the declared appearances are all errors, for a plain `JSONDecoder` as much as for `ThemeCodec`), and `ThemeCodec.encode`
  refuses what decode would refuse. `Theme.composed(with:)` always returns a valid theme: an app palette without dark values makes
  the result light only (how `Theme.princeton` is built). Hex parsing takes ASCII hex digits only. `ThemeValidator.measure(hexes:)`
  throws on a bad hex. Theme JSON written by 0.4.0 (no `conformance`, `extras`, `colourOverrides` or `rampOverrides`) no longer
  decodes; nothing emitted theme JSON before 0.6.0.

- **Chart alignment** (0.6.0; owner decisions 2026-11-09, `project/plans/proposals/2026-11-09_ChartAlignmentToApprovedDesign.md`):
  Swiss expresses the approved "Swiss and Apple" chart. Marks are neutral by default and the accent is reserved for emphasis:
  `palette.muted` is the history grey (#B9BBBD / #4E5053; Increase Contrast #8E9196 / #6F7176; 1.84:1 and 2.34:1, ledgered, printed
  values are the relief), `MarkSpec.defaultFill` / `defaultEmphasis` / `emphasisFill`, the title rule above the title (`gapAfter`), a 1.5 pt ink
  baseline, bars 0.7 of the slot, a muted solid hairline target line with an ink label, `LabelSpec.valueHalo`, minimal decimals
  (`NumberFormatSpec.maxDecimals`), margins 6/8/12/8, and an opt-in card border (`Theme.withCardBorder(_:padding:)`, off by default). Swiss's
  sequential and diverging ramps are **grey to orange**, the family of the bars (owner decision 2026-11-09, "Heatmaps and scatter
  grey-to-orange"), each with an authored dark variant; the blue sequential and blue-orange diverging ramps are the named alternates
  `extraRamps["sequentialBlue"]` and `["divergingBlueOrange"]`. Scatter points take the same fills as bars (neutral, the emphasised point in
  the accent) and a colour-encoded third variable uses `sequential`. `Palette.sequential`, `Palette.diverging` and `tokens.css` are unchanged. Every new field defaults to the old behaviour, so House, FT, Economist and the
  legacy themes behave as before; Princeton, a Swiss variant, inherits the new structure. `ChartStyle` exposes all of it
  (`markFill(emphasised:)`, `emphasisColour`, `titleRuleGap`, `referenceColor`, `valueHalo`, `fractionDigits(_:)` and the rest).

Not yet here: increased-contrast values for the roles listed above, and dark values for Princeton.

## Platforms

The core library (`DesignTokens`) is Foundation-only, expected to build on Linux, untested: no Linux build has been run. Foundation-only is a guard against
SwiftUI imports in the core, not a commitment to a Linux GUI (there is none; a future GUI path that consumes the
`Theme` is possible but out of scope). It builds and is tested on macOS. It holds data, not `Color` values: on Apple
platforms a resolver should use the system's own colours (the HIG says not to hard-code them), and the
values here are a labelled snapshot (`Snapshot.systemRelease`) for web, SVG, slides and spreadsheets.

## Generating the files

```
swift run design-tokens emit --all Generated      # or just: swift run design-tokens Generated
swift run design-tokens emit --theme ft Generated # one theme's pair only
swift run design-tokens emit --format ansi,slides Generated  # only those kinds (css, json, tumblr, ansi, slides, components)
swift run design-tokens emit --components Generated          # only components.css
swift run design-tokens list                      # the registered theme ids
```

writes `Generated/tokens.css` and `Generated/tokens.json` (the default look), `Generated/components.css` (0.12.0) and, for every theme in `Theme.all`,
`Generated/themes/<id>.css` and `<id>.json`, plus Swiss's Tumblr block `themes/swiss.tumblr.css`. All are committed, and a test fails if any differs from a fresh emit or if
`Generated/` holds a file that is not generated, so regenerate and commit after changing a value.

Each theme also gets a terminal table and slide files (below). A theme's CSS is scoped to `[data-theme-name="<id>"]`, so several themes can coexist on a page. A light-only theme has no
dark blocks; the dark selectors honour `data-theme` and `data-bs-theme` on the element or any ancestor.

## SwiftUI

```swift
import DesignTokensSwiftUI

ContentView().chartTheme(.swiss)                 // sets \.theme and \.chartStyle

ChartStyleReader { style in                      // always current for its own environment
    Text("Revenue").chartText(.title, in: style).foregroundStyle(style.ink)
}
```

`ChartStyle(theme:colorScheme:contrast:)` resolves a theme for the live appearance. A colour that stands for an Apple
system colour defers to it (HIG) when the theme declares both appearances; every other colour is the theme's stored
value. The default theme in the environment is `Theme.legacyDefault`, not Swiss: no default look changes before the
owner has seen the contact sheets. macOS 14, iOS 17, visionOS 1.

The CSS has `@media (prefers-contrast: more)` blocks (light, then `and (prefers-color-scheme: dark)`, then the
explicit dark selectors), ordered so the dark scheme wins over the light contrast block and the dark contrast
block wins over the standard dark values.

## An app's own palette (0.8.0, text roles in 0.9.0)

An app keeps its accent and series on Swiss's structure by declaring them in one file that conforms to `AppPaletteSource`, and tests them
with `#expect(WinePalette.validate().isConformant)`. The palette carries its own ledger of exact findings, exactly as the built-in themes do;
nothing is suppressed. `maxSeriesPerChart`, `labelTogether` and `chartViolations(plotting:labelled:)` state the app's chart rules as code, and
`palette.theme()` feeds the CSS, JSON and ANSI emitters. Walkthrough: `project/docs/technical/HowAnAppAdoptsTheTokens.md`; contract for the
drift checker: `project/plans/proposals/2026-11-10_AppPaletteAdoption.md`.

0.9.0 adds text: `textRoles` (status and secondary text, measured as text at 4.5:1 and never as chart marks), `textSurfaces` (the backgrounds your
text is drawn on, so the guarantee holds on yours and not only on Swiss's), `AppTextRole` and `AppPaletteSource.text(_:)` (one typed source the
views read, cross-checked by `validate()`), and `RGB.contrastRatio(with:)` / `meetsAA(on:)` so an app writes no WCAG of its own. The SwiftUI
`\.theme` default is now Swiss. Proposal: `project/plans/proposals/2026-11-10_TextRolesAndPaletteSurfaces.md`.

## Web components and the Console theme (0.12.0, 0.13.0)

**0.13.0 adds** (all `dt-` classes, theme properties only): a page shell with a sticky navigation column (`dt-shell`, `dt-shell__nav`, `dt-shell__main`, `dt-nav`, `dt-nav__heading`, `dt-nav__item[aria-current]`; one column and a wrapped nav row under 600 px); `dt-prose` for unclassed rendered Markdown (`h1` to `h6`, lists, `blockquote`, `code`, `pre`, `table` with a hairline header and tabular numerals, `hr`, `a`, `mark`, `img`); `mark` and `dt-mark` (a tint derived from `accent` with `color-mix()`, because the palette has no highlight role); list items with a trailing count (`dt-item--meta`, `dt-item__main`, `dt-item__meta`) and `dt-list--columns` (auto-fit columns, one column under 600 px); `dt-banner` holding paragraphs and links; `[hidden]` always wins over a component's `display`; and corrected hover, active, focus, invalid, disabled, forced-colours and increased-contrast states (see `CHANGELOG.md`). For the FleetWatch adoption: `dt-meter` (a `role="meter"` track, fill and figure, five tones), `dt-header` (title and links at the start, session at the end, on the 12-column grid), wrapping `dt-chip` (with `dt-chip--nowrap`) and `dt-checkline`, a non-wrapping `dt-stat__figure` (figure and unit: `13<span class="dt-stat__unit">d</span>`), `dt-input--auto` and `dt-select--auto`, `dt-form` and `dt-form--inline`, `dt-disclosure` (a `<details>` with a count and an optional scrolling body), `dt-plate` (a light surface for a QR code in any theme), `dt-banner__head` and `dt-banner__actions`, and `dt-long` and `dt-long--truncate`. Every registered theme is a public static property (`Theme.swiss`, `.house`, `.princeton`, `.ft`, `.economist`, `.legacyDefault`, `.legacyDark`, `.legacyFinancial`, `.legacyAccessible`, `.console`), as well as `Theme.all` and `Theme.named(_:)`.

`Generated/components.css` is one stylesheet for any web page, written only in terms of a theme's custom properties (`var(--ink)`, `--rule`, `--radius-container`, `--card-border`, the `--type-*` roles, the `--list-*` tokens). Link a theme (`themes/swiss.css`, `themes/console.css`) and `components.css`, set `data-theme-name` on `<html>` (and `data-theme="light|dark"` to pin an appearance), and use the `dt-` classes (`dt-section`, `dt-kv`, `dt-table`, `dt-chip`, `dt-banner`, `dt-segmented`, `dt-button`, `dt-input`, `dt-card`, `dt-grid`...; the list is in `ComponentsCSSEmitter`'s documentation). A `dt-cards` grid of `dt-card`s is an equal-height grid of entity summaries in every theme (three across a 1200 px page, one on a phone), with `dt-stats` setting each card's two or three facts as a small capital label over a large figure; the theme's `cardChrome` decides the card's dress: flat with the section rule across the top under Swiss (`ruled`), a hairline-bordered surface under Console (`bordered`), with the same markup. A `dt-list` of `dt-item`s is plain rows in every theme, and a `dt-table` stacks into cards below 600 px. The registered themes are now `swiss`, `house`, `princeton`, `ft`, `economist`, the four legacy themes and `console` (fixed-dark navy, monospaced, cards: the former FleetWatch page).

## Browser support

The CSS the package emits is written for current browsers and **no fallbacks are provided**: a browser older than the floor is not supported, and gets whatever its parser makes of rules it does not know.

**The floor for a page that links `tokens.css` or a theme file and `components.css`: Chrome 111, Edge 111, Safari 16.2, Firefox 113.** `color-mix()` (in `components.css`) sets the floor in every engine; container queries come one release behind it. The theme files alone need Chrome 96, Edge 96, Safari 14.1, Firefox 101 (`prefers-contrast`). The Tumblr block (`themes/swiss.tumblr.css`) is separate and needs Chrome 105, Edge 105, Safari 15.4, Firefox 121, because it uses `:has()`.

Sources: the first unprefixed, unflagged version of each feature in `@mdn/browser-compat-data` 8.1.8 (the data behind MDN's compatibility tables), read from the npm registry on 2026-11-10; MDN's pages for `color-mix()` and `@container` (both Baseline "widely available", May 2023 and February 2023) as a cross-check. Edge is Chromium-based from 79. Verified in a browser: Chrome only, headless (see `CHANGELOG.md`, 0.12.0); Safari and Firefox are not tested here, so those columns are the compatibility data's, not an observation.

| Feature (note) | Chrome / Edge | Safari | Firefox | Used in |
|---|---|---|---|---|
| color-mix() (ThemeCSSEmitter writes it for a translucent shadow reference; no registered theme has one, so no themes file uses it today) | 111 / 111 | 16.2 | 113 | components |
| @container size queries, container-type | 105 / 105 | 16 | 110 | components |
| :focus-visible | 86 / 86 | 15.4 | 85 | components, tumblr |
| @media (prefers-contrast) | 96 / 96 | 14.1 | 101 | themes, components, tumblr |
| @media (forced-colors) (added 0.13.0; the system colours Highlight and HighlightText it uses are in every browser since 1.0) | 89 / 79 | 16 | 89 | components |
| @media (hover: hover) (added 0.13.0) | 38 / 12 | 9 | 64 | components |
| text-decoration-thickness | 89 / 89 | 12.1 | 70 | components, tumblr |
| @media (prefers-reduced-motion) | 74 / 79 | 10.1 | 63 | components, tumblr |
| @media (prefers-color-scheme) | 76 / 79 | 12.1 | 67 | themes, tumblr |
| color-scheme property | 81 / 81 | 13 | 96 | themes, components, tumblr |
| image-rendering: pixelated (added 0.13.0) | 41 / 79 | 10 | 93 | components |
| clamp() | 79 / 79 | 13.1 | 75 | themes, tumblr |
| min() and max() | 79 / 79 | 11.1 | 75 | components, tumblr |
| Custom properties and var() | 49 / 15 | 9.1 | 31 | themes, components, tumblr |
| calc() | 26 / 12 | 7 | 16 | components, tumblr |
| Grid with minmax() and repeat(auto-fit) (Firefox 76 is when repeat(auto-fit) takes more than one column in a repeated track) | 57 / 16 | 10.1 | 76 | components |
| gap in flex layouts | 84 / 84 | 14.1 | 63 | components, tumblr |
| Logical sizes (inline-size, block-size, min-inline-size, min-block-size) | 57 / 79 | 12.1 | 41 | components |
| padding-inline, padding-block | 87 / 87 | 14.1 | 66 | components |
| border-inline-start, padding-inline-start and -end | 69 / 79 | 12.1 | 41 | components |
| position: sticky (added 0.13.0) | 56 / 16 | 13 | 32 | components |
| inset-inline-start, inset-block-start (added 0.13.0) | 87 / 87 | 14.1 | 63 | components |
| clip-path: inset() | 55 / 79 | 10.1 | 54 | components |
| accent-color (Safari 15.4 to 26.1 implements it without keeping a minimum contrast for the control (MDN lists that as partial); full from 26.2) | 93 / 93 | 15.4 | 92 | components |
| appearance | 84 / 84 | 15.4 | 80 | components |
| overflow-wrap: anywhere | 80 / 80 | 15.4 | 65 | components |
| font-variant-numeric | 52 / 79 | 9.1 | 34 | components, tumblr |
| attr() in content | 2 / 12 | 3.1 | 1 | components |
| #RRGGBBAA hexadecimal colours | 62 / 79 | 10 | 49 | themes |
| :has() | 105 / 105 | 15.4 | 121 | tumblr |
| aspect-ratio | 88 / 88 | 15 | 89 | tumblr |
| env() safe-area insets | 69 / 79 | 11.1 | 65 | tumblr |

Older features the CSS also uses (attribute and structural selectors, `box-shadow`, `transition`, `justify-self`, `text-align: start`) are below every floor above. `ThemeCSSEmitter` can write `color-mix()` for a translucent shadow; no registered theme has one.

### Breakpoints

All from the emitted CSS, and a test fails if this section disagrees with it.

- **600 px** (`@media (max-width: 600px)`, a viewport width, in `components.css`): the table stacks to labelled blocks (each cell carries `data-label`), `dt-col-*` grid helpers go to one column, the page shell becomes one column with a wrapped navigation row, and `dt-list--columns` becomes one column. It is the width at which `SwissTable` stacks. **It cannot be a custom property** (`var()` is not substituted inside a media query), so an app that writes its own responsive rules should use the same value, `@media (max-width: 600px)`; in Swift it is `BrowserSupport.Breakpoints.narrowMediaQuery`, and a test holds it to the emitted CSS.
- **30 rem** (`@container (max-width: 30rem)`, the width of the key and value list's container): a key and value row puts the label above the value.
- **88 base units = 352 px** (`--card-min`, at the 4 px base unit): the narrowest a card is in the `dt-cards` auto-fit grid, so three cards fit a 1200 px page with its padding and a phone gets one column. It is the same in every theme; the theme changes only the card's chrome.
- Tumblr block only: **960 px** and **720 px** (`@media (max-width: ...)`).

## Swiss components for SwiftUI (0.10.0, 0.11.0)

`DesignTokensSwiftUI` has the pieces an app would otherwise write itself: UI type roles (`.uiText(.label)`, `.uiFigure()`), `SwissCard`,
`OutlinedChip`, `SwissSection`, `KeyValueRow`, `SwissSegmentedControl`, `StatusBanner`, `SwissTable`, and Toggle, LabeledContent, Form and text
field styles. All read the theme, the colour scheme, the contrast setting and Dynamic Type, and none holds a literal colour or radius.
`AppPalette(background:surface:)` lets an app declare its own window, which charts then sit on and ink is measured against.
`swift run swiss-gallery <folder>` renders every component, light and dark. API, what SwiftUI does and does not allow for tables and form
controls, and ownership: `project/docs/technical/SwissComponents.md`.

0.11.0 closes what the dashboard still hand-rolled after porting onto 0.10.0: `UIRole.section` and `.cardTitle` with a measured size ordering (a Mac section heading is 17 pt, a phone's 20),
`SwissCard` borderless in a `SwissEqualGrid` with the footer pinned to the row's bottom, `SwissFlowLayout`, a `SwissTable` with selection, copy, tree rows, `sortBy` and a stacked
layout for phone widths and accessibility sizes (and cells that draw nothing no longer shift the columns), `Adaptive.dynamicColor`, square `OutlinedChip`s, `.caution` and `.warning` statuses, and a
`SwissSegmentedControl` that becomes a menu rather than break words. `swift run swiss-gallery <folder>` draws the new scenes; `GalleryRenderTests` draws them on an iOS Simulator.
Proposal: `project/plans/proposals/2026-11-10_UIGaps0110.md`.

## Terminal and slides (0.7.0)

`themes/<id>.ansi.txt` is a terminal role table, one block per colour slot (`light`, `light-increased`, `dark`, `dark-increased`; a
light-only theme has the first two, a fixed-dark theme the last two). Each row is `role kind hex truecolor c256 c16 glyph ascii note`,
where the three colour columns are SGR parameter lists (`38;2;255;141;40`, `38;5;208`, `33`; `48;...` for the `background` and
`surface` rows). The 256-colour column is the nearest xterm entry from indices 16 to 255 (cube, then greys; never the user's own
0 to 15), the 16-colour column the nearest of xterm's default sixteen, both by squared RGB distance with ties to the lowest index.
Status is never colour alone: `positive` is `▲` (ASCII `+`), `negative` `▼` (`-`), `warning` `!`; an absent value is `.`. It is a role
table, not a terminal theme: it does not set the terminal's background.

`themes/<id>.slides.txt` is the colour and font list for Keynote and PowerPoint templates (hex per slot, series, then the fifteen type
roles with font chain SF Pro Text, SF Pro, Helvetica Neue, Helvetica, Arial). `themes/<id>.slides.colors.<appearance>.xml` (light, dark) and
`themes/<id>.slides.fonts.xml` are DrawingML `<a:clrScheme>` and `<a:fontScheme>` documents, the roots of PowerPoint's Theme Colors and
Theme Fonts files; the mapping (dk1 to lt2, accent1 to 6, hlink) is in the `SlidesEmitter` documentation. They have been checked for
well-formedness and mapping, not opened in Keynote or PowerPoint, and no `.thmx` / `.potx` package or Keynote theme is produced.

## The Tumblr full theme (0.7.0)

The block alone gives a blank page: Tumblr's *Edit HTML* needs a whole document. `Generated/themes/swiss.tumblr.html` is one: the
markup the block's selectors expect, every Tumblr tag block the blog uses, and the generated block (with its stamp) in the single
`<style>`. Replace the editor's contents with it. The blog's own values are not in the package: the wordmark (default Tumblr's `{Title}`),
a parent-site link, a `rel="me"` link and a Google Tag Manager id (default none) are options of `design-tokens tumblr --full`, validated.
`check-blog` reads the stamp from this document too. It has not been opened in Tumblr's editor by this tooling.

## The Tumblr block

```
swift run design-tokens tumblr --theme swiss      # writes Generated/themes/swiss.tumblr.css (also written by `emit`)
swift run design-tokens tumblr --full --wordmark NAME --gtm GTM-XXXX --parent-url URL --parent-label TEXT --rel-me URL   # also the full theme document, tumblr.html
swift run design-tokens check-blog                # is the blog's pasted block the current one? (the theme, template and hash decide; the package version alone does not)
```

The blog gets a generated block that the owner pastes by hand into the Tumblr theme's `<style>` element (not a linked
stylesheet). It is CSS only: the theme's colour for light, dark and `prefers-contrast: more`, rule weights, grid, type
roles and fonts as custom properties, then fixed selectors for the blog's classes and Tumblr's own, with no colour
literal. The Tumblr tags, the analytics snippet and the `<link>` elements stay in the theme HTML, which the block
assumes keeps its class names (listed in the block's header). The block's first lines carry a stamp (theme id,
DesignTokens version, template revision, hash of the theme's canonical JSON), also in `--theme-stamp`.

`check-blog` loads the live page in headless Chrome (a plain `curl` gets 403 and a bot challenge, so it needs a local
Google Chrome), reads the stamp from the `<style>` elements and compares it with the current theme. Exit codes: 0
current, 1 stale, 2 unstamped, 3 garbled stamp, 4 page could not be read. `--html-file` checks a saved page instead.
As of 2026-11-09 the live blog already uses the Swiss draft but has no stamp, so it reports unstamped. Nothing has been
rendered in Tumblr or pasted by this tooling.

## Requirements

Swift 6.2 or later.
