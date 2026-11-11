import Foundation

/// Emits `components.css`: the web counterpart of the SwiftUI Swiss components, one stylesheet any page can link.
///
/// The stylesheet is written **only in terms of the theme's custom properties** (see ``ThemeCSSEmitter``): colours as
/// `var(--ink)`, `var(--rule)`, `var(--surface)`; rule weights as `var(--rule-hairline)`; radii, card border and padding, gutter
/// and base unit; the six UI type roles as `var(--type-body-size)` and the like; and the card tokens the theme derives from its
/// ``CardChrome``. It names no theme, writes no colour, font or radius of its own, and declares no custom property of its own, so a
/// test can hold every `var(--x)` it reads against the properties a theme declares.
///
/// ### One markup, two looks
/// A `dt-cards` grid of `dt-card`s is an equal-height grid of entity summaries in every theme: as many columns as fit the card
/// minimum width (three across a 1200 px page, one on a phone). What the theme changes is the card's chrome: under ``CardChrome/ruled``
/// (Swiss) no border and no fill with the section rule in ink across the top, under ``CardChrome/bordered`` (Console) a hairline
/// border, the surface fill and the container radius. Inside a card, a `dt-stats` row sets two or three facts as a small capital
/// label over a large figure, the number as the hero. The markup does not change: the theme swaps `data-theme-name` on an ancestor.
/// A `dt-list` of `dt-item`s is plain rows (a list of documents), the same in every theme, and the table stacks into cards below the
/// breakpoint.
///
/// ### Components
/// Every class is prefixed `dt-` (BEM-style, `dt-block__element`, `dt-block--modifier`):
///
/// | Block | Classes | SwiftUI counterpart |
/// |---|---|---|
/// | Page and type roles | `dt-page`, `dt-label`, `dt-caption`, `dt-body`, `dt-heading`, `dt-title`, `dt-display`, `dt-figure` | `UIRole`, `View.uiText(_:)` |
/// | Section and rules | `dt-section`, `dt-section__heading`, `dt-rule`, `dt-rule--section`, `dt-rule--page` | `SwissSection`, `SwissRule` |
/// | Key and value | `dt-kv`, `dt-kv__row`, `dt-kv__key`, `dt-kv__value` | `KeyValueList`, `KeyValueRow` |
/// | Table | `dt-table` (a real `<table>`; cells carry `data-label`), `dt-num`, `aria-sort`, `aria-selected` | `SwissTable` |
/// | Card grid and card | `dt-cards`, `dt-card`, `dt-card__header`, `dt-card__name`, `dt-card__title`, `dt-card__footer` | `SwissEqualGrid`, `SwissCard` |
/// | Stats | `dt-stats`, `dt-stat`, `dt-stat__label`, `dt-stat__figure`, `dt-stat__unit` | `KeyValueRow`, set compactly |
/// | Plain list | `dt-list`, `dt-item`, `dt-item__title`; 0.13.0: `dt-item--meta` with `dt-item__main` and `dt-item__meta` (a trailing count), `dt-list--columns` (auto-fit columns, one under 600 px) | `KeyValueList` rows |
/// | Page shell and navigation (0.13.0) | `dt-shell` (a sticky navigation column and a main column; one column and a wrapped nav row under 600 px), `dt-shell__nav`, `dt-shell__main`, `dt-nav`, `dt-nav__heading`, `dt-nav__item` (`aria-current` marks the page) | none |
/// | Prose (0.13.0) | `dt-prose`: unclassed `h1` to `h6`, `p`, lists, `blockquote`, `code`, `pre`, `table`, `hr`, `a`, `mark`, `img` inside it | none |
/// | Mark (0.13.0) | `mark` and `dt-mark`: a tint derived from `--accent`, since the palette has no highlight role | none |
/// | Hidden (0.13.0) | `[hidden]` is `display: none !important`, so no component's `display` can show a hidden element | none |
/// | Chip | `dt-chip` with `--success`, `--caution`, `--warning`, `--destructive`, `--neutral` | `OutlinedChip` |
/// | Banner | `dt-banner` with the same five modifiers; holds text, paragraphs and links (0.13.0) | `StatusBanner` |
/// | Segmented control | `dt-segmented`, `dt-segmented__option` (`aria-checked="true"` selects) | `SwissSegmentedControl` |
/// | Buttons | `dt-button`, `dt-button--primary`, `dt-button--destructive` | none (the system's) |
/// | Actions | `dt-actions`, `dt-checkline` | none |
/// | Form | `dt-field`, `dt-field__label`, `dt-input`, `dt-select`, `dt-textarea`, `dt-check` | `SwissTextField`, `SwissToggleStyle` |
/// | Grid | `dt-grid`, `dt-col-1` to `dt-col-12`, `dt-col-start-1` to `dt-col-start-12` | `SwissGrid` |
///
/// ### States (0.13.0)
/// Hover (only where a pointer hovers: `@media (hover: hover)`), active, keyboard focus, invalid, disabled, increased contrast, forced
/// colours and reduced motion were driven in headless Chrome and corrected in 0.13.0: a hover or press is an inner outline in the
/// current colour (it keeps the words' contrast and survives forced colours), a focus ring inside a clipping parent is drawn inside the
/// control, an invalid control has a heavier negative border, a disabled one is dimmed, forced colours mark selection with a glyph, a
/// system-colour outline and an underline, and under increased contrast the primary button is the ink on the page colour.
///
/// The stylesheet is built in blocks of one component each, in the order page, type, rules, key and value, list, shell, prose, cards,
/// stats, table, chip, banner, segmented, buttons, form, grid, then the cross-cutting hidden, hover, invalid, focus, contrast, forced
/// colours and motion rules, so a new block (a dense chip list, a collapsing card section, a meter, a stale indicator, a toolbar) is
/// added beside its siblings and picks up the shared state rules by selector.
///
/// The browser floor and the breakpoints are in ``BrowserSupport``, and in the generated header of the file. The 600 px breakpoint cannot
/// be a custom property; an app that writes its own responsive rules uses ``BrowserSupport/Breakpoints/narrowMediaQuery``.
///
/// Departures from the SwiftUI set, on purpose: a banner is a tinted surface with a heavy edge in the status colour and the words
/// in ink (a stylesheet cannot measure which of two colours reads better on a fill, as `StatusBannerStyle` does, so the text is
/// always the ink on a surface close to the page's); and the table is a native `<table>` so assistive technology and copy and
/// paste keep working.
public enum ComponentsCSSEmitter {
    /// The complete stylesheet, ending in a newline.
    public static func emit() -> String {
        header + css
    }

    /// The generated header: the version, then the browser floor, the features behind it and the breakpoints, all from
    /// ``BrowserSupport`` so the comment cannot say what the rules do not.
    private static var header: String {
        let floor = BrowserSupport.floor(for: [.components, .themes])
        let features = BrowserSupport.features.filter { $0.scopes.contains(.components) }.map(\.name).joined(separator: "; ")
        let breakpoints = BrowserSupport.Breakpoints.self
        return """
        /* Generated by design-tokens. Do not edit. Web components | DesignTokens \(DesignTokens.version) | reads only the custom properties a theme stylesheet declares */
        /* Browser support: \(BrowserSupport.floorText(floor)), or newer. No fallbacks are provided; an older browser is not supported.
         * Source: MDN browser-compat-data 8.1.8, the first unprefixed, unflagged version of each feature.
         * Features used here: \(features).
         * Breakpoints (a media query's width cannot be a custom property, so an app that writes its own uses this value, \(breakpoints.narrowMediaQuery)): the table stacks to labelled blocks, and the grid helpers to one column, below a viewport of \(breakpoints.tableStackBelowPixels)px;
         * a key and value row stacks when its container is under \(breakpoints.keyValueStackBelowRem)rem; a card in a cards theme is at least
         * \(breakpoints.cardMinimumWidthInBaseUnits) base units wide (the theme's --card-min). */

        """
    }

    /// `calc(var(--space-unit) * n)`: a multiple of the theme's base unit.
    private static func unit(_ n: Double) -> String { "calc(var(--space-unit) * \(CSSNumber.string(n)))" }

    /// The declarations of one UI text role.
    private static func role(_ name: String) -> String {
        """
          font-family: var(--type-\(name)-family);
          font-size: var(--type-\(name)-size);
          line-height: var(--type-\(name)-line);
          font-weight: var(--type-\(name)-weight);
          letter-spacing: var(--type-\(name)-tracking);
          text-transform: var(--type-\(name)-transform);
          font-style: var(--type-\(name)-style);
        """
    }

    /// The five status tones, as the colour property each reads.
    private static let tones: [(name: String, colour: String, glyph: String)] = [
        ("success", "var(--positive)", "\\2713"),
        ("caution", "var(--warning)", "\\25B2"),
        ("warning", "var(--extra-alert)", "\\25C6"),
        ("destructive", "var(--negative)", "\\2715"),
        ("neutral", "var(--secondary-ink)", "\\25CB"),
    ]

    private static var typeRoles: String {
        ["label", "caption", "body", "heading", "title", "display"].map { name in
            ".dt-\(name) {\n\(role(name))\n}\n"
        }.joined(separator: "\n")
    }

    private static var chips: String {
        tones.map { tone in
            """
            .dt-chip--\(tone.name) {
              border-color: \(tone.colour);
            }
            .dt-chip--\(tone.name)::before {
              content: "\(tone.glyph)";
              color: \(tone.colour);
            }

            """
        }.joined(separator: "\n")
    }

    private static var banners: String {
        tones.map { tone in
            """
            .dt-banner--\(tone.name) {
              background: color-mix(in srgb, \(tone.colour) 14%, var(--background));
              border-inline-start-color: \(tone.colour);
            }
            .dt-banner--\(tone.name)::before {
              content: "\(tone.glyph)";
              color: \(tone.colour);
            }

            """
        }.joined(separator: "\n")
    }

    private static var columns: String {
        let spans = (1...12).map { ".dt-col-\($0) { grid-column: span \($0); }" }.joined(separator: "\n")
        let starts = (1...12).map { ".dt-col-start-\($0) { grid-column-start: \($0); }" }.joined(separator: "\n")
        return spans + "\n" + starts
    }

    private static var css: String {
        #"""
        /* ---- Page and type roles ---- */
        .dt-page {
          background: var(--background);
          color: var(--ink);
        \#(role("body"))
          margin: 0;
          padding: calc(var(--gutter) * 2);
          box-sizing: border-box;
        }
        .dt-page *, .dt-page *::before, .dt-page *::after {
          box-sizing: border-box;
        }

        \#(typeRoles)
        .dt-label, .dt-caption {
          color: var(--secondary-ink);
        }
        .dt-figure {
          font-variant-numeric: tabular-nums;
        }
        .dt-link {
          color: var(--link);
        }

        /* ---- Rules and section ---- */
        .dt-rule {
          border: 0;
          border-top: var(--rule-hairline) solid var(--rule);
          margin: 0;
        }
        .dt-rule--section {
          border-top: var(--rule-section) solid var(--ink);
        }
        .dt-rule--page {
          border-top: var(--rule-page) solid var(--ink);
        }
        .dt-section {
          border-top: var(--rule-section) solid var(--ink);
          padding-top: \#(unit(3));
          margin-top: \#(unit(8));
          margin-bottom: \#(unit(3));
        }
        .dt-section__heading {
        \#(role("heading"))
          margin: 0 0 \#(unit(2));
          color: var(--ink);
        }
        .dt-section__heading.dt-label {
        \#(role("label"))
          color: var(--secondary-ink);
        }

        /* ---- Key and value ---- */
        .dt-kv {
          container-type: inline-size;
          margin: 0;
          padding: 0;
        }
        .dt-kv__row {
          display: grid;
          grid-template-columns: repeat(var(--columns), minmax(0, 1fr));
          column-gap: var(--gutter);
          align-items: baseline;
          padding-block: \#(unit(1.5));
          border-top: var(--rule-hairline) solid var(--rule);
        }
        .dt-kv__row:first-child {
          border-top-color: transparent;
        }
        .dt-kv__key {
        \#(role("label"))
          grid-column: 1 / span 3;
          margin: 0;
          color: var(--secondary-ink);
        }
        .dt-kv__value {
        \#(role("body"))
          grid-column: 4 / span 7;
          margin: 0;
          overflow-wrap: anywhere;
        }
        @container (max-width: \#(BrowserSupport.Breakpoints.keyValueStackBelowRem)rem) {
          .dt-kv__row {
            grid-template-columns: minmax(0, 1fr);
            row-gap: \#(unit(0.5));
          }
          .dt-kv__key, .dt-kv__value {
            grid-column: 1 / -1;
          }
        }

        /* ---- Plain list: rows, the same in every theme ---- */
        .dt-list {
          margin: 0;
          padding: 0;
          list-style: none;
        }
        .dt-item {
          min-inline-size: 0;
          padding-block: \#(unit(3));
          border-top: var(--rule-hairline) solid var(--rule);
        }
        .dt-list > .dt-item:last-child {
          border-bottom: var(--rule-hairline) solid var(--rule);
        }
        .dt-item__title {
        \#(role("body"))
          font-weight: var(--type-heading-weight);
          margin: 0 0 \#(unit(1));
          overflow-wrap: anywhere;
        }

        .dt-item--meta {
          display: flex;
          align-items: baseline;
          justify-content: space-between;
          gap: var(--gutter);
        }
        .dt-item__main {
          flex: 1 1 auto;
          min-inline-size: 0;
        }
        .dt-item__meta {
        \#(role("caption"))
          flex: none;
          white-space: nowrap;
          font-variant-numeric: tabular-nums;
          color: var(--secondary-ink);
        }
        .dt-list--columns {
          display: grid;
          grid-template-columns: repeat(auto-fit, minmax(min(\#(unit(80)), 100%), 1fr));
          column-gap: calc(var(--gutter) * 2);
        }
        .dt-list--columns > .dt-item {
          border-bottom: var(--rule-hairline) solid var(--rule);
        }

        /* ---- Page shell: a sticky navigation column beside the main column ---- */
        .dt-shell {
          display: grid;
          grid-template-columns: minmax(0, \#(unit(56))) minmax(0, 1fr);
          column-gap: calc(var(--gutter) * 2);
          align-items: start;
        }
        .dt-shell__nav {
          position: sticky;
          top: var(--gutter);
          align-self: start;
          max-block-size: calc(100vh - var(--gutter) * 2);
          overflow-y: auto;
        }
        .dt-shell__main {
          min-inline-size: 0;
        }
        .dt-nav {
          display: block;
          margin: 0;
          padding: 0;
          list-style: none;
        }
        .dt-nav__heading {
        \#(role("label"))
          margin: 0 0 \#(unit(2));
          color: var(--secondary-ink);
        }
        .dt-nav__item {
        \#(role("body"))
          display: block;
          padding: \#(unit(1)) \#(unit(3));
          border-inline-start: calc(var(--rule-section) * 2) solid transparent;
          color: var(--ink);
          text-decoration: none;
          overflow-wrap: anywhere;
        }
        .dt-nav__item[aria-current] {
          border-inline-start-color: var(--ink);
          font-weight: var(--type-heading-weight);
        }

        /* ---- Prose: rendered Markdown with no classes on it ---- */
        .dt-prose {
          max-inline-size: \#(unit(180));
          color: var(--ink);
        \#(role("body"))
          overflow-wrap: anywhere;
        }
        .dt-prose h1, .dt-prose h2, .dt-prose h3, .dt-prose h4, .dt-prose h5, .dt-prose h6 {
          margin: \#(unit(6)) 0 \#(unit(2));
          color: var(--ink);
        }
        .dt-prose h1 {
        \#(role("title"))
        }
        .dt-prose h2 {
        \#(role("heading"))
        }
        .dt-prose h3 {
        \#(role("body"))
          font-weight: var(--type-heading-weight);
        }
        .dt-prose h4, .dt-prose h5, .dt-prose h6 {
        \#(role("label"))
        }
        .dt-prose > :first-child {
          margin-top: 0;
        }
        .dt-prose p, .dt-prose ul, .dt-prose ol, .dt-prose blockquote, .dt-prose pre, .dt-prose table {
          margin: 0 0 \#(unit(3));
        }
        .dt-prose ul, .dt-prose ol {
          padding-inline-start: \#(unit(6));
        }
        .dt-prose li {
          margin: 0 0 \#(unit(1));
        }
        .dt-prose blockquote {
          padding-inline-start: \#(unit(4));
          border-inline-start: var(--rule-section) solid var(--rule);
          color: var(--secondary-ink);
        }
        .dt-prose code {
          font-family: var(--font-mono);
          font-size: 0.9em;
        }
        .dt-prose pre {
          padding: \#(unit(3));
          border: var(--rule-hairline) solid var(--rule);
          border-radius: var(--radius-control);
          background: color-mix(in srgb, var(--ink) 5%, transparent);
          overflow-x: auto;
        }
        .dt-prose pre code {
          font-size: inherit;
        }
        .dt-prose table {
          inline-size: 100%;
          border-collapse: collapse;
          font-variant-numeric: tabular-nums;
        }
        .dt-prose th {
        \#(role("label"))
          text-align: start;
          color: var(--secondary-ink);
          padding: \#(unit(2)) \#(unit(3)) \#(unit(2)) 0;
          border-bottom: var(--rule-hairline) solid var(--ink);
        }
        .dt-prose td {
          padding: \#(unit(2)) \#(unit(3)) \#(unit(2)) 0;
          border-top: var(--rule-hairline) solid var(--rule);
          vertical-align: baseline;
        }
        .dt-prose hr {
          border: 0;
          border-top: var(--rule-hairline) solid var(--rule);
          margin: \#(unit(6)) 0;
        }
        .dt-prose a {
          color: var(--link);
          text-decoration: underline;
        }
        .dt-prose img {
          max-inline-size: 100%;
          block-size: auto;
        }
        .dt-prose mark {
          margin: 0;
        }

        /* ---- Mark: a highlight tinted from accent (the palette has no highlight role), the words stay in ink ---- */
        mark, .dt-mark {
          background: color-mix(in srgb, var(--accent) 32%, var(--background));
          color: var(--ink);
          padding-inline: \#(unit(0.5));
        }

        /* ---- Card grid and card: equal heights, the chrome is the theme's ---- */
        .dt-cards {
          display: grid;
          grid-template-columns: repeat(auto-fit, minmax(min(var(--card-min), 100%), 1fr));
          gap: var(--card-gap);
          margin: 0;
          padding: 0;
          list-style: none;
        }
        .dt-card {
          display: flex;
          flex-direction: column;
          gap: \#(unit(3));
          min-inline-size: 0;
          background: var(--card-surface);
          color: var(--ink);
          border: var(--card-border) solid var(--rule);
          border-top: max(var(--card-top-rule), var(--card-border)) solid var(--card-top-color);
          border-radius: var(--radius-container);
          box-shadow: var(--shadow);
          padding-block: max(var(--card-padding), \#(unit(3)));
          padding-inline: var(--card-padding);
        }
        .dt-card__header {
          display: flex;
          align-items: center;
          justify-content: space-between;
          gap: var(--gutter);
        }
        .dt-card__name {
        \#(role("body"))
          font-weight: var(--type-heading-weight);
          margin: 0;
          overflow-wrap: anywhere;
        }
        .dt-card__title {
        \#(role("title"))
          margin: 0;
        }
        .dt-card__footer {
          margin-top: auto;
          padding-top: \#(unit(2));
          border-top: var(--rule-hairline) solid var(--rule);
        }

        /* ---- Stats: the number is the hero. A small capital label over a large figure; as many to a row as fit ---- */
        .dt-stats {
          display: grid;
          grid-template-columns: repeat(auto-fit, minmax(\#(unit(20)), 1fr));
          gap: \#(unit(3)) var(--gutter);
          margin: 0;
          padding: 0;
        }
        .dt-stat {
          min-inline-size: 0;
          margin: 0;
        }
        .dt-stat__label {
        \#(role("label"))
          display: block;
          margin: 0 0 \#(unit(1));
          color: var(--secondary-ink);
        }
        .dt-stat__figure {
        \#(role("heading"))
          display: block;
          margin: 0;
          font-variant-numeric: tabular-nums;
          line-height: 1;
          color: var(--ink);
        }
        .dt-stat__unit {
        \#(role("caption"))
          margin-inline-start: \#(unit(1));
          color: var(--secondary-ink);
        }

        /* ---- Table ---- */
        .dt-table {
          inline-size: 100%;
          border-collapse: separate;
          border-spacing: 0;
          background: var(--card-surface);
          color: var(--ink);
          border: var(--card-border) solid var(--rule);
          border-radius: var(--radius-container);
          overflow: hidden;
        \#(role("body"))
        }
        .dt-table th {
        \#(role("label"))
          text-align: start;
          color: var(--secondary-ink);
          padding: \#(unit(2)) \#(unit(3));
          border-bottom: var(--rule-hairline) solid var(--ink);
        }
        .dt-table td {
          padding: \#(unit(2)) \#(unit(3));
          border-top: var(--rule-hairline) solid var(--rule);
          vertical-align: baseline;
        }
        .dt-table tbody tr:first-child td {
          border-top-color: transparent;
        }
        .dt-table th:first-child, .dt-table td:first-child {
          padding-inline-start: max(var(--card-padding), \#(unit(3)));
        }
        .dt-table th:last-child, .dt-table td:last-child {
          padding-inline-end: max(var(--card-padding), \#(unit(3)));
        }
        .dt-table .dt-num {
          text-align: end;
          font-variant-numeric: tabular-nums;
        }
        .dt-table th[aria-sort] {
          cursor: pointer;
          color: var(--ink);
        }
        .dt-table th[aria-sort="ascending"]::after {
          content: " \25B2";
        }
        .dt-table th[aria-sort="descending"]::after {
          content: " \25BC";
        }
        .dt-table tr[aria-selected="true"] td {
          background: color-mix(in srgb, var(--accent) 14%, transparent);
        }
        .dt-table tr[aria-selected="true"] td:first-child {
          box-shadow: inset calc(var(--rule-section) * 2) 0 0 var(--accent);
        }
        @media (max-width: \#(BrowserSupport.Breakpoints.tableStackBelowPixels)px) {
          .dt-table, .dt-table tbody, .dt-table tr, .dt-table td {
            display: block;
          }
          .dt-table {
            border: 0;
            border-radius: 0;
            background: transparent;
            overflow: visible;
          }
          .dt-table thead {
            position: absolute;
            inline-size: 1px;
            block-size: 1px;
            overflow: hidden;
            clip-path: inset(50%);
            white-space: nowrap;
          }
          .dt-table tbody {
            display: grid;
            gap: var(--card-gap);
          }
          .dt-table tr {
            background: var(--card-surface);
            border: var(--card-border) solid var(--rule);
            border-top: max(var(--card-top-rule), var(--card-border)) solid var(--card-top-color);
            border-radius: var(--radius-container);
            padding-block: \#(unit(1.5));
            padding-inline: max(var(--card-padding), \#(unit(3)));
          }
          .dt-table td, .dt-table td:first-child, .dt-table td:last-child {
            display: grid;
            grid-template-columns: minmax(0, 1fr) minmax(0, 2fr);
            column-gap: var(--gutter);
            align-items: baseline;
            padding: \#(unit(1)) 0;
            border-top: 0;
            text-align: start;
            background: transparent;
          }
          .dt-table td::before {
            content: attr(data-label);
        \#(role("label"))
            color: var(--secondary-ink);
          }
          .dt-table .dt-num {
            text-align: start;
          }
          .dt-table td > .dt-chip {
            justify-self: start;
          }
          .dt-table tr[aria-selected="true"] {
            background: color-mix(in srgb, var(--accent) 14%, var(--card-surface));
            box-shadow: inset calc(var(--rule-section) * 2) 0 0 var(--accent);
          }
          .dt-table tr[aria-selected="true"] td, .dt-table tr[aria-selected="true"] td:first-child {
            background: transparent;
            box-shadow: none;
          }
        }

        /* ---- Chip: words in ink, an outline in the status colour, and a glyph, so the colour is never the only signal ---- */
        .dt-chip {
          display: inline-flex;
          align-items: center;
          gap: \#(unit(1));
          padding: \#(unit(0.5)) \#(unit(2));
          border: calc(var(--rule-hairline) * 2) solid var(--secondary-ink);
          border-radius: var(--radius-control);
          color: var(--ink);
          background: transparent;
        \#(role("caption"))
          white-space: nowrap;
        }
        .dt-chip::before {
          font-style: normal;
          line-height: 1;
        }

        \#(chips)
        /* ---- Banner: a block that holds text, paragraphs and links; the glyph sits in the start padding, so nothing splits into flex items ---- */
        .dt-banner {
          position: relative;
          padding-block: \#(unit(3));
          padding-inline: calc(var(--gutter) + \#(unit(6))) var(--gutter);
          border: var(--rule-hairline) solid var(--rule);
          border-inline-start: calc(var(--rule-section) * 2) solid var(--secondary-ink);
          border-radius: var(--radius-control);
          color: var(--ink);
        \#(role("body"))
        }
        .dt-banner::before {
          position: absolute;
          inset-block-start: \#(unit(3));
          inset-inline-start: var(--gutter);
          inline-size: \#(unit(4));
          font-style: normal;
          text-align: center;
        }
        .dt-banner > p {
          margin: 0;
        }
        .dt-banner > p + p {
          margin-top: \#(unit(2));
        }
        .dt-banner a {
          color: inherit;
          text-decoration: underline;
        }

        \#(banners)
        /* ---- Segmented control ---- */
        .dt-segmented {
          display: inline-flex;
          border: var(--rule-hairline) solid var(--ink);
          border-radius: var(--radius-control);
          overflow: hidden;
        }
        .dt-segmented__option {
          appearance: none;
          margin: 0;
          min-block-size: \#(unit(11));
          padding: \#(unit(1)) \#(unit(4));
          border: 0;
          border-inline-start: var(--rule-hairline) solid var(--ink);
          background: transparent;
          color: var(--ink);
          cursor: pointer;
        \#(role("label"))
          color: var(--ink);
        }
        .dt-segmented__option:first-child {
          border-inline-start: 0;
        }
        .dt-segmented__option[aria-checked="true"], .dt-segmented__option[aria-pressed="true"] {
          background: var(--ink);
          color: var(--background);
        }

        /* ---- Buttons ---- */
        .dt-button {
          appearance: none;
          display: inline-flex;
          align-items: center;
          justify-content: center;
          gap: \#(unit(2));
          min-block-size: \#(unit(11));
          padding: \#(unit(1)) \#(unit(4));
          border: var(--rule-hairline) solid var(--ink);
          border-radius: var(--radius-control);
          background: transparent;
          color: var(--ink);
          cursor: pointer;
        \#(role("body"))
          font-weight: var(--type-heading-weight);
          text-decoration: none;
        }
        .dt-button--primary {
          background: var(--accent);
          border-color: var(--accent);
          color: var(--on-accent);
        }
        .dt-button--destructive {
          border-color: var(--negative);
          color: var(--negative);
        }
        .dt-button[disabled], .dt-button[aria-disabled="true"] {
          opacity: 0.5;
          cursor: not-allowed;
        }

        /* ---- Actions: a row of buttons and a check that wraps instead of overflowing ---- */
        .dt-actions {
          display: flex;
          flex-wrap: wrap;
          align-items: center;
          gap: \#(unit(3)) var(--gutter);
        }
        .dt-checkline {
          display: inline-flex;
          align-items: center;
          gap: \#(unit(2));
          white-space: nowrap;
        }

        /* ---- Form controls ---- */
        .dt-field {
          display: flex;
          flex-direction: column;
          gap: \#(unit(1));
          min-inline-size: 0;
          margin: 0;
        }
        .dt-field__label {
        \#(role("label"))
          color: var(--secondary-ink);
        }
        .dt-input, .dt-select, .dt-textarea {
          inline-size: 100%;
          min-block-size: \#(unit(11));
          padding: \#(unit(1)) \#(unit(3));
          border: var(--rule-hairline) solid var(--secondary-ink);
          border-radius: var(--radius-control);
          background: var(--background);
          color: var(--ink);
        \#(role("body"))
        }
        .dt-input::placeholder, .dt-textarea::placeholder {
          color: var(--secondary-ink);
        }
        .dt-input:focus, .dt-select:focus, .dt-textarea:focus {
          border-color: var(--accent);
        }
        .dt-check {
          accent-color: var(--accent);
          inline-size: \#(unit(5));
          block-size: \#(unit(5));
          margin: 0;
        }

        /* ---- Grid: the theme's columns and gutter ---- */
        .dt-grid {
          display: grid;
          grid-template-columns: repeat(var(--columns), minmax(0, 1fr));
          column-gap: var(--gutter);
          row-gap: var(--gutter);
        }
        \#(columns)
        @media (max-width: \#(BrowserSupport.Breakpoints.tableStackBelowPixels)px) {
          .dt-grid > [class*="dt-col-"] {
            grid-column: 1 / -1;
          }
        }
        @media (max-width: \#(BrowserSupport.Breakpoints.tableStackBelowPixels)px) {
          .dt-shell {
            grid-template-columns: minmax(0, 1fr);
            row-gap: \#(unit(4));
          }
          .dt-shell__nav {
            position: static;
            max-block-size: none;
            overflow-y: visible;
          }
          .dt-nav {
            display: flex;
            flex-wrap: wrap;
            gap: \#(unit(1)) var(--gutter);
          }
          .dt-nav__item {
            border-inline-start: 0;
            border-block-end: calc(var(--rule-section) * 2) solid transparent;
            padding: \#(unit(1)) 0;
          }
          .dt-nav__item[aria-current] {
            border-block-end-color: var(--ink);
          }
          .dt-list--columns {
            grid-template-columns: minmax(0, 1fr);
          }
        }

        /* ---- Hidden: the attribute always wins, whatever display a component sets ---- */
        [hidden] {
          display: none !important;
        }

        /* ---- Hover and active: an inner outline in the current colour, so the words keep their contrast and forced colours keep the shape ---- */
        @media (hover: hover) {
          .dt-button:not([disabled]):not([aria-disabled="true"]):hover, .dt-segmented__option:hover {
            outline: var(--rule-hairline) solid currentColor;
            outline-offset: calc(var(--rule-hairline) * -3);
          }
          .dt-input:not(:disabled):hover, .dt-select:not(:disabled):hover, .dt-textarea:not(:disabled):hover {
            border-color: var(--ink);
          }
          .dt-link:hover {
            text-decoration-thickness: calc(var(--rule-hairline) * 2);
          }
          .dt-table th[aria-sort]:hover, .dt-nav__item:hover {
            text-decoration: underline;
          }
        }
        .dt-button:not([disabled]):not([aria-disabled="true"]):active, .dt-segmented__option:active {
          outline: calc(var(--rule-hairline) * 2) solid currentColor;
          outline-offset: calc(var(--rule-hairline) * -4);
        }

        /* ---- Invalid and disabled controls: a heavier negative border (a shape, not only a colour), and a dimmed, inert control ---- */
        .dt-input[aria-invalid="true"], .dt-select[aria-invalid="true"], .dt-textarea[aria-invalid="true"] {
          border-color: var(--negative);
          border-width: calc(var(--rule-hairline) * 2);
        }
        .dt-input:disabled, .dt-select:disabled, .dt-textarea:disabled, .dt-check:disabled {
          opacity: 0.5;
          cursor: not-allowed;
        }

        /* ---- Focus: the ink, two rule weights wide, never colour alone ---- */
        .dt-button:focus-visible, .dt-segmented__option:focus-visible, .dt-input:focus-visible, .dt-select:focus-visible,
        .dt-textarea:focus-visible, .dt-check:focus-visible, .dt-link:focus-visible, .dt-table th[aria-sort]:focus-visible,
        .dt-nav__item:focus-visible, .dt-prose a:focus-visible, .dt-banner a:focus-visible {
          outline: calc(var(--rule-hairline) * 2) solid var(--ink);
          outline-offset: calc(var(--rule-hairline) * 2);
        }
        .dt-segmented__option:focus-visible, .dt-table th[aria-sort]:focus-visible, .dt-nav__item:focus-visible {
          outline-offset: calc(var(--rule-hairline) * -3);
        }

        /* ---- Increased contrast: heavier edges, the ink on every boundary ---- */
        @media (prefers-contrast: more) {
          .dt-chip, .dt-input, .dt-select, .dt-textarea, .dt-button, .dt-segmented {
            border-width: calc(var(--rule-hairline) * 2);
          }
          .dt-input, .dt-select, .dt-textarea {
            border-color: var(--ink);
          }
          .dt-item, .dt-card, .dt-table, .dt-table tr, .dt-banner {
            border-color: var(--ink);
          }
          .dt-kv__row, .dt-table td, .dt-item, .dt-rule {
            border-top-color: var(--ink);
          }
          .dt-label, .dt-caption, .dt-kv__key, .dt-field__label, .dt-table th {
            color: var(--ink);
          }
          .dt-button--primary {
            background: var(--ink);
            border-color: var(--ink);
            color: var(--background);
          }
          mark, .dt-mark {
            background: color-mix(in srgb, var(--accent) 45%, var(--background));
            outline: var(--rule-hairline) solid var(--ink);
          }
          .dt-prose blockquote, .dt-prose th, .dt-nav__heading, .dt-item__meta {
            color: var(--ink);
          }
          .dt-prose blockquote, .dt-prose td, .dt-prose pre, .dt-prose hr {
            border-color: var(--ink);
          }
        }

        /* ---- Forced colours: the ink fill and the tint are overridden, so selection is carried by system colours and by shape ---- */
        @media (forced-colors: active) {
          .dt-segmented__option[aria-checked="true"]::before, .dt-segmented__option[aria-pressed="true"]::before {
            content: "\2713\A0";
          }
          .dt-segmented__option[aria-checked="true"], .dt-segmented__option[aria-pressed="true"] {
            text-decoration: underline;
            text-decoration-thickness: calc(var(--rule-hairline) * 2);
          }
          .dt-table tr[aria-selected="true"] {
            outline: calc(var(--rule-section) * 2) solid Highlight;
            outline-offset: calc(var(--rule-section) * -2);
          }
          .dt-button--primary {
            border-width: calc(var(--rule-hairline) * 2);
          }
          mark, .dt-mark {
            outline: calc(var(--rule-hairline) * 2) solid Highlight;
            text-decoration: underline;
          }
          .dt-nav__item {
            border-color: Canvas;
          }
          .dt-nav__item[aria-current] {
            border-color: Highlight;
          }
        }

        /* ---- Motion: only a short colour change, and none when the reader asks for less ---- */
        @media (prefers-reduced-motion: no-preference) {
          .dt-button, .dt-segmented__option, .dt-input, .dt-select, .dt-textarea {
            transition: background-color 120ms ease, border-color 120ms ease, color 120ms ease;
          }
        }
        @media (prefers-reduced-motion: reduce) {
          .dt-button, .dt-segmented__option, .dt-input, .dt-select, .dt-textarea {
            transition: none;
          }
        }
        """# + "\n"
    }
}
