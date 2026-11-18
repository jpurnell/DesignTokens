import Foundation
import Testing
@testable import DesignTokens

/// Expected values are pixels read from Mac OS 8.0 captures (project/docs/technical/SkinMeasurements.md, Platinum), not the theme's own output.
@Suite("Platinum oracle measurements")
struct PlatinumThemeTests {
    private func hex(_ reference: ColourReference) throws -> String {
        let role = ColorRole(rawValue: reference.source).map { Theme.platinum.palette[$0] }
        let adaptive = try #require(role ?? Theme.platinum.palette.extras[reference.source])
        return adaptive.light.hex
    }

    private func sides(_ role: SurfaceRole, _ state: ComponentState = .rest) throws -> (top: [String], leading: [String], bottom: [String], trailing: [String]) {
        let recipe = try #require(Theme.platinum.surfaces?.recipe(for: role, in: state))
        let edges = try #require(recipe.edges)
        return (try edges.top.map { try hex($0.colour) }, try edges.leading.map { try hex($0.colour) },
                try edges.bottom.map { try hex($0.colour) }, try edges.trailing.map { try hex($0.colour) })
    }

    @Test("a button's bevel, outside in: top and left 000000 DDDDDD FFFFFF; bottom and right 000000 777777 AAAAAA (the Cancel button's rows and columns)")
    func buttonBevel() throws {
        let edges = try sides(.button)
        #expect(edges.top == ["#000000", "#DDDDDD", "#FFFFFF"])
        #expect(edges.leading == edges.top)
        #expect(edges.bottom == ["#000000", "#777777", "#AAAAAA"])
        #expect(edges.trailing == edges.bottom)
    }

    @Test("the default button has the ordinary bevel inside a three-pixel frame (the OK button of the colour picker)")
    func defaultRing() throws {
        let edges = try sides(.buttonDefault)
        #expect(edges.top == ["#000000", "#DDDDDD", "#AAAAAA", "#000000", "#DDDDDD", "#FFFFFF"])
        #expect(edges.bottom == ["#000000", "#777777", "#AAAAAA", "#000000", "#777777", "#AAAAAA"])
    }

    @Test("a button's body is the #DDDDDD of the window, 20 px high, with a corner that steps in 3 px")
    func buttonBodyAndSize() throws {
        let recipe = try #require(Theme.platinum.surfaces?.recipe(for: .button, in: .rest))
        #expect(recipe.layers == [.fill(ColourReference(source: "background"))])
        #expect(try hex(ColourReference(source: "background")) == "#DDDDDD")
        #expect(recipe.radius == .uniform(3))
        #expect(Theme.platinum.structure.layout.controlHeight == 20)
    }

    @Test("a text field is a 1 px black outline on white; the progress bar is #6666CC and a selected row #CCCCFF")
    func fieldAndAccents() throws {
        let field = try sides(.field)
        #expect(field.top == ["#000000"] && field.bottom == ["#000000"] && field.leading == ["#000000"] && field.trailing == ["#000000"])
        #expect(try hex(ColourReference(source: "surface")) == "#FFFFFF")
        #expect(try hex(ColourReference(source: "accent")) == "#6666CC")
        #expect(try hex(ColourReference(source: "selection")) == "#CCCCFF")
        #expect(try hex(ColourReference(source: "desktop")) == "#9C9CCE")
    }

    @Test("the sequential ramp is the progress bar's rows, light to dark")
    func ramp() {
        #expect(Theme.platinum.palette.sequential.light.map(\.hex) == ["#CCCCFF", "#9999FF", "#6666CC", "#333399", "#000055"])
    }
}
