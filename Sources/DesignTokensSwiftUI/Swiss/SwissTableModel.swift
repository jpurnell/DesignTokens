#if canImport(SwiftUI)
import DesignTokens
import SwiftUI
#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

/// Which column a table is sorted by, and which way. The app owns the data and its order; the table reports the choice.
@available(macOS 14.0, iOS 17.0, visionOS 1.0, tvOS 17.0, watchOS 10.0, *)
public struct SwissTableSort: Sendable, Hashable {
    /// The sorted column's id.
    public var column: String
    /// Whether the order is ascending.
    public var ascending: Bool

    /// Creates a sort.
    public init(column: String, ascending: Bool) {
        self.column = column
        self.ascending = ascending
    }

    /// The sort after a header is chosen: a new column sorts ascending; the same column flips.
    public static func toggled(_ current: SwissTableSort?, on column: String) -> SwissTableSort {
        guard let current, current.column == column else { return SwissTableSort(column: column, ascending: true) }
        return SwissTableSort(column: column, ascending: !current.ascending)
    }

    /// A header's words for VoiceOver: its title, and its sort state when it is the sorted column.
    public static func description(title: String, column: String, sort: SwissTableSort?) -> String {
        guard let sort, sort.column == column else { return title }
        return "\(title), sorted \(sort.ascending ? "ascending" : "descending")"
    }
}

/// Where a table's columns sit on the 12-column grid.
@available(macOS 14.0, iOS 17.0, visionOS 1.0, tvOS 17.0, watchOS 10.0, *)
public enum SwissTableGeometry {
    /// A column's leading edge and width.
    public struct Frame: Sendable, Hashable {
        /// The leading edge.
        public let x: CGFloat
        /// The width.
        public let width: CGFloat
    }

    /// Whether every span is at least one column and together they fit in the grid's twelve.
    public static func isValid(spans: [Int], columns: Int = Grid.columns) -> Bool {
        spans.allSatisfy { $0 >= 1 } && spans.reduce(0, +) <= columns
    }

    /// The frame of each column, consecutive from column 1; a span that would pass the last column is cut at it.
    public static func frames(spans: [Int], total: CGFloat, grid: SwissGrid) -> [Frame] {
        var next = 1
        var out: [Frame] = []
        for span in spans {
            let first = min(next, grid.columns)
            let last = min(next + max(span, 1) - 1, grid.columns)
            out.append(Frame(x: grid.x(ofColumn: first, in: total), width: grid.width(of: first...max(first, last), in: total)))
            next = last + 1
        }
        return out
    }
}

/// One column of a ``SwissTable``.
@available(macOS 14.0, iOS 17.0, visionOS 1.0, tvOS 17.0, watchOS 10.0, *)
public struct SwissTableColumn<Row>: Identifiable {
    /// The id sorting reports.
    public let id: String
    /// The header words.
    public let title: String
    /// How many of the grid's 12 columns it spans.
    public let span: Int
    /// Whether the column is numbers: monospaced digits, aligned to the trailing edge.
    public let isFigure: Bool
    /// Whether choosing the header sorts by it.
    public let isSortable: Bool
    /// How two rows compare in this column, or `nil` when the app sorts its own rows and the table only reports the choice.
    public let compare: ((Row, Row) -> ComparisonResult)?
    /// Whether the cell has nothing to show for a row, so a stacked row leaves this column's label out rather than label a blank.
    public let isEmpty: ((Row) -> Bool)?
    let cell: (Row) -> AnyView
    let copyText: (Row) -> String

    /// A column with any cell view.
    ///
    /// - Parameters:
    ///   - title: The header words.
    ///   - id: The id sorting reports; defaults to the title.
    ///   - span: How many of the 12 grid columns it takes.
    ///   - isFigure: Numbers: monospaced digits, trailing edge.
    ///   - isSortable: Whether the header is a sort button. A column with a `compare` is sortable.
    ///   - compare: How two rows compare, so the table sorts its rows itself; `nil` leaves the order to the app.
    ///   - copy: The cell's words when rows are copied; `nil` copies nothing for this column.
    ///   - isEmpty: Whether the cell draws nothing for a row; a stacked row then omits this column's label. `nil` never omits.
    ///   - cell: The cell. A cell that draws nothing still holds its column.
    public init<Cell: View>(_ title: String, id: String? = nil, span: Int, isFigure: Bool = false, isSortable: Bool = false,
                            compare: ((Row, Row) -> ComparisonResult)? = nil, copy: ((Row) -> String)? = nil,
                            isEmpty: ((Row) -> Bool)? = nil, @ViewBuilder cell: @escaping (Row) -> Cell) {
        self.id = id ?? title
        self.title = title
        self.span = span
        self.isFigure = isFigure
        self.isSortable = isSortable || compare != nil
        self.compare = compare
        self.isEmpty = isEmpty
        self.cell = { AnyView(cell($0)) }
        self.copyText = copy ?? { _ in "" }
    }

    /// A column with any cell view, sorted by a key path to a `Comparable` value: the easy path, the table sorts its own rows.
    public init<Cell: View, Value: Comparable>(_ title: String, id: String? = nil, span: Int, isFigure: Bool = false,
                                               sortBy key: KeyPath<Row, Value>, copy: ((Row) -> String)? = nil,
                                               isEmpty: ((Row) -> Bool)? = nil, @ViewBuilder cell: @escaping (Row) -> Cell) {
        self.init(title, id: id, span: span, isFigure: isFigure, compare: Self.comparator(key), copy: copy, isEmpty: isEmpty, cell: cell)
    }

    /// A column of text.
    public init(_ title: String, id: String? = nil, span: Int, isFigure: Bool = false, isSortable: Bool = false,
                compare: ((Row, Row) -> ComparisonResult)? = nil, text: @escaping (Row) -> String) {
        self.init(title, id: id, span: span, isFigure: isFigure, isSortable: isSortable, compare: compare, copy: text,
                  isEmpty: { text($0).isEmpty }) { Text(text($0)) }
    }

    /// A column of text, sorted by a key path to a `Comparable` value.
    public init<Value: Comparable>(_ title: String, id: String? = nil, span: Int, isFigure: Bool = false,
                                   sortBy key: KeyPath<Row, Value>, text: @escaping (Row) -> String) {
        self.init(title, id: id, span: span, isFigure: isFigure, compare: Self.comparator(key), text: text)
    }

    private static func comparator<Value: Comparable>(_ key: KeyPath<Row, Value>) -> (Row, Row) -> ComparisonResult {
        { lhs, rhs in
            let a = lhs[keyPath: key], b = rhs[keyPath: key]
            return a < b ? .orderedAscending : (b < a ? .orderedDescending : .orderedSame)
        }
    }
}

/// Sorting a table's rows by its sort state: stable (rows that compare the same keep the order they came in) and a no-op when the sorted
/// column has no `compare`, so an app that sorts its own rows is unaffected.
@available(macOS 14.0, iOS 17.0, visionOS 1.0, tvOS 17.0, watchOS 10.0, *)
public enum SwissTableSorting {
    /// The rows ordered by the sorted column.
    public static func sorted<Row>(_ rows: [Row], columns: [SwissTableColumn<Row>], by sort: SwissTableSort?) -> [Row] {
        guard let sort, let compare = columns.first(where: { $0.id == sort.column })?.compare else { return rows }
        return rows.enumerated().sorted { lhs, rhs in
            switch compare(lhs.element, rhs.element) {
            case .orderedSame: lhs.offset < rhs.offset
            case .orderedAscending: sort.ascending
            case .orderedDescending: !sort.ascending
            }
        }.map(\.element)
    }
}

/// One visible row of a table: the row, how deep it is, and whether it is a group and open.
@available(macOS 14.0, iOS 17.0, visionOS 1.0, tvOS 17.0, watchOS 10.0, *)
public struct SwissTableEntry<Row: Identifiable>: Identifiable {
    /// The row.
    public let row: Row
    /// How many groups deep: 0 at the top.
    public let depth: Int
    /// Whether the row has children (even none yet), so it shows a disclosure control.
    public let isGroup: Bool
    /// Whether a group is open.
    public let isExpanded: Bool
    /// The row's id.
    public var id: Row.ID { row.id }
}

/// Flattening a tree of rows into the rows that are visible.
@available(macOS 14.0, iOS 17.0, visionOS 1.0, tvOS 17.0, watchOS 10.0, *)
public enum SwissTableTree {
    /// The visible rows in display order: each row, then (when it is a group and expanded) its children, depth first. Siblings are
    /// ordered by `order`, which is how a sort applies at every level.
    ///
    /// - Parameters:
    ///   - rows: The top-level rows.
    ///   - children: Where a row's children are; `nil` makes the table flat. A row whose value is `nil` is a leaf.
    ///   - expanded: The ids of the open groups.
    ///   - order: Orders a set of siblings.
    public static func flatten<Row: Identifiable>(_ rows: [Row], children: KeyPath<Row, [Row]?>?, expanded: Set<Row.ID>,
                                                  order: ([Row]) -> [Row] = { $0 }) -> [SwissTableEntry<Row>] {
        var output: [SwissTableEntry<Row>] = []
        var pending = order(rows).reversed().map { (row: $0, depth: 0) }
        while let next = pending.popLast() {
            let kids = children.flatMap { next.row[keyPath: $0] }
            let isOpen = kids != nil && expanded.contains(next.row.id)
            output.append(SwissTableEntry(row: next.row, depth: next.depth, isGroup: kids != nil, isExpanded: isOpen))
            guard isOpen, let kids else { continue }
            for child in order(kids).reversed() { pending.append((row: child, depth: next.depth + 1)) }
        }
        return output
    }
}

/// How taps and arrow keys change a table's selection: pure, so a test holds it.
@available(macOS 14.0, iOS 17.0, visionOS 1.0, tvOS 17.0, watchOS 10.0, *)
public enum SwissTableSelectionRule {
    /// The selection after a row is tapped. A single-selection table selects the row. A multiple-selection table selects only the
    /// row, or, when `extend` is true (command or shift on a Mac, any tap on a touch screen), toggles it in the selection.
    public static func tapped<ID: Hashable>(_ id: ID, current: Set<ID>, multiple: Bool, extend: Bool) -> Set<ID> {
        guard multiple, extend else { return [id] }
        var next = current
        if next.contains(id) { next.remove(id) } else { next.insert(id) }
        return next
    }

    /// The row an arrow key moves to: one step from the last selected row down (`delta` 1) or the first up (`delta` -1) in the displayed
    /// order, staying within it; the first row going down, or the last going up, when nothing is selected. `nil` when there are no rows.
    public static func moved<ID: Hashable>(from current: Set<ID>, by delta: Int, order: [ID]) -> ID? {
        guard !order.isEmpty else { return nil }
        let selected = order.indices.filter { current.contains(order[$0]) }
        guard let anchor = delta >= 0 ? selected.max() : selected.min() else { return delta >= 0 ? order.first : order.last }
        return order[min(max(anchor + delta, 0), order.count - 1)]
    }
}

/// Rows as text for the pasteboard.
@available(macOS 14.0, iOS 17.0, visionOS 1.0, tvOS 17.0, watchOS 10.0, *)
public enum SwissTableCopy {
    /// The rows as tab-separated text, one row to a line, in the order given. A cell's words come from the column's `copy` (or its
    /// text); tabs and line breaks inside a cell become spaces, so the shape survives a paste into a spreadsheet.
    public static func text<Row>(rows: [Row], columns: [SwissTableColumn<Row>]) -> String {
        rows.map { row in
            columns.map { column in
                String(column.copyText(row).map { $0.isNewline || $0 == "\t" ? " " : $0 })
            }.joined(separator: "\t")
        }.joined(separator: "\n")
    }

    /// Puts text on the general pasteboard.
    @MainActor
    static func write(_ text: String) {
        #if canImport(AppKit)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        #elseif canImport(UIKit)
        UIPasteboard.general.string = text
        #endif
    }
}

@available(macOS 14.0, iOS 17.0, visionOS 1.0, tvOS 17.0, watchOS 10.0, *)
extension SwissMetrics {
    /// The width under which a table stacks its rows: 150 base units (600 pt in Swiss), about where twelve grid columns stop being legible.
    public var tableStackedBelow: CGFloat { step(150) }
}
#endif
