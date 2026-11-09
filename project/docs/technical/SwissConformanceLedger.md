# Swiss conformance ledger

Owner decision 2026-11-09: Swiss keeps Apple's system colours for the series and the accent, and the palette is not re-stepped.
**Exception, decided the same day:** Swiss's `positive` and `negative` (gain and loss, text and marks) are the darker text-safe pair
and are deliberately NOT system colours (light #268053 / #DB2C2C, dark #30D158 / #FF4245, Increase Contrast light #0E6B3A / #B81D1D and
dark #4AD968 / #FF6165). They reach 4.5:1 as text on the background and the card surface in all four appearances, so the ledger has no row
for them; `success` and `destructive` (the system colours) are unchanged and no longer reach Swiss's roles. The dataviz
method (`validate_palette.js`) finds the following. These are exact measurements. Since 0.5.0 they are held in
`Theme.swiss.conformance` (`Sources/DesignTokens/Themes/ThemeLedgers.swift`) and checked against the Swift
`ThemeValidator`: a finding that appears, changes value (at the validator's displayed rounding) or disappears fails a test, so the finding is neither hidden nor silenced. The 0.4.0 rows are
also pinned by `Tests/DesignTokensTests/SwissConformanceLedgerTests.swift`. Measured against the Swiss
`background` (#FAFAFA light, #101112 dark).

## The 0.4.0 rows (unchanged; now reproduced by the Swift validator)

| Check | Appearance | Failing slots | Measured | Threshold |
|---|---|---|---|---|
| OKLCH lightness band | light | yellow #FFCC00 | L 0.865 | 0.43 to 0.77 |
| OKLCH lightness band | dark | orange #FF9230 / green #30D158 / yellow #FFD600 / cyan #3CD3FE | L 0.762 / 0.756 / 0.885 / 0.808 | 0.48 to 0.67 |
| Mark contrast vs surface | light | orange / green / yellow / cyan | 2.21 / 2.13 / 1.45 / 2.07 | 3:1 |

Passing: chroma floor; adjacent colour-vision separation (worst adjacent dE 22.4 light, 24.1 dark) and
normal-vision adjacent separation (37.8, 36.1), measured in Swift in 0.5.0 and equal to the JavaScript run
recorded in the proposal; dark contrast vs surface at least 3:1.

## Rows first measured in 0.5.0 (25 findings in all, 15 failing; was 31 before the text-safe `positive` and `negative`)

The 0.5.0 validator measures more than the 0.4.0 tests did. These are the additional findings on Swiss, recorded
rather than fixed:

| Check | Appearance | Finding |
|---|---|---|
| Mark contrast vs the card surface | light | orange 2.31, green 2.22, yellow 1.51, cyan 2.16 (3:1) |
| ~~Text contrast (4.5:1)~~ | ~~light~~ | ~~`positive` 2.13 on background, `negative` 3.42~~ **Removed 2026-11-09:** the roles are now text-safe (4.68 / 4.56 on the background); four light rows and two Increase Contrast rows (4.35, 4.36) are gone |
| Mark contrast (3:1) | light | `accent` 2.21 on background, 2.31 on the card surface |
| Sequential ramp, darkest step on the dark surface | dark | 1.99:1 against a 2:1 floor (the ramp is the light one reversed: derived, not measured) |
| Increase Contrast on, light | lightIncreased | ~~`positive` 4.35 and `negative` 4.36 on background (4.5)~~ (removed 2026-11-09: now 6.32 and 6.23); `onAccent` on the increased accent 4.12 (fail, 4.5) |
| OKLCH lightness band, Increase Contrast on, dark | darkIncreased | all eight above 0.67: orange 0.789, indigo 0.769, green 0.784, purple 0.781, yellow 0.904, blue 0.756, red 0.698, cyan 0.836 |

The increased-contrast dark values are lighter than the standard dark ones, so they are further outside the dark
band: increasing contrast against the dark surface and staying inside a lightness band pull opposite ways.

Required of consumers: orange, green, yellow and cyan (`SwissLedger.directLabelSlots`: the slots with a lightness-band or
3:1 mark-contrast row in the light or standard dark appearance, derived from the ledger) are labelled directly or have their
values printed; colour is never the only encoding. With Increase Contrast on in dark, every one of the eight series has a
`darkIncreased` band row, so there all eight need that treatment (`SwissLedger.slotsNeedingDirectLabels(in: [.darkIncreased])`). Lowercase names are `Palette.seriesNames`.
