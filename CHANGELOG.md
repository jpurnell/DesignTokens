# Changelog

## [Unreleased]

## [0.2.0] - 2026-11-09

### Added
- `ColorToken.success.dark` (#30D158) and `.destructive.dark` (#FF4245), measured on macOS 27.2.
  `ColorToken.unmeasuredDark` is now empty.
- `Palette.seriesDark`: the eight system colours in the dark appearance, measured. Emitted as `--series-N`
  in the dark CSS block and as `palette.seriesDark` in the JSON.
- `Palette.sequentialDark`: the sequential ramp reversed (derived), emitted as `palette.sequentialDark`.

### Not included
- Increased-contrast values: system colours report the same value under the increased-contrast
  appearances from a command-line process, so they cannot be measured here.
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
- Palette tests: validated order, adjacent OKLab distance of at least 15, contrast of label on background.

[Unreleased]: https://github.com/jpurnell/DesignTokens/compare/0.2.0...HEAD
[0.2.0]: https://github.com/jpurnell/DesignTokens/compare/0.1.0...0.2.0
[0.1.0]: https://github.com/jpurnell/DesignTokens/releases/tag/0.1.0
