# Design Proposal: text roles, host surfaces and a public contrast function (0.9.0)

**Status:** approved by the brief of 2026-11-10 (owner), implemented on `feature/text-roles-0.9.0`.
**Source:** the first real adoption of 0.8.0, the quality-gate dashboard
(`quality-gate-dashboard/.../project/plans/proposals/2026-11-10_DashboardAdoptsDesignTokens.md`, section 8) and its
`DashboardPalette.swift` and `LegibilityTests`, read as the consumer to design against.
**Breaking:** yes (source, 0.x). No compatibility shims.

## 1. Objective

0.8.0's `AppPalette` has slots for an accent and chart series. The dashboard's colours are not that: they are *text*
(status words, secondary captions) drawn on the host app's own backgrounds. To fit them in, it had to declare them as
chart series, which produced chart findings about text (separation, lightness band, 3:1 marks), left `secondary` outside
the palette and unvalidated, kept its own WCAG arithmetic, and measured nothing against its real backgrounds. This
release makes text roles first-class, validated as text on the surfaces the app says it draws them on.

## 2. Decisions, finding by finding

| # | Finding | Decision |
|---|---------|----------|
| 1 | No slot for text roles | **Fix.** `AppPalette.textRoles: [NamedAdaptive]`, validated as text (4.5:1). |
| 2 | No public contrast function; `RGB` collision | **Fix** the function; **document, not rename** `RGB` (see 2.2). |
| 3 | No way to measure against the host's backgrounds | **Fix.** `AppPalette.textSurfaces: TextSurfaces?`. |
| 4 | Printed-only sets still get chart checks | **Fix by construction**, and decline a separate flag (see 2.4). |
| 5 | `\.theme` defaults to legacy | **Fix.** Default is Swiss. |
| 6 | Nothing ties declared roles to the colours views use | **Fix, small:** `AppPaletteSource.TextRoles`, `text(_:)`, cross-checked by `validate()`. |

### 2.1 Text roles (finding 1)

```swift
public var textRoles: [NamedAdaptive]      // default []; light, dark, lightIncreased, darkIncreased slots
```

- Each role is measured as **text**: `textContrast` at 4.5:1 (`ValidationThresholds.textContrast`), severity `fail`
  (a text role is text; Swiss's softer `warn` for positive/negative belongs to roles that are also chart marks).
  Subject is `"<role> on <surface>"`. Nothing else is measured for it: no lightness band, no chroma floor, no
  separation, no mark contrast, no `labelRequired`.
- Appearances: light and dark as for every palette; an increased-contrast appearance is added when any text role has
  that slot, and a role without the slot is not measured in it (as `roleFindings` does for Swiss).
- A role with no dark value demotes the composition to light-only, exactly as an accent or series without one does
  (0.8.0 rule, extended to text roles). No dark value is invented.
- Composition (`Theme.composed(with:)`): a role named like one of Swiss's text roles (`ink`, `secondaryInk`, `link`,
  `positive`, `negative`, `warning`) **overrides** that role in the composed theme (so the app can override Swiss's
  positive, negative, warning and secondaryInk, finding 1's last clause); any other name lands in the theme palette's
  `extras`, which CSS and JSON already emit. So the web and terminal output carries the app's text colours too.
- Codable: `textRoles` and `textSurfaces` default when absent, so 0.8.0 JSON decodes.

### 2.2 Public contrast, and the `RGB` question (finding 2)

On `RGB` (not a new namespace, because the type the app already has in hand is the right home):

```swift
public var relativeLuminance: Double
public func contrastRatio(with other: RGB) -> Double          // 1...21, order-independent
public func meetsAA(on background: RGB, largeText: Bool = false) -> Bool   // 4.5, or 3.0 for large text
ValidationThresholds.largeTextContrast = 3.0
```

The internal `Contrast` enum keeps its call sites and forwards, so there is one formula. The comparison is unrounded
(`ratio >= 4.5`), the same comparison the validator makes, so an app's assertion and the validator cannot disagree.

**`RGB` name collision: documented, not renamed.** Measured on 2026-11-10: an app type named `RGB` *shadows* the
package's with no ambiguity error (module-local declarations win), so the collision costs a compile error only in a
file that wants both. The obvious qualifier `DesignTokens.RGB` does **not** work: the package's `public enum
DesignTokens` shadows the module name, so `DesignTokens.RGB` is "type 'DesignTokens' has no member 'RGB'" (a nested
`typealias RGB = RGB` in an extension of that enum is rejected as self-referential). A rename would break every
consumer (BusinessMath-UI, WineTaster, the generators, the dashboard) for a collision the contrast API removes the
cause of: an app declared its own `RGB` only because it had to write its own WCAG. The honest fix is to document that
(the app deletes its `RGB`) and not to promise a qualifier that does not exist. Written into
`HowAnAppAdoptsTheTokens.md`.

### 2.3 Host surfaces (finding 3)

```swift
public struct TextSurfaces: Sendable, Hashable, Codable {
    public var light: [ColorValue]                // required: the backgrounds text is drawn on in light
    public var dark: [ColorValue]?                // nil: the theme's own dark surfaces
    public var lightIncreased: [ColorValue]?      // nil: `light`
    public var darkIncreased: [ColorValue]?       // nil: `dark`
    public init(light: [UInt32], dark: [UInt32]? = nil, lightIncreased: [UInt32]? = nil, darkIncreased: [UInt32]? = nil)
}
public var textSurfaces: TextSurfaces?            // nil: the theme's background and surface (Swiss's, by default)
```

Every text role is measured against **every** surface of the appearance's list; a translucent surface is composited over
white (black in dark) as the theme's own surfaces are. With `textSurfaces == nil` the roles are measured on the
theme's `background` and `surface`, so a palette that draws only on Swiss's surfaces declares nothing. Subjects name
the surface by hex when declared (`"failure on #ECECEC"`), by role otherwise (`"failure on background"`).
Swiss's own roles are still validated on Swiss's surfaces by Swiss's own ledger and are unchanged.

`textSurfaces` is *what text is drawn on*, not a theme: it does not change the composed theme's surfaces or any chart.

### 2.4 Never plotted (finding 4)

Text roles are not series. A set that is printed with a word and never plotted is declared as `textRoles` and the
palette has `series: nil`: no chart check applies, because there is no series to check. The dashboard's six status
colours move from `series` to `textRoles`; the 7 `labelRequired` pairs and 22 ledger rows (all separation and
lightness-band findings about charts) do not exist. **Declined: a `neverPlotted` flag on `series`.** A set of colours
declared as series and exempted from every series check is not a series; the flag would be a second way to say "not a
series" that can be forgotten or contradicted (`labelTogether` and `seriesOrder` on a never-plotted set). One way, by
type. What is lost is honest: the old ledger recorded that the status colours are not distinguishable by colour alone.
That is now the app's documented rule (a word and a glyph always accompany a status colour), not a ledger row about a
chart that does not exist.

### 2.5 The theme environment default (finding 5)

`EnvironmentValues.theme` and `chartStyle` default to `Theme.swiss`, not `legacyDefault`. Why: 0.6.0 chose the legacy
default only to avoid changing any look "before the owner has seen the contact sheets"; Swiss has since been the
approved design (the 0.5.0 chart alignment, the Swiss ledger, every app palette composes onto it), and 0.8.0's
adoption flow validates against Swiss. A view that reads the environment without an injected theme should get the
look that was validated, not the one nothing validates against; an app that wants legacy injects it with
`.chartTheme(.legacyDefault)`. Source-compatible, visually breaking for a view with no theme injected. The one
`defaultValue` pair changes, and a test asserts both.

### 2.6 One typed source of truth (finding 6)

```swift
public protocol AppTextRole: RawRepresentable, CaseIterable, Sendable where RawValue == String {}
public enum NoTextRoles: String, AppTextRole {}            // the default

public protocol AppPaletteSource: Sendable {
    associatedtype TextRoles: AppTextRole = NoTextRoles    // defaulted: a conformer need not name it
    static var palette: AppPalette { get }
}
extension AppPaletteSource {
    static func text(_ role: TextRoles) -> Adaptive        // the declared colour, light/dark/increased
}
```

The app writes `enum Role: String, AppTextRole { case failure, ... }` and `typealias TextRoles = Role` beside its
palette, and views read `DashboardPalette.text(.failure)` (or `ChartStyle.color(_:)` on that). `validate()` cross-checks
the enum against the declared roles: a case with no declared colour and a declared colour with no case are each a
failing `structure` finding (`"text role failure (not declared)"`, `"text role x (no case in TextRoles)"`). That is the
drift guard: the roles are one typed source, the enum cannot disagree with what was validated, and a view can only ask
for a `Role`. `text(_:)` is total (an undeclared role, already a failing finding, reads as Swiss's `ink` rather than
trapping: there is no force-unwrap and no crash path in an app's view code).

What stays out of scope: forcing views to *only* use these (a literal colour in a view is the drift checker's job in
quality-gate-swift, not the package's), and a SwiftUI `Color` accessor (`ChartStyle.color(_ adaptive:)` already turns
the returned `Adaptive` into a dynamic colour).

## 3. The drift-checker marker contract

Unchanged. The checker (`DesignTokenDriftAuditor/SwiftDrift.swift`) reads syntactically: a declaration whose inheritance
clause lists `AppPaletteSource` and exactly one `AppPalette(id: "<literal>"` call in the file. The new fields are
labelled arguments after `id:` in the same call; the associated type is a `typealias` inside the conforming type, which
the visitor does not look at; no second `AppPalette(` call is needed anywhere. The colour literals in `textRoles` and
`textSurfaces` live in the palette file, which is the file the checker already exempts. I read the checker; I did not
modify it. One observation for that repo, not a break: `AppPaletteSource` now has an associated type, so `any
AppPaletteSource` is no longer a valid existential spelling anywhere (nothing in the package uses one).

## 4. Tests (red first)

- `RGB` contrast: anchors (21, 1, #777777 on white = 4.48, not AA), order independence, large text, equal to the
  internal `Contrast`, written against an independent formula.
- Text roles: measured as text only (no chart check ever appears), subjects and values equal the independent WCAG
  figure, AA guarantee asserted and a below-4.5 role fails, increased slot measured only where present, no-dark demotes,
  override of Swiss names lands in `palette.<role>`, other names in `extras`, 0.8.0 JSON decodes, round trip.
- Surfaces: a role that passes on Swiss's surfaces and fails on the host's darker grey is a finding only when the host's
  list is declared; dark list; defaults.
- Typed roles: `text(_:)`, an enum case without a colour, a colour without a case.
- Environment defaults are Swiss (SwiftUI test target).
- The dashboard-shaped worked example (the proof of done): re-expressed 7 roles, 4+4 backgrounds, the old 22-row ledger
  as a series set, then the new form: 0 findings, 0 label requirements, AA asserted per role on every background,
  Swiss's own roles still validated on Swiss's surfaces by `Theme.swiss.conformance`.

## 5. Not doing

- Large-text thresholds per role (WCAG's 3:1): `largeText` exists on `meetsAA`, but a role is always held to 4.5.
- A `neverPlotted` flag (2.4). Renaming `RGB` (2.2).
- Checking the app's views for literal colours (the drift checker's job).
