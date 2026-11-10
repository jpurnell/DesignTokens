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

## 2b. Text colours (0.9.0)

Status words, secondary captions and the like are **text**, not chart series. Declare them as `textRoles`, on the
backgrounds you actually draw them on, and read them through an enum:

```swift
enum Role: String, AppTextRole { case secondary, failure, success }

enum AppColours: AppPaletteSource {
    typealias TextRoles = Role
    static let palette = AppPalette(
        id: "my-app",
        textRoles: [NamedAdaptive("secondary", light: 0x5C5C61, dark: 0xAEAEB2),
                    NamedAdaptive("failure", light: 0xC4161C, dark: 0xFF6961),
                    NamedAdaptive("success", light: 0x1B7030, dark: 0x30D158)],
        textSurfaces: TextSurfaces(light: [0xFFFFFF, 0xF2F2F7, 0xECECEC], dark: [0x000000, 0x1C1C1E, 0x323232]))
}
// in a view: ChartStyle.color(_ adaptive:) turns it into a dynamic colour
let failure = AppColours.text(.failure)
```

- Each role is measured as text, 4.5:1, against **every** surface listed for the appearance. Nothing chart-shaped applies:
  no lightness band, separation or `labelRequired`. A palette of text roles only has no ledger to keep.
- Leave `textSurfaces` out and the roles are measured on Swiss's `background` and `surface`. Swiss's own text-safe colours hold
  4.5:1 only there (negative is 4.03 on `#ECECEC`, dark negative 3.73 on `#323232`), which is what `textSurfaces` is for.
- A role named `ink`, `secondaryInk`, `link`, `positive`, `negative` or `warning` overrides Swiss's; any other name is an extra of the
  composed theme.
- `validate()` fails if an enum case has no declared colour or a declared colour has no case, so the enum the views read is the set that
  was validated. A colour typed as a literal in a view is the drift checker's to find, not the package's.
- Text is held to 4.5:1 always (`meetsAA(on:largeText:)` exists for your own large-text checks, and no role is large).
- A status colour is not told apart from the others by colour alone; print a word and a glyph with it. That is your rule, no longer a ledger row.

**Contrast without writing WCAG:** `RGB.contrastRatio(with:)`, `RGB.meetsAA(on:largeText:)` and `RGB.relativeLuminance`, the same
function the validator uses. **If your app has its own `RGB` type, delete it:** it shadows the package's with no error, and
`DesignTokens.RGB` does not work as a qualifier (the package's `DesignTokens` enum shadows the module name), so a file that needs both has no
spelling for the package's.

## 2c. Your own window and surfaces (0.10.0)

An app that draws on its own window grey declares it, so charts sit on it and the theme's text colours are measured on it:

```swift
AppPalette(id: "my-app",
           background: Adaptive(light: ColorValue(RGB(rgb: 0xECECEC), alpha: 0), dark: ColorValue(RGB(rgb: 0x323232), alpha: 0)),
           surface: Adaptive(light: 0xFFFFFF, dark: 0x1C1C1E),
           textRoles: [NamedAdaptive("secondaryInk", light: 0x5C5C61, dark: 0xAEAEB2)],
           textSurfaces: TextSurfaces(light: [0xFFFFFF, 0xF2F2F7, 0xECECEC], dark: [0x000000, 0x1C1C1E, 0x323232]))
```

`palette.theme()` is Swiss with those surfaces (no hand-cloned theme). `validate()` measures Swiss's `ink`, `secondaryInk` and `link` against the
declared surfaces (a `textContrast` finding names the one that cannot read), and the text roles on them when `textSurfaces` is `nil`. A
translucent background is measured composited over white (black in dark), so say the real greys in `textSurfaces`. A surface with no dark
value makes the composition light only, as everywhere else. The marker contract is unchanged (two more labelled arguments of the one call).

## 2d. Components (0.10.0)

Type roles, card, chip, section, key/value rows, segmented control, banner, table and form styles are in `DesignTokensSwiftUI`; an app writes
none of them. `project/docs/technical/SwissComponents.md` has the API, what SwiftUI allows for tables and form controls, and what the dashboard deletes.

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
ledger and the one-line test above; `DashboardShapedExampleTests.swift` is the text-role example (the dashboard's seven roles on its own
backgrounds, with the 0.8.0 series form and its 22 chart rows kept as the "before"). The mark-contrast rows are checked against the WCAG formula from the stated hex values.
