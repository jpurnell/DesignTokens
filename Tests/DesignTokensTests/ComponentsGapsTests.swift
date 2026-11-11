import Foundation
import Testing
@testable import DesignTokens

@Suite("components.css gaps reported by the Vault adoption (0.13.0)")
struct ComponentsGapsTests {
    private static var css: String { ComponentsCSSEmitter.emit() }
    private static let narrow = "@media (max-width: \(BrowserSupport.Breakpoints.tableStackBelowPixels)px)"

    private static func narrowBody() -> String {
        CSSReader.mediaBodies("max-width: \(BrowserSupport.Breakpoints.tableStackBelowPixels)px", in: css).joined(separator: "\n")
    }

    // MARK: Hidden

    @Test("[hidden] always wins over a component's display value")
    func hiddenWins() {
        let rule = CSSReader.declarations(of: "[hidden]", in: Self.css)
        #expect(rule.contains("display: none !important"))
        // !important, so the position of the rule in the file is not what makes it win
    }

    // MARK: Shell and navigation

    @Test("the shell is two columns, a sticky navigation column and the main column, and one wrapped row under the breakpoint")
    func shell() {
        let css = Self.css
        let shell = CSSReader.declarations(of: ".dt-shell ", in: css)
        #expect(shell.contains("display: grid"))
        #expect(shell.contains("grid-template-columns: minmax(0, calc(var(--space-unit) * 56)) minmax(0, 1fr)"))
        let nav = CSSReader.declarations(of: ".dt-shell__nav ", in: css)
        #expect(nav.contains("position: sticky") && nav.contains("top: var(--gutter)") && nav.contains("align-self: start"))
        #expect(css.contains(".dt-shell__main"))
        let narrow = Self.narrowBody()
        #expect(CSSReader.declarations(of: ".dt-shell ", in: narrow).contains("grid-template-columns: minmax(0, 1fr)"))
        #expect(CSSReader.declarations(of: ".dt-shell__nav ", in: narrow).contains("position: static"))
        let row = CSSReader.declarations(of: ".dt-nav ", in: narrow)
        #expect(row.contains("display: flex") && row.contains("flex-wrap: wrap"))
    }

    @Test("a nav heading is the label role; the current page is marked by aria-current with a heavier edge, not colour alone")
    func nav() {
        let css = Self.css
        let heading = CSSReader.declarations(of: ".dt-nav__heading ", in: css)
        #expect(heading.contains("font-size: var(--type-label-size)") && heading.contains("color: var(--secondary-ink)"))
        let current = CSSReader.declarations(of: #".dt-nav__item[aria-current]"#, in: css)
        #expect(current.contains("border-inline-start-color: var(--ink)") && current.contains("font-weight: var(--type-heading-weight)"))
        #expect(css.contains(".dt-nav__item:focus-visible"))
    }

    // MARK: Prose

    @Test("prose styles unclassed rendered Markdown: every heading, lists, quote, code, pre, table, rule, link, mark and image")
    func prose() {
        let css = Self.css
        for tag in ["h1", "h2", "h3", "h4", "h5", "h6", "p", "ul", "ol", "li", "blockquote", "code", "pre", "table", "th", "td", "hr", "a", "mark", "img"] {
            #expect(css.contains(".dt-prose \(tag)"), Comment(rawValue: tag))
        }
        #expect(CSSReader.declarations(of: ".dt-prose img", in: css).contains("max-inline-size: 100%"))
        let table = CSSReader.declarations(of: ".dt-prose td", in: css) + CSSReader.declarations(of: ".dt-prose table", in: css)
        #expect(table.contains("font-variant-numeric: tabular-nums"))
        let header = CSSReader.declarations(of: ".dt-prose th", in: css)
        #expect(header.contains("border-bottom: var(--rule-hairline) solid var(--ink)"))
        let pre = CSSReader.declarations(of: ".dt-prose pre", in: css)
        #expect(pre.contains("overflow-x: auto"))
        #expect(CSSReader.declarations(of: ".dt-prose code", in: css).contains("font-family: var(--font-mono)"))
    }

    // MARK: Mark

    @Test("mark and dt-mark are a tint derived from accent (the palette has no highlight role), in ink, with a shape under contrast and forced colours")
    func mark() {
        let css = Self.css
        let mark = CSSReader.declarations(of: ".dt-mark", in: CSSReader.outsideMedia(css))
        #expect(mark.contains("background: color-mix(in srgb, var(--accent)"))
        #expect(mark.contains("color: var(--ink)"))
        let more = CSSReader.mediaBodies("prefers-contrast: more", in: css).joined(separator: "\n")
        #expect(CSSReader.declarations(of: ".dt-mark", in: more).contains("outline:"))
        let forced = CSSReader.mediaBodies("forced-colors: active", in: css).joined(separator: "\n")
        let forcedMark = CSSReader.declarations(of: ".dt-mark", in: forced)
        #expect(forcedMark.contains("outline:") && forcedMark.contains("Highlight"))
        // a transparent border is drawn in a forced border colour, so only the current nav item may have a visible bar
        #expect(CSSReader.declarations(of: ".dt-nav__item ", in: forced).contains("border-color: Canvas"))
        #expect(CSSReader.declarations(of: ".dt-nav__item[aria-current]", in: forced).contains("border-color: Highlight"))
    }

    // MARK: Item variants and columns

    @Test("an item can carry a trailing count or meta, kept on one line and in tabular numerals")
    func itemMeta() {
        let css = Self.css
        let row = CSSReader.declarations(of: ".dt-item--meta ", in: css)
        #expect(row.contains("display: flex") && row.contains("justify-content: space-between"))
        let meta = CSSReader.declarations(of: ".dt-item__meta ", in: css)
        #expect(meta.contains("font-variant-numeric: tabular-nums") && meta.contains("white-space: nowrap") && meta.contains("flex: none"))
        #expect(css.contains(".dt-item__main"))
    }

    // MARK: Banner

    @Test("a banner holds paragraphs and inline links: its glyph is positioned in the padding, so it is not a flex line that splits the content")
    func banner() {
        let css = Self.css
        let banner = CSSReader.declarations(of: ".dt-banner ", in: css)
        #expect(!banner.contains("display: flex") && !banner.contains("display: grid"))
        #expect(banner.contains("position: relative"))
        let glyph = CSSReader.declarations(of: ".dt-banner::before ", in: css)
        #expect(glyph.contains("position: absolute") && glyph.contains("inset-inline-start"))
        #expect(CSSReader.declarations(of: ".dt-banner a", in: css).contains("text-decoration: underline"))
        #expect(css.contains(".dt-banner > p"))
    }

    // MARK: Fit for the gaps still to come

    @Test("the stylesheet declares no custom property of its own and stays inside the documented breakpoint, so the dense chip list, collapsing card, meter, stale and toolbar gaps can be added as more blocks")
    func stillOnlyTokens() {
        let css = Self.css
        #expect(!css.contains("\n  --") && !css.contains("{ --"), "no custom property is declared here")
        let widths = css.components(separatedBy: "@media (max-width: ").dropFirst().map { String($0.prefix(while: { $0 != ")" })) }
        #expect(!widths.isEmpty && Set(widths) == ["\(BrowserSupport.Breakpoints.tableStackBelowPixels)px"], "one width, the documented one")
    }

    // MARK: The breakpoint

    @Test("the breakpoint cannot be a custom property, and the documented query string is the emitted one")
    func breakpointDocumented() throws {
        #expect(BrowserSupport.Breakpoints.narrowMediaQuery == "(max-width: 600px)")
        #expect(Self.css.contains("@media \(BrowserSupport.Breakpoints.narrowMediaQuery)"))
        let readme = try String(contentsOf: URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("README.md"), encoding: .utf8)
        #expect(readme.contains("cannot be a custom property"))
        #expect(readme.contains(BrowserSupport.Breakpoints.narrowMediaQuery))
        #expect(Self.css.contains("cannot be a custom property"), "the generated header says it too")
    }
}
