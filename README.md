# DesignTokens

The design system's values, held once as typed Swift and generated for every surface that cannot import Swift.

**Status:** pre-release (`0.x`, latest tag 0.5.0; 0.6.0 is unreleased and untagged; the Tumblr block and `check-blog` are merged into it on `merge/tumblr-into-0.6.0`; 0.6.0 carries the fixes from an independent review of 0.4.0 and 0.5.0: see `CHANGELOG.md`). Phase 1 and 1b of `project/master_plan.md`.

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
  measured); the diverging ramp (no dark ramp yet: its tints would have to be invented); and Princeton
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
  and text contrast, ramps, structure), cross-checked under Node against a vendored, hash-pinned copy of the script
  (`Tests/DesignTokensTests/Vendored/`, `JavaScriptCrossCheckTests`; skipped with a visible reason when Node is absent), and its
  thresholds are read out of the script's text by a test that needs no Node. `Theme.conformance`:
  `strict`, or a `ledger` / `legacy` ledger of the exact findings (measured values at the validator's displayed rounding):
  a finding that appears, disappears or changes value fails a test; a ledger is not a suppression. A colour change that
  moves no finding is not caught by the ledger: it is caught by the committed `Generated/themes/` files (0.6.0), which a
  test compares with a fresh emit.
  `AppPalette` `entityOrder`: every failing pair must be listed in `labelRequired` and becomes a mandatory direct
  label (`ThemeValidator.requiresDirectLabels`). `Theme.all`: Swiss, House, Princeton, FT and Economist (with
  authored dark variants, our interpretation of those houses), and the four legacy BusinessMath-UI themes (the
  Default as a labelled snapshot of the system colours), each a `Theme` value that round-trips through
  `ThemeCodec`. Findings: `project/docs/technical/ThemeConformance.md`.

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

Not yet here: increased-contrast values for the roles listed above, and a dark diverging ramp.

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
swift run design-tokens list                      # the registered theme ids
```

writes `Generated/tokens.css` and `Generated/tokens.json` (the default look) and, for every theme in `Theme.all`,
`Generated/themes/<id>.css` and `<id>.json`, plus Swiss's Tumblr block `themes/swiss.tumblr.css`. All are committed, and a test fails if any differs from a fresh emit or if
`Generated/` holds a file that is not generated, so regenerate and commit after changing a value.

A theme's CSS is scoped to `[data-theme-name="<id>"]`, so several themes can coexist on a page. A light-only theme has no
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

## The Tumblr block

```
swift run design-tokens tumblr --theme swiss      # writes Generated/themes/swiss.tumblr.css (also written by `emit`)
swift run design-tokens check-blog                # is the blog's pasted block the current one?
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
