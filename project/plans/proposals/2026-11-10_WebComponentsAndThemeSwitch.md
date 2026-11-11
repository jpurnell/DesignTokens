# Proposal: Swiss web components, a "console" theme, and a runtime theme switch

Status: implemented in 0.12.0 on `feature/console-theme-components-0.12.0` (steps 1 and 2 of "Order of work"; steps 3 and 4 are other repositories'), with the owner's answers of 2026-11-10 recorded below. Original status: draft, 2026-11-10. Driven by the FleetWatch web migration (`Sources/FleetWatchServer/Page`).

## Why

FleetWatch's web page is 89 lines of hand-written CSS with 11 hex colours, 25 off-token font sizes and 13 off-grid gaps
(measured with `design-token-drift` on a scratch copy: 60 errors, 4 warnings). The owner decided (2026-11-10):

1. Follow the user's light/dark setting.
2. Use the system font; the monospaced face is for places the layout calls for it, not the whole page.
3. Use the Swiss table layout. The current look becomes a **theme in the design system**, and the site offers a toggle
   between the two. The toggle is the test of the theme model.

## What exists

- `ThemeCSSEmitter` already scopes every theme to `[data-theme-name="<id>"]`, so several coexist on a page, and a
  `fixedDark` appearance exists. A runtime switch is the attribute on `<html>` changing. No new emitter is needed for it.
- `Structure` carries rules, radii (`containerRadius`, `controlRadius`), `cardBorder`, `cardPadding`, grid
  (`columns`, `gutter`), type roles with a font-family reference, and a palette. **Unverified:** whether a
  monospaced family can be the default for the UI roles (check `FontFamilyRef`).
- There is **no web component stylesheet** in the package. The site and FleetWatch each hand-write component CSS
  against the tokens. That is the real gap, and Vault's web UI and the site need it too.

## Proposal

### 1. `console` theme (working name)

A registered theme that reproduces today's FleetWatch page: fixed-dark navy surfaces, the three status colours, SF Mono,
8 px cards with a 1 px border. Built as `Structure + Palette` like the others, so it is validated, round-tripped and
held to a ledger by the existing tests. Its palette will fail some contrast and colour-blind checks the Swiss palette
passes; the ledger records what it measures. It does not hide that.

The navy colours (`#1a1a2e`, `#16213e`, `#0f3460`, `#0a0a1a`) are the theme's own values, not system colours.
Nothing here tries to map them onto the Swiss tokens.

### 2. `components.css`: one stylesheet for the Swiss web components

Emitted from the package (`design-tokens emit --components`), written only in terms of the tokens: `--ink`, `--rule`,
`--container-radius`, `--card-border`, `--gutter`, the type-role properties. Components: section, rule, key-value list,
table (selectable rows, stacks below 600 px, matching `SwissTable`), chip/status (symbol plus colour, never colour
alone), banner, segmented control, form controls. Matching the SwiftUI set keeps the Apple app and the web page one
design, not two.

### 3. One markup, two looks

The same HTML renders as hairline rows under the Swiss theme and as bordered cards under `console`, because the
components read `--container-radius`, `--card-border`, `--card-padding` and the surface colour from the theme.

Open: that covers radii, borders and colour, but not **table versus card grid**. Two ways:

- (a) Add a `listStyle` (`rows` | `cards`) to `Structure` and emit it as a CSS custom property the components key off.
  Source-breaking, which is acceptable. Recommended: it makes the layout part of the theme, so the toggle genuinely
  tests the model.
- (b) Keep one layout and let the tokens change only the surface. Smaller, but then the toggle shows a re-skin, not a
  layout change, and tells us less.

### 4. The toggle

`<html data-theme-name="swiss">` swapped by a few lines of script, with the choice kept in `localStorage` (wrapped in
try/catch; the page renders correctly without it) and defaulting to the system setting. `data-theme="light|dark"`
remains the independent appearance override the emitter already supports. No new runtime in the package.

## Tests (red first)

- `console` passes the registry's validation, round-trip and ledger tests.
- Generated `components.css` equals a fresh emit; contains no hex colour, font name or px radius literal (every value is
  a `var(--…)`).
- Every custom property `components.css` reads is declared by the Swiss theme and by `console`.
- Drift checker run on a fixture page using both themes reports 0 findings.
- Browser check (screenshots, light and dark, narrow and wide) of the FleetWatch page in both themes, before release.

## Order of work

1. `console` theme and ledger (DesignTokens 0.12.0).
2. `listStyle` and `components.css` (same release).
3. FleetWatch `Page/` migrated onto them, after its SwiftHTTPService 0.8.1 redeploy lands; the checker enabled there with
   `cssPaths` and `tokenFiles`.
4. The Apple app, then Vault's web UI.

## Open questions for the owner

1. `listStyle` as a theme property (a), or one layout (b)?
2. Name: `console`, `classic`, or `fleetwatch`? A name tied to one app is wrong, since other pages may want it.
3. Should the toggle be offered to every operator or only appear in settings?
4. Should `components.css` be a DesignTokens product the site also adopts, replacing its hand-written component CSS?

## Implementation notes (0.12.0), and where it departed

Owner answers, 2026-11-10: (1) `listStyle` is a theme property; (2) the id is `console`, name "Console"; (3) the appearance toggle is a persistent per-user setting built on the FleetWatch side, so the package only supports the `data-theme-name` and `data-theme` swap; (4) `components.css` is a portfolio-wide product with generic `dt-` classes.

Departures:
- `listStyle` is emitted as `--list-style` and as derived properties (`--list-item-min`, `--list-item-rule`, `--list-item-surface`, `--list-gap`, `--card-top-rule`), because a custom property cannot branch; the components read the derived ones. The card minimum width is 96 base units (384 px), derived from the page's 380.
- The property names are the emitter's real ones (`--radius-container`, `--radius-control`), not the `--container-radius` this proposal wrote.
- Console needed no model change for the monospaced face: `FontFamilyRef.named` with fallbacks expresses the stack.
- Console's card padding is 20, not the page's 19.2 (`1.2rem`), to stay on the 4 px grid; the gutter stays 16.
- The banner is a tinted surface with a heavy status edge and ink text, not the SwiftUI banner's solid fill, since CSS cannot choose the better-contrast text colour.
- The test "drift checker reports 0 findings" was run on a scratch fixture (58 tokens loaded, 3 files read), not on FleetWatch.
- The browser check covered a demo page of every component, not the FleetWatch page.

### Correction before release: `listStyle` became `CardChrome`

Owner review of the first screenshots: with Swiss as `listStyle: rows`, a collection of machines rendered one fact per line across the full width, with the same data repeated in the table. The approved Swiss design for a collection of entity summaries is an equal-height grid of borderless cards with a rule across the top (`SwissCard` with `.borderless`, `SwissEqualGrid`, the Stack Map "Hybrid" cards), so I had the model wrong. Decision: **rename and re-mean, not keep both.** A collection of entity summaries is a card grid in every theme, so a rows-or-cards switch had no remaining job; what a theme changes is the card's chrome. `ListStyle` became `CardChrome` (`ruled`: no border, no fill, the section rule in ink across the top; `bordered`: surface, hairline border, container radius), `LayoutSpec.listStyle` became `cardChrome` (decoded as `ruled` when absent), and the `--list-*` CSS properties became `--card-chrome`, `--card-surface`, `--card-top-rule`, `--card-top-color`, `--card-min`, `--card-gap`. Plain lists (`dt-list`) are rows in every theme and read no theme property; a table is a table and stacks into cards below 600 px. The card minimum is 88 base units (352 px), not 96, so three cards fit a 1200 px page with its padding. Inside a card, `dt-stats` sets facts compactly: a small capital label over a large tabular figure, as many to a row as fit (an auto-fit grid, no new CSS feature, so the browser floor is unchanged).
