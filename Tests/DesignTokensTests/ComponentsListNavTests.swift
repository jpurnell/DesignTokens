import Foundation
import Testing
@testable import DesignTokens

@Suite("components.css list columns and navigation, gaps found by the Vault 0.13.0 adoption (0.14.0)")
struct ComponentsListNavTests {
    private static var css: String { ComponentsCSSEmitter.emit() }

    private static func narrowBody() -> String {
        CSSReader.mediaBodies("max-width: \(BrowserSupport.Breakpoints.tableStackBelowPixels)px", in: css).joined(separator: "\n")
    }

    // MARK: dt-list--columns

    @Test("a column list reads down each column: CSS multi-column, not a grid that flows across rows")
    func columnsReadDown() {
        let list = CSSReader.declarations(of: ".dt-list--columns ", in: Self.css)
        #expect(list.contains("column-width:"))
        #expect(!list.contains("display: grid"))
        #expect(!list.contains("grid-template-columns"))
        #expect(!list.contains("grid-auto-flow"))
    }

    @Test("an item is never split across two columns")
    func itemsDoNotBreak() {
        let item = CSSReader.declarations(of: ".dt-list--columns > .dt-item", in: Self.css)
        #expect(item.contains("break-inside: avoid"))
    }

    @Test("rows in a column list share one rule: the list has the top rule and each item only a bottom rule")
    func oneRuleBetweenRows() {
        let css = Self.css
        let item = CSSReader.declarations(of: ".dt-list--columns > .dt-item", in: css)
        #expect(item.contains("border-top: 0"))
        #expect(item.contains("border-bottom: var(--rule-hairline) solid var(--rule)"))
        #expect(CSSReader.declarations(of: ".dt-list--columns ", in: css).contains("border-top: var(--rule-hairline) solid var(--rule)"))
    }

    @Test("a column list is one column under the breakpoint")
    func oneColumnWhenNarrow() {
        let narrow = CSSReader.declarations(of: ".dt-list--columns ", in: Self.narrowBody())
        #expect(narrow.contains("column-width: auto"))
    }

    // MARK: Navigation groups

    @Test("consecutive navigation groups are separated by a token-derived gap")
    func navGroupsGap() {
        let css = Self.css
        for selector in [".dt-nav + .dt-nav", ".dt-nav + .dt-nav__heading", ".dt-nav__item + .dt-nav__heading"] {
            let rule = CSSReader.declarations(of: selector, in: css)
            #expect(rule.contains("margin-block-start: calc(var(--space-unit) * "), "\(selector) has a gap from the spacing unit")
        }
    }

    // MARK: Trailing count

    @Test("a navigation item can end with a count, pushed to the end, tabular, muted, and set in the caption role")
    func navCount() {
        let css = Self.css
        let item = CSSReader.declarations(of: ".dt-nav__item ", in: css)
        #expect(item.contains("display: flex") && item.contains("justify-content: space-between"))
        let count = CSSReader.declarations(of: ".dt-nav__count ", in: css)
        #expect(count.contains("margin-inline-start: auto"))
        #expect(count.contains("flex: none"))
        #expect(count.contains("font-variant-numeric: tabular-nums"))
        #expect(count.contains("color: var(--secondary-ink)"))
        #expect(count.contains("font-size: var(--type-caption-size)"), "a smaller size, so the count is not told apart by colour alone")
    }

    @Test("the count keeps its place in the collapsed navigation row, after the name with a gap")
    func navCountNarrow() {
        let narrow = Self.narrowBody()
        #expect(CSSReader.declarations(of: ".dt-nav__item ", in: Self.css).contains("gap: calc(var(--space-unit) * 2)"))
        #expect(!CSSReader.declarations(of: ".dt-nav__item ", in: narrow).contains("display: block"))
        #expect(CSSReader.declarations(of: ".dt-nav__count", in: narrow).contains("margin-inline-start: 0"))
    }

    @Test("the count is ink under increased contrast, and the current item does not bold it")
    func navCountContrast() {
        let more = CSSReader.mediaBodies("prefers-contrast: more", in: Self.css).joined(separator: "\n")
        #expect(CSSReader.declarations(of: ".dt-nav__count", in: more).contains("color: var(--ink)"))
        #expect(CSSReader.declarations(of: ".dt-nav__item[aria-current] .dt-nav__count", in: Self.css).contains("font-weight: var(--type-caption-weight)"))
    }

    // MARK: Browser support

    @Test("multi-column layout is in the browser table, inside the page floor")
    func multicolumnDocumented() {
        let names = BrowserSupport.features.map(\.name)
        #expect(names.contains { $0.contains("Multi-column") })
        #expect(BrowserSupport.pageFloor == BrowserSupport.Versions(chrome: 111, edge: 111, safari: 16.2, firefox: 113))
    }
}
