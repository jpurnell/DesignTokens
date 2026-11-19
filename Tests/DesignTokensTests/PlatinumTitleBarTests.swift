import Foundation
import Testing
@testable import DesignTokens

/// Expected pixels are read from the Appearance window of the Mac OS 8.0 desktop capture (rows 106 to 127, columns 229 to 625;
/// project/docs/technical/SkinMeasurements.md, Platinum title bar), not from the theme's output.
@Suite("Platinum title bar measurements")
struct PlatinumTitleBarTests {
    private func hex(_ reference: ColourReference) throws -> String {
        let role = ColorRole(rawValue: reference.source).map { Theme.platinum.palette[$0] }
        let adaptive = try #require(role ?? Theme.platinum.palette.extras[reference.source])
        return adaptive.light.hex
    }

    private func recipe(_ role: SurfaceRole) throws -> SurfaceRecipe {
        try #require(Theme.platinum.surfaces?.recipe(for: role, in: .rest))
    }

    private func pattern(_ role: SurfaceRole) throws -> PatternSpec {
        let layers = try recipe(role).layers
        guard case .pattern(let spec)? = layers.last else {
            Issue.record("\(role) has no pattern layer")
            throw SurfaceError.cellSize(0)
        }
        return spec
    }

    @Test("the bar is #CCCCCC inside black then white at the top and left, black then black then #999999 at the right, #999999 then black at the bottom")
    func bar() throws {
        let bar = try recipe(.titleBar)
        #expect(bar.layers == [.fill(ColourReference(source: "bar"))])
        #expect(try hex(ColourReference(source: "bar")) == "#CCCCCC")
        let edges = try #require(bar.edges)
        #expect(try edges.top.map { try hex($0.colour) } == ["#000000", "#FFFFFF"])
        #expect(try edges.leading.map { try hex($0.colour) } == ["#000000", "#FFFFFF"])
        #expect(try edges.bottom.map { try hex($0.colour) } == ["#000000", "#999999"])
        #expect(try edges.trailing.map { try hex($0.colour) } == ["#000000", "#000000", "#999999"])
    }

    @Test("the stripes alternate #FFFFFF and #777777 down the bar, white first, 12 px high")
    func stripes() throws {
        let tile = try pattern(.titleStripes)
        #expect(tile.width == 1 && tile.height == 2)
        #expect(try tile.cells.map { try hex($0) } == ["#FFFFFF", "#777777"])
        #expect(Theme.platinum.windowControls?.titleBar?.stripeHeight == 12)
    }

    @Test("the close box is 13 x 13: #888888 top and left, #FFFFFF bottom and right, a #222222 frame, a diagonal bevel that darkens to the top left")
    func box() throws {
        let tile = try pattern(.windowBox)
        #expect(tile.width == 13 && tile.height == 13)
        func cell(_ x: Int, _ y: Int) throws -> String { try hex(tile.cells[y * 13 + x]) }
        // row 0 of the capture (y = 110): #888888 x12, then the bar's #CCCCCC
        #expect(try (0..<12).map { try cell($0, 0) } == Array(repeating: "#888888", count: 12))
        #expect(try cell(12, 0) == "#CCCCCC")
        // column 0 (x = 233) is #888888 down to the last row, which is #CCCCCC then white
        #expect(try (0..<12).map { try cell(0, $0) } == Array(repeating: "#888888", count: 12))
        #expect(try cell(0, 12) == "#CCCCCC")
        #expect(try (1..<13).map { try cell($0, 12) } == Array(repeating: "#FFFFFF", count: 12))
        #expect(try (1..<13).map { try cell(12, $0) } == Array(repeating: "#FFFFFF", count: 12))
        // the frame, the one highlight pixel inside it, and the bevel's first and last interior rows
        #expect(try (1..<12).map { try cell($0, 1) } == Array(repeating: "#222222", count: 11))
        #expect(try cell(2, 2) == "#FFFFFF")
        #expect(try (3..<10).map { try cell($0, 3) } == ["#999999", "#999999", "#AAAAAA", "#AAAAAA", "#BBBBBB", "#BBBBBB", "#CCCCCC"])
        #expect(try (3..<10).map { try cell($0, 9) } == ["#CCCCCC", "#CCCCCC", "#DDDDDD", "#DDDDDD", "#EEEEEE", "#EEEEEE", "#FFFFFF"])
        #expect(try (3..<11).map { try cell($0, 10) } == Array(repeating: "#888888", count: 8))
    }

    @Test("the metrics: 22 px bar, 13 px boxes, a 4 px gap, boxes 2 px below the inner top edge")
    func metrics() throws {
        let bar = try #require(Theme.platinum.windowControls?.titleBar)
        #expect(bar.height == 22)
        #expect(bar.boxSize == 13)
        #expect(bar.gap == 4)
        #expect(bar.inset == Insets(top: 4, leading: 4, bottom: 2, trailing: 5))
    }

    @Test("the web stylesheet places the boxes by the theme's order: close leading, zoom then windowshade trailing")
    func webPlacement() throws {
        let css = try ThemeCSSEmitter.emit(.platinum)
        func order(_ name: String) throws -> Int {
            let block = try #require(css.range(of: ".dt-titlebar__box--\(name) {"))
            let tail = css[block.upperBound...]
            let start = try #require(tail.range(of: "order:"))
            let end = try #require(tail.range(of: ";", range: start.upperBound..<tail.endIndex))
            return try #require(Int(tail[start.upperBound..<end.lowerBound].trimmingCharacters(in: .whitespaces)))
        }
        let close = try order("close"), zoom = try order("zoom"), minimize = try order("minimize")
        #expect(close < 0)
        #expect(0 < zoom && zoom < minimize)
    }
}
