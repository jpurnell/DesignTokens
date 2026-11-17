# Design Proposal: The Standards Guide (token gaps, a browsable specimen with dos and don'ts, and an MCP)

**Status:** Proposed, 2026-11-17. Not approved. No code written.
**Owner decisions 2026-11-17:** (1) the MCP works with **any registered theme** and compares them (FT vs Economist vs Swiss vs House); (2) **standards.site is not used** (it is paid and not needed): its help center is read only as a checklist of what a guide covers; (3) the specimen is hosted on the owner's site, `justinpurnell.com`; (5) what travels is **just the theme definition**, readable without this package and loadable by the MCP (4.11); a page and a small app with a target per major platform take a definition and demonstrate it (4.12); the Reunions Typeface is **Taylor Penton's Lennon** (4.10); (6) **tvOS and watchOS count** as platforms the demo and the tokens must serve, because live packages extend to them; (7) the demo should be a **playground for the site's page managers**, so a theme must **hot-reload** (4.13); (8) the reunions pages with inline styles **should be fixed to be flexible** (4.14); (4) the **Princeton Class of 2000 reunions site** (`reunions.princeton2000.org`) is the first real adopter and gets its own theme, with measurements taken from the live page (section 4.10).
**Master Plan Reference:** Phase 1b (theme model) extended; new Phase 6, "the guide". Reconcile `project/master_plan.md` on approval.
**Source of the comparison:** the standards.site help center (https://help.standards.site/), read 2026-11-17: 22 pages across the four groups below, plus Automations, Components, Color, Fonts, Accessibility, Localization, Project Export, `standards.md` and MCP from an earlier pass. The pages give **structure, not values**: no spacing, radius, duration, easing or shadow numbers appear on any of them. Nothing in this proposal is copied from their numbers.

Sidebar groups, read from the site's own navigation data (the earlier guess at the grouping was wrong in four places and is corrected here):

| Group | Pages |
|---|---|
| Content Elements | Text, Media, Button, Dropdown, Video, Sequence, Toggle |
| Editor & Design | Adding Content, Automations, Components, Layouts, Grid, Pages, Responsive Optimizations, Menu, Search, Copying & Moving Content, Files & Downloads |
| Styling | Fonts, Color, Effects |
| Behaviors | Click & Hover Behaviors, States, Tooltips, Links |

---

## 1. Objective

Three deliverables, in dependency order:

1. **Close the token gaps** the comparison exposed, as additive `Theme` data: breakpoints, a state matrix, motion, effects, text depth, colour pairings and proportion, print colour, gradients, scrollbar, icon sizing, optional brand marks.
2. **A browsable specimen**: a generated, static, per-theme guide whose every section shows distinct **Do** and **Don't** examples, rendered from the live theme and checked by the validator, so a Don't is demonstrably wrong and a Do demonstrably right.
3. **An MCP server** that serves the same guide to agents and to future projects, so "what is the accent on dark with Increase Contrast?" and "may I put orange text on this surface?" are answered from the source, not from memory.

## 2. Motivation

**Current situation.** The values are held once and validated (palette, ledger, ten themes, `components.css`, a Chrome-driven state check in 0.13.0), but nothing a person outside this repo can read says *how to use them*. The knowledge sits in ledgers, DocC and the owner's head. Adopters (FleetWatch, Vault, the dashboard, Ignite) each reported gaps one by one, which is how 0.9.0 to 0.14.0 happened.

**Workaround today.** An adopter reads `components.css`, the gallery PNGs and `SwissConformanceLedger.md`, then discovers a misuse when the validator or a reviewer catches it, or never.

**Drawbacks.** Misuse is found late. The same question gets answered per project. Agents guessing at tokens produce plausible but wrong CSS. And the comparison shows a real set of unmodelled things (below).

**What the comparison showed** (our state is from this repo's code at `7cc3266`; "absent" means a grep of `Sources/` found nothing):

| standards.site | Ours | Gap |
|---|---|---|
| Responsive Optimizations: desktop over 1020 px, tablet 1020 to 600, mobile 600 and under; per-breakpoint overrides | One query, `(max-width: 600px)`, a constant in `BrowserSupport.Breakpoints` | No tablet tier; breakpoints are not theme data |
| Grid: max grid width, columns per breakpoint, margin, gutter | `LayoutSpec`: `margins`, `gaps`, `gutter`, `columns` | No max content width, no per-breakpoint columns |
| States: a matrix per element, inheriting from Default, overrides tracked; Search input has Loading | States verified in Chrome in 0.13.0; none declared | No state matrix as data, so no test can enforce it |
| Effects: drop shadow, backdrop filter, rotate, stretch | `ShadowSpec` only | No backdrop blur or translucency |
| Sequence and Toggle: Behavior (Instant, Slide, Fade), Motion, Duration | Transitions written inside the CSS emitters | No motion tokens |
| Text: paragraph spacing in line heights, responsive text scaling, OpenType toggles, variable axes | `TextSpec`: size, weight, tracking, italic, uppercase, lineHeight | None of the four |
| Menu: scrollbar track and thumb colour, width, radius; Translucent style | none | No scrollbar tokens |
| Tooltips and Links as named style categories | Colour and type roles; `link` colour | Whether tooltip and link exist as theme data must be checked (open question) |
| Color: Name, HEX, RGB, CMYK, PMS, RAL; gradients | HEX with alpha, light, dark, increased contrast | No print values; no gradients |
| Color automations: Combinations, Contrast, Proportion, Albers' proportion, Don'ts | Contrast validated; pairings and proportion not declared | No sanctioned pairings, no usage ratio |
| Logo automations: Specimen, On color, Single color, Scaling, Don'ts | none | No brand-mark rules |
| Don'ts in Logo, Type and Color | none | No misuse examples anywhere |
| Strategy and Language: Audience, Mission, Personality, Principles, Tagline, Calls to action | none | No voice or principles |
| Accessibility: heading levels, button labels, section labels, alt text | Contrast and colour-vision validation | No author guidance |
| Components: lock content, overrides, reset | `dt-` components | No statement of what may be overridden |
| standards.md and MCP (Pro and Enterprise) | JSON, CSS, ANSI, slides, Tumblr emitters | No agent-readable guide |
| Iconography, imagery | none (they have none either) | Added deliberately: small, see 4.6 |

## 3. Proposed Architecture

**Principle: the guide is generated from the theme and the validator, never hand-drawn.** A guide that is drawn by hand drifts the way `master_plan.md` drifts. A Do is a component rendered with theme tokens. A Don't is the same component with *one deliberate violation applied*, and a test proves a checker rejects it. If a Don't cannot be shown to fail, it does not ship.

**Module placement**

```
Sources/DesignTokens/                 (Foundation only, unchanged dependency list)
  Theme/Breakpoints.swift             new  breakpoint tiers, per-tier overrides
  Theme/MotionSpec.swift              new  durations, easings, behaviours, reduced-motion rule
  Theme/EffectSpec.swift              new  backdrop blur, translucency (extends ShadowSpec)
  Theme/TextDepth.swift               new  paragraph spacing, responsive scale, font features
  Theme/ScrollbarSpec.swift           new
  Theme/IconSpec.swift                new  sizes and stroke, tied to base unit and rule weights
  Theme/PrintColour.swift             new  authored CMYK / PMS / RAL, optional per role
  Theme/Gradient.swift                new  optional; fills only
  Theme/ColourGuidance.swift          new  sanctioned pairings, proportion
  Theme/StateMatrix.swift             new  component -> states -> overrides
  Theme/BrandMarks.swift              new  optional; empty by default
  Guide/Guideline.swift               new  Do / Don't model
  Guide/GuideCatalogue.swift          new  the authored rules, per topic
  Guide/GuideChecks.swift             new  proves each Do passes and each Don't fails
  Emitters/SpecimenEmitter.swift      new  static HTML per theme
  Emitters/StandardsMarkdownEmitter.swift  new  standards.md per theme
  Emitters/GuideJSONEmitter.swift     new  canonical guide JSON per theme
  Guide/ThemeDefinition.swift         new  the handed-over theme: format version, strict size-capped reader
  Apps/ThemeDemo/ (+ ThemeDemoScenes target)  new  shared scenes and a thin app shell per platform (4.12)
  Guide/ThemeComparison.swift         new  pure function: N themes x a section -> rows, differences (used by MCP and specimen)
  Emitters/ComparisonEmitter.swift    new  the specimen's "compare themes" page
Generated/standards/<theme>/index.html, standards.md, guide.json     new, golden-tested

DesignTokensMCP/  (new sibling package, like DevGuidelinesMCP, GeoSEOMCP, SearchOperatorMCP)
  depends on DesignTokens (path or tag), SwiftMCPServer, swift-mcp-sdk (the pinned fork)
```

**Why a sibling package for the MCP.** The master plan states "Dependencies: none (Foundation only)". `SwiftMCPServer` is a real dependency. Putting it in this package would end that, and every adopter (SwiftUI apps, Ignite) would resolve an MCP stack they never use. A sibling package follows the existing `DevGuidelinesMCP` layout and imports `DesignTokens` directly, so the server reads `Theme.all` and the catalogue in-process and **cannot drift from the emitted files**.

**Modified files:** `Structure.swift` and `Theme.swift` (new optional fields, all `decodeIfPresent`), `ThemeCodec.swift` (canonical key order), `ComponentsCSSEmitter.swift` and `ThemeCSSEmitter.swift` (emit the new properties), `BrowserSupport.swift` (breakpoints read from the theme, constant kept as the default), `ThemeValidator.swift` (new rules), `Generator`, `design-tokens` CLI (`emit --guide`).

### Phasing (each step is a releasable, golden-tested increment)

| Step | Delivers | Visual change |
|---|---|---|
| 0 | **Make the core build on every platform it should serve.** Move or guard the process-spawning code (`BoundedProcess`, used by the Chrome blog fetcher) so `DesignTokens` and `DesignTokensSwiftUI` build for tvOS and watchOS as well as macOS, iOS and visionOS; add a CI-style check that builds each | Nothing visible; the library gains two platforms |
| A | **Promote what exists.** Extract the transition values, the 600 px breakpoint and the shadow already written inside the emitters into `MotionSpec`, `Breakpoints`, `EffectSpec`. | None. The goldens must not change; that proves it. |
| B | New values: tablet tier, max content width, per-tier columns, backdrop blur, text depth, scrollbar, icon sizing, gradients | Additive; only themes that opt in change |
| C | Colour guidance: pairings, proportion, print values; validator rules | None |
| D | State matrix, enforced by a test that drives each declared state | Fixes anything it finds |
| E | `Guideline` model, catalogue, `GuideChecks`, `ThemeComparison` | None |
| F | Specimen (with the compare page), standards.md, guide.json emitters; the copy into `justinpurnell.com` | New generated files; new pages on the site |
| G | `DesignTokensMCP`, including `compare_themes` over every registered theme | New package |
| H | `princeton2000` theme and `BootstrapThemeEmitter` (4.10). Needs only the colour and type steps, so it can land any time after C. **No deadline:** the next reunion is about four years away (owner, 2026-11-17), so it is sequenced for convenience, not urgency | New theme; the site's `theme.css` can drop its hard-coded colours |
| I | **The theme definition** (4.11): hardened reader, `design-tokens check` and `emit --from`, MCP `--theme`; **the demo** (4.12): `ThemeDemoScenes`, macOS, iOS and iPadOS, visionOS, tvOS, watchOS, terminal; **hot reload** (4.13) | A small app per platform; no change to the library |
| J | **The reunions pages** (4.14): replace inline styles that carry theme values with role classes, in the site's own repository | A branch there, reviewed by the owner; nothing in this package |

A step ships only after the previous is green. Steps A to D are useful without F or G.

## 4. API Surface

All new types are `Sendable, Hashable, Codable`, value types, and every `Theme` field is optional with a default that reproduces today's output (the 0.4.0 rule: "every new field defaults to the old behaviour").

### 4.1 Breakpoints and layout

```swift
/// A viewport tier. Widths are the upper bound in CSS pixels; `nil` means unbounded.
public enum BreakpointTier: String, Sendable, Hashable, Codable, CaseIterable { case desktop, tablet, mobile }

public struct Breakpoints: Sendable, Hashable, Codable {
    /// Largest viewport width that is still `tablet` / `mobile`. Defaults: 1020 and 600 (see Open Question 3).
    public var tabletMaxWidth: Int
    public var mobileMaxWidth: Int
    public func mediaQuery(for tier: BreakpointTier) -> String   // "(max-width: 600px)"
    public init(tabletMaxWidth: Int = 1020, mobileMaxWidth: Int = 600) throws  // throws if tablet <= mobile or either <= 0
}

public struct LayoutSpec {          // extended
    public var maxContentWidth: Double?                 // nil = unbounded (today)
    public var columnsByTier: [BreakpointTier: Int]     // default: [.desktop: columns, .mobile: 1]
}
```

### 4.2 Motion and effects

```swift
public struct MotionSpec: Sendable, Hashable, Codable {
    public struct Easing: Sendable, Hashable, Codable { public var x1, y1, x2, y2: Double }  // cubic-bezier; x in 0...1 enforced
    public var fast: Int, base: Int, slow: Int          // milliseconds, fast < base < slow
    public var standard: Easing, enter: Easing, exit: Easing
    public var behaviour: TransitionBehaviour          // .instant | .slide | .fade
    public var reducedMotion: ReducedMotionRule       // .none | .fadeOnly (never movement)
}
public struct EffectSpec { public var shadow: ShadowSpec?; public var backdropBlur: Double?; public var translucency: Double? }
```

### 4.3 Text depth

```swift
public struct TextDepth: Sendable, Hashable, Codable {
    public var paragraphSpacingInLineHeights: Double?      // theirs: measured in line heights
    public var scaleByTier: [BreakpointTier: Double]        // multiplier on size, headings scale more
    public var headingScaleBoost: Double
    public var features: [FontFeature]                      // e.g. tabularFigures for numerals
}
```

### 4.4 Colour: pairings, proportion, print, gradients

```swift
public struct ColourPairing: Sendable, Hashable, Codable {
    public var foreground: ColorRole, background: ColorRole
    public var use: PairingUse          // .text | .largeText | .graphic | .decorative
    public var note: String
}
public struct ColourProportion: Sendable, Hashable, Codable { public var role: ColorRole; public var share: Double }  // shares sum to 1.0 ± 1e-9
public struct PrintColour: Sendable, Hashable, Codable { public var cmyk: [Double]?; public var pantone: String?; public var ral: String? }
public struct GradientSpec: Sendable, Hashable, Codable {
    public enum Kind: String, Sendable, Hashable, Codable { case linear, radial, conic }
    public var kind: Kind; public var stops: [Stop]; public var angle: Double?
    /// Fills only. Never text, icon colour, stroke or a chart mark (mirrors their rule; the validator enforces it).
}
```

**Print values are authored, never computed.** Their own docs warn that automatic CMYK can differ from the screen colour. We store a value only if the owner supplies it from a proof, validate its shape (four components in 0 to 100, a Pantone string that parses, an RAL number in the RAL Classic range), and mark it `authored` in the guide. The guide says "not verified against a print proof" unless a proof reference is recorded.

### 4.5 State matrix

```swift
public enum ComponentState: String, Sendable, Hashable, Codable, CaseIterable {
    case rest, hover, active, activeHover, focus, focusHover, loading, open, closed, disabled, invalid
}
public struct StateMatrix: Sendable, Hashable, Codable {
    /// component class (e.g. "dt-button") -> the states it must style
    public var states: [String: [ComponentState]]
    /// A state inherits from `rest`; only these properties may differ. Anything else is a defect.
    public var mayOverride: [String: Set<StateProperty>]
}
```

A state is not enough on its own: each declared state must also **pass contrast** against its surface. `disabled` is declared here even though standards.site has none, since we already ship and verify it.

### 4.6 Smaller models

```swift
public struct ScrollbarSpec { public var trackWidth, thumbWidth, thumbRadius: Double; track: ColorRole; thumb: ColorRole }  // thumbWidth <= trackWidth
public struct IconSpec { public var sizes: [Double]; public var strokeWeight: Double; public var alignsTo: RuleWeight }       // sizes on the 4 pt base
public struct BrandMarks { public var clearSpaceInBaseUnits: Double; public var minimumWidth: Double; public var variants: [MarkVariant] } // optional, empty by default
```

### 4.7 The guide

```swift
public enum GuidelineKind: String, Sendable, Hashable, Codable { case `do`, dont }
public enum GuideTopic: String, Sendable, Hashable, Codable, CaseIterable {
    case colour, typography, layout, spacing, components, states, motion, effects, iconography, charts, accessibility, voice, marks
}

public struct Guideline: Sendable, Hashable, Codable, Identifiable {
    public var id: String                     // "colour.text-on-surface.do-1"
    public var topic: GuideTopic
    public var kind: GuidelineKind
    public var rule: String                   // one sentence, imperative
    public var example: Example               // what is rendered
    public var evidence: Evidence             // what proves it
}

public enum Example: Sendable, Hashable, Codable {
    case swatchPair(foreground: ColorRole, background: ColorRole)
    case component(class: String, state: ComponentState, violation: Violation?)   // nil = the Do
    case typeSample(TypeRole, violation: Violation?)
    case chartSlot(Int, onSurface: ColorRole, violation: Violation?)
    case prose(String)                       // voice and principles; no render check possible
}
public enum Violation: Sendable, Hashable, Codable {
    case lowContrast, wrongRole(ColorRole), stretched, tooSmall(Double), tracking(Double), missingState(ComponentState), gradientOnText, mixedRadius, offGrid(Double)
}
public enum Evidence: Sendable, Hashable, Codable {
    case validator(Finding.Kind)             // a Don't: this finding must appear
    case measured(minimumContrast: Double)   // a Do: must meet this
    case ledger(String)                      // cites a SwissConformanceLedger row
    case authored                            // prose; flagged "unchecked" in the output
}

public struct GuideCatalogue: Sendable {
    public static func guidelines(for theme: Theme) -> [Guideline]
    public static func verify(_ theme: Theme) -> [GuideDefect]        // empty means every Do passes and every Don't fails
}
```

### 4.7b Comparing themes

```swift
public enum ComparisonSection: String, Sendable, Hashable, Codable, CaseIterable {
    case colour, type, space, rules, radius, motion, breakpoints, effects, chart, conformance
}
public struct ComparisonRow: Sendable, Hashable, Codable {
    public var key: String                      // "accent", "title.size", "ledger.directLabelSlots"
    public var values: [String: String]         // theme id -> rendered value; absent = unavailable
    public var allEqual: Bool                   // every compared theme has this key and the same value
}
public struct ThemeComparison: Sendable, Hashable, Codable {
    public var section: ComparisonSection
    public var themes: [String]                 // order preserved as requested
    public var rows: [ComparisonRow]
    public var unavailable: [String]            // themes lacking the appearance or section
    /// Throws `.fewerThanTwoThemes`, `.duplicateTheme`, `.unknownTheme(id, valid:)`.
    public static func compare(_ ids: [String], section: ComparisonSection,
                               appearance: Appearance, contrast: Contrast) throws -> ThemeComparison
}
```

It is a pure function over `Theme.all`, so the MCP tool, the specimen's compare page and a unit test all call the same code. Properties held by tests: comparing a theme with itself reports every row `allEqual`; the result does not depend on the order of the ids except for column order; a value shown is byte-equal to the value the single-theme path (`get_tokens`) returns.

### 4.8 Emitters

```swift
public enum SpecimenEmitter {
    /// Static HTML: no script required, light and dark, prefers-contrast aware. It need not be a single self-contained file (owner, 2026-11-17).
    public static func html(for theme: Theme) -> String
}
public enum StandardsMarkdownEmitter { public static func markdown(for theme: Theme) -> String }
public enum GuideJSONEmitter { public static func json(for theme: Theme) throws -> Data }   // canonical key order
```

CLI: `design-tokens emit --guide` writes `Generated/standards/<theme>/`.

### 4.9 Specimen layout (what the reader sees)

One page per theme, a sticky contents list, each section a **Do** card beside a **Don't** card with the rule underneath and the evidence chip ("measured 7.9:1", "fails 3:1, see ledger row 4", "authored, unchecked"):

1. Principles and voice (authored, marked unchecked)
2. Colour: roles, palette, proportion, sanctioned pairings, Don'ts (the measured failures from the ledger are the Don't examples, so they are real)
3. Type: roles, hierarchy, paragraph spacing, Don'ts
4. Layout: grid, breakpoints (all three tiers shown), spacing, Don'ts
5. Components: every `dt-` class with its state strip (rest to disabled) and its overrides
6. Motion and effects, with the reduced-motion rendering shown side by side
7. Charts: the eight slots, which need direct labels (`SwissLedger.directLabelSlots`), Do and Don't
8. Iconography, marks (if present)
9. Accessibility: heading levels, labels, contrast, increased contrast
10. Downloads: links to `tokens.json`, `<theme>.css`, `components.css`, slides and terminal files
11. **Compare themes** (its own page): pick any two or more registered themes and a section; the table, swatches and conformance ledgers sit side by side, generated by `ThemeComparison` so the page and the MCP agree. Static: every pairwise and the all-themes view are pre-rendered, no script required beyond a theme picker that shows or hides prebuilt columns.

**Hosting.** The specimen is plain static files: it needs no server, so it can live on the owner's site, `justinpurnell.com`, which is an Ignite static site that already depends on `DesignTokens` (`from: "0.11.0"`; it would need a bump to a release containing the guide). See Open Question 7 for the mechanism. The MCP is not static and is not hosted by the site; v1 runs locally over stdio (Open Question 6).

### 4.10 First adopter: the Princeton Class of 2000 reunions site

`reunions.princeton2000.org` is an Ignite static site (Bootstrap 5.3, `data-bs-theme`) whose own styling is two small files: `theme.css` (1,374 bytes) and `layout.css` (1,031 bytes) over stock Bootstrap. The deployed CSS was fetched live on 2026-11-17 and is **byte-identical** to the local copy in `reunions2025/css/`, so that copy is a fair source for the site's rules.

**Live measurements** (Safari, the real page, computed styles, light appearance, 2026-11-17; contrast is WCAG relative luminance with alpha composited over the background):

| Element | Measured | Result |
|---|---|---|
| Nav links ("Store"), `#EE7F2D` on white | 2.72:1 | Below 4.5:1 for text, and below 3:1 |
| Footer line "© 2026 Princeton Class of 2000" | `rgba(33,37,41,0.5)` on white, effective `#909294`, **3.12:1**, at **6.4 px** (`.text-body-tertiary { font-size: .4rem }`) | Both too small and too faint |
| Body | 16 px Libre Franklin, line height 18.4 px (1.15) | Tight for running text |
| Headings and paragraphs | 15.43:1 and 21:1 | Fine |
| Brand orange for reference: package `Palette.princetonAccent` `#E77500` on white | 3.02:1 (computed, not live) | Passes 3:1 for graphics and large text, **fails 4.5:1 as text** |

So the site has a link colour that cannot be read by many people, and the package's own Princeton orange would not fix it as text. That is the specimen's first honest Do/Don't pair for the theme: brand orange is for marks, rules and large display, and **a darker text orange, measured to at least 4.5:1, is the link colour**. Its value is found by measurement against the site's surfaces (the way Swiss `positive` and `negative` were, 2026-11-09), not chosen here. Not yet measured: dark appearance (`theme.css` has dark-mode image rules, and the page declares `data-bs-theme`), the other roughly fifty pages, and mobile.

**A theme for it.** Add `princeton2000` (name: "Princeton 2000"), a *new* registered theme, not a change to `princeton`. `princeton` is the BusinessMath-UI chart theme (Swiss structure, light only) and other code reads its values; reunions needs a web theme with a dark appearance, an accessible link role and serif-and-sans type. Open Question 13 asks whether it should inherit from `princeton`.

**What the site needs that the package cannot emit today.**
1. **A Bootstrap bridge.** The site is Bootstrap, so tokens must arrive as Bootstrap's own custom properties (`--bs-body-color`, `--bs-link-color`, `--bs-body-bg`, the `data-bs-theme` light and dark blocks, `--bs-font-sans-serif`), not `dt-` classes. Proposed: `BootstrapThemeEmitter` writing `Generated/themes/<id>.bootstrap.css`, which the site loads after Bootstrap and which would replace the hard-coded `#EE7F2D` and `#444` in `theme.css`. This is the bridge that lets a site we do not rewrite adopt the theme; without it the theme is a document, not a fix. It joins the web-components work in 0.12.0 to 0.14.0 as another consumer of the same tokens.
2. **Type, and the identity face.** **The Reunions Typeface is Taylor Penton's *Lennon*** (the site's colophon), loaded as `TAYLennonRegular` from `fonts/tayLennon/` (`woff2` 14 KB, plus `woff`, `ttf`, `otf`, `eot`, `svg`) and used on at least a dozen pages: `h3.tayLennon` headings ("Our 25th Reunion", "The Latest") and banner lines set inline in brand orange at a fluid size (`calc(1.2rem + .5vw)`). **This was missed in the first pass** (the font list came from a truncated search); it is the center of the identity, so the theme's **display** and **heading** roles are Lennon, with **Libre Franklin** as the body face. The site also loads `franklin_gothic` and `princeton_monticello`; where those two are used on the page has *not* been checked, so they are listed in the theme only once a use is found (Open Question 21). **The owner confirmed 2026-11-17 that we can use the fonts.** Every family is named with a fallback (a system serif for display, then Libre Franklin) so a consumer without the files still renders, and the demo shows which families it could not find (4.12). Font files are not part of the theme definition (4.11).

   Two consequences the comparison with the live pages exposes: (a) the inline `style=` attributes carry the orange and the fluid size in each page's markup, so a Bootstrap-variable bridge fixes links, nav and body but **cannot reach inline styles**; those pages need a role class (a `dt-display` rule) instead, which is a site change, not a package one; (b) `calc(1.2rem + .5vw)` is a hand-written responsive type scale, the thing the **text depth** token (4.3, `scaleByTier`) exists to hold, so this site is concrete evidence for that gap and its numbers can seed the tokens.
3. **The tiny footer is accepted.** The 6.4 px copyright line is a deliberate choice, not a defect (owner, 2026-11-17). The theme therefore declares a `legal` text role at that size, and the conformance ledger **records it as an accepted finding with its reason**, the same mechanism Swiss uses for the system colours it keeps by decision. It is a ledger entry, not a suppression: it still appears in the guide and the MCP answers for it. The ledger entry covers the *size* only. The footer's measured contrast, 3.12:1, is a separate finding that the decision did not cover; it stays recorded until the owner says it is accepted too (Open Question 15).

**Why this helps the next reunion.** Several people and tools will make pages (the committee site, the jacket and gear pages, emails, slides, the QR code project in `Princeton/ReunionsQRCode`): they all need the same orange, the same type and the same "orange text is not for body copy" rule. `princeton2000` emits to CSS, Bootstrap variables, slides colour and font XML, ANSI and JSON from one definition, the MCP answers "may I put orange text on the photo banner?" from the source, and the compare page shows Princeton 2000 against Swiss, `princeton`, FT, Economist and House. Slides for the reunion committee are the existing `SlidesEmitter`'s job.

**Acceptance for this theme** (tests, not claims): the conformance ledger records every failing pair and the new text orange is at least 4.5:1 on every surface the site uses; the Bootstrap file, applied to a fixture built from the site's own `index.html`, leaves no link or footer below the stated floors, checked in headless Chrome and, because it is the browser the owner uses, Safari with the same probe used above; both appearances are measured; a golden test pins the generated files.

### 4.11 The theme definition: one small file you can hand over

**Requirement (owner, 2026-11-17, revised):** the thing passed around is **just the theme definition**, independent of this package. It is not a page and not a bundle of evidence. A page or a demo is a *separate* thing that takes a definition and shows it (4.12).

**This already half exists.** `Generated/themes/<id>.json` is the canonical `Theme` JSON from `ThemeCodec`, and it already carries the colour roles in every appearance, structure, type roles and the **conformance ledger** (the accepted findings and their reasons). So the definition file is that file, with three additions and a hardened reader; nothing about guidelines, evidence or fonts is stored in it.

```swift
public struct ThemeDefinition: Sendable, Hashable, Codable {
    /// Bumped when the format changes incompatibly. A reader rejects a version it does not know, naming the one it supports.
    public var formatVersion: Int                // to confirm: add only if ThemeCodec has no version today
    public var theme: Theme
    public var generator: String?                // "DesignTokens 0.x", informational
}
public extension ThemeDefinition {
    /// Strict, size-capped, JSON only. Unknown format version, an unknown key, a value out of range or an oversize file
    /// throw a typed `DefinitionError` naming the key; it never partially loads.
    static func read(_ data: Data) throws -> ThemeDefinition
    func encoded() throws -> Data                // canonical, byte-stable, the same bytes as ThemeJSONEmitter today
}
```

**Why guidelines and evidence are not in the file.** The Dos, Don'ts and their proof are *derived* by running the catalogue on the theme, so a definition cannot disagree with its guide, and a reader with the package always sees the current rules. A reader without the package gets the values and the ledger, which is what a handed-over theme needs. This is much smaller than the earlier bundle idea and removes its drift, checksum and font-embedding problems.

**Fonts are named, not carried.** The definition holds family names and fallbacks (`FontFamilyRef`). Font files stay where they are; that also removes the question of whether a licensed face (Lennon, the Princeton faces) may travel inside a file given to a third party.

**New CLI.** `design-tokens check <file.theme.json>` reads a definition, runs the validator and prints the findings and ledger; `design-tokens emit --from <file>` writes the CSS, Bootstrap, slides and ANSI files for a definition that is not registered in the package. This is how a theme made elsewhere becomes usable without editing Swift.

**The MCP reads definitions.** `--theme path/to/reunions.theme.json` (repeatable) registers each beside `Theme.all`, so `list_themes`, `compare_themes`, `check_pair` and `get_guidelines` work over a definition exactly as over a built-in. A definition whose id matches a built-in is rejected unless the user passes `--as <name>`, so a file cannot silently replace `swiss`. The reader only parses data: it never executes anything, never follows a path or URL inside the file, and rejects input over a cap (Resource Budget).

### 4.12 The demo: a small app, per platform, that shows any theme

**Requirement (owner, 2026-11-17):** a page and a small app with targets for each major platform that can take a theme definition and demonstrate it.

**What "demonstrate" means.** Given a definition (a built-in, or a file opened or dropped), the demo shows, live: the palette in light, dark and increased contrast; the type roles *rendered in the theme's actual faces* (so Lennon headings are visible, or the fallback is shown with a note that the family was not found); the components in every declared state; a chart with the eight series and which need direct labels; the ledger's accepted findings with their reasons; and the Dos and Don'ts with their evidence. Controls: appearance, contrast, text size, reduce motion, theme picker, and a **compare** view for two themes.

**Why native, not a web re-implementation.** The app uses the real `DesignTokensSwiftUI` (`ChartStyle`, the Swiss components, `Theme` to colours and fonts), so it shows what an adopting app gets, not an approximation. A browser page that interpreted an arbitrary definition would need either a second JavaScript copy of the CSS emitter (drift) or the Swift emitter compiled to WebAssembly (a toolchain this repo does not have). So the **web** demo is the static specimen (section 4.9) pre-rendered for every registered theme; a theme outside the registry is demonstrated in the native apps, or after `design-tokens emit --from`. Open Question 22 asks whether to take the harder web route.

**Targets**

| Platform | Basis | Notes |
|---|---|---|
| macOS | extends `swiss-gallery` | the existing gallery is macOS and Swiss-only |
| iOS and iPadOS | `DesignTokensSwiftUI` builds on iOS today | adaptive layout; render test already runs in the iOS Simulator for `SwissGalleryScenes` |
| visionOS | builds today per the master plan | glass and depth are system-driven: the demo says what the theme does not control |
| Web | the static specimen from 4.9 | no script needed beyond a theme picker over prebuilt columns |
| Terminal | `design-tokens demo <file>` | prints the ANSI role table and swatches; also runs on Linux |
| tvOS | **does not build today** | `DesignTokens` (the core) fails on tvOS: `Sources/DesignTokens/Emitters/BoundedProcess.swift` calls `posix_spawn_file_actions_*`, which tvOS marks unavailable (measured 2026-11-17 with `xcodebuild -scheme DesignTokensSwiftUI -destination 'generic/platform=tvOS Simulator'`). visionOS builds (`BUILD SUCCEEDED`). A prerequisite step (0) fixes it |
| watchOS | **not yet checkable** | no watchOS SDK is installed on this machine (`xcodebuild -showsdks` lists iOS, tvOS and visionOS only); install it, then run the same build. Expect the same `posix_spawn` failure |

**Structure.** One shared target, `ThemeDemoScenes`, holds the views (a generalisation of `SwissGalleryScenes` from Swiss to any `Theme`: to confirm by reading it); each platform target is a thin shell around it. The apps are not part of the `DesignTokens` library products, so the core stays Foundation-only. **How the iOS and visionOS apps are built** (an Xcode project under `Apps/` depending on this package, or a SwiftPM app product) is Open Question 24; a plain SwiftPM executable can be a macOS app but not an iOS one.

**Testing.** The shared scenes keep the existing render tests (macOS, iOS Simulator), extended with a visionOS Simulator run; every registered theme and one external definition file render without a crash in both appearances; a missing font renders the fallback and reports it; a malformed definition shows the typed error rather than a blank screen; screenshots of Princeton 2000 (Lennon headings, orange links, the ledgered footer) are reviewed by eye.

### 4.13 Hot reload: a playground for page managers

**Requirement (owner, 2026-11-17):** being able to hot-reload a theme is "incredibly valuable", because page managers may use this as a playground.

**Design.** The definition file is the single thing being edited. A watcher re-reads it when it changes and everything downstream refreshes, with no rebuild:

- **Native apps (4.12):** the app watches the opened definition file (a file-system event source on the file's directory) and re-renders on change. A malformed save shows the typed error over the last good render rather than a blank screen, so a half-typed edit never loses the preview.
- **The real web pages:** `design-tokens watch <file.theme.json> --out <dir>` re-runs the Swift emitters on every change and writes the CSS, the Bootstrap variables and the role-class stylesheet into `<dir>`. `design-tokens serve` is the same with a tiny local HTTP preview that serves `<dir>` beside a copy of the site's pages and tells the open browser tab to reload its stylesheet. Because the emitters are the real Swift ones, **what a page manager sees is what ships**, and there is no JavaScript copy of the emitter to drift. This is the answer to Open Question 22 that avoids both a JS mirror and WebAssembly.
- **No restart for the MCP:** a `--theme` file the server was started with is re-read when it changes, so asking `check_pair` after an edit answers for the edited theme.

**Constraints.** The watcher debounces (a save is often several writes), reads the file only after it is stable, and applies a change only if it decodes and validates; otherwise it keeps the previous theme and reports why. It watches only the paths it was given. The serve target is local-only (bound to the loopback address) and not part of the library, so the core keeps no networking dependency; where it lives follows Open Question 24.

**Tests.** A temporary directory with a definition: change one colour, assert the emitted CSS changes within a bounded time and only that property differs; write invalid JSON, assert the last good output is kept and an error is reported; write twice in quick succession, assert one reload; delete the file, assert a clear message and no crash.

### 4.14 The reunions pages: fix the inline styles

**Requirement (owner, 2026-11-17):** the pages with inline styles should be fixed to be more flexible.

**Measured, deployed site, 2026-11-17** (`reunions2025/`, identical to the live CSS):

| | Count |
|---|---|
| Pages | 153 |
| Pages with at least one inline `style=` | **153** (all of them) |
| Inline `style=` attributes in total | **4,812** |
| Inline `font-family: TAYLennonRegular` | **304** |
| Inline use of brand orange `#EE7F2D` | **152** |

Every page restates the identity (Lennon, orange, fluid size) by hand in its markup, which is why changing the theme cannot reach them and why the contrast problem (4.10) exists on every page at once.

**Approach.** Theme-carrying inline styles become **role classes**: the theme emits a stylesheet defining them (`.dt-display`, `.dt-display--accent`, `.dt-eyebrow`, and so on, named from the type roles), and the pages use the class. After that, changing the theme changes every page, and the page managers' playground (4.13) edits one file. Inline styles that are only *layout* (margins, alignment) are left alone: they are not theme values (Open Question 27).

**Where it lives.** In the site's own repository and source, not in this package. The deployed `reunions2025/` HTML is generated (the site is Ignite), so the change belongs where the markup is generated, as a branch the owner reviews. This package supplies the role-class stylesheet and the mapping from each inline style to a role; the migration itself is a separate piece of work in the other repository.

**Measured success.** Count inline `font-family`, colour and font-size declarations before and after, over all 153 pages; the target is **zero** theme-carrying inline styles, with the page rendering the same except where the theme deliberately differs (the new text orange); compare screenshots of a sample of pages in light and dark.

## 5. MCP Schema

**Server:** `design-tokens-mcp`, built on `SwiftMCPServer` like `DevGuidelinesMCP`. Read-only. No tool mutates anything; no tool takes a path; no tool reads outside the compiled-in `Theme.all` and catalogue.

**Tools**

| Tool | Purpose |
|---|---|
| `list_themes` | every registered theme (`Theme.all`: swiss, house, princeton, ft, economist, console, and the legacy ones): id, name, appearances, conformance kind |
| `compare_themes` | **two or more themes side by side** on a section (colour, type, space, rules, radius, motion, breakpoints, chart, conformance): values, and what differs |
| `get_tokens` | one theme's values for a section, appearance and contrast |
| `get_component` | a `dt-` component: classes, states, overridable properties, its Dos and Don'ts, for one theme or several |
| `get_guidelines` | the Do and Don't list for a topic; which guidelines hold in which theme |
| `check_pair` | contrast and sanction for a foreground and background, in one theme or across several |
| `explain_finding` | what a ledger finding means and which slots need direct labels |
| `get_standards_md` | the whole guide for a theme as markdown |
| `search_guide` | text search over rules and captions, across all themes unless one is named |

**The server is theme-agnostic by construction.** There is no theme named in the server's code: it asks `Theme.all` at start-up, so a theme registered in the core package (the next house style, an adopted app palette composed on a theme) appears in every tool with no change to the MCP. A test asserts `list_themes` equals `Theme.all` ids, so a new theme that the server fails to expose is a failing test, not a silent omission. A theme that is light-only (Princeton, House) answers a dark request with a typed "no dark appearance" result, not a guess.

**Resources:** `standards://<theme>/standards.md`, `standards://<theme>/guide.json`, `standards://<theme>/specimen.html`, and `standards://compare/<a>,<b>[,<c>...]/<section>`.

**Tool Description (`compare_themes`):** Compare two or more themes on one section and report what is the same and what differs.

**REQUIRED STRUCTURE (JSON):**
```json
{
  "themes": ["ft", "economist", "swiss", "house"],
  "section": "colour",
  "appearance": "light",
  "contrast": "standard",
  "onlyDifferences": false
}
```

**Parameter Types:**
- themes (array of string): two to ten theme ids from `list_themes`, no duplicates. Required.
- section (string): `colour, type, space, rules, radius, motion, breakpoints, effects, chart, conformance`. Required.
- appearance (string): `"light"` or `"dark"`. Default `"light"`. A theme without that appearance is reported as `unavailable`, not omitted.
- contrast (string): `"standard"` or `"increased"`. Default `"standard"`.
- onlyDifferences (boolean): when true, drop rows every theme agrees on. Default false.

**Result (JSON), shape only:**
```json
{
  "section": "colour",
  "themes": ["ft", "economist", "swiss", "house"],
  "rows": [
    { "key": "accent", "values": { "ft": "#RRGGBB", "economist": "#RRGGBB", "swiss": "#RRGGBB", "house": "#RRGGBB" }, "allEqual": false }
  ],
  "unavailable": [],
  "summary": "…"
}
```
For `section: "conformance"` each theme's ledger is compared: which findings it carries (for example the slots that need direct labels) and whether its conformance is `strict`, `ledger` or `legacy`. This is the answer to "which of these four can I plot eight series on without direct labels?"

**Tool Description (`check_pair`):** Check whether a foreground may be used on a background in a theme, and why.

**REQUIRED STRUCTURE (JSON):**
```json
{
  "theme": "swiss",
  "foreground": "accent",
  "background": "background",
  "appearance": "light",
  "contrast": "standard",
  "use": "text"
}
```

**Parameter Types:**
- theme (string): a theme id from `list_themes`. Required.
- foreground, background (string): a role name (`accent`, `label`, `positive`, ...) or a `#RRGGBB` hex. Required.
- appearance (string): `"light"` or `"dark"`. Default `"light"`.
- contrast (string): `"standard"` or `"increased"`. Default `"standard"`.
- use (string): `"text"`, `"largeText"`, `"graphic"`, `"decorative"`. Default `"text"`.

**Result (JSON):**
```json
{
  "ratio": 4.52,
  "requiredRatio": 4.5,
  "passes": true,
  "sanctioned": true,
  "guideline": "colour.text-on-surface.do-1",
  "advice": null
}
```
`ratio` is computed by the same `RGB.contrastRatio(with:)` the validator uses; the numbers above are the shape, not measured values.

**Tool Description (`get_guidelines`):**
```json
{ "theme": "swiss", "topic": "colour", "kind": "dont" }
```
- topic (string): one of `colour, typography, layout, spacing, components, states, motion, effects, iconography, charts, accessibility, voice, marks`. Required.
- kind (string, optional): `"do"` or `"dont"`; omit for both.

**Tool Description (`get_tokens`):**
```json
{ "theme": "console", "section": "motion", "appearance": "dark", "contrast": "increased" }
```
- section (string): `colour, type, space, rules, radius, motion, breakpoints, effects, print`.

Stochastic functions: none, so no seed. Dates: none returned; the guide carries `DesignTokens.version` and the OS release it was measured on, as strings. Enum values are listed exhaustively above and generated from the `CaseIterable` types so the schema cannot drift from the code.

## 6. Constraints & Compliance

- **Concurrency:** all types are immutable `Sendable` values. The MCP server holds `Theme.all` and the catalogue as `let` state.
- **Safety:** no force unwraps, `try!` or casts. Every divisor guarded (the pairing and proportion math divides by nothing but is checked to sum to 1). Hex and print parsing strict, like the existing colour parsing.
- **Determinism:** emitters are pure functions of a `Theme`, canonical key order, no dates in the output other than the recorded version; golden-tested.
- **Foundation only** in the core; the MCP dependency lives in its own package.
- **DocC** on every public API; a narrative article (section 17).
- **Quality gate:** 0 errors and 0 warnings, no suppressions.
- **No hand-drawn assets.** The specimen is HTML and CSS plus inline SVG only: no images to go stale, no web fonts downloaded, so it works offline and from a file URL.

## 7. Source & API Compatibility

**Breaking changes:** none intended. Every new `Theme` and `LayoutSpec` field is optional with a default equal to today's behaviour; `ThemeCodec` writes a new key only when it is set, so existing `Generated/themes/*.json` stay **byte-identical** until a theme opts in. Step A is the proof: its only acceptance criterion is "every golden file unchanged".
**Incremental adoption:** yes. An adopter can ignore the guide and the MCP entirely.
**Type-checking risk:** no overloads of existing functions. `BrowserSupport.Breakpoints.narrowMediaQuery` stays as the documented default and becomes `Breakpoints().mediaQuery(for: .mobile)`; the constant is kept, so callers (the dashboard, FleetWatch, Vault) are not broken.
**One caution:** if the tablet tier changes any existing layout (Open Question 3), that is a visible change and a minor-version bump, called out in the CHANGELOG.

## 8. Backend Abstraction

N/A. Nothing here is compute-intensive: contrast checks over tens of colours, HTML string generation.

## 9. Resource Budget

**Data read:** the ten themes' values, held as Swift constants compiled in. Today `Generated/themes/` is about 1.2 MB for 68 files; `components.css` 42 KB. No files are read at run time by the MCP server.
**Held vs streamed:** the server holds `Theme.all` (about 10 themes at a few KB each as structs) and the catalogue. Specimen and markdown strings are built per request and discarded.
**Growth:** grows with the number of themes and guidelines, linearly. At 20 themes and 300 guidelines each, still well under a megabyte of structs.
**Budget:** MCP server at most 50 MB resident at rest, 80 MB peak while serving a full specimen and with ten definition files loaded. Each generated `index.html` under 1 MB (no fonts are embedded anywhere); a theme definition is on the order of 10 to 30 KB today (`Generated/themes/*.json` are 10 to 27 KB), and the reader rejects any input over 1 MB before parsing it, so a hostile file cannot make the server grow.
**Measured by:** a test asserting each emitted specimen's byte size; the server's `phys_footprint` read with `footprint <pid>` after serving every tool once and compared with the first reading.
**Lifetime:** long-running. A repeated `get_standards_md` loop must not grow the process; the measurement above is repeated 1,000 times.

## 10. Dependencies

**Internal:** `Theme`, `ThemeValidator`, `SwissLedger`, `ComponentsCSSEmitter`, `ThemeCodec`, `BrowserSupport`, `RGB.contrastRatio`.
**External:** core: none (unchanged). MCP package: `SwiftMCPServer` (`from: "5.5.0"`) and the pinned `swift-mcp-sdk` fork, exactly as `DevGuidelinesMCP` declares them (SwiftPM identity trap noted in that Package.swift: reuse its exact URLs).
**Deployment:** not decided here. Build on the target host (per standing notes) and verify the Swift version there rather than reciting it; which host runs it is Open Question 6.

## 11. Test Strategy

**Test categories**
- **Golden path:** each new emitter's output equals the committed file; step A leaves every existing golden unchanged.
- **Edge cases:** breakpoints with `tablet <= mobile`; proportion shares that do not sum to 1; a thumb wider than its track; a gradient assigned to text; an empty state matrix; a theme with no dark appearance (Princeton, House) rendering a light-only specimen; zero guidelines for a topic.
- **Invalid input:** MCP tools given an unknown theme, role, topic, or malformed hex return a typed error naming the valid values; nothing throws past the protocol boundary.
- **Round trip:** every new type survives `ThemeCodec` encode and decode, and a theme with none of the new fields encodes exactly as before.
- **Determinism:** the same theme emits identical bytes twice.
- **The central property test:** for every theme and every `Guideline`, `GuideCatalogue.verify` finds no defect: each **Do** passes its evidence (`measured`) and each **Don't** reproduces its finding (`validator` or `ledger`). A Don't that stops failing, or a Do that starts failing, fails the build. This is what makes the specimen trustworthy.
- **State matrix:** for each component and declared state, drive the state in headless Chrome over the DevTools protocol as 0.13.0 did, and assert the computed style differs from `rest` only in `mayOverride` and that contrast holds.
- **Theme comparison:** `compare` over `["ft","economist","swiss","house"]` for every section and both appearances returns a row for every key any theme has; a value equals the single-theme `get_tokens` value byte for byte; self-comparison is all-equal; one id, a duplicate id and an unknown id each give the typed error; light-only themes (Princeton, House) are listed `unavailable` for dark, never dropped; the MCP's `list_themes` equals `Theme.all` ids, so a theme added to the package is exposed with no server change. Expected values are read from the themes, not retyped in the test.
- **Theme definition:** every registered theme's canonical JSON reads back as an equal `Theme`; a definition read in a process that never touches `Theme.all` works; an unknown `formatVersion`, an unknown key, an out-of-range value, truncated JSON and a file over the cap each throw their typed error and load nothing; a definition whose id matches a built-in is rejected by the MCP unless renamed; the MCP lists, compares and checks a pair across a definition and a built-in together; `design-tokens check` on a known-bad definition reports the same findings as the validator in-process.
- **MCP:** call every tool in-process against the server's registry (as `DevGuidelinesMCPTests` does) and once over the real transport; run the official conformance suite the way `SwiftMCPServer` documents.
- **Rendered check:** the specimen opened in headless Chrome at 1200 and 390 px, light and dark, Increase Contrast and reduced motion; screenshots reviewed. Safari and Firefox stay "unverified" until run, as now.

**Reference truth (independently checkable, no invented numbers)**
- Contrast: the WCAG 2.x relative luminance formula, already in `RGB.contrastRatio` and cross-checked in `JavaScriptCrossCheckTests` against the pinned `validate_palette.js`.
- Failing examples: the rows of `project/docs/technical/SwissConformanceLedger.md` (per the README, orange, green, yellow and cyan are under 3:1 on the light surface, so those four need direct labels). Test expectations are read from the ledger rows, not retyped.
- Print colour: nothing to compute against, which is the point; the test checks shape and the "authored" flag, not equivalence to the screen colour.
- Their structure is the reference for *what to cover*, never for values.

**Validation Trace (REQUIRED)**
- *Input:* the Swiss theme, guideline `charts.slot-on-light-surface.dont`, a series slot the ledger lists as failing 3:1 on the light surface. *Expected:* `ThemeValidator` reports that finding at the ledger's recorded value (read from the ledger at test time), and the specimen's evidence chip shows that same number.
- *Input:* `check_pair(theme: "swiss", foreground: "positive", background: "background", appearance: "light")`. *Expected:* `passes: true` with `ratio` at least 4.5, because the 2026-11-09 owner decision states Swiss `positive` is at least 4.5:1 as text on the background; the exact figure is read from `RGB.contrastRatio` in the test, not asserted from this document.
- *Input:* `Breakpoints()` default. *Expected:* `mediaQuery(for: .mobile) == "(max-width: 600px)"`, byte-equal to the string already held by `BrowserSupport.Breakpoints.narrowMediaQuery` today (step A's regression anchor).

## 12. Architecture Decision Review

**ADR Check:**
- [ ] Reviewed `architecture_decisions.md` for related decisions (**not yet done; do at approval**)
- [ ] Does this supersede an existing ADR? Unknown until reviewed
- [ ] Does this amend an existing ADR? Likely the master plan's "Dependencies: none" statement is untouched, because the MCP is a separate package; confirm
- [ ] New ADR required? Probably yes, one entry:

**New ADR Draft:**
- Title: The guide is generated from the theme and verified; Dos and Don'ts are proven, not drawn
- Category: architecture
- Key decision: A guideline ships only if a checker demonstrates it (a Do passes, a Don't fails); prose guidance is allowed but is labelled "authored, unchecked" everywhere it appears.

## 13. Adversarial Review

**Strongest case for a different approach:**
Build far less: extend the existing `swiss-gallery` and the DocC articles, add the missing tokens (steps A to D), and skip the Do/Don't catalogue, the specimen emitters and the MCP. Steps A to D already close every gap the comparison found; E to G add a verification layer, a site and a server whose audience today is one owner and some agents. A reviewer would say the gap list was the deliverable and the rest is a product.

**Why we are proceeding anyway:** the owner wants all three, wants agents to be able to answer "FT vs Economist vs Swiss vs House" from the source, and has decided against paying for standards.site (2026-11-17), so the hosted alternative is out. The phasing keeps the cheaper path real: A to D ship alone, and the proposal can be cut after any step.

**Where this design is most likely wrong:**
1. *Don'ts from mutations may be contrived.* A "violation" we apply on purpose can look nothing like a real mistake. Mitigation: seed the catalogue from real defects (the 0.12.0 to 0.14.0 findings, the adopters' reports), and keep a visible "found in the wild" source on each Don't. If we run out of real Don'ts, the section should be short, not padded.
2. *The state matrix could be a second source of truth* for what `components.css` already says, and drift from it. Mitigation: the matrix is *tested against the rendered CSS* in Chrome; it describes and is checked, it does not generate.
3. *The scope is large.* Eleven new models plus three emitters plus a package. Mitigation: the phasing makes A to D worthwhile alone; the proposal should be cut at F or G if the owner prefers.
4. *Authored prose cannot be verified*, so voice and principles inherit nothing of the "proven" promise. Mitigation: labelled unchecked, rendered visually distinct.

**What an experienced critic would say:** "This is a design system documenting itself with a feature larger than the system's last four releases combined, and the audience is one person and some agents." We proceed because the agents are the point: an MCP that answers from the validator turns the ledger from a document into a service, and the specimen is the same data rendered. If no second human ever reads the specimen, the MCP and `standards.md` still pay for it.

## 14. Alternatives Considered

**Alternative 1: Publish on standards.site**
- Advantage: zero code; hosting, access control, versions, localisation and an agent endpoint included.
- Disadvantage: it is a paid service and the owner does not need it; hand-entered values drift from the source; no automated Dos and Don'ts; its API and export are Enterprise; its markdown is AI-generated from the published page.
- Why rejected: owner decision 2026-11-17 (cost, and no need), plus the verification is the value. Its structure is used as a checklist only; no content or service of theirs is used.

**Alternative 2: Extend the existing `swiss-gallery`**
- Advantage: already renders every Swiss component, light and dark, with a render test.
- Disadvantage: macOS and AppKit, PNG-based, Swiss only, SwiftUI only. It cannot show the web components, other themes, or be read by an agent.
- Why rejected: kept as a SwiftUI companion; the specimen is web and theme-generic.

**Alternative 3: A DocC article per topic**
- Advantage: fits the toolchain; the quality gate already checks DocC.
- Disadvantage: not browsable by non-Swift people; no live rendering of states; no machine-readable form.
- Why rejected: DocC remains the API reference; the narrative article (section 17) links to the specimen.

**Alternative 4: Put the MCP tools inside the `design-tokens` executable**
- Advantage: one fewer package.
- Disadvantage: puts `SwiftMCPServer` in this package's graph and ends "Foundation only".
- Why rejected: see section 3.

**Alternative 5: Storybook or a JS docs generator**
- Advantage: mature, interactive.
- Disadvantage: a Node toolchain this repo avoids; Swift is the source and the generated files are golden-tested.
- Why rejected: the specimen needs no framework.

## 15. Future Directions

- A hosted MCP endpoint (the site itself is static, so v1 is local); a per-theme "diff since last release" page generated from the golden files.
- Per-guideline screenshots captured in CI and diffed, rather than only DOM and computed-style checks.
- `localization` of the guide (they support up to 20 languages).
- A `lint_css` MCP tool that reads a CSS snippet and reports uses that contradict the guide (a hex that is not a token, a transition outside `MotionSpec`).
- Feeding the guide into the existing drift checker (Phase 5) so a project's own CSS is checked against it.
- Print proofing workflow to turn `authored` colour into `verified`.

## 16. Open Questions

1. **Sidebar mapping:** resolved. Read from the site's navigation data; the corrected table is at the top. (The Chrome extension was not connected; Safari was open on the States page, which confirmed the same site.)
2. **Tooltip and link as theme data:** does anything in `Theme` carry them today, or only `components.css`? Needs a read of `Structure.swift` and the emitter before step B.
3. **Tablet tier:** adopt 1020 px, or choose from where our own components actually break? Their width is a default, not a standard. If our grid and cards already reflow at other widths (the card minimum is 352 px), a tier at 1020 might be wrong for us. Recommend measuring where `components.css` breaks and deciding from that.
4. **Which marks exist?** There is no logo in this repo. `BrandMarks` is optional and empty, and the specimen skips that section; does an owner-supplied mark exist to model (Princeton orange is an accent, not a mark)?
5. **Print values:** who supplies CMYK, Pantone and RAL, and from what proof? Without a source the fields stay empty and the guide says so.
6. **Where does the MCP run?** Per the standing notes, `roseclub.org` (Chromedome) is the production MCP host and the vault services run elsewhere; confirm the host and read its Swift version over ssh before building. Is it local-only (stdio, no hosting) in v1?
7. **How does the specimen reach justinpurnell.com?** (a) **Copy** the generated, self-contained `Generated/standards/` files into the site's content so Ignite serves them as static pages (recommended: the specimen's inline CSS cannot be affected by the site's theme, and Ignite is not involved in rendering it); or (b) call `SpecimenEmitter` from an Ignite page at build time, since the site already depends on `DesignTokens`. Under (a) the copy is a release step; a CI check could compare the site's copy to the tagged package output. And the URL: `/standards/`, `/design-system/`, other?
8. **Licence of the reference:** we use their *structure* only; confirm that is fine for anything shipped publicly (no copied text or figures are included).
9. **Voice and principles:** who authors them, and are they per theme or global?
10. **Iconography and imagery:** neither exists on their site either. Include `IconSpec` now (small) or defer both until an icon set exists? Recommend defer imagery, include icon sizing only.
11. **Release numbering:** 0.14.0 is on a branch and untagged; step A should start from whatever that becomes.
12. **Where does the reunions theme live and who owns its values?** The theme is a registered `Theme` in this package (so the MCP sees it automatically). Is that the right home for a class-site theme, or does it belong in the reunions repo and register itself? Recommend this package, since the compare tool only sees registered themes.
13. **Inherit from `princeton` or stand alone?** Sharing the orange and the chart series keeps one Princeton; standing alone avoids breaking the chart consumers. Recommend `composed(with:)` on Swiss as `princeton` does, with its own text-orange role.
14. ~~**Font licensing**~~ **Answered 2026-11-17: we can use the fonts.** Because a definition names fonts and never carries them (4.11), what a third party may do with the font files no longer touches this design.
15. ~~**Type floor**~~ **Answered 2026-11-17: the tiny footer is fine.** No floor is imposed on `legal`; it is a ledgered, accepted finding. Still open: is the footer's 3.12:1 contrast also accepted, or should the footer colour be darkened while keeping the size?
16. **Which pages and appearances to measure first:** the live probe has run on the home page in light only. Dark mode and the other pages need the same probe (Safari works for it; the Chrome extension was not connected).
17. **Bootstrap bridge scope:** emit only colour, type and link variables first, or also component variables (accordion, dropdown, `.text-bg-primary`, all of which `theme.css` overrides today)?
18. **Definition identity:** when a definition's id collides with a built-in, reject, or load under a required `--as` name? Recommend reject-unless-renamed (4.11).
19. **Format stability:** a definition handed out today will be read by a later version. How many past `formatVersion`s must the reader keep? Recommend all of them (it is data), with a golden file per version.
20. **Trust:** nothing is executed and nothing is fetched, so no signing in v1; revisit only if definitions are ever fetched over a network.
21. ~~**Where are `franklin_gothic` and `princeton_monticello` used?**~~ **Answered 2026-11-17: largely backup.** Measured 2026-11-17 against the deployed pages: **0 of 153 pages** name either family (Libre Franklin is named on 2, the colophon, and is the body face). So they are fallbacks only: listed after Lennon and Libre Franklin in the stacks, not roles.
22. ~~**Web demo of an arbitrary definition**~~ **Answered 2026-11-17: native-only is fine, but make hot reload possible** because the demo may be a playground for page managers. See 4.13 for a design that gives hot reload on the real web pages *without* a JavaScript mirror of the emitter or WebAssembly.
23. ~~**tvOS and watchOS**~~ **Answered 2026-11-17: they count.** Finding: tvOS does not build today (4.12); watchOS is untested for lack of an SDK. Step 0 fixes the first and checks the second.
24. ~~**How are the iOS and visionOS apps built**~~ **Answered 2026-11-17: "seems like yes"** to an Xcode project depending on this package. Taken as `Apps/ThemeDemo/` in this repository (assumption: confirm if you would rather keep it beside the package).
25. ~~**Lennon's licence beyond the site**~~ **Answered 2026-11-17: allowed.** The demo app may carry the font. One new, smaller question: this package's GitHub repository (`jpurnell/DesignTokens`) is what the site depends on; if it is public, committing the font files there publishes them. Recommend the files live in the app target's resources or the reunions repo, not in the library.
26. **Hot reload mechanism (4.13):** is a local preview server enough for page managers, or must it run in a browser tab without any local tool? The second would need a hosted editor and a different design.
27. **Inline-style migration scope (4.14):** all 4,812 inline attributes, or only those carrying theme values (font family, colour, size)? Recommend the second, since the rest is layout. Where is the page *source* (Ignite Swift) that generates the deployed `reunions2025/` HTML?



## 17. Documentation Strategy

**Documentation Type:** Narrative Article Required.

**Complexity Threshold Check:**
- Combines 3+ APIs? **Yes** (theme fields, catalogue, emitters, MCP).
- Explanation requires 50+ lines? **Yes**.
- Needs theory or background context? **Yes** (the Do/Don't proof model, measured conformance).

**Article Names:** `HowTheGuideIsProven.md` and `UsingTheDesignTokensMCP.md`. (Neither may match a Swift symbol name; `GuideCatalogue` and `Guideline` are the nearest, and do not.)

**Doc housekeeping on approval and on each release** (per the standing rule): reconcile `project/master_plan.md` (type table, Current Status, Roadmap, new Phase 6), the CHANGELOG including its link definitions, `README.md`, `capability_map.md`, and bump **Last Updated**.

---

## Appendix A. Coverage of every page read

| Page | Disposition |
|---|---|
| Text, Fonts | **Add** paragraph spacing, tier scale, features (4.3); font file metadata is out of scope (we hold roles, not files) |
| Media, Video, Sequence, Toggle | **Add** motion (4.2); autoplay and loop rules go in Do/Don't ("never autoplay without reduced-motion handling") |
| Button, Dropdown | **Add** to the state matrix (4.5): rest, hover, active, activeHover; closed, open |
| Layouts, Grid | **Add** max content width, columns by tier (4.1) |
| Responsive Optimizations | **Add** breakpoints (4.1) |
| Pages, Adding Content, Copying & Moving, Files & Downloads, Search | **Out of scope**: editor mechanics of a hosted authoring tool. The specimen's own contents list and downloads section cover what is relevant |
| Menu | **Add** scrollbar (4.6) and translucent effect (4.2); menu variants become `dt-nav` guidance |
| Automations | **Adopted as the section list** of the specimen (Logo, Type, Color, Strategy, Language, Don'ts) |
| Components | **Add** `mayOverride` (4.5) |
| Color | **Add** print values, gradients, pairings, proportion (4.4) |
| Effects | **Add** backdrop blur, translucency (4.2); rotate and stretch are out of scope |
| Click & Hover Behaviors | **Out of scope** except hover states (matrix) |
| States | **Add** the matrix and the inheritance rule (4.5) |
| Tooltips, Links | **Verify** whether they are theme data (Open Question 2); then add as named styles |
| Accessibility | **Add** as the Accessibility topic (heading levels, labels, contrast) |
| Localization | Future Directions |
| Project Export, standards.md, MCP | **The model for deliverables 2 and 3**, with ours computed rather than AI-generated |

## Proposal Review Checklist (to tick at approval)

- [ ] Module placement follows the existing structure (core stays Foundation only; MCP is a sibling package)
- [ ] Concurrency Swift 6 compliant
- [ ] No forbidden patterns
- [ ] Source compatibility: goldens unchanged at step A
- [ ] MCP schema, parameter types, enums exhaustive
- [ ] Resource budget given as peak and at-rest numbers with a measurement
- [ ] ADR review done
- [ ] Open questions 2 to 7 and 10 answered or deferred
