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

    @Test("the bar is #DADADA inside black then white at the top and left, black then black then #B3B3B3 at the right, #B3B3B3 then black at the bottom")
    func bar() throws {
        let bar = try recipe(.titleBar)
        #expect(bar.layers == [.fill(ColourReference(source: "bar"))])
        #expect(try hex(ColourReference(source: "bar")) == "#DADADA")
        let edges = try #require(bar.edges)
        #expect(try edges.top.map { try hex($0.colour) } == ["#000000", "#FFFFFF"])
        #expect(try edges.leading.map { try hex($0.colour) } == ["#000000", "#FFFFFF"])
        #expect(try edges.bottom.map { try hex($0.colour) } == ["#000000", "#B3B3B3"])
        #expect(try edges.trailing.map { try hex($0.colour) } == ["#000000", "#000000", "#B3B3B3"])
    }

    @Test("the stripes alternate #FFFFFF and #969696 down the bar, white first, 12 px high")
    func stripes() throws {
        let tile = try pattern(.titleStripes)
        #expect(tile.width == 1 && tile.height == 2)
        #expect(try tile.cells.map { try hex($0) } == ["#FFFFFF", "#969696"])
        #expect(Theme.platinum.windowControls?.titleBar?.stripeHeight == 12)
    }

    @Test("the close box is 13 x 13: #A5A5A5 top and left, #FFFFFF bottom and right, a #3F3F3F frame, a diagonal bevel that darkens to the top left")
    func box() throws {
        let tile = try pattern(.windowBox)
        #expect(tile.width == 13 && tile.height == 13)
        func cell(_ x: Int, _ y: Int) throws -> String { try hex(tile.cells[y * 13 + x]) }
        // row 0 of the capture (y = 110): #A5A5A5 x12, then the bar's #DADADA
        #expect(try (0..<12).map { try cell($0, 0) } == Array(repeating: "#A5A5A5", count: 12))
        #expect(try cell(12, 0) == "#DADADA")
        // column 0 (x = 233) is #A5A5A5 down to the last row, which is #DADADA then white
        #expect(try (0..<12).map { try cell(0, $0) } == Array(repeating: "#A5A5A5", count: 12))
        #expect(try cell(0, 12) == "#DADADA")
        #expect(try (1..<13).map { try cell($0, 12) } == Array(repeating: "#FFFFFF", count: 12))
        #expect(try (1..<13).map { try cell(12, $0) } == Array(repeating: "#FFFFFF", count: 12))
        // the frame, the one highlight pixel inside it, and the bevel's first and last interior rows
        #expect(try (1..<12).map { try cell($0, 1) } == Array(repeating: "#3F3F3F", count: 11))
        #expect(try cell(2, 2) == "#FFFFFF")
        #expect(try (3..<10).map { try cell($0, 3) } == ["#B3B3B3", "#B3B3B3", "#C0C0C0", "#C0C0C0", "#CDCDCD", "#CDCDCD", "#DADADA"])
        #expect(try (3..<10).map { try cell($0, 9) } == ["#DADADA", "#DADADA", "#E7E7E7", "#E7E7E7", "#F3F3F3", "#F3F3F3", "#FFFFFF"])
        #expect(try (3..<11).map { try cell($0, 10) } == Array(repeating: "#A5A5A5", count: 8))
    }

    @Test("the windowshade box is the close box's bevel crossed by two #3F3F3F lines, rows 5 and 7, the full width of the frame")
    func minimizeBox() throws {
        let tile = try pattern(.windowBoxMinimize)
        let close = try pattern(.windowBox)
        #expect(tile.width == 13 && tile.height == 13)
        func row(_ spec: PatternSpec, _ y: Int) throws -> [String] { try (0..<13).map { try hex(spec.cells[y * 13 + $0]) } }
        let lines = ["#A5A5A5"] + Array(repeating: "#3F3F3F", count: 11) + ["#FFFFFF"]
        #expect(try row(tile, 5) == lines)
        #expect(try row(tile, 7) == lines)
        for y in [0, 1, 2, 3, 4, 6, 8, 9, 10, 11, 12] { #expect(try row(tile, y) == row(close, y)) }
    }

    @Test("the zoom box is the close box's bevel crossed by one #3F3F3F line, row 5 (the About window's box at columns 445 to 457)")
    func zoomBox() throws {
        let tile = try pattern(.windowBoxZoom)
        let close = try pattern(.windowBox)
        func row(_ spec: PatternSpec, _ y: Int) throws -> [String] { try (0..<13).map { try hex(spec.cells[y * 13 + $0]) } }
        #expect(try row(tile, 5) == ["#A5A5A5"] + Array(repeating: "#3F3F3F", count: 11) + ["#FFFFFF"])
        for y in 0..<13 where y != 5 { #expect(try row(tile, y) == row(close, y)) }
    }

    @Test("two boxes at the right sit 3 px apart (a 16 px pitch), not the 4 px gap between other parts")
    func boxSpacing() throws {
        #expect(Theme.platinum.windowControls?.titleBar?.boxGap == 3)
        let css = try ThemeCSSEmitter.emit(.platinum)
        #expect(css.contains(".dt-titlebar__box--minimize {\n  order: 2;\n  margin-inline-start: -1px;"))
        #expect(!css.contains(".dt-titlebar__box--zoom {\n  order: 1;\n  margin-inline-start"))
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
            let block = try #require(css.range(of: ".dt-titlebar__box--\(name) {\n  order:"))
            let tail = css[block.upperBound...]
            let start = (tail.startIndex..<tail.startIndex)
            let end = try #require(tail.range(of: ";", range: start.upperBound..<tail.endIndex))
            return try #require(Int(tail[start.upperBound..<end.lowerBound].trimmingCharacters(in: .whitespaces)))
        }
        let close = try order("close"), zoom = try order("zoom"), minimize = try order("minimize")
        #expect(close < 0)
        #expect(0 < zoom && zoom < minimize)
    }
}
