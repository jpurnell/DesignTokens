# Session summary 2026-11-09: emitters and the SwiftUI adapter, 0.6.0 (DesignTokens half)

Branch `feature/emitters-swiftui-0.6.0` (from `main` at tag 0.5.0), untagged, unpushed. BusinessMath-UI was not touched.

- `ThemeCSSEmitter` / `ThemeJSONEmitter` / `Generator`; `design-tokens emit [--all | --theme id] [dir]` and `list`.
  `Generated/themes/` holds 18 files (CSS and JSON for each of the nine themes). `tokens.css` and `tokens.json` are
  byte-identical to 0.5.0 (SHA-256 pinned in `ThemeEmitterTests`).
- `DesignTokensSwiftUI`: `ChartStyle`, `ChartText` / `FontPlan`, `\.theme` and `\.chartStyle`, `ChartStyleReader`,
  `.chartTheme(_:)`, `.chartText(_:in:)`. Environment default is `Theme.legacyDefault` on purpose.
- Model additions found by reading BusinessMath-UI's Charts and Editorial sources: `MarkSpec.areaOpacity`, `.fillOpacity`,
  `.detailLineWidth`; `LayoutSpec.annotationRadius`; `TypeRole`, `NumberKind`, `Ramp.sample`, `ColorValue.interpolated`.
- TDD: both test groups were written first and failed to compile (a red tree cannot be committed: the pre-commit hook builds
  and runs the gate). The gate blocked the first commit attempts, for `try?`, `print`, `String(format:)`, a newline `split`,
  float `==` and weak assertions; all fixed in code, none suppressed. Mutation checks: a skewed green channel and a swapped
  system colour both fail the SwiftUI tests.
- Verified: `swift test` 132 + 27 tests; gate 0/0; xcodebuild builds of the SwiftUI target for iOS, iOS Simulator, visionOS,
  visionOS Simulator, tvOS, watchOS, macOS.

Open: Linux unbuilt; iOS and visionOS built, not run; Increase Contrast under system-colour deferral untestable
(`colorSchemeContrast` is read-only); no Dynamic Type; the BusinessMath-UI conversion (proposal 6.1) and Visual checkpoint 1.
Next: BusinessMath-UI conversion on its own branch, pinning 0.6.0 after the tag.
