# Theme conformance (0.5.0)

Every registered theme (`Theme.all`) carries a `conformance`: `strict` (no findings), `ledger` (the owner keeps the
theme despite its findings) or `legacy` (BusinessMath-UI's four legacy themes, carried as they are). A ledger is
the exact list of findings, in `Sources/DesignTokens/Themes/ThemeLedgers.swift`. `ThemeValidator.deviations(of:)`
returns every way the validator's findings and the ledger disagree (a new finding, a changed value, a vanished
finding) and `everyRegisteredThemeValidates` fails on any. Nothing in a ledger is a suppression, and nothing was
tuned to reduce it.

What a ledger pins, exactly: each finding's check, appearance, subject and measured value at the validator's displayed
rounding (3 decimals for lightness and chroma, 1 for colour-vision and normal-vision distance, 2 for contrast), and its threshold.
It does not pin a colour: a change that moves no finding (an ink that stays above 4.5:1, a surface that stays under the same
threshold) leaves the ledger green. The whole theme, every colour and structure value, is pinned by the committed
`Generated/themes/<id>.css` and `.json` (0.6.0): `ThemeEmitterTests.generatedFilesMatchCommitted` fails when a value
changes until the files are regenerated and committed, a deliberate step. On 0.5.0, before those files existed, five single-value mutations
(FT dark ink, FT light muted, legacy Financial `info`, FT `marks.lineWidth`, House `surface`) left every test green; on 0.6.0 all five fail
that test. `ConformanceTests.legacyLedgersAndThreeSeriesArrays` writes out only three legacy series arrays; there is no BusinessMath-UI
source in this repository for a test to compare the rest with. Method: the dataviz skill's `validate_palette.js`, ported to Swift and cross-checked against
the script under Node (`JavaScriptCrossCheckTests`).

Findings by theme (a finding is a measured result short of a threshold; "fail" breaks the method, "warn" is legal only
with labels or a table):

| Theme | Kind | Findings | Failing | What |
|---|---|---|---|---|
| swiss | ledger | 28 | 14 | see `SwissConformanceLedger.md`; 31 before 2026-11-09, when `positive` and `negative` became the text-safe pair (not system colours) and their six rows went; then the chart alignment dropped the orange dark ramp row and added four `muted` mark-contrast rows (1.84, 1.93, 2.34, 2.20) |
| house | ledger | 9 | 3 | cyan 2.98 on background (mark); `secondaryInk` 4.02 (text); status colours under 4.5 as text; sequential ramp lightest step 1.08:1 on white |
| princeton | ledger | 10 | 0 | orange 2.9, sky 2.15, teal 2.09, periwinkle 2.27 under 3:1 on the light surface (and sky, teal, periwinkle on the card surface); `accent` 2.9; `muted` 1.84 and 1.93 (the neutral mark grey it inherits from Swiss). No status rows: it has Swiss's text-safe gain and loss (12 before the chart alignment, 14 with `muted`, 10 once it followed Swiss) |
| ft | ledger | 10 | 3 | light: purple L 0.407 (band 0.43), teal chroma 0.086 (0.10), orange 2.15 under 3:1, sequential lightest step 1.09:1; authored dark: claret 2.89 and purple 2.85 on the card surface (3:1) |
| economist | ledger | 18 | 6 | light: yellow L 0.80, green chroma 0.094, plum 0.086, cyan 2.25 and yellow 1.89 under 3:1, `secondaryInk` 3.48, sequential 1.36:1; authored dark: blue, yellow and plum 2.8 on the card surface |
| legacy-default | legacy | 64 | 47 | ten series (method allows eight); yellow band; blue-green-orange adjacency is a colour-vision finding (green / orange 6.6 light, 4.9 dark, 3.4 with Increase Contrast on); rainbow `sequential`, `volatility` and `sharpe` ramps fail monotone, step gap and single hue |
| legacy-dark | legacy | 23 | 23 | ten series; all ten above the dark band (0.70 to 0.89); green / orange 3.6 under deutan (#4CE666 / #FFB24C); rainbow ramps |
| legacy-financial | legacy | 19 | 13 | blue L 0.424, bronze and slate chroma floor, gold 2.57 under 3:1; ramps |
| legacy-accessible | legacy | 15 | 10 | blue L 0.309, grey and teal chroma, olive 2.27 under 3:1; ramps. It advertises colour-blind safety: it passes the colour-vision separation check (9.6 worst adjacent, above 8) and fails the band and chroma checks |

FT and Economist divergences (our authored interpretation; none of it was compared with the houses' own charts, and nothing
was rendered): see the proposal's "Decisions 2026-11-09" and "Corrections found while implementing 0.5.0".
