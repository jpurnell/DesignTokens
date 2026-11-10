#if canImport(SwiftUI) && os(macOS)
import SwiftUI
import Testing
@testable import DesignTokensSwiftUI

@Suite("Equal-height grid arithmetic")
struct SwissEqualGridTests {
    @Test("columns: as many as fit at the minimum width, never fewer than one, however narrow or odd the width")
    func columns() {
        // 3 columns of 280 with 16 gaps need 3*280 + 2*16 = 872.
        #expect(SwissEqualGridArrangement.columns(width: 872, minimumWidth: 280, spacing: 16) == 3)
        #expect(SwissEqualGridArrangement.columns(width: 871, minimumWidth: 280, spacing: 16) == 2)
        #expect(SwissEqualGridArrangement.columns(width: 100, minimumWidth: 280, spacing: 16) == 1)
        #expect(SwissEqualGridArrangement.columns(width: 0, minimumWidth: 280, spacing: 16) == 1)
        #expect(SwissEqualGridArrangement.columns(width: .infinity, minimumWidth: 280, spacing: 16) == 1)
        #expect(SwissEqualGridArrangement.columns(width: 500, minimumWidth: 0, spacing: 16) == 1)
        #expect(SwissEqualGridArrangement.columns(width: .greatestFiniteMagnitude, minimumWidth: 1, spacing: 0) == 10_000)
    }

    @Test("column width: the columns and the gaps together fill the width exactly")
    func columnWidth() {
        let w = SwissEqualGridArrangement.columnWidth(width: 872, columns: 3, spacing: 16)
        #expect(near(w, 280))
        #expect(near(3 * w + 2 * 16, 872))
        #expect(SwissEqualGridArrangement.columnWidth(width: 10, columns: 3, spacing: 16) == 0, "never negative")
        #expect(SwissEqualGridArrangement.columnWidth(width: 300, columns: 1, spacing: 16) == 300)
    }

    @Test("row heights: each row is as tall as its tallest card; a lone last card gets a row of its own height")
    func rowHeights() {
        let rows = SwissEqualGridArrangement.rowHeights([100, 140, 90, 200, 50, 70, 60], columns: 3)
        #expect(rows == [140, 200, 60])
        #expect(SwissEqualGridArrangement.rowHeights([], columns: 3).isEmpty)
        #expect(SwissEqualGridArrangement.rowHeights([10, 20], columns: 0).isEmpty)
    }
}

@Suite("Flow arrangement")
struct SwissFlowTests {
    private func box(_ w: CGFloat, _ h: CGFloat = 20) -> CGSize { CGSize(width: w, height: h) }

    @Test("items wrap onto a new line when the next would pass the width, and the lines are spaced")
    func wraps() {
        let result = SwissFlowArrangement.place(sizes: [box(50), box(50), box(50), box(50)], width: 120, spacing: 8, lineSpacing: 4)
        // 50 + 8 + 50 = 108 fits in 120; a third would be 166.
        #expect(result.lines == [0, 0, 1, 1])
        #expect(result.origins[0] == CGPoint(x: 0, y: 0))
        #expect(result.origins[1] == CGPoint(x: 58, y: 0))
        #expect(result.origins[2] == CGPoint(x: 0, y: 24))
        #expect(result.size == CGSize(width: 108, height: 44))
    }

    @Test("an item wider than the container takes a line of its own; the first item never wraps")
    func oversize() {
        let result = SwissFlowArrangement.place(sizes: [box(200), box(30)], width: 100, spacing: 8, lineSpacing: 8)
        #expect(result.lines == [0, 1])
        #expect(result.origins[1] == CGPoint(x: 0, y: 28))
    }

    @Test("items on a line are centred vertically on the tallest")
    func centred() {
        let result = SwissFlowArrangement.place(sizes: [box(40, 40), box(40, 20)], width: 200, spacing: 8, lineSpacing: 8)
        #expect(result.origins[1].y == 10)
        #expect(result.size.height == 40)
    }

    @Test("no items is an empty size, and an unbounded width is one unbroken line")
    func edges() {
        #expect(SwissFlowArrangement.place(sizes: [], width: 100, spacing: 8, lineSpacing: 8).size == .zero)
        let line = SwissFlowArrangement.place(sizes: [box(500), box(500), box(500)], width: .infinity, spacing: 10, lineSpacing: 10)
        #expect(line.lines == [0, 0, 0])
        #expect(line.size.width == 1_520)
    }
}
#endif
