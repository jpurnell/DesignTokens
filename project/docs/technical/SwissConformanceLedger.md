# Swiss conformance ledger

Owner decision 2026-11-09: Swiss keeps Apple's system colours and the palette is not re-stepped. The dataviz
method (`validate_palette.js`) finds the following. These are exact measurements, pinned by
`Tests/DesignTokensTests/SwissConformanceLedgerTests.swift`, which fails on any change, so the finding is
neither hidden nor silenced. Measured against the Swiss `background` (#FAFAFA light, #101112 dark).

| Check | Appearance | Failing slots | Measured | Threshold |
|---|---|---|---|---|
| OKLCH lightness band | light | yellow #FFCC00 | L 0.865 | 0.43 to 0.77 |
| OKLCH lightness band | dark | orange #FF9230 / green #30D158 / yellow #FFD600 / cyan #3CD3FE | L 0.762 / 0.756 / 0.885 / 0.808 | 0.48 to 0.67 |
| Mark contrast vs surface | light | orange / green / yellow / cyan | 2.21 / 2.13 / 1.45 / 2.07 | 3:1 |

Passing: chroma floor; adjacent colour-vision separation (worst adjacent dE 22.4 light, 24.1 dark, from the
JavaScript validator run recorded in the proposal; not re-measured in Swift until 0.5.0); normal-vision
adjacent separation (37.8, 36.1, same source); dark contrast vs surface at least 3:1 (tested).

Required of consumers: orange, green, yellow and cyan (`SwissLedger.directLabelSlots`) are labelled directly
or have their values printed; colour is never the only encoding. Lowercase names are `Palette.seriesNames`.
