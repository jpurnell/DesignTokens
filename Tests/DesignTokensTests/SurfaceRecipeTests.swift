import Foundation
import Testing
@testable import DesignTokens

/// Expected pixels in this file come from `project/docs/technical/SkinMeasurements.md` (read from period screenshots), not from the
/// emitter's own output: a small rasteriser paints the emitted `box-shadow` list the way CSS defines it and the result is compared with
/// the measured rows.
@Suite("Surface recipes")
struct SurfaceRecipeTests {
    private func ref(_ name: String) -> ColourReference { ColourReference(source: name) }
    /// Test colours are literal hex strings, so the resolver is the identity on `source`.
    private let resolve: (ColourReference) -> String = { $0.source }

    // MARK: Validation

    @Test("an edge step must be at least one logical pixel wide")
    func edgeStepWidth() throws {
        #expect(throws: SurfaceError.self) { try EdgeStep(colour: ref("#000000"), width: 0) }
        #expect(throws: SurfaceError.self) { try EdgeStep(colour: ref("#000000"), width: -1) }
        #expect(throws: SurfaceError.self) { try EdgeStep(colour: ref("#000000"), width: .nan) }
        #expect(try EdgeStep(colour: ref("#000000"), width: 1).width == 1)
    }

    @Test("a pattern needs width x height cells, and a cell size of 1 to 16")
    func patternShape() throws {
        let black = ref("#000000"), white = ref("#FFFFFF")
        #expect(throws: SurfaceError.cellCount(expected: 4, got: 3)) { try PatternSpec(width: 2, height: 2, cells: [black, white, white]) }
        #expect(throws: SurfaceError.cellSize(0)) { try PatternSpec(width: 0, height: 2, cells: []) }
        #expect(throws: SurfaceError.cellSize(17)) { try PatternSpec(width: 17, height: 1, cells: Array(repeating: black, count: 17)) }
        #expect(try PatternSpec(width: 2, height: 2, cells: [black, white, white, black]).cells.count == 4)
    }

    @Test("a gradient needs two stops in non-decreasing order, and equal positions are allowed (a hard step)")
    func gradientStops() throws {
        let a = ref("#AAAAAA"), b = ref("#BBBBBB")
        #expect(throws: SurfaceError.stopCount(1)) { try GradientSpec(angleDegrees: 180, stops: [GradientStop(colour: a, position: 0)]) }
        #expect(throws: SurfaceError.stopOrder) {
            try GradientSpec(angleDegrees: 180, stops: [GradientStop(colour: a, position: 0.6), GradientStop(colour: b, position: 0.4)])
        }
        #expect(throws: SurfaceError.stopPosition(1.5)) {
            try GradientSpec(angleDegrees: 180, stops: [GradientStop(colour: a, position: 0), GradientStop(colour: b, position: 1.5)])
        }
        #expect(throws: SurfaceError.self) {
            try GradientSpec(angleDegrees: .nan, stops: [GradientStop(colour: a, position: 0), GradientStop(colour: b, position: 1)])
        }
        let hard = try GradientSpec(angleDegrees: 180, stops: [
            GradientStop(colour: a, position: 0), GradientStop(colour: a, position: 0.5),
            GradientStop(colour: b, position: 0.5), GradientStop(colour: b, position: 1)])
        #expect(hard.stops.count == 4)
    }

    // MARK: Edges, rasterised

    /// A 20 x 20 button painted from `recipe`: its `box-shadow` list, topmost first, and the fill, as the CSS spec defines them.
    private func raster(_ recipe: SurfaceRecipe, size: Int = 20) -> [[String]] {
        let declarations = SurfaceCSS.declarations(for: recipe, resolve: resolve)
        let fill = declarations.first { $0.hasPrefix("background-color: ") }.map { String($0.dropFirst("background-color: ".count)) } ?? "?"
        let shadowLine = declarations.first { $0.hasPrefix("box-shadow: ") }.map { String($0.dropFirst("box-shadow: ".count)) } ?? ""
        let shadows = shadowLine.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        var grid = Array(repeating: Array(repeating: fill, count: size), count: size)
        for row in 0..<size {
            for col in 0..<size {
                for shadow in shadows {
                    // "inset X Y 0 0 COLOUR": painted where the pixel is outside the box shifted by (X, Y).
                    let parts = shadow.split(separator: " ").map(String.init)
                    guard parts.count == 6, parts[0] == "inset",
                          let x = Int(parts[1].replacingOccurrences(of: "px", with: "")),
                          let y = Int(parts[2].replacingOccurrences(of: "px", with: "")) else { continue }
                    if col < x || col >= x + size || row < y || row >= y + size { grid[row][col] = parts[5]; break }
                }
            }
        }
        return grid
    }

    private func edge(_ steps: [(String, Double)]) throws -> [EdgeStep] {
        try steps.map { try EdgeStep(colour: ref($0.0), width: $0.1) }
    }

    /// Platinum, Mac OS 8: measured top and left `000000, DDDDDD, FFFFFF`; bottom and right, outside in, `000000, 777777, AAAAAA`; body `DDDDDD`.
    private func platinumButton() throws -> SurfaceRecipe {
        let light = try edge([("#000000", 1), ("#DDDDDD", 1), ("#FFFFFF", 1)])
        let dark = try edge([("#000000", 1), ("#777777", 1), ("#AAAAAA", 1)])
        return SurfaceRecipe(layers: [.fill(ref("#DDDDDD"))], edges: Edges(top: light, leading: light, bottom: dark, trailing: dark),
                             radius: .uniform(0), backdropBlur: nil, ink: ref("#000000"), scale: .integer)
    }

    @Test("a Platinum button's edges reproduce the measured pixel rows and columns")
    func platinumRows() throws {
        let grid = raster(try platinumButton())
        // Measured vertically through Cancel (SkinMeasurements.md): 000000, DDDDDD, FFFFFF, DDDDDD x14, AAAAAA, 777777, 000000.
        let column = grid.map { $0[10] }
        #expect(column == ["#000000", "#DDDDDD", "#FFFFFF"] + Array(repeating: "#DDDDDD", count: 14) + ["#AAAAAA", "#777777", "#000000"])
        // Measured horizontally: the same sequence.
        #expect(grid[10] == column)
    }

    @Test("an OPENSTEP button is one light pixel top and left, two dark pixels bottom and right")
    func nextRows() throws {
        let light = try edge([("#FFFFFF", 1)]), dark = try edge([("#000000", 1), ("#555555", 1)])
        let recipe = SurfaceRecipe(layers: [.fill(ref("#AAAAAA"))], edges: Edges(top: light, leading: light, bottom: dark, trailing: dark),
                                   radius: .uniform(0), backdropBlur: nil, ink: ref("#000000"), scale: .integer)
        let column = raster(recipe).map { $0[10] }
        // Measured: FFFFFF x1, body AAAAAA, 555555 x1, 000000 x1.
        #expect(column == ["#FFFFFF"] + Array(repeating: "#AAAAAA", count: 17) + ["#555555", "#000000"])
    }

    @Test("a System 7 button is a one-pixel black outline on white, and nothing else")
    func systemSevenRows() throws {
        let outline = try edge([("#000000", 1)])
        let recipe = SurfaceRecipe(layers: [.fill(ref("#FFFFFF"))], edges: Edges(top: outline, leading: outline, bottom: outline, trailing: outline),
                                   radius: .uniform(4), backdropBlur: nil, ink: ref("#000000"), scale: .integer)
        let column = raster(recipe).map { $0[10] }
        #expect(column == ["#000000"] + Array(repeating: "#FFFFFF", count: 18) + ["#000000"])
        #expect(Set(raster(recipe).flatMap { $0 }) == ["#000000", "#FFFFFF"], "1-bit: only black and white appear anywhere")
    }

    // MARK: Other CSS

    @Test("a hard-stop gradient keeps both stops at the shared position")
    func hardStopCSS() throws {
        let gradient = try GradientSpec(angleDegrees: 180, stops: [
            GradientStop(colour: ref("#77A3DE"), position: 0), GradientStop(colour: ref("#84B4E9"), position: 0.5),
            GradientStop(colour: ref("#4A91E3"), position: 0.5), GradientStop(colour: ref("#9AE0FF"), position: 1)])
        #expect(SurfaceCSS.gradient(gradient, resolve: resolve)
                == "linear-gradient(180deg, #77A3DE 0%, #84B4E9 50%, #4A91E3 50%, #9AE0FF 100%)")
    }

    @Test("layers are listed top first in CSS, so a recipe's bottom-to-top order is reversed")
    func layerOrder() throws {
        let gradient = try GradientSpec(angleDegrees: 90, stops: [GradientStop(colour: ref("#111111"), position: 0), GradientStop(colour: ref("#222222"), position: 1)])
        let recipe = SurfaceRecipe(layers: [.fill(ref("#EEEEEE")), .gradient(gradient)], edges: nil, radius: .capsule, backdropBlur: nil,
                                   ink: ref("#000000"), scale: .free)
        let lines = SurfaceCSS.declarations(for: recipe, resolve: resolve)
        #expect(lines.contains("background-color: #EEEEEE"))
        #expect(lines.contains("background-image: linear-gradient(90deg, #111111 0%, #222222 100%)"))
        #expect(lines.contains("border-radius: 9999px"))
        #expect(lines.contains("color: #000000"))
    }

    @Test("a 2 x 2 checkerboard pattern becomes a crisp inline SVG tile of that size")
    func checkerboardCSS() throws {
        let k = ref("#000000"), w = ref("#FFFFFF")
        let pattern = try PatternSpec(width: 2, height: 2, cells: [k, w, w, k])
        let css = SurfaceCSS.pattern(pattern, resolve: resolve)
        #expect(css.hasPrefix("url(\"data:image/svg+xml,"))
        #expect(css.components(separatedBy: "%3Crect").count - 1 == 4)
        #expect(css.contains("shape-rendering%3D'crispEdges'"))
        let lines = SurfaceCSS.declarations(for: SurfaceRecipe(layers: [.pattern(pattern)], edges: nil, radius: .uniform(0), backdropBlur: nil,
                                                               ink: k, scale: .integer), resolve: resolve)
        #expect(lines.contains("background-size: 2px 2px"))
        #expect(lines.contains("image-rendering: pixelated"))
    }

    @Test("backdrop blur is emitted with its prefixed twin; none when the recipe has no blur")
    func blurCSS() {
        let glass = SurfaceRecipe(layers: [.fill(ref("#DEDEDE"))], edges: nil, radius: .uniform(24), backdropBlur: 7, ink: ref("#000000"), scale: .free)
        let lines = SurfaceCSS.declarations(for: glass, resolve: resolve)
        #expect(lines.contains("backdrop-filter: blur(7px)"))
        #expect(lines.contains("-webkit-backdrop-filter: blur(7px)"))
        let flat = SurfaceRecipe(layers: [.fill(ref("#DEDEDE"))], edges: nil, radius: .uniform(0), backdropBlur: nil, ink: ref("#000000"), scale: .free)
        #expect(!SurfaceCSS.declarations(for: flat, resolve: resolve).contains { $0.contains("backdrop-filter") })
    }

    @Test("an integer-scale recipe refuses a fractional edge width; one that is not snapped accepts it")
    func pixelSnapping() throws {
        let half = try edge([("#000000", 0.5)])
        let edges = Edges(top: half, leading: half, bottom: half, trailing: half)
        let snapped = SurfaceRecipe(layers: [], edges: edges, radius: .uniform(0), backdropBlur: nil, ink: ref("#000000"), scale: .integer)
        #expect(throws: SurfaceError.fractionalWidth(0.5)) { try snapped.validate() }
        var loose = snapped
        loose.scale = .free
        #expect(throws: Never.self) { try loose.validate() }
    }

    @Test("an integer scale policy snaps a requested scale to a whole number of at least 1; a free policy leaves it alone")
    func scalePolicy() {
        #expect(ScalePolicy.free.effectiveScale(for: 1.25).isEqual(to: 1.25))
        #expect(ScalePolicy.integer.effectiveScale(for: 1).isEqual(to: 1))
        #expect(ScalePolicy.integer.effectiveScale(for: 1.25).isEqual(to: 1))
        #expect(ScalePolicy.integer.effectiveScale(for: 1.5).isEqual(to: 2))
        #expect(ScalePolicy.integer.effectiveScale(for: 2.4).isEqual(to: 2))
        #expect(ScalePolicy.integer.effectiveScale(for: 3).isEqual(to: 3))
        #expect(ScalePolicy.integer.effectiveScale(for: 0.5).isEqual(to: 1), "never below 1: a pixel is not drawn smaller than itself")
        #expect(ScalePolicy.integer.effectiveScale(for: .nan).isEqual(to: 1))
        #expect(ScalePolicy.integer.effectiveScale(for: .infinity).isEqual(to: 1))
        #expect(ScalePolicy.free.effectiveScale(for: .nan).isEqual(to: 1))
    }

    @Test("a decoded edge step is validated like a constructed one")
    func decodingValidates() {
        let bad = Data(#"{"colour":{"source":"ink","opacity":1},"width":0}"#.utf8)
        #expect(throws: SurfaceError.width(0)) { try JSONDecoder().decode(EdgeStep.self, from: bad) }
    }

    // MARK: Codable

    @Test("a recipe survives a JSON round trip unchanged")
    func codable() throws {
        let original = try platinumButton()
        let data = try JSONEncoder().encode(original)
        #expect(try JSONDecoder().decode(SurfaceRecipe.self, from: data) == original)
    }
}
