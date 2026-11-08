# Design Proposal: DesignTokens, one source for the design system

**Date:** 2026-11-08 (moved here from SwiftCLIKit, where it was drafted 2026-11-07)
**Status:** Accepted by the owner on 2026-11-08; Phase 1 in progress.

## Decisions (2026-11-08)

1. The package is its own repository, `DesignTokens`, a sibling under `Tools/`.
2. Swift is the source of truth; JSON, CSS, SVG and the rest are outputs.
3. Only this package and declared app-palette files (WineTaster) may define colours.
4. Order: tokens package, then the site and the chart libraries; SwiftGUIKit's Swiss tier and the terminal resolver follow.
5. The drift checker is opt-in, later, starting with projects that already use system colours.

The rest of this document is the original proposal, unchanged except that its status line is superseded by the above.

---

# Design Proposal: one source for the design system, generated for every project

**Date:** 2026-11-07
**Status:** Draft, for discussion. No code written. Open questions in §9.
**Author:** Claude (session with Justin Purnell)
**Parent:** Stack Map capability #13, Design tokens and theming. Decisions so far are in the design-system artifact ("Swiss and Apple") and in `2026-07-10_TokenVocabulary_v1.md`.

## 1. Objective

The same look across every project, held in place by construction, not by remembering. Each value (colour,
type size, rule weight, grid column) is defined once. Every consumer gets it by generation or by import,
and a check fails the build when a project drifts.

**Scope decision (2026-11-07):** the Tumblr blog is a best-effort consumer. It receives the generated
values to paste into its theme, and nothing enforces it, because Tumblr's markup and stylesheet are not
ours. Everything else is held to the rule.

## 2. Motivation: how far apart things already are

Measured today by searching Swift and CSS sources (hex literals, `Color(red:)` initialisers, fixed font sizes):

| Project | Hex literals (distinct) | Notes |
|---|---|---|
| justinpurnell.com CSS | 31 (12) | The Princeton orange #E77500 appears 15 times, with three other oranges (#f58025, #ff7f00, #ff9f7f) |
| BusinessMath-UI | 682 (214) | Mostly colour conversions, gradients and theme tables; 9 `Color(red:)` calls |
| BusinessMathCharts (SVG and app) | 24 (16) | `SVGTheme` has its own blue, #4AA3E0, where `EditorialTheme.house` has #2B6CB0 |
| SwiftCLIKit | 8 (2) | |
| KEXPPower (Spinner), WineTaster 4, IconquerApp | 0 | Already use system colours, which is the right starting point |
| Hyrule | 29 `Color(red:)` | A game palette; out of scope |

Where one decision, "the accent is system orange", would currently have to be made by hand:
SwiftGUIKit's `AppleTokenResolver`, `EditorialTheme` (three variants now), `ChartThemeProviding`,
`SVGTheme`, the site's CSS, the Tumblr theme, the terminal resolver, and the slide templates. Seven
places, no link between them.

## 3. What "rigid" means: invariants that can be tested

Each is a property a check can assert, not a style preference.

| # | Invariant |
|---|---|
| 1 | Grid: 12 columns, 16pt gutter, 4pt base unit. Label column is 1–3, reading column is 4–10, wide media 4–12. |
| 2 | Colour roles come from one list (the nine in SwiftGUIKit plus `link`), each with light, dark and increased-contrast values. The accent is system orange; a person's own system accent is used when it is neither orange nor blue. |
| 3 | Series colours are the eight system colours in the validated order. Apps may supply their own palette through `recolored`, and the structure stays the same. |
| 4 | Type roles and sizes come from one scale: Apple's text styles for the UI register, plus the display register. SF with the Helvetica fallback. |
| 5 | Rule weights are 1, 3 and 8pt. Container radius is 0; control radius is 4pt. No dashed borders. |
| 6 | Media sits on the column edge at the column width, with the standard caption (thin rule, orange square, figure number). No text over pictures. |
| 7 | Quoted text sits on the column edge with one hairline hung in the gutter. |
| 8 | Orange is for rules, large type and labelled marks. Small text is ink. |
| 9 | Every status has a glyph, so meaning never depends on colour alone. |

## 4. Architecture

```
DesignTokens   (a small SwiftPM package; Foundation only; builds on Linux)
 ├── Tokens.swift         typed source: ColorRole values for light, dark and high contrast,
 │                        TypeRole scale, SpaceToken, Rule weights, Grid, Radius
 ├── Palette.swift        the eight series colours and their validated order
 └── design-tokens (CLI)  emits artefacts from the types above
        css        tokens.css     custom properties for light, dark and high contrast
        json       tokens.json    for tools that cannot import Swift
        svg        SVG theme block (replaces the hand-written SVGTheme values)
        ansi       terminal role table
        tumblr     the CSS block to paste into the theme (best effort)
        slides     colour and font list for the Keynote and PowerPoint templates
```

- **Swift is the source, not JSON.** The values are typed, checked by the compiler, and the Ignite site
  (a Swift project) can depend on the package and read them at build time. Only consumers that cannot
  import Swift get generated files.
- **Import, don't copy,** wherever the consumer is Swift: SwiftGUIKit's resolvers, `EditorialTheme`,
  `ChartThemeProviding`, the Ignite site.
- **Generated files say so** in a header and are committed; a test regenerates them and fails on any
  difference.
- **Apple platforms keep deferring to the system.** `Color.orange`, Dynamic Type and the system
  materials stay the Apple resolver's answer. The package holds the values for everything that cannot
  call the system (SVG, web, terminal, slides) as a labelled snapshot, with the OS release it was taken on.

## 5. Enforcement

A quality-gate checker, in the same SwiftSyntax style as the existing auditors:

- **Swift:** flags hex colour literals, `Color(red:)`-style initialisers, `.system(size:)` and `.custom(...)` fonts, and
  hard-coded corner radii outside the tokens package and the files that define an app palette.
- **CSS and HTML:** flags colour literals, font sizes and column widths that are not in the generated token set.
- **No overrides.** Per the existing rule, a finding is fixed in code, not silenced. A deliberate
  exception, such as an app palette, lives in a declared file and is checked for validity (the colour
  validator) instead of being skipped.

## 6. Migration order

| Phase | Work | Verifiable result |
|---|---|---|
| 1 | The `DesignTokens` package: roles, scale, grid, palette; the CSS and JSON emitters, test-first; golden-file tests. | Generated `tokens.css` equals the checked-in copy. |
| 2 | The Ignite site depends on the package and replaces its 12 hex values and four oranges. | The site's CSS has zero literals outside the generated file. |
| 3 | `EditorialTheme.swiss`, `SVGTheme` and `ChartThemeProviding` read from the package. | One accent hex in the chart libraries, not three. |
| 4 | SwiftGUIKit's Swiss tier (rule weights, grid, display register) and the terminal resolver, including the background detection in the other proposal. | Resolver tests per surface. |
| 5 | The checker, run on the projects that already use system colours (Spinner, WineTaster, Iconquer) to prove it stays quiet on correct code. | Zero findings there; findings on a seeded violation. |
| 6 | Slide templates and the Tumblr paste block from the generators. | Files produced; the Tumblr block is pasted by hand. |

## 7. What we do not unify

- Hyrule's game palette, and any app's artwork.
- Apple's own system values: the snapshot exists only for places the system cannot reach.
- The Tumblr theme beyond the generated block.

## 8. Risks

- **System colours drift between OS releases,** so the snapshot ages. Mitigation: record the release in the
  generated header, and add a test on macOS that reads the live system colours and compares.
- **A Linux-buildable package cannot import SwiftUI,** so it holds data, not `Color` values. The Apple
  resolver maps the data to `Color`.
- **The checker will find real drift in old code** (BusinessMath-UI's 682 literals are mostly legitimate
  colour maths). It needs a way to say "this file defines colours" that is declared and validated, not a
  suppression.

## 9. Open questions for the owner

1. **Package home.** A new small package (its own repository) that SwiftGUIKit, BusinessMath-UI and the
   site all depend on, or a product inside SwiftCLIKit. *Lean: its own package, so the chart library and the
   site do not depend on a terminal kit.*
2. **Source of truth in Swift or in JSON.** *Lean: Swift, with JSON as an output.*
3. **Who may define colours.** *Lean: the tokens package, plus declared app-palette files (WineTaster).*
4. **Order.** Start with the site and the chart libraries, where the drift is worst (phases 1–3). *Lean: yes.*
5. **Checker scope.** All projects, or only those that opt in with a config entry. *Lean: opt in, starting with the
   ones that already use system colours.*
