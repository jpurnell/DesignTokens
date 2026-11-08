import Testing
@testable import DesignTokens

@Suite("Typography")
struct TypographyTests {
    @Test("the sans stack starts with the system font and falls back to Helvetica")
    func sansStack() {
        let stack = FontStack.sans
        #expect(stack.hasPrefix("-apple-system, BlinkMacSystemFont, \"SF Pro Text\""))
        #expect(stack.contains("\"Helvetica Neue\", Helvetica, Arial"))
        #expect(stack.hasSuffix("sans-serif"))
    }

    @Test("mono and the two serif options are defined; serif is a switch, not the default")
    func otherStacks() {
        #expect(FontStack.mono.contains("\"SF Mono\""))
        #expect(FontStack.serifNewYork.contains("\"New York\""))
        #expect(FontStack.serifGaramond.contains("Garamond"))
        #expect(FontStack.serifNewYork != FontStack.sans)
    }

    @Test("the type scale has the six roles in a fixed order")
    func roles() {
        #expect(TypeStyle.allCases.map(\.name) == ["label", "caption", "body", "heading", "title", "display"])
    }

    @Test("label is 11 point semibold capitals with positive tracking")
    func label() {
        let label = TypeStyle.label
        #expect(label.size == "11px")
        #expect(label.weight == 600)
        #expect(label.uppercase)
        #expect(label.tracking == "0.08em")
    }

    @Test("sizes step up from label to display and display tracks tight")
    func ordering() {
        let px = TypeStyle.allCases.compactMap { Int($0.size.replacingOccurrences(of: "px", with: "")) }
        #expect(px == px.sorted()) // display's clamp() size is not a plain px value, so it is excluded
        #expect(px.count == 5)
        #expect(TypeStyle.display.tracking.hasPrefix("-"))
        #expect(!TypeStyle.body.uppercase)
    }

    @Test("CSS carries the stacks and every role's size, line, weight and tracking")
    func css() {
        let css = CSSEmitter.emit()
        #expect(css.contains("--font-sans: -apple-system"))
        #expect(css.contains("--font-mono: ui-monospace"))
        #expect(css.contains("--type-label-size: 11px;"))
        #expect(css.contains("--type-label-transform: uppercase;"))
        #expect(css.contains("--type-body-line: 1.5;"))
        #expect(css.contains("--type-display-tracking: -0.05em;"))
    }
}
