import Foundation
import Testing
@testable import DesignTokens

/// Scroll bars of Platinum and OPENSTEP, measured from a live horizontal bar of Mac OS 8.0 and a vertical scroller of OPENSTEP 4.2.
@Suite("Scroll bars")
struct ScrollBarTests {
    private func ref(_ name: String) -> ColourReference { ColourReference(source: name) }

    private func tile(_ theme: Theme, _ role: SurfaceRole) throws -> PatternSpec {
        let recipe = try #require(theme.surfaces?.recipes[role]?[.rest], Comment(rawValue: "\(theme.id) \(role)"))
        guard case .pattern(let spec)? = recipe.layers.last else { throw SurfaceError.cellSize(0) }
        return spec
    }

    private func rule(_ css: String, _ selector: String) throws -> String {
        let start = try #require(css.range(of: selector + " {"), Comment(rawValue: selector))
        return String(css[start.upperBound...].prefix(while: { $0 != "}" }))
    }

    /// The last rule for a selector: the drawing, which follows the layout rule of the same selector.
    private func lastRule(_ css: String, _ selector: String) throws -> String {
        let start = try #require(css.range(of: selector + " {", options: .backwards), Comment(rawValue: selector))
        return String(css[start.upperBound...].prefix(while: { $0 != "}" }))
    }

    @Test("transposing a tile turns rows into columns, and twice is the identity")
    func transpose() {
        let a = ref("a"), b = ref("b"), c = ref("c"), d = ref("d"), e = ref("e"), f = ref("f")
        let spec = PatternSpec(literal: 3, 2, [a, b, c, d, e, f])
        #expect(spec.transposed.width == 2 && spec.transposed.height == 3)
        #expect(spec.transposed.cells == [a, d, b, e, c, f])
        #expect(spec.transposed.transposed == spec)
    }

    @Test("transposing edges swaps top with leading and bottom with trailing")
    func edges() {
        let step = { (n: String) in EdgeStep(literal: ColourReference(source: n), 1) }
        let e = Edges(top: [step("t")], leading: [step("l")], bottom: [step("b")], trailing: [step("r")])
        #expect(e.transposed.top == e.leading && e.transposed.leading == e.top)
        #expect(e.transposed.bottom == e.trailing && e.transposed.trailing == e.bottom)
    }

    @Test("Platinum's arrows are 16 x 16 tiles with black outline, a white top-left bevel and a 4 x 8 black triangle")
    func platinumArrow() throws {
        let end = try tile(.platinum, .scrollArrowEnd)
        #expect(end.width == 16 && end.height == 16)
        let black = ref("ink")
        func at(_ x: Int, _ y: Int) -> ColourReference { end.cells[y * 16 + x] }
        #expect((0..<16).allSatisfy { at($0, 0) == black && at($0, 15) == black && at(0, $0) == black && at(15, $0) == black })
        #expect(at(1, 5) == ref("surface") && at(14, 5) == ref("grayBB"))
        // the right-pointing triangle: widths 1 2 3 4 4 3 2 1 from column 6 on rows 4 to 11
        let widths = (4..<12).map { y in (2..<14).filter { at($0, y) == black }.count }
        #expect(widths == [1, 2, 3, 4, 4, 3, 2, 1])
        let start = try tile(.platinum, .scrollArrowStart)
        #expect((4..<12).map { y in (2..<14).filter { start.cells[y * 16 + $0] == black }.count } == [1, 2, 3, 4, 4, 3, 2, 1])
    }

    @Test("Platinum's grip is eight by eight: grooves of #333399 beside #CCCCFF")
    func platinumGrip() throws {
        let grip = try tile(.platinum, .scrollGrip)
        #expect(grip.width == 8 && grip.height == 8)
        #expect(grip.cells[2 * 8 + 0] == ref("selection") && grip.cells[2 * 8 + 1] == ref("link"))
    }

    @Test("Platinum lays out a 16 px bar with an arrow at each end, and a vertical bar turns the tiles")
    func platinumCSS() throws {
        let css = try ThemeCSSEmitter.emit(.platinum)
        #expect(try rule(css, ".dt-scrollbar").contains("block-size: 16px"))
        #expect(!css.contains("order: 2;\n}\n.dt-scrollbar__arrow--end"))
        let vertical = try rule(css, "[data-orientation=\"vertical\"] .dt-scrollbar__arrow--start")
        #expect(vertical.contains("inline-size: 16px") && vertical.contains("block-size: 16px"))
        #expect(try rule(css, ".dt-scrollbar__grip").contains("inline-size: 8px"))
    }

    @Test("a vertical track has its stripes on the leading and trailing sides")
    func verticalTrack() throws {
        let css = try ThemeCSSEmitter.emit(.platinum)
        let horizontal = try lastRule(css, "[data-theme-name=\"platinum\"] .dt-scrollbar__track")
        let vertical = try lastRule(css, ".dt-scrollbar[data-orientation=\"vertical\"] .dt-scrollbar__track")
        #expect(horizontal.contains("inset 0 1px 0 0"), "the first stripe is a row at the top")
        #expect(vertical.contains("inset 1px 0 0 0"), "the first stripe is a column at the leading side")
    }

    @Test("OPENSTEP puts the arrows together after the track, start first, 20 px thick with a 2 px inset")
    func openstepCSS() throws {
        let css = try ThemeCSSEmitter.emit(.openstep)
        let bar = try rule(css, ".dt-scrollbar")
        #expect(bar.contains("block-size: 20px") && bar.contains("padding: 2px") && bar.contains("gap: 1px"))
        #expect(try rule(css, ".dt-scrollbar__track").contains("flex: 1 1 0"))
        #expect(css.contains(".dt-scrollbar__arrow--start {\n  order: 2;"))
        #expect(css.contains(".dt-scrollbar__arrow--end {\n  order: 3;"))
    }

    @Test("OPENSTEP's arrow, turned for a horizontal bar, is a 16 px tile whose triangle points left at the start")
    func openstepArrow() throws {
        let start = try tile(.openstep, .scrollArrowStart)
        #expect(start.width == 16 && start.height == 16)
        let black = ref("ink")
        // up arrow, widths by row 3...11 of the vertical tile: 1 3 3 5 5 7 7 9 9 black or edge pixels; turned, the same count by column
        let perColumn = (3..<12).map { x in (1..<15).filter { start.cells[$0 * 16 + x] == black }.count }
        #expect(perColumn == [0, 1, 1, 3, 3, 5, 5, 7, 7])
    }

    @Test("a theme without scroll bars writes none, and the metrics survive the JSON round trip")
    func absentAndRoundTrip() throws {
        #expect(Theme.swiss.scrollBar == nil)
        #expect(try !ThemeCSSEmitter.emit(.swiss).contains("dt-scrollbar"))
        for theme in [Theme.platinum, .openstep] {
            let decoded = try ThemeCodec.decode(try ThemeCodec.encode(theme))
            #expect(decoded.scrollBar == theme.scrollBar, "\(theme.id)")
            #expect(decoded.surfaces?.recipes[.scrollArrowEnd] == theme.surfaces?.recipes[.scrollArrowEnd], "\(theme.id)")
        }
    }

    @Test("Platinum's track starts again past the thumb: two outer shadows, #969696 then #A5A5A5, shrunk by a pixel")
    func platinumThumbShadow() throws {
        let recipe = try #require(Theme.platinum.surfaces?.recipes[.scrollThumb]?[.rest])
        let shadows = recipe.layers.compactMap { layer -> ShadowLayer? in if case .shadow(let s) = layer { return s } else { return nil } }
        #expect(shadows.map(\.shadow.colour.source) == ["gray96", "gray88"])
        #expect(shadows.map(\.shadow.x) == [2, 3] && shadows.allSatisfy { $0.spread == -1 && !$0.inset })
        // turned for a vertical bar the offsets are vertical
        #expect(recipe.transposed.layers.compactMap { layer -> Double? in if case .shadow(let s) = layer { return s.shadow.y } else { return nil } } == [2, 3])
    }

    @Test("OPENSTEP's track dither starts with #555555, as on the capture's first track row")
    func openstepDither() throws {
        let recipe = try #require(Theme.openstep.surfaces?.recipes[.scrollTrack]?[.rest])
        guard case .pattern(let spec)? = recipe.layers.last else { Issue.record("no pattern"); return }
        #expect(spec.cells == [ref("muted"), ref("background"), ref("background"), ref("muted")])
    }
}
