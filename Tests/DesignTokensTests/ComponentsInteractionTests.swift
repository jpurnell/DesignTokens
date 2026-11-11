import Foundation
import Testing
@testable import DesignTokens

/// A small reader of the emitted stylesheet: the body of each `@media` block, and the declarations of each rule whose selector
/// matches. Brace counting is enough because the emitter writes no braces inside strings other than `content: "..."` glyphs.
enum CSSReader {
    /// The bodies of every top-level `@media` block whose prelude contains `prelude`.
    static func mediaBodies(_ prelude: String, in css: String) -> [String] {
        var bodies: [String] = []
        var search = css.startIndex
        while let hit = css.range(of: "@media (\(prelude))", range: search..<css.endIndex) ?? css.range(of: "@media \(prelude)", range: search..<css.endIndex) {
            guard let open = css.range(of: "{", range: hit.upperBound..<css.endIndex) else { break }
            var depth = 1
            var index = open.upperBound
            while index < css.endIndex, depth > 0 {
                if css[index] == "{" { depth += 1 } else if css[index] == "}" { depth -= 1 }
                index = css.index(after: index)
            }
            bodies.append(String(css[open.upperBound..<css.index(before: index)]))
            search = index
        }
        return bodies
    }

    /// The css with every `@media` block removed (the rules that apply always).
    static func outsideMedia(_ css: String) -> String {
        var result = css
        while let hit = result.range(of: "@media ") {
            guard let open = result.range(of: "{", range: hit.upperBound..<result.endIndex) else { break }
            var depth = 1
            var index = open.upperBound
            while index < result.endIndex, depth > 0 {
                if result[index] == "{" { depth += 1 } else if result[index] == "}" { depth -= 1 }
                index = result.index(after: index)
            }
            result.removeSubrange(hit.lowerBound..<index)
        }
        return result
    }

    /// The declaration text of every rule in `css` whose selector list contains `selector` (substring match), joined.
    static func declarations(of selector: String, in css: String) -> String {
        var found: [String] = []
        var search = css.startIndex
        while let open = css.range(of: "{", range: search..<css.endIndex) {
            guard let close = css.range(of: "}", range: open.upperBound..<css.endIndex) else { break }
            let before = css[css.startIndex..<open.lowerBound]
            let selectorText = before.split(separator: "}").last.map(String.init) ?? ""
            if selectorText.contains(selector) { found.append(String(css[open.upperBound..<close.lowerBound])) }
            search = close.upperBound
        }
        return found.joined(separator: "\n")
    }
}

@Suite("components.css interaction and accessibility states (0.13.0)")
struct ComponentsInteractionTests {
    private static var css: String { ComponentsCSSEmitter.emit() }

    // MARK: Hover and active

    @Test("every :hover rule is inside @media (hover: hover), so a touch screen never keeps a hover state")
    func hoverOnlyWhereHoverExists() {
        let css = Self.css
        let outside = CSSReader.outsideMedia(css)
        #expect(!outside.contains(":hover"), "a :hover rule outside a media query")
        let inside = CSSReader.mediaBodies("hover: hover", in: css).joined(separator: "\n")
        for selector in [#".dt-button:not([disabled]):not([aria-disabled="true"]):hover"#, ".dt-segmented__option:hover", ".dt-input:not(:disabled):hover", ".dt-link:hover", ".dt-table th[aria-sort]:hover"] {
            #expect(inside.contains(selector), Comment(rawValue: selector))
        }
    }

    @Test("hover and active change something that is not only a colour of text, and never lower the contrast of the words")
    func hoverIsContrastNeutral() {
        let inside = CSSReader.mediaBodies("hover: hover", in: Self.css).joined(separator: "\n")
        // a hover is an inner outline in the current colour: it works in forced colours and does not change a fill under the words
        let button = CSSReader.declarations(of: #".dt-button:not([disabled]):not([aria-disabled="true"]):hover"#, in: inside)
        #expect(button.contains("outline:") && button.contains("currentColor"))
        #expect(!button.contains("background"), "a button hover must not change the fill under text")
        let active = CSSReader.declarations(of: #".dt-button:not([disabled]):not([aria-disabled="true"]):active"#, in: Self.css)
        #expect(active.contains("outline:"), ":active shows something")
        #expect(CSSReader.declarations(of: ".dt-segmented__option:active", in: Self.css).contains("outline:"))
    }

    @Test("a disabled control gets no hover or active state")
    func disabledIsInert() {
        let css = Self.css
        #expect(css.contains(".dt-button:not([disabled]):not([aria-disabled=\"true\"]):hover"))
        #expect(css.contains(".dt-button:not([disabled]):not([aria-disabled=\"true\"]):active"))
    }

    // MARK: Focus

    @Test("focus rings of controls inside a clipping parent are drawn inside the control, so overflow:hidden cannot cut them")
    func focusRingNotClipped() {
        let css = Self.css
        for selector in [".dt-segmented__option:focus-visible", ".dt-table th[aria-sort]:focus-visible"] {
            let offsets = CSSReader.declarations(of: selector, in: css)
            #expect(offsets.contains("outline-offset: calc(var(--rule-hairline) * -"), Comment(rawValue: "\(selector) needs a negative outline-offset"))
        }
    }

    @Test("the focus ring is the ink, never colour alone, and uses theme tokens only")
    func focusRingUsesTokens() {
        let css = Self.css
        let ring = CSSReader.declarations(of: ".dt-button:focus-visible", in: css)
        #expect(ring.contains("outline: calc(var(--rule-hairline) * 2) solid var(--ink)"))
    }

    // MARK: Form states

    @Test("an invalid control is marked by a negative-colour heavier border (shape as well as colour); a disabled control is dimmed and inert")
    func invalidAndDisabled() {
        let css = Self.css
        let invalid = CSSReader.declarations(of: #".dt-input[aria-invalid="true"]"#, in: css)
        #expect(invalid.contains("border-color: var(--negative)"))
        #expect(invalid.contains("border-width: calc(var(--rule-hairline) * 2)"), "a heavier border survives forced colours")
        for control in [".dt-select[aria-invalid", ".dt-textarea[aria-invalid"] { #expect(css.contains(control), Comment(rawValue: control)) }
        let disabled = CSSReader.declarations(of: ".dt-input:disabled", in: css)
        #expect(disabled.contains("opacity: 0.5") && disabled.contains("cursor: not-allowed"))
    }

    // MARK: Forced colours

    @Test("forced colours: selection is carried by system colours, since the ink fill and the tint are overridden")
    func forcedColours() {
        let forced = CSSReader.mediaBodies("forced-colors: active", in: Self.css).joined(separator: "\n")
        #expect(!forced.isEmpty)
        // the ink fill is overridden, and a Highlight fill gets a text backplate that hides the label (seen in Chrome), so a
        // selected option is marked with a check glyph and a heavier underline: shapes, not colours
        let marker = CSSReader.declarations(of: ".dt-segmented__option[aria-checked=\"true\"]::before", in: forced)
        #expect(marker.contains("content:"))
        let underline = CSSReader.declarations(of: ".dt-segmented__option[aria-checked=\"true\"]", in: forced)
        #expect(underline.contains("text-decoration: underline"))
        #expect(!forced.contains("forced-color-adjust"), "Safari has no forced-color-adjust; the rules must not depend on it")
        let row = CSSReader.declarations(of: "tr[aria-selected=\"true\"]", in: forced)
        #expect(row.contains("outline:") && row.contains("Highlight"), "a selected row needs a shape in forced colours")
        let primary = CSSReader.declarations(of: ".dt-button--primary", in: forced)
        #expect(primary.contains("border-width: calc(var(--rule-hairline) * 2)"), "the primary button keeps its emphasis as a heavier border")
        // no colour literal other than a system colour keyword
        #expect(!forced.contains("#"))
    }

    // MARK: Increased contrast

    @Test("increased contrast: the primary button is ink on the page colour, because accent with on-accent can fall under 4.5:1")
    func contrastPrimary() {
        let more = CSSReader.mediaBodies("prefers-contrast: more", in: Self.css).joined(separator: "\n")
        let primary = CSSReader.declarations(of: ".dt-button--primary", in: more)
        #expect(primary.contains("background: var(--ink)") && primary.contains("color: var(--background)"))
    }

    // MARK: Motion

    @Test("every transition is inside prefers-reduced-motion: no-preference, and reduce switches them off")
    func motion() {
        let css = Self.css
        let outside = CSSReader.outsideMedia(css)
        #expect(!outside.contains("transition:"), "a transition outside a media query")
        #expect(!outside.contains("animation"), "no animation anywhere")
        for body in CSSReader.mediaBodies("prefers-reduced-motion: reduce", in: css) { #expect(body.contains("transition: none")) }
        for body in CSSReader.mediaBodies("hover: hover", in: css) { #expect(!body.contains("transition")) }
        let allowed = CSSReader.mediaBodies("prefers-reduced-motion: no-preference", in: css).joined(separator: "\n")
        #expect(allowed.contains("transition:"))
    }
}
