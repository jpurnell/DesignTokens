# Design Proposal: Swiss components for SwiftUI (0.10.0)

**Status:** approved by the brief of 2026-11-10 (owner), implemented on `feature/swiss-components-0.10.0`.
**Source:** the quality-gate dashboard's adoption branch (final commit `ae45fdc`), read as the consumer to design against:
`DashboardType.swift`, `DashboardShape.swift`, `DashboardChartTheme.swift`, `AdaptiveViews.swift` (`KeyValueRow`),
`PortfolioBannerView.swift`, `StackMapView.swift` (gap card, chips), and its checklist `CURRENT_design-tokens.md`, which lists
the upstream gaps this release answers.
**Visual spec:** the owner-approved "Swiss and Apple" design-system artifact (ANATOMY, the Hybrid card of nine components; type roles;
rule weights 1 / 3 / 8 pt; 12-column grid, label column 1-3 and reading column 4-10; 4 pt base unit; control radius 4, container
radius 0; no dashed borders; neutral marks, accent only on emphasis; status by outlined chip and words). Matched, not reinterpreted.
**Breaking:** the only source break is additive-with-defaults (see 6); no shims.

## 1. Objective

The dashboard had to hand-roll, in its own target, everything the design system says an app needs after colours: the UI-register type
roles, a card, a chip, a section, a key/value row, a segmented control, a banner, and it still could not style a table or a form control
or give its palette a window background. Each of those is a function of the tokens, so each belongs in the package once, in
`DesignTokensSwiftUI`, read from `\.theme`, `\.colorScheme`, `\.colorSchemeContrast` and Dynamic Type, with no literal colour, radius
or font.

## 2. Decisions, gap by gap

| # | Gap | Verdict | API shape |
|---|-----|---------|-----------|
| 1 | UI-register type roles, label role, figure | **Built** | `UIRole`, `UITextSpec`, `View.uiText(_:)`, `View.uiFigure()` |
| 2 | Card, chip, section, key/value, segmented, banner | **Built** | `SwissCard`, `OutlinedChip`, `SwissSection`, `SwissRule`, `KeyValueRow`, `KeyValueList`, `SwissSegmentedControl`, `StatusBanner` |
| 3 | Styling native `Table` | **Built differently**: native header cannot be styled; `SwissTable` on the grid, plus a small native-table modifier | `SwissTable`, `SwissTableColumn`, `SwissTableSort`, `View.swissTableStyle()` |
| 4 | Form controls | **Partly built, partly declined** | `SwissToggleStyle`, `SwissLabeledContentStyle`, `SwissFormStyle`, `SwissTextField`; declined: custom `PickerStyle`, `TextFieldStyle`, section headers |
| 5 | `AppPalette` cannot declare its own window or surface | **Built** | `AppPalette.background`, `AppPalette.surface`, composed into the theme, measured |
| 6 | Where SwissTier lives | **Decided**: components in `DesignTokensSwiftUI`, terminal and GUI renderers stay in their kits | documentation only |

### 2.1 Type roles (gap 1)

The six UI roles of `TypeRoles` (`label`, `caption`, `body`, `heading`, `uiTitle`, `display`) become SwiftUI text, resolved in one
place, by one pure value so it can be tested without rendering:

```swift
public enum UIRole: Sendable, Hashable, CaseIterable { case label, caption, body, heading, title, display }
public struct UITextSpec: Sendable, Hashable {
    public init(_ role: UIRole, theme: Theme)
    public let textStyle: Font.TextStyle   // the Dynamic Type style the role is set in
    public let weight: Font.Weight         // from the theme's TextSpec.weight
    public let design: Font.Design         // from the theme's TextSpec.family
    public let tracking: CGFloat           // em * size, only where the theme's tracking is positive (the label)
    public let isUppercase: Bool           // the theme's TextSpec.uppercase
    public let usesSecondaryInk: Bool      // label and caption
    public let isHeader: Bool              // heading and title
}
View.uiText(_ role: UIRole) ; View.uiFigure()   // monospaced digits
```

**Why a table from role to text style, and not a size lookup.** The tokens' sizes (heading 28, title 34, display 168) are CSS pixels
for the web register. On Apple platforms the artifact's decision is that Dynamic Type text styles carry the UI register, and the
platform's sizes differ per OS (a body is 17 on iOS and 13 on macOS). Mapping 28 pt to the nearest text style would give
`.title` for a heading and `.largeTitle` for a title, which is not the approved scale and not what the dashboard (and the drift
checker) accepts. So the **text style** is a stated mapping (`title` -> `.title`, `heading` -> `.headline`, `body` -> `.body`,
`caption` -> `.footnote`, `label` -> `.caption2`, `display` -> `.largeTitle`), and everything else comes from the theme: weight (600 / 700
/ 800), font design, capitals, and tracking. Tracking is applied only where the theme's is positive: the tokens' negative tracking is
for a fixed point size, and the system applies its own optical tracking to larger text styles, so applying `-0.03em` to a Dynamic Type
title would tighten it twice.

The label role is capitals, `0.08em`, semibold, **secondary ink**. The foreground comes from the theme (`ink`, or `secondaryInk`), so a
caller that wants another colour overrides it after the modifier, as with `chartText`.

### 2.2 Components (gap 2)

Each is a `View`, small, composed of the others, and reads the theme and appearance from the environment (through
`ChartStyleReader`'s inputs). Shared geometry is one value, `SwissMetrics(theme:)`: base unit, `step(n)`, gutter, rule weights, radii,
and the 12-column `SwissGrid` (column and span positions, label 1...3, reading 4...10), so a test compares every number with the token
and no view contains one.

- **`SwissCard`**: the Hybrid card. A 3 pt rule in ink (the section rule) across the top; a header row of a small label and an
  `OutlinedChip` slot; the title in the title role; a secondary-ink description; a footer slot set off by an **ink** hairline (the
  artifact's "strict Swiss footer rule above Builds on"; the dashboard drew it in ink as well). Square (container radius), a hairline
  border in the neutral `rule` colour, no fill (the page is the surface), no shadow. `SwissCardFooter("Builds on", names:)` is the
  label-in-secondary, names-in-bold row. Read by VoiceOver as one container whose children are still reachable.
- **`OutlinedChip`**: words in ink, a 2 pt outline at the control radius, an optional glyph (a different *shape* per state, never
  colour alone). `ChipTone`: `.neutral` (secondary ink, the outline), `.emphasis` (the accent), `.positive`, `.negative`, `.warning`
  (the theme's text-safe roles), `.custom(Color)` for an app's own palette role. Not interactive, so no hit target; the glyph is
  hidden from VoiceOver because the words say it.
- **`SwissSection`**: the 3 pt ink rule, the heading role, the content. `SwissRule(_:)` is the rule on its own (`.hairline`,
  `.section`, `.page`), weights from `rules`.
- **`KeyValueRow` / `KeyValueList` and `SwissLabeledContentStyle`**: the label in the label role in columns 1-3, the value in the body
  role in columns 4-10, a hairline above each row, baseline-aligned. Where the container is too narrow for a legible label column
  (the column would be under `minimumLabelWidth`, scaled with Dynamic Type) it stacks: label above value. One element for VoiceOver
  ("label, value"). The row is a `LabeledContent` underneath, so `LabeledContent` in any `Form` can take the same look with
  `.labeledContentStyle(.swiss)`.
- **`SwissSegmentedControl`**: the control radius, an ink hairline border, label role, selected segment filled with ink with text in the
  colour that **measures** best on it, `isSelected` trait, at least 44 pt tall on touch platforms, radio-group semantics.
- **`StatusBanner`**: a solid fill in a status role (`.positive`, `.negative`, `.warning`, `.neutral`), a glyph and the words; the text
  is whichever of the theme's `ink` and `background` has the higher measured contrast against the fill **in the appearance it is
  drawn in** (light, dark, each increased-contrast variant). `StatusBannerStyle.resolve` is a pure function, and the tests hold every
  status fill in every appearance to 4.5:1.

### 2.3 Tables (gap 3)

Investigated on macOS 27.2 SDK by rendering a native `Table` (`NSHostingView.cacheDisplay`):

- `TableColumn`'s title is `LocalizedStringKey` or `StringProtocol`; there is **no `Text`/`View` title overload**
  ("initializer 'init(_:content:)' requires that 'some View' conform to 'StringProtocol'"), so the header text cannot take a type role.
- The header bar, the column dividers and the resize cursor are `NSTableHeaderView` chrome; no SwiftUI modifier reaches them.
- What *can* be set: `tableStyle(.inset(alternatesRowBackgrounds: false))` (no zebra), `scrollContentBackground(.hidden)`, hiding the
  header (`tableColumnHeaders(.hidden)`, which leaves no header at all), and the **cell** content (roles, figures, chips), which is the
  app's own view. On iPhone `Table` collapses to its first column; on visionOS it is unavailable in this form.

So: **built differently.** `SwissTable` is a table on the grid, not on `Table`: a header row in the label role with an ink hairline
under it, rows separated by `rule` hairlines, columns by 12-column span, an optional sortable header (a binding, VoiceOver sort
trait, a glyph that is also a word for assistive tech), figure columns in monospaced digits, and a horizontal scroll under a minimum
width instead of crushing. It is lazy (`LazyVStack`), cross-platform, and has no system chrome. The app owns the data and the sort
(the component reports the binding and does not reorder). `View.swissTableStyle()` is offered for a native `Table` an app keeps
(selection, resizing, many thousand rows): it removes the zebra and the scroll background, and says in its documentation what it
cannot do. Declined: a native-header restyle, because there is none.

### 2.4 Form controls (gap 4)

Investigated by rendering (same method):

| Control | Verdict | Why |
|---|---|---|
| `Toggle` | **Built**: `SwissToggleStyle` (`.swiss`) | `ToggleStyle` is public. A square-cornered (control radius) box with an ink hairline, a check glyph, the label in the body role; 44 pt target on touch; `isToggle` semantics kept (it is a `Button` with `.isToggle`...). |
| `LabeledContent` | **Built**: `SwissLabeledContentStyle` (`.swiss`) | `LabeledContentStyle` is public; shared with `KeyValueRow`. |
| `Form` | **Built, modestly**: `SwissFormStyle` (`.swiss`) | `FormStyle` is public but only receives the *content*: it can remove the grouped inset chrome and set spacing; it cannot restyle a `Section` header (verified: the header renders as plain system text). So the guidance is `SwissSection` instead of `Section` inside it. |
| `TextField` | **Built differently**: `SwissTextField` (a view) | `TextFieldStyle` has no public requirements (custom styles are not possible; `_body` is private). A wrapper view draws the label role above, the control-radius border (hairline in ink, 2 pt in the accent on focus) around a plain-style field. |
| `Picker` (menu, inline) | **Declined** | `PickerStyle` is sealed. `SwissSegmentedControl` is the Swiss picker for a few options; a long list keeps the system menu. |

### 2.5 App palette surfaces (gap 5)

0.9.0's `textSurfaces` says what text is *measured against* and changes nothing. The dashboard needed its chart on the Mac window's
grey and had to clone Swiss, zero the background's alpha and swap `secondaryInk` by hand (`DashboardChartTheme.swift`), and then
`ThemeValidator` could not be run on it. Now an app palette declares them:

```swift
public var background: Adaptive?   // the window or page; nil keeps the theme's
public var surface: Adaptive?      // a card or raised surface; nil keeps the theme's
```

- `Theme.composed(with:)` sets `palette.background` / `palette.surface` from them. Everything the validator already measures
  against the composed theme's surfaces (series and accent marks, ink, secondary ink, positive, negative, link, the text roles when
  `textSurfaces` is nil) is therefore measured against the app's own, in light, dark and each increased-contrast variant it declares.
  **Ink is validated against the declared surfaces for free**, by the role checks that already existed, and an app that declares a
  surface its ink cannot read on gets a `textContrast` finding instead of a silent unreadable page.
- The 0.8.0 appearance rule extends to them: a surface with no dark value demotes a `both` composition to light-only (no dark
  value is invented).
- `textSurfaces`, when declared, still wins for the *text roles* (a role may be drawn on a bar the page background does not name);
  when it is nil, text roles are measured on the declared `background` and `surface`.
- A translucent background (alpha 0, "the window shows through") is allowed, and is measured as the validator measures every
  translucent surface: composited over white (black in dark). That is only as accurate as that assumption, which is why a palette on a
  system window declares `textSurfaces` with the real greys too; documented.
- **Marker contract** (quality-gate-swift reads `AppPaletteSource` conformance and exactly one `AppPalette(id: "<literal>"` call
  syntactically): **not broken.** The new parameters are two more defaulted, labelled arguments of the same initializer; the `id:`
  literal stays first; the conformance and the call count are untouched. `Codable` keys are optional (absent decodes to `nil`).

### 2.6 Ownership (gap 6)

`SwissTier` (rule weights, `GridSpec`) lives only in an unreleased SwiftCLIKit, and SwiftGUIKit has no Swiss card. Decision:
**the SwiftUI components belong here, in `DesignTokensSwiftUI`**, because they are functions of the `Theme`, which is this package's;
a second implementation in SwiftGUIKit would be a second source of the same numbers, the exact drift this package exists to remove.
The terminal renderer (box-drawing card, ANSI chip) stays in SwiftCLIKit, where the `ANSIEmitter`'s output is consumed, and SwiftGUIKit
keeps only what Apple names semantically (its inclusion rule). Both read their numbers from `Rule`, `Grid`, `Radius`, `TypeStyle` or the
`Theme`. Neither is modified by this release; "How a renderer adopts the components" (in `SwissComponents.md`) says how each should
map when it does: SwiftGUIKit's resolvers delegate `heading/body/caption/label` to `UITextSpec` instead of keeping a second mapping, and
SwiftCLIKit's `SwissTier` is replaced by `Rule` and `Grid` (and `Theme.structure.rules`) so it stops being a copy.

## 3. Non-goals

No change to the core `DesignTokens` target's dependencies (still Foundation-only, Linux-buildable). No custom icon set (glyphs are SF
Symbol names the caller or the component passes). No motion. No change to the chart styles. No tvOS or watchOS verification.

## 4. Test plan (written first)

1. `UITextSpec`: the role-to-text-style table; label tracking equals `0.08 * 11`, uppercase, secondary ink; weights equal the
   theme's; negative tracking not applied; header flags; every role resolves for every built-in theme.
2. `SwissMetrics`/`SwissGrid`: rule weights and radii equal `Rule` / `Radius` and the theme; label and reading spans are columns
   1...3 and 4...10; column geometry sums to the width; the value column starts where column 4 starts.
3. `StatusBannerStyle`: text on every status fill, every appearance and increased-contrast variant, at least 4.5:1; the chosen
   colour is the better of the two.
4. `ChipTone` mapping to theme roles; chip outline weight is a token-derived constant; no literal colour (a source scan test over
   `Sources/DesignTokensSwiftUI/Swiss*` for `Color(` / `#` / `.system(size:` / `cornerRadius: <number>`).
5. `AppPalette.background`/`surface`: composed theme carries them; ink is measured against them (a failing pairing is a finding);
   Codable round trip and 0.9.0 JSON still decode; the dark-demotion rule; a dashboard-shaped palette still validates; the
   `AppPaletteSource` marker shape is unchanged (the existing adoption tests keep passing).
6. A dashboard-shaped screen test: the screens the dashboard hand-rolled, rebuilt from the new components with a dashboard-shaped
   palette, rendered (non-empty, size) and mapped file by file in `SwissComponents.md`.
7. The gallery (an executable that writes PNGs, light and dark, plus increased contrast for the banner and chips) and an `index.html`.

## 5. Build matrix to attempt

macOS `swift build` / `swift test`; `xcodebuild -scheme DesignTokensSwiftUI -destination` for the iOS Simulator and visionOS Simulator;
`DesignTokens` core on Linux is not buildable here (no Linux toolchain), so it is checked structurally: no `import SwiftUI` /
`AppKit` / `UIKit` in `Sources/DesignTokens`.

## 6. Source-breaking changes

None required by the design. `AppPalette.init` gains two defaulted labelled parameters (`background:`, `surface:`) so an existing
call compiles unchanged. `ChartStyle` is untouched. (Anything the dashboard deletes is its own code, listed in `SwissComponents.md`.)
