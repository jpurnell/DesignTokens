# DesignTokens

The design system's values, held once as typed Swift and generated for every surface that cannot import Swift.

**Status:** pre-release (`0.x`, latest tag 0.4.0; 0.5.0 in preparation on `feature/themes-validator-0.5.0`, untagged; the Tumblr block and `check-blog` are on `feature/tumblr-emitter`, unreleased). Phase 1 and 1b of `project/master_plan.md`.

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
- **Palette** (`Palette`): eight series colours in a fixed order, validated for adjacency and colour-vision separation (it fails the dataviz lightness band for yellow in light and for orange, green, yellow and cyan in dark, and orange, green, yellow and cyan are under 3:1 on the light surface, so those slots need direct labels: see `SwissLedger`), in light (`series`) and dark
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
  and text contrast, ramps, structure), cross-checked against the script under Node when Node and the script are
  present (`JavaScriptCrossCheckTests`; the test is skipped with a visible reason otherwise). `Theme.conformance`:
  `strict`, or a `ledger` / `legacy` ledger of exact measurements that fails on any change (not a suppression).
  `AppPalette` `entityOrder`: every failing pair must be listed in `labelRequired` and becomes a mandatory direct
  label (`ThemeValidator.requiresDirectLabels`). `Theme.all`: Swiss, House, Princeton, FT and Economist (with
  authored dark variants, our interpretation of those houses), and the four legacy BusinessMath-UI themes (the
  Default as a labelled snapshot of the system colours), each a `Theme` value that round-trips through
  `ThemeCodec`. Findings: `project/docs/technical/ThemeConformance.md`. No emitters for themes yet.

Not yet here: increased-contrast values for the roles listed above, and a dark diverging ramp.

## Platforms

Foundation-only, expected to build on Linux, untested: no Linux build has been run. Foundation-only is a guard against
SwiftUI imports in the core, not a commitment to a Linux GUI (there is none; a future GUI path that consumes the
`Theme` is possible but out of scope). It builds and is tested on macOS. It holds data, not `Color` values: on Apple
platforms a resolver should use the system's own colours (the HIG says not to hard-code them), and the
values here are a labelled snapshot (`Snapshot.systemRelease`) for web, SVG, slides and spreadsheets.

## Generating the files

```
swift run design-tokens Generated
```

writes `Generated/tokens.css` and `Generated/tokens.json`. Both are committed, and a test fails if either
differs from a fresh emit, so regenerate and commit after changing a value.

The CSS has `@media (prefers-contrast: more)` blocks (light, then `and (prefers-color-scheme: dark)`, then the
explicit dark selectors), ordered so the dark scheme wins over the light contrast block and the dark contrast
block wins over the standard dark values.

## The Tumblr block

```
swift run design-tokens tumblr --theme swiss      # writes Generated/themes/swiss.tumblr.css
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
