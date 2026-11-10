#if canImport(SwiftUI) && os(macOS)
import DesignTokens
import SwiftUI
import Testing
@testable import DesignTokensSwiftUI

@Suite("Swiss table")
struct SwissTableTests {
    private let grid = SwissMetrics(theme: .swiss).grid

    @Test("columns sit on the 12-column grid in order: starts and widths follow the spans")
    func frames() {
        let frames = SwissTableGeometry.frames(spans: [4, 2, 2, 4], total: 1_000, grid: grid)
        #expect(frames.count == 4)
        let c = grid.columnWidth(in: 1_000)
        #expect(near(frames[0].x, 0))
        #expect(near(frames[0].width, 4 * c + 3 * 16))
        #expect(near(frames[1].x, grid.x(ofColumn: 5, in: 1_000)))
        #expect(near(frames[1].width, 2 * c + 16))
        #expect(near(frames[3].x, grid.x(ofColumn: 9, in: 1_000)))
        #expect(near(frames[3].x + frames[3].width, 1_000), "spans that fill 12 columns end at the right edge")
    }

    @Test("spans that sum past 12 columns are clamped to the grid, never laid out beyond it")
    func overflow() {
        let frames = SwissTableGeometry.frames(spans: [8, 8], total: 1_000, grid: grid)
        #expect(frames.count == 2)
        #expect(frames[1].x + frames[1].width <= 1_000 + 1e-9)
        #expect(SwissTableGeometry.isValid(spans: [8, 8]) == false)
        #expect(SwissTableGeometry.isValid(spans: [4, 2, 2, 4]))
        #expect(SwissTableGeometry.isValid(spans: [0, 4]) == false)
    }

    @Test("sorting: a new column sorts ascending; the same column flips; a third tap on a descending column goes back to ascending")
    func sorting() {
        var sort: SwissTableSort? = nil
        sort = SwissTableSort.toggled(sort, on: "name")
        #expect(sort == SwissTableSort(column: "name", ascending: true))
        sort = SwissTableSort.toggled(sort, on: "name")
        #expect(sort == SwissTableSort(column: "name", ascending: false))
        sort = SwissTableSort.toggled(sort, on: "name")
        #expect(sort == SwissTableSort(column: "name", ascending: true))
        sort = SwissTableSort.toggled(sort, on: "count")
        #expect(sort == SwissTableSort(column: "count", ascending: true))
    }

    @Test("the accessibility description of a header says its sort state in words")
    func headerWords() {
        #expect(SwissTableSort.description(title: "Name", column: "name", sort: nil) == "Name")
        #expect(SwissTableSort.description(title: "Name", column: "name", sort: SwissTableSort(column: "name", ascending: true)) == "Name, sorted ascending")
        #expect(SwissTableSort.description(title: "Name", column: "name", sort: SwissTableSort(column: "name", ascending: false)) == "Name, sorted descending")
        #expect(SwissTableSort.description(title: "Count", column: "count", sort: SwissTableSort(column: "name", ascending: true)) == "Count")
    }
}
#endif
