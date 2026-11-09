# DesignTokens

The design system's values, held once as typed Swift and generated for every surface that cannot import Swift.

**Status:** pre-release (`0.x`, latest 0.3.0; 0.4.0 in preparation). Phase 1 of `project/master_plan.md`.

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

## Requirements

Swift 6.2 or later.
