import Foundation
import Testing
@testable import DesignTokens

/// The disabled, inactive and focus states of the three skins. Disabled buttons and Platinum's inactive scroll bar are measured from the Open
/// dialogs of the Mac OS 8.0 and System 7.0 captures; the focus rings are chosen (neither platform draws one).
@Suite("Skin states")
struct SkinStatesTests {
    private func ref(_ name: String) -> ColourReference { ColourReference(source: name) }

    private func lastRule(_ css: String, _ selector: String) throws -> [String] {
        let start = try #require(css.range(of: selector + " {", options: .backwards), Comment(rawValue: selector))
        return String(css[start.upperBound...].prefix(while: { $0 != "}" })).split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespaces) }
    }

    @Test("Platinum's disabled button is flat #DDDDDD with a one-pixel #888888 outline and #888888 text, no bevel")
    func platinumDisabledButton() throws {
        let rest = try #require(Theme.platinum.surfaces?.recipes[.button]?[.rest])
        let disabled = try #require(Theme.platinum.surfaces?.recipes[.button]?[.disabled])
        #expect(disabled.layers == [.fill(ref("background"))])
        let gray = [EdgeStep(literal: ref("gray88"), 1)]
        #expect(disabled.edges?.top == gray && disabled.edges?.leading == gray && disabled.edges?.bottom == gray && disabled.edges?.trailing == gray)
        #expect(disabled.ink == ref("gray88"))
        #expect(disabled.radius == rest.radius)
        let css = try ThemeCSSEmitter.emit(.platinum)
        let rule = try lastRule(css, "[data-theme-name=\"platinum\"] .dt-button:disabled")
        #expect(rule.contains("color: var(--extra-gray88);") && rule.contains("background-color: var(--background);"))
        #expect(rule.contains("box-shadow: inset 0 1px 0 0 var(--extra-gray88), inset 1px 0 0 0 var(--extra-gray88), inset 0 -1px 0 0 var(--extra-gray88), inset -1px 0 0 0 var(--extra-gray88);"))
    }

    @Test("System 7's disabled button keeps the black outline and draws its label in #808080")
    func system7DisabledButton() throws {
        let css = try ThemeCSSEmitter.emit(.system7)
        #expect(css.contains("--extra-dim: #808080;"))
        let rule = try lastRule(css, "[data-theme-name=\"system7\"] .dt-button:disabled")
        #expect(rule.contains("color: var(--extra-dim);") && rule.contains("background-color: var(--background);"))
        #expect(rule.contains("box-shadow: inset 0 1px 0 0 var(--ink), inset 1px 0 0 0 var(--ink), inset 0 -1px 0 0 var(--ink), inset -1px 0 0 0 var(--ink);"))
    }

    @Test("a disabled menu title or row is drawn in the dimmed ink on every skin that has menus")
    func disabledMenu() throws {
        let cases: [(Theme, String, String, String)] = [
            (.system7, ".dt-menubar__item", "system7", "var(--extra-dim)"),
            (.platinum, ".dt-menubar__item", "platinum", "var(--extra-gray88)"),
            (.openstep, ".dt-menu__item", "openstep", "var(--muted)"),
        ]
        for (theme, selector, id, colour) in cases {
            let rule = try lastRule(try ThemeCSSEmitter.emit(theme), "[data-theme-name=\"\(id)\"] \(selector)[aria-disabled=\"true\"]")
            #expect(rule.contains("color: \(colour);"), "\(id)")
        }
    }

    @Test("Platinum's inactive scroll bar: flat #EEEEEE with black outlines, arrows without a bevel and with #888888 triangles")
    func platinumInactiveScrollBar() throws {
        let surfaces = try #require(Theme.platinum.surfaces)
        let track = try #require(surfaces.recipes[.scrollTrack]?[.disabled])
        #expect(track.layers == [.fill(ref("grayEE"))])
        #expect(track.edges?.top == [EdgeStep(literal: ref("ink"), 1)] && track.edges?.bottom == [EdgeStep(literal: ref("ink"), 1)])
        for role in [SurfaceRole.scrollArrowStart, .scrollArrowEnd] {
            let recipe = try #require(surfaces.recipes[role]?[.disabled], Comment(rawValue: "\(role)"))
            guard case .pattern(let tile)? = recipe.layers.last else { throw SurfaceError.cellSize(0) }
            #expect(tile.width == 16 && tile.height == 16)
            // the triangle is 1+2+3+4+4+3+2+1 = 20 pixels, and nothing else is #888888 or white
            #expect(tile.cells.filter { $0 == ref("gray88") }.count == 20)
            #expect(!tile.cells.contains(ref("surface")))
            // the side facing the track (the right column of the start arrow, the left of the end arrow) is #555555, every other edge black, and the inner side's two end pixels too
            let towardTrack = role == .scrollArrowStart ? 15 : 0
            let black = ref("ink"), dark = ref("gray55")
            for i in 0..<16 {
                #expect(tile.cells[i] == black && tile.cells[15 * 16 + i] == black, "\(role) horizontal edges at column \(i)")
                #expect(tile.cells[i * 16 + towardTrack] == (i == 0 || i == 15 ? black : dark), "\(role) inner side at row \(i)")
                #expect(tile.cells[i * 16 + (15 - towardTrack)] == black, "\(role) outer side at row \(i)")
            }
            #expect(tile.cells[2 * 16 + 2] == ref("grayEE"))
        }
    }

    @Test("an inactive scroll bar is selected by aria-disabled, and turned for a vertical one")
    func inactiveScrollCSS() throws {
        let css = try ThemeCSSEmitter.emit(.platinum)
        let horizontal = try lastRule(css, "[data-theme-name=\"platinum\"] .dt-scrollbar[aria-disabled=\"true\"] .dt-scrollbar__track")
        #expect(horizontal.contains("background-color: var(--extra-gray-e-e);"))
        let vertical = try lastRule(css, "[data-theme-name=\"platinum\"] .dt-scrollbar[data-orientation=\"vertical\"][aria-disabled=\"true\"] .dt-scrollbar__track")
        #expect(vertical.contains("background-color: var(--extra-gray-e-e);"))
        #expect(!(try ThemeCSSEmitter.emit(.openstep)).contains("[aria-disabled=\"true\"] .dt-scrollbar__track"))
    }

    @Test("a focused button or field keeps its drawing and adds a two-pixel ring: black on System 7 and OPENSTEP, the accent on Platinum")
    func focusRing() throws {
        let cases: [(Theme, String, String)] = [(.system7, "system7", "ink"), (.platinum, "platinum", "accent"), (.openstep, "openstep", "ink")]
        for (theme, id, ring) in cases {
            let css = try ThemeCSSEmitter.emit(theme)
            for selector in [".dt-button", ".dt-textarea"] {
                let rest = try lastRule(css, "[data-theme-name=\"\(id)\"] \(selector)")
                let focus = try lastRule(css, "[data-theme-name=\"\(id)\"] \(selector):focus-visible")
                let fill = try #require(rest.first { $0.hasPrefix("background-color:") })
                #expect(focus.contains(fill), "\(id) \(selector) keeps its fill")
                #expect(focus.contains { $0.hasPrefix("box-shadow:") && $0.hasSuffix(", 0 0 0 2px var(--\(ring));") }, "\(id) \(selector) ring: \(focus)")
                let restShadow = try #require(rest.first { $0.hasPrefix("box-shadow:") })
                #expect(!restShadow.contains("0 0 0 2px"), "\(id) \(selector) has no ring at rest")
            }
        }
    }

    // MARK: the components stylesheet must not draw over a skin's states

    @Test("a skin removes the hover and pressed outlines the components stylesheet gives a button, which the original platforms never drew")
    func noOutlinesOnSkins() throws {
        for id in ["system7", "platinum", "openstep"] {
            let theme = try #require(Theme.named(id), Comment(rawValue: id))
            let css = try ThemeCSSEmitter.emit(theme)
            let reset = "[data-theme-name=\"\(id)\"] .dt-button:not([disabled]):not([aria-disabled=\"true\"]):hover,\n"
                + "[data-theme-name=\"\(id)\"] .dt-button:not([disabled]):not([aria-disabled=\"true\"]):active {\n  outline: 0;\n}"
            #expect(css.contains(reset), "\(id)")
        }
        #expect(!(try ThemeCSSEmitter.emit(.swiss)).contains(":not([disabled]):not([aria-disabled=\"true\"]):hover"))
    }

    @Test("a disabled skin control is drawn by its recipe alone: no half-opacity on top, and aria-disabled counts as disabled")
    func disabledIsNotDimmedTwice() throws {
        for id in ["system7", "platinum", "openstep"] {
            let theme = try #require(Theme.named(id), Comment(rawValue: id))
            let css = try ThemeCSSEmitter.emit(theme)
            let rule = try lastRule(css, "[data-theme-name=\"\(id)\"] .dt-button:disabled")
            #expect(rule.contains("opacity: 1;"), "\(id)")
            #expect(css.contains("[data-theme-name=\"\(id)\"] .dt-button[aria-disabled=\"true\"],\n[data-theme-name=\"\(id)\"] .dt-button:disabled {"), "\(id)")
        }
    }

    @Test("a skin's focus ring replaces the components stylesheet's outline instead of adding to it")
    func focusReplacesOutline() throws {
        for id in ["system7", "platinum", "openstep"] {
            let theme = try #require(Theme.named(id), Comment(rawValue: id))
            let rule = try lastRule(try ThemeCSSEmitter.emit(theme), "[data-theme-name=\"\(id)\"] .dt-button:focus-visible")
            #expect(rule.contains("outline: 0;"), "\(id)")
        }
    }

    // MARK: pressed, measured on a live Mac OS 8.0 (Infinite Mac)

    @Test("Platinum's pressed button, held on a live Mac OS 8.0: black, #666666 and #777777 inside the top and left, #888888 fill, #999999 and #AAAAAA inside the bottom and right, white text")
    func platinumPressed() throws {
        let surfaces = try #require(Theme.platinum.surfaces)
        let step = { (name: String) in EdgeStep(literal: ColourReference(source: name), 1) }
        let inner = (top: [step("ink"), step("gray66"), step("muted")], bottom: [step("ink"), step("gray99"), step("shade")])
        let button = try #require(surfaces.recipes[.button]?[.active])
        #expect(button.layers == [.fill(ref("gray88"))])
        #expect(button.ink == ref("surface"))
        #expect(button.edges?.top == inner.top && button.edges?.leading == inner.top)
        #expect(button.edges?.bottom == inner.bottom && button.edges?.trailing == inner.bottom)
        // the default button's ring is unchanged; only what is inside it is pressed
        let ring = try #require(surfaces.recipes[.buttonDefault]?[.rest]?.edges)
        let ringTop = Array(ring.top.prefix(3)), ringBottom = Array(ring.bottom.prefix(3))
        let ringed = try #require(surfaces.recipes[.buttonDefault]?[.active])
        #expect(ringed.edges?.top == ringTop + inner.top && ringed.edges?.bottom == ringBottom + inner.bottom)
        #expect(ringed.layers == [.fill(ref("gray88"))] && ringed.ink == ref("surface"))
    }

    @Test("Platinum's highlighted menu title is the lavender highlight with white text, as the live Mac OS 8.0 draws it, not black")
    func platinumMenuHighlight() throws {
        let css = try ThemeCSSEmitter.emit(.platinum)
        #expect(css.contains("--extra-highlight: #5454B3;"))
        let rule = try lastRule(css, "[data-theme-name=\"platinum\"] .dt-menubar__item[aria-selected=\"true\"]")
        #expect(rule.contains("background-color: var(--extra-highlight);") && rule.contains("color: var(--surface);"))
    }
}
