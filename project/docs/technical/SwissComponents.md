# Swiss components for SwiftUI (0.10.0)

Everything here is in `DesignTokensSwiftUI`, reads `\.theme`, `\.colorScheme`, `\.colorSchemeContrast` and Dynamic Type, and contains no
literal colour, radius or font (`SwissSourceDisciplineTests` scans the sources). Design and decisions:
`project/plans/proposals/2026-11-10_SwissComponents.md`. Look at them: `swift run swiss-gallery <folder>` writes a PNG of every
component, light and dark, and an `index.html`.

## The pieces

| Piece | API | Notes |
|---|---|---|
| Type roles | `.uiText(_ role: UIRole, ink: UIInk = .automatic)`, `.uiFigure()`, `UITextSpec(role, theme:)` | `UIRole`: `label`, `caption`, `body`, `heading`, `title`, `display`. Text style by role (`caption2`, `footnote`, `body`, `headline`, `title`, `largeTitle`); weight, design, capitals and positive tracking from the theme. |
| Metrics | `SwissMetrics(theme:)`, `SwissGrid`, `SwissRule(_:tone:)` | unit, `step(n)`, gutter, rule weights 1/3/8, radii 0/4, chip outline (2 x hairline), 12-column spans (label 1-3, reading 4-10). |
| Container | `.swissContainer()` | Square, hairline `rule` border, no fill. |
| Card | `SwissCard(label:title:description:chip:footer:)`, `SwissCardFooter(_:names:)` | The Hybrid card. |
| Chip | `OutlinedChip(_:tone:glyph:)`, `ChipTone` | `.neutral`, `.emphasis`, `.positive`, `.negative`, `.warning`, `.custom(Color)`. |
| Section | `SwissSection(_:content:)` | 3 pt rule, heading. |
| Key/value | `KeyValueRow`, `KeyValueList`, `.labeledContentStyle(.swiss)`, `KeyValueGeometry` | Label columns 1-3, value 4-10, stacks when the label column would be narrower than 24 base units (scaled with Dynamic Type). |
| Segmented | `SwissSegmentedControl(title:options:name:selection:)` | Selected text colour is measured (`ReadableText`). |
| Banner | `StatusBanner(_:text:)`, `StatusKind`, `StatusBannerStyle.resolve`, `ReadableText.on(_:style:)` | Text is ink or background, whichever measures higher on the fill in that appearance. |
| Table | `SwissTable`, `SwissTableColumn`, `SwissTableSort`, `SwissTableGeometry`, `.swissTableStyle()` | On the grid, no system chrome; the native-table modifier is a small helper. |
| Forms | `.toggleStyle(.swiss)`, `.formStyle(.swiss)`, `SwissTextField`, `.swissTouchTarget()` | See the table below. |
| App palette | `AppPalette(background:surface:)` | Composed into the theme and measured. |

**Foreground order.** SwiftUI's innermost foreground style wins, so `Text("x").uiText(.body).foregroundStyle(.red)` stays ink. Choose the
ink in the modifier: `.uiText(.body, ink: .custom(color))`.

## Tables and form controls: what SwiftUI allows (measured on the macOS 27.2 SDK)

| Thing | Can it be styled? | What this package does |
|---|---|---|
| `Table` header text | No. `TableColumn`'s title is a `LocalizedStringKey` or `StringProtocol`; there is no `Text`/`View` overload ("requires that 'some View' conform to 'StringProtocol'"). | `SwissTable` draws its own header. |
| `Table` header bar, dividers | No. `NSTableHeaderView` chrome; no modifier reaches it. | same |
| `Table` rows | Partly: `tableStyle(.inset(alternatesRowBackgrounds: false))`, `scrollContentBackground(.hidden)`; cells are the app's views. | `.swissTableStyle()` |
| `Table` on iPhone, visionOS | iPhone shows the first column only. | `SwissTable` is the same everywhere. |
| `Toggle` | Yes, `ToggleStyle`. | `SwissToggleStyle` |
| `LabeledContent` | Yes, `LabeledContentStyle`. | `SwissLabeledContentStyle` (shared with `KeyValueRow`) |
| `Form` | Layout only. `FormStyle` receives the content; a `Section` header renders as plain system text (verified). | `SwissFormStyle` removes the grouped chrome; use `SwissSection`. |
| `TextField` | No custom style: `TextFieldStyle` has no public requirements. | `SwissTextField`, a view. |
| `Picker` (menu, inline) | No: `PickerStyle` is sealed. | Declined; `SwissSegmentedControl` for a few options, the system menu for a long list. |

## Ownership: SwissTier, SwiftCLIKit, SwiftGUIKit

The SwiftUI components live here because they are functions of `Theme`, which is this package's. A second implementation in SwiftGUIKit
would be a second source of the same numbers. Terminal and other renderers stay in their kits. **Not modified by this release.** When
they adopt:

- **SwiftGUIKit**: `AppleTokenResolver.font(_:)` stops keeping its own heading/body/caption mapping and calls `UITextSpec(_:theme:)`
  (which also gives it the label role it lacks); a Swiss card is `SwissCard`, not a second one; it keeps what Apple names semantically.
- **SwiftCLIKit**: `SwissTier` (rule weights, `GridSpec`) is replaced by `Rule.hairline/section/page.points`, `Grid`, and
  `Theme.structure.rules`, so it is no longer a copy of the tokens. The box-drawing card and ANSI chip stay there, drawn with
  `ANSIEmitter`'s colours; the chip's neutral/emphasis/status tones are the same `ChipTone` vocabulary.

## What the dashboard would delete or replace (do not change its repo; read at `ae45fdc`)

| Dashboard file / type | Replaced by |
|---|---|
| `DashboardType.swift`: `dashboardTitle/Heading/Body/Caption/Label/Figure` | `.uiText(.title/.heading/.body/.caption/.label)`, `.uiFigure()` |
| `DashboardType.swift`: `DashboardSpace` | `SwissMetrics.unit`, `step(_:)`, `gutter` |
| `DashboardType.swift`: `DashboardSection`, `HairlineRule` | `SwissSection`, `SwissRule` |
| `DashboardType.swift`: `DashboardSegmented` | `SwissSegmentedControl` |
| `DashboardShape.swift`: `hairline`, `heavyRule`, `chipOutline`, `container`, `control`, `neutralBorder` | `SwissMetrics`; the border is the theme's `rule` (not `secondary.opacity(0.4)`) |
| `DashboardShape.swift`: `dashboardCard()` | `.swissContainer()` (panels, `RowCard`) or `SwissCard` |
| `DashboardShape.swift`: `StatusChip` | `OutlinedChip(_, tone: .custom(color))` or a status tone |
| `DashboardChartTheme.swift` (the whole file) | `AppPalette(background:, textRoles: [secondaryInk])` and `palette.theme()`; `DashboardWindowSurfaceTests` is the proof |
| `AdaptiveViews.swift`: `KeyValueRow`, `dashboardTouchTarget()` | `KeyValueRow`, `.swissTouchTarget()` |
| `PortfolioBannerView.swift` (the view and its per-appearance `textColor`) | `StatusBanner`; `PortfolioBanner` keeps deciding the state |
| `WCAG.swift` | `RGB.contrastRatio(with:)` (0.9.0) |
| `StackMapView.swift`: `gapCard`, `namesRow` | `SwissCard`, `SwissCardFooter` (the names stay buttons: a footer takes any view) |
| `ProjectDetailView`, `ProjectsTableView`, `AnalyticsTables`, `ClustersTableView`: native `Table`s | `SwissTable` (they are the ones the dashboard left) |
| `LoadStatusBar.swift` status sheet | `SwissSection` + `KeyValueList` |
| Settings `Form` and fields | `SwissFormStyle`, `.toggleStyle(.swiss)`, `SwissTextField` where the design wants them; the Mac Settings scene may keep the platform's |

`DashboardReexpressionTests` rebuilds a dashboard Summary screen from these pieces on a theme composed from a dashboard-shaped palette.
