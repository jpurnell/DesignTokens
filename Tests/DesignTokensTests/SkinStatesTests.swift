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

    @Test("Platinum's disabled button is a flat face with a one-pixel dimmed outline (#A5A5A5 live) and dimmed text, no bevel")
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

    @Test("Platinum's inactive scroll bar: flat #F3F3F3 with #777777 outlines, arrows without a bevel and with #A5A5A5 triangles")
    func platinumInactiveScrollBar() throws {
        let surfaces = try #require(Theme.platinum.surfaces)
        let track = try #require(surfaces.recipes[.scrollTrack]?[.disabled])
        #expect(track.layers == [.fill(ref("grayEE"))])
        #expect(track.edges?.top == [EdgeStep(literal: ref("gray77"), 1)] && track.edges?.bottom == [EdgeStep(literal: ref("gray77"), 1)])
        for role in [SurfaceRole.scrollArrowStart, .scrollArrowEnd] {
            let recipe = try #require(surfaces.recipes[role]?[.disabled], Comment(rawValue: "\(role)"))
            guard case .pattern(let tile)? = recipe.layers.last else { throw SurfaceError.cellSize(0) }
            #expect(tile.width == 16 && tile.height == 16)
            // the triangle is 1+2+3+4+4+3+2+1 = 20 pixels, and nothing else is the dimmed grey or white
            #expect(tile.cells.filter { $0 == ref("gray88") }.count == 20)
            #expect(!tile.cells.contains(ref("surface")))
            // the side facing the track (the right column of the start arrow, the left of the end arrow) is #555555, every other edge black, and the inner side's two end pixels too
            let towardTrack = role == .scrollArrowStart ? 15 : 0
            let black = ref("ink"), dark = ref("gray77")
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

    @Test("Platinum's pressed button, held on a live Mac OS 8.0: black, #666666 and #777777 inside the top and left, #878787 fill, #969696 and #A5A5A5 inside the bottom and right, white text")
    func platinumPressed() throws {
        let surfaces = try #require(Theme.platinum.surfaces)
        let step = { (name: String) in EdgeStep(literal: ColourReference(source: name), 1) }
        let inner = (top: [step("ink"), step("gray66"), step("gray77")], bottom: [step("ink"), step("gray96"), step("gray88")])
        let button = try #require(surfaces.recipes[.button]?[.active])
        #expect(button.layers == [.fill(ref("gray87"))])
        #expect(button.ink == ref("surface"))
        #expect(button.edges?.top == inner.top && button.edges?.leading == inner.top)
        #expect(button.edges?.bottom == inner.bottom && button.edges?.trailing == inner.bottom)
        // the default button's ring is unchanged; only what is inside it is pressed
        let ring = try #require(surfaces.recipes[.buttonDefault]?[.rest]?.edges)
        let ringTop = Array(ring.top.prefix(3)), ringBottom = Array(ring.bottom.prefix(3))
        let ringed = try #require(surfaces.recipes[.buttonDefault]?[.active])
        #expect(ringed.edges?.top == ringTop + inner.top && ringed.edges?.bottom == ringBottom + inner.bottom)
        #expect(ringed.layers == [.fill(ref("gray87"))] && ringed.ink == ref("surface"))
    }

    @Test("Platinum's highlighted menu title is the lavender highlight with white text, as the live Mac OS 8.0 draws it, not black")
    func platinumMenuHighlight() throws {
        let css = try ThemeCSSEmitter.emit(.platinum)
        #expect(css.contains("--extra-highlight: #5454B3;"))
        let rule = try lastRule(css, "[data-theme-name=\"platinum\"] .dt-menubar__item[aria-selected=\"true\"]")
        #expect(rule.contains("background-color: var(--extra-highlight);") && rule.contains("color: var(--surface);"))
    }

    // MARK: an inactive window, measured on a live Mac OS 8.0 (Infinite Mac)

    @Test("an inactive Platinum window is flat #E7E7E7 with #777777 outlines, no stripes or boxes, and #878787 title text")
    func platinumInactiveWindow() throws {
        let surfaces = try #require(Theme.platinum.surfaces)
        let grey = EdgeStep(literal: ref("gray77"), 1)
        let bar = try #require(surfaces.recipes[.titleBar]?[.disabled])
        #expect(bar.layers == [.fill(ref("background"))])
        #expect(bar.ink == ref("gray87"))
        #expect(bar.edges?.top == [grey] && bar.edges?.leading == [grey] && bar.edges?.bottom == [grey])
        #expect(bar.edges?.trailing == [grey, grey])
        let frame = try #require(surfaces.recipes[.window]?[.disabled])
        let flat = [grey] + Array(repeating: EdgeStep(literal: ref("background"), 1), count: 4)
        let dimShadow = frame.layers.compactMap { layer -> ShadowLayer? in
            if case .shadow(let s) = layer { return s } else { return nil }
        }
        #expect(dimShadow.count == 1 && dimShadow[0].shadow.colour == ref("gray77") && dimShadow[0].shadow.x == 1 && dimShadow[0].shadow.y == 1)
        #expect(frame.edges?.top == [grey] && frame.edges?.leading == flat && frame.edges?.bottom == flat && frame.edges?.trailing == flat)
        // the stripes and the boxes are painted out with the bar's own colour
        let blank = [SurfaceLayer.fill(ref("background")), .pattern(PatternSpec(literal: 1, 1, [ref("background")]))]
        for role in [SurfaceRole.titleStripes, .windowBox, .windowBoxZoom, .windowBoxMinimize] {
            #expect(surfaces.recipes[role]?[.disabled]?.layers == blank, Comment(rawValue: "\(role)"))
        }
    }

    @Test("an active Platinum window frame is the measured five-pixel bevel with a one-pixel shadow, not a dither")
    func platinumWindowFrame() throws {
        let surfaces = try #require(Theme.platinum.surfaces)
        let frame = try #require(surfaces.recipes[.window]?[.rest])
        func steps(_ names: [String]) -> [EdgeStep] { names.map { EdgeStep(literal: ref($0), 1) } }
        // live Mac OS 8.0: outside in, black, white, two #DADADA, #B3B3B3 on the leading side; the bottom and trailing sides reverse the light
        #expect(frame.edges?.leading == steps(["ink", "surface", "bar", "bar", "gray99"]))
        #expect(frame.edges?.bottom == steps(["ink", "gray99", "bar", "bar", "surface"]))
        #expect(frame.edges?.trailing == steps(["ink", "gray99", "bar", "bar", "surface"]))
        #expect(frame.edges?.top == steps(["ink", "surface"]))
        #expect(frame.layers.contains(.fill(ref("bar"))))
        let shadow = frame.layers.compactMap { layer -> ShadowLayer? in
            if case .shadow(let s) = layer { return s } else { return nil }
        }
        #expect(shadow.count == 1 && shadow[0].shadow.x == 1 && shadow[0].shadow.y == 1 && shadow[0].shadow.colour == ref("ink"))
    }

    @Test("an inactive window is a title bar marked aria-disabled; its stripes and boxes follow it")
    func inactiveWindowCSS() throws {
        let css = try ThemeCSSEmitter.emit(.platinum)
        let bar = try lastRule(css, "[data-theme-name=\"platinum\"] .dt-titlebar:disabled")
        #expect(bar.contains("background-color: var(--background);") && bar.contains("color: var(--extra-gray87);"))
        #expect(css.contains("[data-theme-name=\"platinum\"] .dt-titlebar[aria-disabled=\"true\"],\n"))
        for part in ["stripes", "box", "box--zoom", "box--minimize"] {
            let rule = try lastRule(css, "[data-theme-name=\"platinum\"] .dt-titlebar[aria-disabled=\"true\"] .dt-titlebar__\(part)")
            #expect(rule.contains("background-color: var(--background);"), Comment(rawValue: part))
        }
        for theme in [Theme.system7, .openstep, .swiss] {
            #expect(!(try ThemeCSSEmitter.emit(theme)).contains(".dt-titlebar[aria-disabled"), "\(theme.id)")
        }
    }

    // MARK: pressed scroll bar parts, held on a live Mac OS 8.0 (Infinite Mac)

    private func tile(_ theme: Theme, _ role: SurfaceRole, _ state: ComponentState) throws -> PatternSpec {
        let recipe = try #require(theme.surfaces?.recipes[role]?[state], Comment(rawValue: "\(role) \(state)"))
        guard case .pattern(let spec)? = recipe.layers.last else { throw SurfaceError.cellSize(0) }
        return spec
    }

    @Test("a pressed scroll arrow is 16 x 16: black outline, #777777 down the top and leading, #969696 fill, #B3B3B3 at the bottom and trailing, black triangle")
    func pressedArrow() throws {
        let key: [Character: String] = ["K": "ink", "7": "gray77", "9": "gray96", "B": "gray99"]
        for (role, base, growsRight) in [(SurfaceRole.scrollArrowEnd, 6, true), (.scrollArrowStart, 9, false)] {
            var rows: [[Character]] = []
            for row in 0..<16 {
                switch row {
                case 0, 15: rows.append(Array(repeating: "K", count: 16))
                case 1: rows.append(["K"] + Array(repeating: "7", count: 13) + ["9", "K"])
                case 14: rows.append(["K", "9"] + Array(repeating: "B", count: 13) + ["K"])
                default: rows.append(["K", "7"] + Array(repeating: "9", count: 12) + ["B", "K"])
                }
            }
            let widths = [1, 2, 3, 4, 4, 3, 2, 1]
            for (index, width) in widths.enumerated() {
                let columns = growsRight ? Array(base..<base + width) : Array((base - width + 1)...base)
                for column in columns { rows[4 + index][column] = "K" }
            }
            let expected = rows.flatMap { $0 }.map { ColourReference(source: key[$0] ?? "?") }
            let pressed = try tile(.platinum, role, .active)
            #expect(pressed.width == 16 && pressed.height == 16, Comment(rawValue: "\(role)"))
            #expect(pressed.cells == expected, Comment(rawValue: "\(role)"))
        }
    }

    @Test("a pressed thumb is the same drawing one step darker down the lavender ramp, and its grip with it")
    func pressedThumb() throws {
        let surfaces = try #require(Theme.platinum.surfaces)
        let thumb = try #require(surfaces.recipes[.scrollThumb]?[.active])
        let step = { (name: String) in EdgeStep(literal: ColourReference(source: name), 1) }
        #expect(thumb.layers.first == .fill(ref("lavenderShade")))
        #expect(thumb.edges?.top == [step("ink"), step("lavender")] && thumb.edges?.leading == [step("ink"), step("lavender")])
        #expect(thumb.edges?.bottom == [step("ink"), step("highlight")] && thumb.edges?.trailing == [step("ink"), step("highlight")])
        // the grip's four tones: #F3F3F3 > #DADAFF, #B3B3FF > #8787DA, #DADAFF > #B3B3FF, #5454B3 > #000077
        let rest = try tile(.platinum, .scrollGrip, .rest)
        let pressed = try tile(.platinum, .scrollGrip, .active)
        let shift: [ColourReference: ColourReference] = [ref("grayEE"): ref("selection"), ref("lavender"): ref("lavenderShade"),
                                                         ref("selection"): ref("lavender"), ref("link"): ref("navy")]
        #expect(pressed.width == 8 && pressed.height == 8)
        #expect(pressed.cells == rest.cells.map { shift[$0] ?? $0 })
        #expect(Theme.platinum.palette.extras["navy"]?.light.hex == "#000077")
    }

    @Test("pressed parts are drawn by :active, turned for a vertical bar, and an inactive bar still wins; skins without a measurement write none")
    func pressedScrollCSS() throws {
        let css = try ThemeCSSEmitter.emit(.platinum)
        let scope = "[data-theme-name=\"platinum\"]"
        for part in ["thumb:active", "thumb:active .dt-scrollbar__grip", "arrow--start:active", "arrow--end:active"] {
            let rule = try lastRule(css, "\(scope) .dt-scrollbar__\(part)")
            #expect(rule.contains { $0.hasPrefix("background") }, Comment(rawValue: part))
            let turned = try lastRule(css, "\(scope) .dt-scrollbar[data-orientation=\"vertical\"] .dt-scrollbar__\(part)")
            #expect(turned.contains { $0.hasPrefix("background") }, Comment(rawValue: part))
        }
        let pressedAt = try #require(css.range(of: "\(scope) .dt-scrollbar__arrow--end:active {"))
        let inactiveAt = try #require(css.range(of: "\(scope) .dt-scrollbar[aria-disabled=\"true\"] .dt-scrollbar__arrow--end {"))
        #expect(pressedAt.lowerBound < inactiveAt.lowerBound)
        for theme in [Theme.system7, .openstep, .swiss] {
            #expect(!(try ThemeCSSEmitter.emit(theme)).contains(".dt-scrollbar__thumb:active"), "\(theme.id)")
        }
    }
}
