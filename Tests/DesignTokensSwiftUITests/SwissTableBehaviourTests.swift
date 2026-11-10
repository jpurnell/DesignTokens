#if canImport(SwiftUI) && os(macOS)
import DesignTokens
import SwiftUI
import Testing
@testable import DesignTokensSwiftUI

private struct Item: Identifiable {
    let id: Int
    let name: String
    let count: Int
    var children: [Item]?
}

private var columns: [SwissTableColumn<Item>] { [
    SwissTableColumn("Name", id: "name", span: 5, sortBy: \.name, text: { $0.name }),
    SwissTableColumn("Count", id: "count", span: 3, isFigure: true, sortBy: \.count, text: { String($0.count) }),
    SwissTableColumn("Status", id: "status", span: 4, isSortable: true) { Text($0.count > 100 ? "high" : "low") },
] }

@Suite("Swiss table: sorting")
struct SwissTableSortingTests {
    private let items = [Item(id: 1, name: "bravo", count: 5), Item(id: 2, name: "alpha", count: 9),
                         Item(id: 3, name: "charlie", count: 5), Item(id: 4, name: "delta", count: 1)]

    @Test("ascending and descending by a key path; the order is the column's, not the input's")
    func byKeyPath() {
        let ascending = SwissTableSorting.sorted(items, columns: columns, by: SwissTableSort(column: "name", ascending: true))
        #expect(ascending.map(\.name) == ["alpha", "bravo", "charlie", "delta"])
        let descending = SwissTableSorting.sorted(items, columns: columns, by: SwissTableSort(column: "count", ascending: false))
        #expect(descending.map(\.count) == [9, 5, 5, 1])
    }

    @Test("equal keys keep their input order whichever way the column is sorted (a stable sort)")
    func stable() {
        let up = SwissTableSorting.sorted(items, columns: columns, by: SwissTableSort(column: "count", ascending: true))
        #expect(up.map(\.id) == [4, 1, 3, 2])
        let down = SwissTableSorting.sorted(items, columns: columns, by: SwissTableSort(column: "count", ascending: false))
        #expect(down.map(\.id) == [2, 1, 3, 4])
    }

    @Test("no sort, an unknown column, or a column with no comparison leaves the rows as the app gave them")
    func noOp() {
        let order = items.map(\.id)
        #expect(SwissTableSorting.sorted(items, columns: columns, by: nil).map(\.id) == order)
        #expect(SwissTableSorting.sorted(items, columns: columns, by: SwissTableSort(column: "nope", ascending: true)).map(\.id) == order)
        #expect(SwissTableSorting.sorted(items, columns: columns, by: SwissTableSort(column: "status", ascending: true)).map(\.id) == order)
    }

    @Test("a column with a comparison is sortable even if it did not say so; one without is sortable only when it says so")
    func sortableFlag() {
        #expect(columns[0].isSortable)
        #expect(columns[1].isSortable)
        #expect(columns[2].isSortable)
        #expect(columns[2].compare == nil)
        #expect(SwissTableColumn<Item>("Plain", span: 2, text: { $0.name }).isSortable == false)
    }
}

@Suite("Swiss table: tree rows")
struct SwissTableTreeTests {
    private let tree = [
        Item(id: 1, name: "b-group", count: 0, children: [Item(id: 11, name: "z-leaf", count: 1, children: nil),
                                                         Item(id: 12, name: "a-leaf", count: 2, children: nil),
                                                         Item(id: 13, name: "inner", count: 3, children: [Item(id: 131, name: "deep", count: 4, children: nil)])]),
        Item(id: 2, name: "a-leaf-top", count: 7, children: nil),
        Item(id: 3, name: "empty-group", count: 0, children: []),
    ]

    @Test("collapsed, only the top rows show; groups are marked, leaves are not, an empty group is still a group")
    func collapsed() {
        let entries = SwissTableTree.flatten(tree, children: \.children, expanded: [])
        #expect(entries.map(\.id) == [1, 2, 3])
        #expect(entries.map(\.isGroup) == [true, false, true])
        #expect(entries.map(\.isExpanded) == [false, false, false])
        #expect(entries.map(\.depth) == [0, 0, 0])
    }

    @Test("expanded groups show their children right after them, depth first, with their depth")
    func expanded() {
        let entries = SwissTableTree.flatten(tree, children: \.children, expanded: [1, 13])
        #expect(entries.map(\.id) == [1, 11, 12, 13, 131, 2, 3])
        #expect(entries.map(\.depth) == [0, 1, 1, 1, 2, 0, 0])
        #expect(entries.map(\.isExpanded) == [true, false, false, true, false, false, false])
    }

    @Test("an open id that is not a group, or whose parent is closed, shows nothing extra")
    func strayIds() {
        #expect(SwissTableTree.flatten(tree, children: \.children, expanded: [2, 131]).map(\.id) == [1, 2, 3])
    }

    @Test("siblings are ordered at every level by the order given")
    func orderedPerLevel() {
        let order: ([Item]) -> [Item] = { SwissTableSorting.sorted($0, columns: columns, by: SwissTableSort(column: "name", ascending: true)) }
        let entries = SwissTableTree.flatten(tree, children: \.children, expanded: [1], order: order)
        #expect(entries.map(\.id) == [2, 1, 12, 13, 11, 3], "a-leaf-top, b-group, then its children a-leaf, inner, z-leaf, then empty-group")
    }

    @Test("without a children key path the table is flat, whatever the rows hold")
    func flat() {
        #expect(SwissTableTree.flatten(tree, children: nil, expanded: [1]).map(\.id) == [1, 2, 3])
    }
}

@Suite("Swiss table: selection and copy")
struct SwissTableSelectionTests {
    @Test("single selection: a tap selects that row only, whatever was selected, whatever the modifier")
    func single() {
        #expect(SwissTableSelectionRule.tapped(3, current: [1], multiple: false, extend: false) == [3])
        #expect(SwissTableSelectionRule.tapped(3, current: [1], multiple: false, extend: true) == [3])
    }

    @Test("multiple selection: a plain click replaces; an extending click toggles the row in and out")
    func multiple() {
        #expect(SwissTableSelectionRule.tapped(3, current: [1, 2], multiple: true, extend: false) == [3])
        #expect(SwissTableSelectionRule.tapped(3, current: [1, 2], multiple: true, extend: true) == [1, 2, 3])
        #expect(SwissTableSelectionRule.tapped(2, current: [1, 2], multiple: true, extend: true) == [1])
    }

    @Test("arrow keys move one row from the last selected going down and the first going up, staying inside the rows")
    func arrows() {
        let order = [10, 20, 30, 40]
        #expect(SwissTableSelectionRule.moved(from: [20], by: 1, order: order) == 30)
        #expect(SwissTableSelectionRule.moved(from: [20], by: -1, order: order) == 10)
        #expect(SwissTableSelectionRule.moved(from: [20, 30], by: 1, order: order) == 40)
        #expect(SwissTableSelectionRule.moved(from: [20, 30], by: -1, order: order) == 10)
        #expect(SwissTableSelectionRule.moved(from: [40], by: 1, order: order) == 40)
        #expect(SwissTableSelectionRule.moved(from: [10], by: -1, order: order) == 10)
        #expect(SwissTableSelectionRule.moved(from: [], by: 1, order: order) == 10)
        #expect(SwissTableSelectionRule.moved(from: [], by: -1, order: order) == 40)
        #expect(SwissTableSelectionRule.moved(from: [99], by: 1, order: order) == 10, "a selection that is not visible counts as none")
        #expect(SwissTableSelectionRule.moved(from: [1], by: 1, order: [Int]()) == nil)
    }

    @Test("copy: tab-separated cells, one row to a line, in the order given; tabs and breaks inside a cell become spaces")
    func copy() {
        let rows = [Item(id: 1, name: "alpha", count: 9), Item(id: 2, name: "multi\nline\tname", count: 5)]
        let text = SwissTableCopy.text(rows: rows, columns: columns)
        #expect(text == "alpha\t9\t\nmulti line name\t5\t", "the status column draws a view and supplies no copy text, so it is empty")
        #expect(SwissTableCopy.text(rows: [Item](), columns: columns) == "")
    }

    @Test("a column's copy closure overrides nothing but the copied words: a custom cell can say what it copies")
    func copyClosure() {
        let withCopy = [SwissTableColumn<Item>("S", span: 3, copy: { $0.count > 100 ? "high" : "low" }) { _ in Text("x") }]
        #expect(SwissTableCopy.text(rows: [Item(id: 1, name: "a", count: 500)], columns: withCopy) == "high")
    }
}

@MainActor
@Suite("Swiss table: layout in a real window")
struct SwissTableLayoutTests {
    private let rows = [Item(id: 1, name: "alpha", count: 50), Item(id: 2, name: "bravo", count: 500), Item(id: 3, name: "charlie", count: 60)]

    private func frames(width: CGFloat, size: DynamicTypeSize = .large, cols: [SwissTableColumn<Item>] = columns) -> [String: CGRect] {
        let table = SwissTable(rows, columns: cols).environment(\.swissTableProbe, true).environment(\.dynamicTypeSize, size)
        return renderProbedTable(table, width: width)
    }

    @Test("a cell that draws nothing still holds its column: the cells after it sit where they do in rows that draw")
    func emptyCellsDoNotShiftColumns() throws {
        let sparse: [SwissTableColumn<Item>] = [
            columns[0], columns[1],
            SwissTableColumn("Status", id: "status", span: 4) { item in if item.id == 2 { EmptyView() } else { Text("here") } },
        ]
        let sparseFrames = frames(width: 900, cols: sparse)
        let first = try #require(sparseFrames["1/status"]), empty = try #require(sparseFrames["2/status"]), third = try #require(sparseFrames["3/status"])
        let count1 = try #require(sparseFrames["1/count"]), count2 = try #require(sparseFrames["2/count"])
        #expect(near(first.minX, third.minX), "the status cells that draw sit in the same column")
        #expect(near(empty.minX, first.minX), "the one that draws nothing holds that column")
        #expect(near(count1.minX, count2.minX), "and the column before it is unmoved")
        let grid = SwissMetrics(theme: .swiss).grid
        let expected = SwissTableGeometry.frames(spans: [5, 3, 4], total: 900, grid: grid)[2]
        #expect(near(first.minX - count1.minX, expected.x - SwissTableGeometry.frames(spans: [5, 3, 4], total: 900, grid: grid)[1].x, tolerance: 0.5))
    }

    @Test("at a wide width the columns are side by side on one line; the first cell's tops align")
    func wideLayout() throws {
        let f = frames(width: 900)
        let name = try #require(f["1/name"]), count = try #require(f["1/count"]), status = try #require(f["1/status"])
        #expect(count.minX > name.maxX - 1)
        #expect(status.minX > count.maxX - 1)
        #expect(near(name.minY, count.minY, tolerance: 2))
    }

    @Test("under the stacking width the cells of a row are stacked: the title, then each value under it")
    func stackedNarrow() throws {
        let f = frames(width: 390)
        let name = try #require(f["1/name"]), count = try #require(f["1/count"]), status = try #require(f["1/status"])
        #expect(count.minY > name.maxY - 1, "the count is below the name, not beside it")
        #expect(status.minY > count.maxY - 1)
        let next = try #require(f["2/name"])
        #expect(next.minY > status.maxY - 1, "the next row starts below the last value")
    }

    @Test("at an accessibility text size the rows stack even in a wide window")
    func stackedAtAccessibilitySize() throws {
        let f = frames(width: 900, size: .accessibility3)
        let name = try #require(f["1/name"]), count = try #require(f["1/count"])
        #expect(count.minY > name.maxY - 1)
    }

    @Test("narrow: .scroll keeps the columns side by side under the width")
    func scrollKeepsColumns() throws {
        let table = SwissTable(rows, columns: columns, minimumWidth: 700, narrow: .scroll).environment(\.swissTableProbe, true)
        let f = renderProbedTable(table, width: 390)
        let name = try #require(f["1/name"]), count = try #require(f["1/count"])
        #expect(near(name.minY, count.minY, tolerance: 2))
    }

    @Test("stacked, a column whose cell is empty for a row leaves its label out; a column that has a value keeps it")
    func stackedOmitsEmptyLabels() throws {
        let columns: [SwissTableColumn<Item>] = [
            columns[0],
            SwissTableColumn("Status", id: "status", span: 4, isEmpty: { $0.id == 2 }) { Text("v\($0.id)") },
        ]
        let table = SwissTable(rows, columns: columns).environment(\.swissTableProbe, true)
        let f = renderProbedTable(table, width: 390)
        _ = try #require(f["1/status"])
        _ = try #require(f["3/status"])
        #expect(f["2/status"] == nil, "row 2 has nothing for Status, so no label and no value are placed")
    }

    @Test("with a selection the content sits inside the row by two base units, so the accent bar and the fill do not cover it")
    func selectionInset() throws {
        let plain = renderProbedTable(SwissTable(rows, columns: columns).environment(\.swissTableProbe, true), width: 900)
        let selectable = renderProbedTable(SwissTable(rows, columns: columns, selection: .constant(Set<Int>())).environment(\.swissTableProbe, true), width: 900)
        let before = try #require(plain["1/name/content"]), after = try #require(selectable["1/name/content"])
        #expect(near(after.minX - before.minX, 8, tolerance: 0.5))
    }

    @Test("disclosure rows: expanding a group shows its children indented one level, in the first column")
    func treeIndent() throws {
        let tree = [Item(id: 1, name: "group", count: 0, children: [Item(id: 11, name: "child", count: 1, children: nil)]),
                    Item(id: 2, name: "leaf", count: 2, children: nil)]
        let table = SwissTable(tree, columns: columns, children: \.children, expanded: .constant([1])).environment(\.swissTableProbe, true)
        let f = renderProbedTable(table, width: 900)
        let group = try #require(f["1/name/content"]), child = try #require(f["11/name/content"]), leaf = try #require(f["2/name/content"])
        #expect(near(child.minX - group.minX, 16, tolerance: 0.5), "one level is four base units: \(child.minX - group.minX) \(group) \(child)")
        #expect(near(leaf.minX, group.minX, tolerance: 0.5), "a top-level leaf lines up with a top-level group")
        #expect(child.minY > group.minY)
    }
}
#endif
