# DesignTokens

The design system's values, held once as typed Swift and generated for every surface that cannot import Swift.

**Status:** pre-release (`0.x`, latest tag 0.5.0; 0.6.0 in preparation on `feature/emitters-swiftui-0.6.0`, untagged). Phase 1 and 1b of `project/master_plan.md`.

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
  `ThemeCodec`. Findings: `project/docs/technical/ThemeConformance.md`.

- **Emitters and SwiftUI adapter** (0.6.0, additive): `ThemeCSSEmitter` and `ThemeJSONEmitter` write one scoped CSS file
  (`[data-theme-name="<id>"]`: light, `prefers-contrast: more`, dark, and the contrast-dark blocks) and one canonical JSON
  file per theme into `Generated/themes/`; `tokens.css` and `tokens.json` are byte-identical to 0.5.0. A second library,
  `DesignTokensSwiftUI` (`import DesignTokensSwiftUI`), turns a `Theme` into a `ChartStyle`: SwiftUI colours, fonts,
  rule weights (including the title rule), flags, layout, marks and number formats for the current appearance and
  Increase Contrast, with `EnvironmentValues.theme`, `ChartStyleReader` and `.chartTheme(_:)`. See "SwiftUI" below.

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
`Generated/themes/<id>.css` and `<id>.json`. All are committed, and a test fails if any differs from a fresh emit or if
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

## Requirements

Swift 6.2 or later.
