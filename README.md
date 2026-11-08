# DesignTokens

The design system's values, held once as typed Swift and generated for every surface that cannot import Swift.

**Status:** pre-release (`0.x`). Phase 1 of `project/master_plan.md`.

## What it holds

- **Colour roles** (`ColorToken`): the nine SwiftGUIKit roles plus `onAccent` and `link`, each with a light and a dark value.
  A dark value that has not been measured on the snapshot release is `nil` and listed in
  `ColorToken.unmeasuredDark`; it is not guessed. Today that is `success` and `destructive`.
- **Palette** (`Palette`): eight series colours in a validated order, the sequential and diverging ramps,
  and Princeton orange as a custom accent.
- **Metrics** (`Rule`, `Grid`, `Radius`): rule weights 1, 3 and 8 pt; a 12-column grid with a 16 pt gutter
  and a 4 pt base; container radius 0, control radius 4 pt.

Not yet here: the type scale, and increased-contrast values (neither has been measured or settled).

## Platforms

Foundation only. Builds on macOS, iOS, visionOS and Linux. It holds data, not `Color` values: on Apple
platforms a resolver should use the system's own colours (the HIG says not to hard-code them), and the
values here are a labelled snapshot (`Snapshot.systemRelease`) for web, SVG, slides and spreadsheets.

## Generating the files

```
swift run design-tokens Generated
```

writes `Generated/tokens.css` and `Generated/tokens.json`. Both are committed, and a test fails if either
differs from a fresh emit, so regenerate and commit after changing a value.

## Requirements

Swift 6.2 or later.
