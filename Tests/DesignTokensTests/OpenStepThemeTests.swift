import Foundation
import Testing
@testable import DesignTokens

/// Expected values are pixels read from OPENSTEP 4.2 captures (project/docs/technical/SkinMeasurements.md, OPENSTEP section): the Open
/// panel's Cancel button and Name field, the Font Panel's title bar and its miniaturize and close buttons.
@Suite("OPENSTEP oracle measurements")
struct OpenStepThemeTests {
    private func hex(_ reference: ColourReference) throws -> String {
        let role = ColorRole(rawValue: reference.source).map { Theme.openstep.palette[$0] }
        let adaptive = try #require(role ?? Theme.openstep.palette.extras[reference.source])
        return adaptive.light.hex
    }

    private func edges(_ role: SurfaceRole, _ state: ComponentState = .rest) throws -> (top: [String], leading: [String], bottom: [String], trailing: [String]) {
        let recipe = try #require(Theme.openstep.surfaces?.recipe(for: role, in: state))
        let edges = try #require(recipe.edges)
        return (try edges.top.map { try hex($0.colour) }, try edges.leading.map { try hex($0.colour) },
                try edges.bottom.map { try hex($0.colour) }, try edges.trailing.map { try hex($0.colour) })
    }

    private func tile(_ role: SurfaceRole) throws -> PatternSpec {
        let recipe = try #require(Theme.openstep.surfaces?.recipe(for: role, in: .rest))
        guard case .pattern(let spec)? = recipe.layers.last else {
            Issue.record("\(role) has no pattern layer")
            throw SurfaceError.cellSize(0)
        }
        return spec
    }

    @Test("a button: one white pixel at the top and left; at the bottom and right #000000 outermost then #555555 (Cancel's row, left to right: FFFFFF x1 … 555555 x1, 000000 x1)")
    func buttonBevel() throws {
        let sides = try edges(.button)
        #expect(sides.top == ["#FFFFFF"])
        #expect(sides.leading == ["#FFFFFF"])
        #expect(sides.bottom == ["#000000", "#555555"])
        #expect(sides.trailing == ["#000000", "#555555"])
        let recipe = try #require(Theme.openstep.surfaces?.recipe(for: .button, in: .rest))
        #expect(recipe.layers == [.fill(ColourReference(source: "background"))])
        #expect(try hex(ColourReference(source: "background")) == "#AAAAAA")
    }

    @Test("at the top-right and bottom-left corners the dark sides own the pixel: the capture's four corners are FFFFFF 000000 / 000000 000000")
    func cornerOwnership() throws {
        let recipe = try #require(Theme.openstep.surfaces?.recipe(for: .button, in: .rest))
        #expect(recipe.edges?.stacking == .bottomTrailingFirst)
        let css = try ThemeCSSEmitter.emit(.openstep)
        let shadow = "box-shadow: inset 0 -1px 0 0 var(--ink), inset -1px 0 0 0 var(--ink), inset 0 1px 0 0 var(--surface), inset 1px 0 0 0 var(--surface), "
            + "inset 0 -2px 0 0 var(--muted), inset -2px 0 0 0 var(--muted)"
        #expect(css.contains(shadow))
    }

    @Test("a recipe that does not say keeps the top and leading sides first")
    func defaultStacking() throws {
        let edges = Edges(top: [EdgeStep(literal: ColourReference(source: "ink"), 1)], leading: [EdgeStep(literal: ColourReference(source: "ink"), 1)],
                          bottom: [EdgeStep(literal: ColourReference(source: "ink"), 1)], trailing: [EdgeStep(literal: ColourReference(source: "ink"), 1)])
        #expect(edges.stacking == nil)
        let recipe = SurfaceRecipe(layers: [.fill(ColourReference(source: "background"))], edges: edges, radius: .uniform(0), backdropBlur: nil,
                                   ink: ColourReference(source: "ink"), scale: .integer)
        let lines = SurfaceCSS.declarations(for: recipe, resolve: { _ in "#000000" })
        let shadow = try #require(lines.first { $0.hasPrefix("box-shadow:") })
        #expect(shadow == "box-shadow: inset 0 1px 0 0 #000000, inset 1px 0 0 0 #000000, inset 0 -1px 0 0 #000000, inset -1px 0 0 0 #000000")
    }

    @Test("the Cancel button is 27 px high (rows 297 to 323) with square corners")
    func buttonSize() throws {
        #expect(Theme.openstep.structure.layout.controlHeight == 27)
        let recipe = try #require(Theme.openstep.surfaces?.recipe(for: .button, in: .rest))
        #expect(recipe.radius == .uniform(0))
    }

    @Test("a default button has no ring: its box is the ordinary button's")
    func noRing() {
        #expect(Theme.openstep.surfaces?.defaultRingExtra == 0)
    }

    @Test("the Name field is white, sunken: #555555 twice at the top and left; #FFFFFF then #AAAAAA at the bottom and right, outside in")
    func field() throws {
        let sides = try edges(.field)
        #expect(sides.top == ["#555555", "#555555"])
        #expect(sides.leading == sides.top)
        #expect(sides.bottom == ["#FFFFFF", "#AAAAAA"])
        #expect(sides.trailing == sides.bottom)
        let recipe = try #require(Theme.openstep.surfaces?.recipe(for: .field, in: .rest))
        #expect(recipe.layers == [.fill(ColourReference(source: "surface"))])
    }

    @Test("the desktop is #555577")
    func desktop() throws {
        let recipe = try #require(Theme.openstep.surfaces?.recipe(for: .desktop, in: .rest))
        #expect(recipe.layers == [.fill(ColourReference(source: "desktop"))])
        #expect(try hex(ColourReference(source: "desktop")) == "#555577")
    }

    @Test("the title bar is black, framed black then #AAAAAA at the top and left, black then #555555 at the right and bottom, 23 rows")
    func titleBar() throws {
        let sides = try edges(.titleBar)
        #expect(sides.top == ["#000000", "#AAAAAA"])
        #expect(sides.leading == ["#000000", "#AAAAAA"])
        #expect(sides.bottom == ["#000000", "#555555"])
        #expect(sides.trailing == ["#000000", "#555555"])
        let bar = try #require(Theme.openstep.surfaces?.recipe(for: .titleBar, in: .rest))
        #expect(bar.layers == [.fill(ColourReference(source: "ink"))])
        #expect(try hex(bar.ink) == "#FFFFFF")
        #expect(Theme.openstep.windowControls?.titleBar?.height == 23)
    }

    @Test("miniaturize at the left, close at the right: the reverse of the Macintosh")
    func placement() throws {
        let controls = try #require(Theme.openstep.windowControls)
        #expect(controls.leading == [.minimize])
        #expect(controls.trailing == [.close])
        #expect(controls.gtkDecorationLayout == "minimize:close")
    }

    @Test("the miniaturize button: 15 x 15 from the Font Panel, a raised bevel (white top and left, #555555 bottom and right) around a black window glyph")
    func miniaturize() throws {
        let spec = try tile(.windowBoxMinimize)
        #expect(spec.width == 15 && spec.height == 15)
        func cell(_ x: Int, _ y: Int) throws -> String { try hex(spec.cells[y * 15 + x]) }
        #expect(try (0..<14).map { try cell($0, 0) } == Array(repeating: "#FFFFFF", count: 14))
        #expect(try (0..<14).map { try cell(0, $0) } == Array(repeating: "#FFFFFF", count: 14))
        #expect(try (1..<14).map { try cell($0, 13) } == Array(repeating: "#555555", count: 13))
        #expect(try (1..<14).map { try cell(13, $0) } == Array(repeating: "#555555", count: 13))
        // the glyph: a black frame 10 px square (x 2 to 11, y 2 to 11) with a #AAAAAA window at x 3 to 10, y 5 to 10
        #expect(try (2..<12).map { try cell($0, 2) } == Array(repeating: "#000000", count: 10))
        #expect(try (3..<11).map { try cell($0, 7) } == Array(repeating: "#AAAAAA", count: 8))
        #expect(try cell(2, 7) == "#000000" && cell(11, 7) == "#000000")
        #expect(try (2..<12).map { try cell($0, 11) } == Array(repeating: "#000000", count: 10))
    }

    @Test("the close button: 14 x 14, the same bevel around a black X drawn with #555555 anti-aliasing, symmetric left to right")
    func close() throws {
        let spec = try tile(.windowBox)
        #expect(spec.width == 14 && spec.height == 14)
        func cell(_ x: Int, _ y: Int) throws -> String { try hex(spec.cells[y * 14 + x]) }
        #expect(try (0..<14).map { try cell($0, 0) } == Array(repeating: "#FFFFFF", count: 14))
        #expect(try (1..<14).map { try cell($0, 13) } == Array(repeating: "#555555", count: 13))
        // the X's diagonals: black at (2,2) and (11,2), crossing at the centre pixels (6,6) (7,6) (6,7) (7,7)
        #expect(try cell(2, 2) == "#000000" && cell(11, 2) == "#000000")
        #expect(try cell(6, 6) == "#000000" && cell(7, 6) == "#000000" && cell(6, 7) == "#000000" && cell(7, 7) == "#000000")
        #expect(try cell(3, 2) == "#555555")
    }
}
