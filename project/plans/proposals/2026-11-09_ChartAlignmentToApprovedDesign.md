# Chart alignment to the approved design (Swiss and Apple, "Hybrid" chart)

**Status:** The DesignTokens side of section 4 is implemented on branch `feature/chart-alignment-spec` (unreleased 0.6.0, see "Decisions 2026-11-09" and "Implementation notes" at the end); the BusinessMath-UI side (sections 5.3 to 5.5: renderers, views, `Emphasis`, `ReferenceLine`, heatmap values and key) is not started. The audit itself edited no source.
**Date:** 2026-11-09
**Scope:** `DesignTokens` (`Theme.swiss`, `Structure`, `ThemePalette`) and the BusinessMath-UI standard views and Editorial renderers (read on branch `design/theme-conversion`, working tree as of 2026-11-09).
**Why:** The owner approved the "Swiss and Apple" artifact (Hybrid base; value labels, target label, no series key and a source line from strict Swiss), then said the current implementation "looks much less refined than our expectations", that marks should be neutral with the accent for emphasis, and that no current sample chart has a source line.

## Verified versus inferred

| Claim type | Meaning in this doc |
|---|---|
| **Verified (artifact)** | Read from the artifact's own JavaScript (`chart(id, kind)`, lines 1637 to 1684 of the saved HTML) and CSS, and the SVG was re-rendered in headless Chrome. |
| **Verified (render)** | Rendered by me from the current code with the exact 8-quarter data (scratch package, not inside any repo). |
| **Verified (code)** | Read in source; the file is named. |
| **Measured** | Run through `ThemeValidator` (a scratch copy of `Tools/DesignTokens/Sources/DesignTokens`; output in `validator-output.txt`). |
| **Inferred** | Reasoned, not run. Marked "(inferred)". |

Caveat on what was rendered: BusinessMath-UI builds against `Tools/DesignTokens-bmui` (a detached 0.6.0 worktree), not the `fix/swiss-text-safe-gain-loss` branch checked out in `Tools/DesignTokens`. The two differ only in Swiss's text-safe gain/loss and the Tumblr emitters, so nothing in this audit depends on the difference. The validator measurements used the `Tools/DesignTokens` working tree.

## Images and scratch files (absolute paths)

All under `/private/tmp/claude-501/-Users-jpurnell-Dropbox-Computer-Development-Swift/047f6047-e3d1-463d-930e-109f43b6ba63/scratchpad/align/`

| File | What |
|---|---|
| `comparison-bar-swiss.png` | Side by side, light and dark: approved Hybrid, our Swiss standard SwiftUI bar, our Swiss Editorial SVG, our Swiss Editorial SwiftUI. Same 8 quarterly values, target 55, subtitle, source. |
| `comparison.html` | Source of the above. |
| `artifact-hybrid-light.png`, `artifact-hybrid-dark.png` | The artifact's Hybrid drawing re-rendered, system accent (#FF8D28 / #FF9230, the page's default `data-accent="sys"`). |
| `artifact-hybrid-princeton-light.png`, `artifact-hybrid-princeton-dark.png` | Same with the `:root` Princeton accent (#E77500 / #DF7105). |
| `out/ours-standard-swiss-light.png`, `out/ours-standard-swiss-dark.png` | `CategoricalChart` under `.chartTheme(.swiss)`. |
| `out/ours-editorial-svg-swiss-light.png`, `out/ours-editorial-svg-swiss-dark.png` (+ `.svg`) | `SVGChartRenderer` on `BarChart.spec(... theme: .swiss)` plus `.referenceLine(y: 55, label: "Target 55")`. |
| `out/ours-editorial-swiftui-swiss-light.png`, `out/ours-editorial-swiftui-swiss-dark.png` | `EditorialLineChartView` on the same spec. |
| `out/ours-heatmap-standard-swiss-light.png`, `out/ours-heatmap-editorial-swiss-light.png`, `out/ours-heatmap-editorial-svg-swiss-light.png` | Heatmap under Swiss. |
| `validator-output.txt` | Every measurement quoted below. |
| `render/Sources/render/main.swift`, `validator/Sources/measure/main.swift` | The scratch programs. |
| `ex/quarterly-performance__swiss.png` | The artifact's own "Examples" render (old Swiss), for contrast with its Hybrid drawing. |
| `/private/tmp/claude-501/-Users-jpurnell-Dropbox-Computer-Development-Swift/047f6047-e3d1-463d-930e-109f43b6ba63/scratchpad/contact/after/out/swiftui-standard/{grouped,line,heatmap}/swiss-light.png`, `.../heatmap/legacy-default-light.png` | Existing contact-sheet cells used for grouped bars, line and the legacy red heatmap. |

Two things the artifact data forced: it repeats the labels Q2, Q3, Q4 (a categorical axis would merge them), so ours use Q1 24 to Q4 25; and its Hybrid drawing is 360 by 300 while the library renders at 420 wide, so compare proportions, not pixels.

## 1. The approved Hybrid chart, exactly

Source: artifact `chart(id,"c")`, viewBox 360 by 300, drawn in `.chartbox` (1px solid `--hair`, `--bg` fill, 8px padding). All coordinates are SVG user units, which are points here. **Verified (artifact).**

### Colours (Colour section, Draft tokens)

| Role | Light | Dark | Note |
|---|---|---|---|
| ink (`--fg`, label) | #111214 | #F2F2EF | titles, value labels, baseline, target line |
| secondary (`--muted`, secondaryLabel) | #6A6D72 | #9A9DA2 | subtitle, axis text, source |
| background (`--bg`) | #FAFAFA | #101112 | chart and card fill |
| card surface (`--panel`) | #FFFFFF | #17181A | |
| hairline (`--hair`, separator) | #D6D8DB | #2E3033 | gridlines and card border |
| accent (system, default) | #FF8D28 | #FF9230 | latest bar. The artifact's `:root` default is Princeton #E77500 / #DF7105 until the script sets `data-accent="sys"` (it does, at load) |
| **history bar grey** | **#B9BBBD** | **#4E5053** | `color-mix(in srgb, var(--muted) 45%, var(--bg))`. Derived by me: 45% of #6A6D72 over #FAFAFA, 45% of #9A9DA2 over #101112 |

The artifact lists no increased-contrast greys. My proposal for them is in section 4.

### Type (Type section; chart roles from `chart()`)

| Element | Size | Weight | Colour | Other |
|---|---|---|---|---|
| Title | 17 | 700 | ink | letter-spacing -0.2, baseline y=36 |
| Unit and period line | 13 | 400 | secondary | baseline y=56 |
| Y axis labels | 11 | 400 | secondary | right-aligned at x = plot left - 6, baseline y+4 (centred on gridline) |
| X category labels | 11 | 400 | secondary | centred under the bar, baseline = plot bottom + 16 |
| Value labels | 11 | 700 | ink | centred, baseline = bar top - 5, one decimal ("41.2") |
| Target label | 11 | 700 | ink | x = plot left + 2, baseline = target y - 5 |
| Source | 11 | 400 | secondary | x=8, baseline y = H - 12 = 288, text "Source: example data" |

Font stack: SF Pro (`-apple-system ...`), the page's title face variable allows a serif for titles.

### Geometry

| Element | Value |
|---|---|
| Heavy rule | x=8, y=6, width 344 (full inner width), height **3**, ink, **above the title** |
| Rule bottom (y=9) to title baseline (y=36) | 27 |
| Title baseline to subtitle baseline | 20 |
| Subtitle baseline (56) to plot top (86) | 30 |
| Plot | left 30, right 12, top 86, bottom 52, so 318 by 162; value domain 0 to 70 (headroom above the top tick, 60) |
| Gridlines | ticks 0, 20, 40, 60; horizontal only; `--hair` 1pt; run plot left to plot right (x 30 to 348) |
| Baseline | ink, **1.5pt**, at value 0 (drawn over the 0 gridline) |
| Bars | 8 slots of 39.75; bar width **0.7 of slot** (27.8); square corners; centred in slot |
| Bar colour | history #B9BBBD / #4E5053; **last bar accent** |
| Target line | ink, 1pt, dash 3 3, plot left to plot right; direct label above its left end |
| Card | 1px hairline border, 8px padding, no radius, no shadow, `--bg` fill |
| Margins in the drawing | 8 leading, 8 trailing for rule, title and source (rule ends x=352); plot ends at x=348 |

### Other components in the artifact's table (Hybrid column)

Chart title "17pt bold, heavy rule above"; unit line "13pt secondary label"; bars "grey for history, accent for the latest"; value gridlines "faint horizontal hairlines"; value labels "11pt bold above every bar" (from strict Swiss); axis text "11pt secondary label, aligned to the grid"; callout "direct label on the target line" (strict Swiss); series key "none; direct labels" (strict Swiss); source "11pt secondary line under the plot" (strict Swiss). Stated limits: "Orange is 2.9:1 against the light surface ... every orange mark carries a printed value"; "One accent and greys works to three series. The eight-colour palette covers more."

### Flaws in the approved drawing itself (so we do not copy them)

1. The dashed target line strikes through the labels "52.6" and "49.9" (see `artifact-hybrid-light.png`). We should give value labels a background-coloured halo; this is a small deviation from the drawing and needs the owner's nod.
2. Gridlines end at x=348 but the rule ends at x=352, a 4pt mismatch.
3. The artifact's own "Examples" section (`ex/quarterly-performance__swiss.png`) is the old as-built Swiss: all bars accent orange, no heavy rule, odd ticks ($35, $70, $105). It is not the target; the Hybrid drawing is.
4. The hybrid grey is 1.84:1 on #FAFAFA (measured). The artifact's relief is printed values; it should be recorded in the conformance ledger rather than left implicit.

## 2. What the current implementation draws (verified by render)

See `comparison-bar-swiss.png`. In words, for the same data:

- **Standard SwiftUI (`CategoricalChart`, Swiss):** heavy rule sits **below** the title; every bar is system orange; value labels read "41 44 47 53 50 63" (rounded, so 63.4 prints as 63 and 49.9 as 50) in regular weight; no target line is possible; no card border; baseline 1pt ink; gridlines correct; source prints as given with no "Source:" prefix.
- **Editorial SVG:** rule below title; all bars orange; value labels bold ink (correct) but "41.20"; axis labels "80.00 60.00 ..." left-aligned at the margin rather than right-aligned to the gridlines; zero line is a faint grey gridline, no heavy baseline; a fixed 70pt reserve on the right leaves the plot ending well short of the rule; target line is grey (secondary ink), not ink, with a grey label; bar width hard-coded.
- **Editorial SwiftUI:** same as SVG but the target label is **dropped entirely** (the dashed line draws, "Target 55" never appears), gridlines are hairline-faint and thinner than the theme's weight, bars narrower than 0.6.
- **Dark:** same structure, orange bars (8.47:1, no problem) on #101112.

## 3. Gap table

Severity: **Critical** = the chart contradicts the approved design's central idea; **High** = visible at a glance or loses information; **Medium** = visible on comparison; **Low** = detail.

| # | Component | Approved spec | `Theme.swiss` today (field, value) | Standard views draw | Editorial renderers draw | Delta | Sev |
|---|---|---|---|---|---|---|---|
| 1 | Default mark colour | Neutral grey (#B9BBBD / #4E5053); accent is emphasis only | No mark-colour field. `palette.muted` = secondaryLabel #6A6D72 / #9A9DA2 (the text grey, 4.98:1). `ChartStyle.primary` = accent when no `primary` extra | `effectiveColor = color ?? style.primary` = orange (`CategoricalChart.swift:49`); grouped uses `style.series(i)`; time series `effectiveColor(for:)` | `style.svgSeriesHex(j)` / `color(i)` = series[0] = orange | Every mark in every chart is orange. There is no neutral default anywhere in the model or either renderer | **Critical** |
| 2 | Emphasis (which mark is accent) | Latest bar accent; others grey | Nothing | Nothing; `color:` only recolours all bars | Nothing; `Annotation.callout` draws an accent dot but no bar emphasis | The model cannot express "which mark" at all, on data side or theme side | **Critical** |
| 3 | Title rule | 3pt, ink, **above** title, inner width; rule to title baseline 27 | `rules.title = TitleRule(weight 3, position .belowTitle, colour .ink, inset 0)` | `ThemedChartFrame` honours `.aboveTitle`; Swiss says `.belowTitle`, gap `layout.gaps.title` = 4 | Both renderers honour `.aboveTitle`; same gap | One enum value (position) plus a missing separate rule-to-title gap (the 4pt title gap is far tighter than the drawing's ~8pt box gap, inferred) | **High** |
| 4 | Title / subtitle type | 17/700, track -0.2; 13/400 secondary | `type.title` 17/700 tracking 0; `subtitle` 13/400; colour via secondaryInk | match | match | Tracking -0.2 absent (immaterial); sizes and weights already right | Low |
| 5 | Value label type | 11 bold ink above every bar | `type.annotation` 11/700 ink; `labels.values = .aboveOrEnd` | `StandardValueLabel` uses the **axisLabel** role (11 regular), not `annotation` (`StandardChartStructure.swift`, `.aboveOrEnd` case) | `annotation` 11/700, tabular figures: correct | Standard views print regular weight | **High** |
| 6 | Value label text | One decimal "41.2" | `numbers.plain` = decimal, 2 places; `currency` abbreviates | `CategoricalChart.formatValue` hard-codes 0 decimals and K/M: 63.4 prints "63", 49.9 "50", 52.6 "53" | `style.format(.plain, v)` = "41.20", axis "80.00" | Standard views lose data; Editorial shows spurious zeros on labels and axis. No "minimal decimals" format exists | **High** |
| 7 | Neutral grey value and contrast | #B9BBBD / #4E5053 | none (see 1). Old `EditorialTheme.swissMuted` #B4B7BC existed on `main` and was dropped in conversion | n/a | n/a | Grey must be added. Contrast measured: #B9BBBD 1.84:1 on #FAFAFA (1.93 on card), #4E5053 2.34:1 on #101112 (2.20 card). Below the 3:1 mark guideline in both; relief is printed values. Needs a ledger row | **High** |
| 8 | Baseline vs gridline weights | Baseline ink 1.5; gridline hairline 1 | `rules.baseline` 1, `gridline` 1 | Baseline Rectangle in ink at `baselineWeight` (1): correct colour, 0.5pt light | Zero line is a gridline in `rule` grey; `editorialDrawsBaseline` only true for `.baselineOnly`/`.both` | Editorial has no heavy baseline at all; standard is 0.5pt light | **High** (Editorial) |
| 9 | Gridline direction and colour | Horizontal hairline #D6D8DB, 1pt | `layout.gridlines = .horizontalFaint`, `rules.gridline` 1, rule colour | Horizontal for columns; **vertical** for horizontal bars; weight via `AxisGridLine(stroke:)` | SVG: horizontal; none for horizontal bars (`skipYGrid`); SwiftUI: default `AxisGridLine()` ignores `rules.gridline` | Right for columns; horizontal-bar behaviour differs by renderer | Medium |
| 10 | Axis labels and alignment | 11pt secondary, right-aligned to gridline, integer ticks 0 20 40 60 | `axisLabel` 11/400; `axisSide .leading`; `axisLabelPlacement .besideAxis` | Swift Charts automatic; right alignment by system; integer ticks OK here | SVG: text anchored **start** at x=mLead (ragged against the gridlines), "80.00"; fixed 40pt gutter; ticks nice but formatted .00 | Editorial label alignment and format | Medium |
| 11 | Target / reference line | Ink 1pt dashed 3 3 with a bold ink label above the left end, baseline gap 5 | `rules.reference = LineSpec(1, [3,3])` (matches); no colour field (renderers hard-code secondaryInk); label gap not in theme | **None.** No standard view has a reference-line API. Only `MonteCarloFanChart(referenceLines:)` has one | `Annotation.referenceLine(y:label:)` exists. SVG draws secondaryInk line and label, y-3. **SwiftUI bar path ignores the label** (`barYAnnotations` pattern `.referenceLine(let y, _)`) | No API on standard views; wrong colour; label dropped in SwiftUI; label collides with value labels | **High** |
| 12 | Value labels on negative bars | Not shown in the drawing | n/a | `valueAnnotation(outside: .top)` for every bar: a negative bar's label sits at the top edge (the zero line), likely over the baseline (inferred, not rendered) | Below the bar for negatives; SVG reserves low-end room (`negativeLabelReserve`) | Standard view wrong for negatives (inferred) | Medium |
| 13 | Direct series labels / legend | None; direct labels | `labels.series = .direct` | Time series: end-of-line label in the **series colour** (orange text 2.2:1, green 2.1:1 on #FAFAFA, text should be 4.5:1). **GroupedCategoricalChart: no key and no label** (render: three colours, no way to tell series apart) | `BarChart.spec` sets `legend: .swatches` for more than one series, ignoring the theme's `.direct` | Grouped bars are unreadable as to series; direct labels fail text contrast | **High** |
| 14 | Source line | 11pt secondary under the plot, "Source: ..." | `labels.sourceLine = true`; `type.source` 11/400; `gaps.source` 10 | Param exists on Categorical, TimeSeries, Waterfall, Statistical; **not** Tornado, Proportional, MonteCarlo. Prints the string as given, no "Source:" prefix | Prints "Source: <text>" | Prefix differs between surfaces; the library's own sample builders (`Views.standardSwiftUI` in the contact harness and `Examples/ChartExportExample`, `SVGExportExample`) pass none, which is why no sample shows one | Medium |
| 15 | Card: border, padding, margins | 1px hairline border, 8px padding, 8/8 horizontal margins | `layout.margins` (top 16, leading 8, bottom 14, trailing 16), `containerRadius` 0; **no border field**, no padding field | `ThemedChartFrame` pads with margins; no border; asymmetrical 8/16 | `ChartFrame` same | No card. Margins asymmetrical | Medium |
| 16 | Plot geometry | right margin 12; bar width 0.7 of slot | `marks.barWidthRatio` 0.6 | Uses 0.6 (the theme) | SVG ignores the theme: hard-coded `group = slot*0.7`, `bar = 0.9*` = 0.63, and reserves 70pt right and 40pt left regardless of mark; SwiftUI default width | Renderer constants beat the theme; plot ends 70pt short of the rule in SVG | Medium |
| 17 | Sequential ramp | Orange is emphasis only, so magnitude needs a non-accent ramp | `Palette.sequential`: five oranges (#FF9134 to #6E3700) | Used as is | Used as is | A magnitude ramp in the accent hue spends the emphasis colour on data | Medium |
| 18 | Diverging ramp | Not in the drawing; owner finds positive-as-red confusing | `Palette.diverging`: blue #0088FF, #8ABBF8, #E8E8E8, #F7BD95, orange #FF8D28; light only, no dark ramp | Swiss: positive = **orange**. Un-themed default (`@Environment(\.theme)` default is `.legacyDefault`): positive = `style.loss` = **red** (`HeatmapCellColour.color`, legacy path) | Swiss: same blue-grey-orange, **no in-cell values, no scale key** | The red is the legacy default path; Swiss is orange. Neither has a key; Editorial heatmap prints no numbers | Medium |
| 19 | Multi-series rule | One accent plus greys to 3 series; eight-colour palette beyond | `palette.series` 8 in validated order, orange first | Grouped/line use `series(i)` always | same | No grey-ladder mode; no way to name the emphasised series | Medium |
| 20 | Light, dark, increased contrast of greys | Dark #4E5053; light #B9BBBD; IC not specified | `muted` has no dark or IC values distinct from the text grey | n/a | n/a | Needs dark and IC values (section 4), and the ledger row | Medium |

Verified facts behind selected rows: row 3 (`ThemeSwiss.swift`: `position: .belowTitle`), row 5 and 6 (`StandardChartStructure.swift` `StandardValueLabel`; `CategoricalChart.swift` `formatValue`), row 8 (`EditorialStyle.swift` `editorialDrawsBaseline`), row 11 (`EditorialLineChartView.swift` `barYAnnotations`), row 13 (grouped render, `BarChart.swift` `legend: inputs.count > 1 ? .swatches : .none`), row 16 (`SVGChartRenderer.swift` `group = slot * 0.7`, `labelRight = 70.0`).

## 4. Spec update

### Principle

Add the least that expresses the approved design, make every new field **default to today's behaviour** so FT, Economist, House and the four legacy themes render identically, and let only Swiss opt in. Every new `Codable` field uses `decodeIfPresent` with that default (the pattern `MarkSpec` and `LayoutSpec` already use), so 0.6.0 theme JSON still decodes.

### No new `mark` colour role: use `muted`

`ColorRole.muted` is documented "De-emphasised marks" and every editorial theme except Swiss already stores a pale mark grey in it (House #A0AEC0, FT #CCC1B7 / #5E544C, Economist #C5D0D6 / #4A565C). Swiss's `muted` is the text grey only because no token existed (recorded in the ThemeModel proposal); BusinessMath-UI's old Swiss kept #B4B7BC for this purpose and the conversion lost it. Adding a thirteenth role would force every `ThemePalette` decode, `ColorRole` switch and emitter to change. So: **the neutral mark colour is `palette.muted`; Swiss's `muted` is corrected.** `ChartStyle.neutral` already falls back to `muted`, so waterfall start, tornado baseline and heatmap NaN follow. The distinction the owner wants (mark default distinct from accent) is made by the structure field below, not a new role.

### Fields

| Where | Field | Type | Swiss value | FT / Economist / House / legacy |
|---|---|---|---|---|
| `ThemePalette` | `muted` (existing) | `Adaptive` | light #B9BBBD, dark #4E5053, lightIncreased #8E9196, darkIncreased #6F7176 | unchanged |
| `MarkSpec` | `defaultFill` (new) | `MarkFill` enum `.series` / `.muted` | `.muted` | `.series` (today) |
| `MarkSpec` | `defaultEmphasis` (new) | `EmphasisDefault` enum `.none` / `.latest` | `.latest` | `.none` |
| `MarkSpec` | `emphasisFill` (new) | `ColorRole` | `.accent` | `.accent` (only used when a caller names emphasis) |
| `MarkSpec` | `barWidthRatio` (existing, now honoured by Editorial SVG and SwiftUI) | `Double` | 0.7 (was 0.6) | unchanged (0.6, 0.45) |
| `RuleSpec.title` | `position` (existing) | `TitleRulePosition` | `.aboveTitle` (was `.belowTitle`) | unchanged |
| `TitleRule` | `gapAfter` (new) | `Double?` (nil = `gaps.title`) | 8 (inferred; confirm with overlay) | nil |
| `RuleSpec` | `baseline` (existing) | `Double` | 1.5 (was 1) | unchanged (1) |
| `RuleSpec` | `baselineColour` (new) | `ColorRole` | `.ink` | `.rule` (Editorial draws an ink baseline only when `baseline > gridline`, which is true for Swiss alone: all other themes have baseline == gridline == 1) |
| `RuleSpec` | `referenceColour` (new) | `ColorRole` | `.ink` | `.secondaryInk` (today's hard-coded colour) |
| `LayoutSpec` | `gaps.referenceLabel` (new) | `Double` | 5 | 3 (today's SVG offset) |
| `LayoutSpec` | `cardBorder` (new) | `Double` (0 = none; colour = `rule`) | 1 | 0 |
| `LayoutSpec` | `cardPadding` (new) | `Double` | 8 | 0 |
| `LayoutSpec` | `margins` (existing) | `Insets` | top 6, leading 8, bottom 12, trailing 8 (was 16/8/14/16; leading and trailing symmetric, top and bottom measured from the drawing's rule y=6 and source baseline H-12) | unchanged |
| `LabelSpec` | `valueHalo` (new) | `Double` (points of background-coloured stroke behind value and reference text; 0 = none) | 3 | 0 |
| `NumberFormatSpec` | `decimals` (existing `Int`) becomes optional meaning "minimal" when nil; add `maxDecimals: Int` | `Int?`, `Int` | `plain`: nil, max 2 (so 41.2, 80, 52.6) | unchanged (explicit integers today) |
| `Palette` / Swiss ramps | `sequential` | `Ramp` | one-hue blue, light "blue C" #6AB0FF #2E92F5 #0A74D6 #0757A6 #053C73 (monotone, no thin steps, light-end contrast 2.17, hue spread 2.2; measured). Dark is derived and needs its own steps (reversed-ramp contrast measured 1.7 at the dark end, not good enough) | unchanged |
| `Palette` / Swiss ramps | `diverging` | `Ramp` | **open question 3** | unchanged |

Series order: **unchanged, orange stays first.** Measured on #FAFAFA (light) and #101112 (dark), `ThemeValidator.measure`:

| Order | Adjacent worst CVD dE (light / dark) | Adjacent worst normal dE | First three, all pairs worst CVD / normal |
|---|---|---|---|
| Current (orange, indigo, green, purple, yellow, blue, red, cyan) | 22.41 / 24.12 (red-cyan) | 37.80 / 36.14 | 6.58 / 26.44 light; 4.85 / 26.69 dark |
| Orange last (rotate) | 22.41 / 24.12 | 30.51 / 30.29 | 3.30 / 19.41 light; 5.70 / 20.73 dark |
| Exploratory (indigo, blue, purple, green, red, cyan, yellow, orange) | 5.94 / 1.23 | 12.19 / 7.81 | worse |

Rotating orange away from slot 1 helps nothing and costs adjacent separation, and the neutral default does not consume a series slot, so there is nothing to revalidate; the existing order, its lightness-band failures (yellow light; orange, green, yellow, cyan dark) and ledger stand as recorded. "Emphasis only" is enforced by the structure, not by moving orange.

Accent-and-greys, up to three series (measured, all pairs):

| Appearance | Slots | Contrast vs background | Worst normal / CVD dE |
|---|---|---|---|
| Light | accent #FF8D28, #6A6D72, #B9BBBD | 2.21 / 4.98 / 1.84 | 17.95 / 15.50 |
| Light (alt) | #FF8D28, #5A5D62, #A9ACB1 | 2.21 / 6.33 / 2.18 | 17.94 / 15.80 |
| Dark | #FF9230, #9A9DA2, #4E5053 | 8.47 / 6.95 / 2.34 | 18.68 / 14.44 |

These meet the method's normal floor (15) and CVD target (8) but the greys sit under 3:1 on the light surface, so they must be directly labelled (same relief as the existing ledger).

### Measured neutral grey

| Colour | On background | On card | Note |
|---|---|---|---|
| Hybrid light #B9BBBD | 1.84 | 1.93 | approved |
| old `swissMuted` #B4B7BC | 1.93 | 2.01 | for reference |
| candidate 3:1 light #8E9196 | 3.03 | 3.16 | used for Increase Contrast |
| Hybrid dark #4E5053 | 2.34 | 2.20 | approved |
| candidate 3:1 dark #6F7176 | 3.87 | 3.64 | used for Increase Contrast |
| accent bar light #FF8D28 / IC #C55300 | 2.21 / 4.36 | 2.31 / 4.55 | |
| accent bar dark #FF9230 / IC #FFA056 | 8.47 / 9.37 | 7.96 / 8.81 | |

Emphasis stays visible against the grey: grey #B9BBBD versus #FF8D28 normal dE 17.95 (CVD 15.50); IC pair #8E9196 versus #C55300 18.58 (CVD 14.49); dark #4E5053 versus #FF9230 37.35 (CVD 30.14), IC dark #6F7176 versus #FFA056 28.36 (CVD 22.11). A 3:1 light grey as the default would put the grey darker than the orange (L 0.66 versus 0.75) and invert the emphasis, so the default stays at the approved 1.84:1 with printed values as relief and a ledger row; the 3:1 grey is the Increase Contrast value.

Validator note: `ThemeValidator.roleFindings` does not check `muted` today (it checks ink, secondaryInk, link, positive, negative, accent, warning). Add `check(.muted, .markContrast, .warn, 3.0)`, and add the four resulting rows to `swissConformance` (the current Swiss ledger has 25 entries, 15 fail and 10 warn, all pinned; this will change the count, so the pinning tests change with it).

### Data and spec side: naming the emphasised mark

```swift
/// Which marks take the accent. The rest take the theme's default fill.
public enum Emphasis: Sendable {
    case automatic                      // the theme's defaultEmphasis (Swiss: latest column)
    case none                           // nothing emphasised
    case latest                         // last category or period
    case indices(Set<Int>)              // category or period indices
    case categories(Set<String>)
    case series(Set<Int>)               // multi-series: which series take the accent
    case matching(@Sendable (_ index: Int, _ category: String, _ value: Double) -> Bool)
}
```

- Views: `CategoricalChart(..., emphasis: Emphasis = .automatic, referenceLines: [ReferenceLine] = [])`, the same on `GroupedCategoricalChart` (with `.series`), `TimeSeriesChart` (`.series`, and `.latest` for the end dot) and `WaterfallChart`.
- Specs: `ChartSpec.emphasis: Emphasis = .automatic` and `BarChart.spec(..., emphasis:)`. It lives on `ChartSpec`, not `Furniture`, because it is a mark decision. `ChartSpec` is already only `Sendable`, so a closure case is fine.
- Behaviour: `.automatic` means `marks.defaultEmphasis` for vertical columns and `.none` for horizontal (ranked) bars, where "latest" is meaningless. Naming emphasis explicitly always greys the rest (`muted`) whatever the theme's `defaultFill`, so it is opt-in for FT, House and the rest. An explicit `color:` argument still wins over everything.
- Series rule: one series, marks `muted`, emphasised marks `emphasisFill`. Two or three series with `.series(...)` named: those series accent, the others a grey ladder (#6A6D72 then #B9BBBD light; #9A9DA2 then #4E5053 dark). Two or three series with nothing named, or more than three: the categorical palette from slot 0, as today.
- Reference lines: one public type shared with the fan chart.

```swift
public struct ReferenceLine: Sendable, Equatable, Identifiable {
    public var value: Double
    public var label: String?
    public init(value: Double, label: String? = nil)
}
```

  `FanReferenceLine` becomes a typealias. `Annotation.referenceLine(y:label:)` is unchanged and remains the Editorial route; the SwiftUI bar path must stop discarding the label.
- Direct series labels for grouped bars: label the series once, over the first group, in `seriesLabel` type in **ink** (not the series colour, which fails text contrast for orange, green, yellow and cyan). Line-end labels likewise go to ink, with the swatch dot carrying the colour.

### Light, dark, increased contrast

Greys: see the table above. Orange IC values are the existing measured set. The heavy rule, baseline, target line and value labels are ink (#111214 / #F2F2EF); there is no IC variant for ink in the theme and none is needed.

## 5. Recommendations, in implementation order

1. Theme data only (DesignTokens, no renderer change): Swiss `muted`, `titleRule.position = .aboveTitle`, `baseline 1.5`, `barWidthRatio 0.7`, `margins`. This alone fixes rows 3, 7 (values), 20.
2. Add the new fields with legacy-preserving defaults, update the Swiss ledger and the conformance tests, regenerate `tokens.css` (should not change for non-Swiss).
3. Renderers read the fields: neutral default and emphasis, ink baseline, reference line colour and label, plot geometry from the theme rather than 70/40/44 constants, card border and padding, minimal-decimals number format, value-label halo, standard value labels use `annotation`.
4. Views and specs: `emphasis:` and `referenceLines:`; grouped direct labels; `Source:` prefix applied in one place for both surfaces; every sample builder passes a source.
5. Heatmap: in-cell values and a scale key for Editorial; ramp decision (open question 3).

## 6. Open questions

1. **Hybrid grey at 1.84:1 / 2.34:1 as the default, with the 3:1 grey only for Increase Contrast?** Lean yes: the owner approved this drawing, the grey must stay lighter than the accent, and printed values are the relief. Needs a ledger row either way.
2. **Value-label halo (3pt background stroke)?** Lean yes: it fixes the approved drawing's own target-line collision (52.6, 49.9). It is a small deviation from the drawing.
3. **Diverging ramp.** Today Swiss is blue to grey to orange (positive = orange), and the red-positive the owner saw is the legacy un-themed default (`@Environment(\.theme)` defaults to `.legacyDefault`, whose heatmap maps positive to the loss red). Options: keep blue/grey/orange (it is the validated CVD-safe pair, and a heatmap cell is a fill, not an emphasis mark), or make positive the blue pole and negative the orange pole so orange keeps meaning "look here". Lean: positive = blue, negative = orange, neutral grey, with a printed key; leave the legacy default alone for pixel parity but have the demo and samples apply Swiss. Needs the owner's call because it flips the convention.
4. **`.automatic` emphasis for horizontal ranked bars: none, or the top-ranked?** Lean none (the author names it); latest-column default only for vertical charts.
5. **Grouped-bar series key when direct labelling is impractical (narrow groups): fall back to a swatch legend, or force direct labels?** Lean direct label over the first group in ink; allow a swatch fallback below a minimum group width, since "no key" cannot hold for adjacent same-width bars.

## Decisions 2026-11-09

Owner decisions on the open questions above. They are binding and override any "lean" wording above that conflicts.

**Principle: marks are neutral by default; the accent is reserved for emphasis.** The approved design draws history in grey and the
latest or highlighted mark in the accent.

1. **Question 1, the grey.** The approved Hybrid grey (light #B9BBBD, dark #4E5053; `color-mix(muted 45%, background)`; stored as `Adaptive`
   values) stays the default although it is 1.84:1 (light) and 2.34:1 (dark) on the background. The mark-contrast check is added to
   `ThemeValidator` and ledgered for Swiss (four rows: muted on background 1.84 and on surface 1.93, light; 2.34 and 2.20, dark); the
   printed values are the relief. The 3:1 greys #8E9196 (light) and #6F7176 (dark) are the Increase Contrast slots.
2. **Question 2, halo.** Yes: `LabelSpec.valueHalo` (3 pt of background-coloured stroke behind value and reference labels). Swiss 3.
3. **Question 3, ramps.** Swiss keeps its blue (low) to neutral to orange (high) diverging ramp. A **dark diverging ramp** and a one-hue **blue
   sequential ramp** (with an authored dark variant) are authored by the series' method (the system dark blue #0091FF and orange #FF9230 as
   endpoints; a chosen and validated neutral midpoint), validated with the ramp checks and ledgered (they pass, so no rows). The orange ramp
   stops being Swiss's default magnitude ramp (orange is emphasis only), but `Palette.sequential` and `tokens.css` are byte-identical; only
   Theme-level data and `Generated/themes/*` moved.
4. **Question 4, `.automatic` emphasis.** None for horizontal ranked bars; latest column only for vertical charts. A view-API matter for
   BusinessMath-UI: documented, and `MarkSpec.defaultEmphasisIndex(count:isVertical:)` encodes it.
5. **Question 5, grouped-bar key.** A direct label in ink over the first group (documented; BusinessMath-UI work). Swatch fallback below a
   minimum group width is BusinessMath-UI's call.
6. **Series order.** Orange stays first for more than three series (the audit validated it). No new `mark` role: `palette.muted` plus the new
   `MarkSpec` fields.

Later the same day (owner adjustments, binding):

7. **Target (reference) line.** A muted **hairline, not dashed**, for Swiss: `rules.reference = LineSpec(weight: hairline, dash: [])` and
   `referenceColour = .secondaryInk` (the muted neutral that reads as a line; `muted` itself, #B9BBBD, is the mark grey and would be too
   faint). The direct label of the line stays in **ink**, on the line: a new `referenceLabelColour` (Swiss `.ink`; default `.secondaryInk`).
   The model still expresses dashed for other themes (the `dash` field stays; House dashes 4 4).
8. **Card border.** `layout.cardBorder` is an **option that defaults to off** for Swiss (0). `cardBorder` and `cardPadding` stay as fields a
   caller or theme variant can turn on: `Structure.withCardBorder(_:padding:)` and `Theme.withCardBorder(_:padding:)` (defaults 1 pt, 8 pt, the
   approved drawing's card; the theme result has id `swiss+card`). Swiss's `cardPadding` is also 0 by default (a deviation from the table
   above, which said 8: padding without a border would double the 8 pt margins).

9. **Heatmaps and scatter grey-to-orange, owner 2026-11-09 (later).** Swiss's sequential and diverging ramps are grey to orange, with dark variants, replacing the blue ones from decision 3; the blue ramps stay as named alternates (`sequentialBlue`, `divergingBlueOrange`). Diverging has the dark neutral at the negative pole. Scatter: neutral points, accent emphasis, the sequential ramp for a third variable; no new field. Princeton keeps its own ramps. The sequential ramp's light grey end is 1.37:1 (ledgered); the values are printed.

## Implementation notes (DesignTokens, 2026-11-09)

Values taken from the table in section 4, and where this implementation differs or confirms an "inferred" value:

| Field | Swiss value | Note |
|---|---|---|
| `palette.muted` | #B9BBBD / #4E5053, IC #8E9196 / #6F7176 | as audited; no system colour |
| `marks.defaultFill`, `defaultEmphasis`, `emphasisFill` | `.muted`, `.latest`, `.accent` | as audited; defaults `.series`, `.none`, `.accent` |
| `marks.barWidthRatio` | 0.7 | as audited |
| `rules.title.position`, `gapAfter` | `.aboveTitle`, 8 | **8 stays inferred**: 27 pt rule-to-baseline less about 19 pt of 17 pt type at 1.3 line height; not confirmed by overlay |
| `rules.baseline`, `baselineColour` | 1.5, `.ink` | default `.rule` (what Editorial draws today; the standard views draw ink for every theme, so a standard view that reads the field for a legacy theme should keep ink) |
| `rules.reference`, `referenceColour`, `referenceLabelColour` | solid 1 pt, `.secondaryInk`, `.ink` | owner decision 7; default `.secondaryInk` for both |
| `gaps.referenceLabel` | 5 | default 3 |
| `layout.cardBorder`, `cardPadding` | 0, 0 | owner decision 8 |
| `layout.margins` | top 6, leading 8, bottom 12, trailing 8 | as audited |
| `labels.valueHalo` | 3 | default 0 |
| `numbers.plain` | `decimals: nil`, `maxDecimals: 2` | **deviation:** `maxDecimals` is `Int?` (not `Int`) and "minimal" means `decimals == nil && maxDecimals != nil`, because `decimals == nil` already means "the renderer's default" for currency and percent in every other theme; changing that meaning would have changed them. `NumberFormatSpec.fractionDigits` gives the range |
| `palette.sequential` | blue C light #6AB0FF #2E92F5 #0A74D6 #0757A6 #053C73; dark #064E8B #0167B8 #1382E1 #449FFA #7FBCFE | light as audited (2.17:1 at the light end, hue spread 2.2); the dark ramp is new (darkest step 2.22:1, hue spread 0.27) |
| `palette.diverging` | light unchanged; dark #0091FF #246BB1 #414344 #AB6224 #FF9230 | new; each arm monotone, no step under 0.13 of OKLCH L, outer ends 8.5:1 or more on #101112 (the midpoint is meant to sit near the surface, 1.9:1) |

**Princeton follows Swiss, owner 2026-11-09 (later the same day).** The system green and red override is removed: Princeton has Swiss's text-safe `positive` / `negative` as well, and keeps only its own accent, series and ramps. Its ledger is 10 findings (no status rows). Swiss `marks.barCornerRadius` is the explicit literal 0 (it was `Radius.container`, also 0); the theme is the single source for square bars. Halo rule: the halo must match the surface actually painted behind the text (`ChartStyle.paintsOwnSurface`, `valueHaloValue(over:)`).

Princeton is composed on Swiss, so it **inherits the whole Swiss structure** (neutral marks, the latest column emphasised, the rule above
the title, the 1.5 pt ink baseline, the hairline target line) and the neutral `muted` grey, and keeps its own accent, its own orange ramps and
the system green and red. Reason: it is a Swiss variant whose only intended differences are colours. It is the one behaviour change among
the themes the brief listed as unchanged; undoing it is a structure override in `Theme.princeton` (set `marks.defaultFill = .series`
and so on), and its ledger gains two light `muted` rows.

Not done here (BusinessMath-UI work): everything in section 5 items 3 to 5, and the visual confirmation of the 8 pt rule gap by overlay.
