# How an app adopts the tokens

An app keeps its own colours (WineTaster's wine types, a team palette) on Swiss's structure: rules, type, spacing,
surfaces, ramps, text-safe status colours. It declares those colours in **one file**, validates them, and writes no
colour anywhere else. Design and contract: `project/plans/proposals/2026-11-10_AppPaletteAdoption.md`.

## 1. Declare the palette (one file)

```swift
import DesignTokens

enum WinePalette: AppPaletteSource {          // the marker the drift checker looks for
    static let palette = AppPalette(
        id: "winetaster",
        accent: Adaptive(light: 0x7F0017, dark: 0xE0788A),
        onAccent: Adaptive(light: 0xFFFFFF, dark: 0x1A0006),   // a dark accent needs its own
        series: [NamedAdaptive("red", light: 0x7F0017, dark: 0xE0788A),
                 NamedAdaptive("light white", light: 0xE9D98B, dark: 0xE9D98B),
                 NamedAdaptive("full white", light: 0xE0D07E, dark: 0xE0D07E)],
        seriesOrder: .entityOrder(labelRequired: [SeriesPair("light white", "full white")]),
        maxSeriesPerChart: 5,                                   // a per-chart limit, not a palette size
        labelTogether: [SeriesPair("light white", "full white")], // your own rule, whatever the numbers say
        conformance: .strict)                                   // until step 3
}
```

- Series have **names** (the entities': wine types, teams). `seriesOrder` is `.validatedOrder` when you chose the
  order so neighbours separate, `.entityOrder(labelRequired:)` when the order is the entities' (every pair is then
  checked, and each pair that fails must be listed).
- Supply a `dark` value for everything or for nothing. A palette with no dark values is light only (Swiss's dark
  surfaces are not used for it); a palette with some is demoted the same way, and no dark value is invented.
- Optional: `sequential` and `diverging` ramps (`Ramp(packedLight: [...], packedDark: [...])`), measured when supplied;
  `lightIncreased` / `darkIncreased` per colour, which adds the increased-contrast appearances.
- Exactly one `AppPalette(` call, with a literal `id:`, and one type conforming to `AppPaletteSource`, per file.
  This file is the only one in the app allowed colour literals; the drift checker exempts it by that conformance.

## 2. Test it from your own test target

```swift
@Test func winePaletteConforms() {
    let result = WinePalette.validate()          // Swiss by default; validate(on: .house) for another theme
    #expect(result.isConformant, "\(result.report)")
}
```

`validate()` composes the palette on Swiss and measures the app's accent, series and ramps in light, dark and each
increased-contrast appearance it has values for: lightness band, chroma, colour-vision and normal separation, mark contrast
on the background and the card surface, accent text contrast. `isConformant` means the findings are *exactly* the
palette's ledger. `report` prints every finding as `severity check | appearance | subject: measured, threshold`.

## 3. Ledger what you keep

Start with `conformance: .strict`, run the test, and read the report. For each finding either change the colour or
keep it deliberately: paste `result.ledgerSource` into `conformance:` and review each row as a decision. From then on
the test fails if a finding appears, if a ledgered value moves, or if one disappears without the ledger being updated.
There is no suppression. Pale colours (WineTaster's whites) will ledger as low mark contrast and a failing pair: the
remedy is a rule for charts (label directly, print values), which is what `labelTogether` and `labelRequirements` state.

## 4. Charts: the rules as code

```swift
WinePalette.palette.chartViolations(plotting: names, labelled: labelledNames)
// [.tooManySeries(plotted: 6, max: 5)], [.unknownSeries("claret")], [.unlabelledPair(light white / full white)]
```

## 5. Web and terminal output (optional)

`WinePalette.palette.theme()` is Swiss with the app's colours (`id` `swiss+winetaster`); give it to `ThemeCSSEmitter`,
`ThemeJSONEmitter` or `ANSIEmitter`. The files are the app's output, generated, not edited, and never hold hand-written colours.

## The worked example

`Tests/DesignTokensTests/AppPaletteAdoptionTests.swift` holds a WineTaster-*shaped* palette (not WineTaster's), its reviewed
ledger and the one-line test above. The mark-contrast rows are checked against the WCAG formula from the stated hex values.
