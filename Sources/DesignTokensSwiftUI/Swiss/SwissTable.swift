#if canImport(SwiftUI)
import DesignTokens
import SwiftUI

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
    fileprivate let cell: (Row) -> AnyView

    /// A column with any cell view.
    public init<Cell: View>(_ title: String, id: String? = nil, span: Int, isFigure: Bool = false, isSortable: Bool = false,
                            @ViewBuilder cell: @escaping (Row) -> Cell) {
        self.id = id ?? title
        self.title = title
        self.span = span
        self.isFigure = isFigure
        self.isSortable = isSortable
        self.cell = { AnyView(cell($0)) }
    }

    /// A column of text.
    public init(_ title: String, id: String? = nil, span: Int, isFigure: Bool = false, isSortable: Bool = false,
                text: @escaping (Row) -> String) {
        self.init(title, id: id, span: span, isFigure: isFigure, isSortable: isSortable) { Text(text($0)) }
    }
}

/// Places its subviews on the grid, one per span, tops aligned.
@available(macOS 14.0, iOS 17.0, visionOS 1.0, tvOS 17.0, watchOS 10.0, *)
private struct GridRowLayout: Layout {
    let spans: [Int]
    let grid: SwissGrid

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        let frames = SwissTableGeometry.frames(spans: spans, total: width, grid: grid)
        var height: CGFloat = 0
        for (index, subview) in subviews.enumerated() where index < frames.count {
            height = max(height, subview.sizeThatFits(ProposedViewSize(width: frames[index].width, height: nil)).height)
        }
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let frames = SwissTableGeometry.frames(spans: spans, total: bounds.width, grid: grid)
        for (index, subview) in subviews.enumerated() where index < frames.count {
            subview.place(at: CGPoint(x: bounds.minX + frames[index].x, y: bounds.minY), anchor: .topLeading,
                          proposal: ProposedViewSize(width: frames[index].width, height: bounds.height))
        }
    }
}

/// A table on the 12-column grid, with none of the system's header or row chrome: the header in the label role over an ink
/// hairline, rows separated by neutral hairlines, no zebra, number columns in monospaced digits, an optional sortable header, and a
/// horizontal scroll under a minimum width instead of crushing the columns. Lazy, and the same on every platform.
///
/// A native `Table`'s header cannot be styled (see ``SwiftUI/View/swissTableStyle()``), which is why this exists.
@available(macOS 14.0, iOS 17.0, visionOS 1.0, tvOS 17.0, watchOS 10.0, *)
public struct SwissTable<Row: Identifiable>: View {
    private let rows: [Row]
    private let columns: [SwissTableColumn<Row>]
    private let sort: Binding<SwissTableSort?>?
    private let minimumWidth: CGFloat?

    /// Creates a table.
    ///
    /// - Parameters:
    ///   - rows: The rows, already in the order to show.
    ///   - columns: The columns; their spans together fit in 12 (``SwissTableGeometry/isValid(spans:columns:)``).
    ///   - sort: The sort the header shows and changes, or `nil` for a table whose headers are not buttons.
    ///   - minimumWidth: The width under which the table scrolls horizontally, or `nil` to always fit.
    public init(_ rows: [Row], columns: [SwissTableColumn<Row>], sort: Binding<SwissTableSort?>? = nil, minimumWidth: CGFloat? = nil) {
        self.rows = rows
        self.columns = columns
        self.sort = sort
        self.minimumWidth = minimumWidth
    }

    /// The table.
    public var body: some View {
        if let minimumWidth {
            ViewThatFits(in: .horizontal) {
                content.frame(minWidth: minimumWidth)
                ScrollView(.horizontal) { content.frame(width: minimumWidth) }
            }
        } else {
            content
        }
    }

    private var content: some View {
        ChartStyleReader { style in
            let metrics = SwissMetrics(theme: style.theme)
            let spans = columns.map(\.span)
            LazyVStack(alignment: .leading, spacing: 0, pinnedViews: []) {
                header(style: style, metrics: metrics, spans: spans)
                ForEach(rows) { row in
                    VStack(spacing: 0) {
                        GridRowLayout(spans: spans, grid: metrics.grid) {
                            ForEach(columns) { column in
                                cell(column, row: row)
                            }
                        }
                        .padding(.vertical, metrics.step(2))
                        SwissRule(.hairline)
                    }
                    .accessibilityElement(children: .combine)
                }
            }
            .accessibilityElement(children: .contain)
        }
    }

    private func cell(_ column: SwissTableColumn<Row>, row: Row) -> some View {
        column.cell(row)
            .uiText(.body)
            .modifier(FigureModifier(isFigure: column.isFigure))
            .frame(maxWidth: .infinity, alignment: column.isFigure ? .trailing : .leading)
    }

    private func header(style: ChartStyle, metrics: SwissMetrics, spans: [Int]) -> some View {
        VStack(spacing: 0) {
            GridRowLayout(spans: spans, grid: metrics.grid) {
                ForEach(columns) { column in
                    headerCell(column, style: style)
                }
            }
            .padding(.bottom, metrics.step(2))
            SwissRule(.hairline, tone: .ink)
        }
    }

    @ViewBuilder
    private func headerCell(_ column: SwissTableColumn<Row>, style: ChartStyle) -> some View {
        let alignment: Alignment = column.isFigure ? .trailing : .leading
        let current = sort?.wrappedValue
        let words = SwissTableSort.description(title: column.title, column: column.id, sort: current)
        if column.isSortable, let sort {
            Button { sort.wrappedValue = SwissTableSort.toggled(sort.wrappedValue, on: column.id) } label: {
                HStack(spacing: SwissMetrics(theme: style.theme).step(1)) {
                    Text(column.title).uiText(.label)
                    if current?.column == column.id {
                        Image(systemName: current?.ascending == true ? "chevron.up" : "chevron.down")
                            .imageScale(.small).foregroundStyle(style.ink).accessibilityHidden(true)
                    }
                }
                .frame(maxWidth: .infinity, alignment: alignment)
                .swissTouchTarget(SwissMetrics(theme: style.theme))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(words)
            .accessibilityAddTraits(.isHeader)
        } else {
            Text(column.title).uiText(.label)
                .frame(maxWidth: .infinity, alignment: alignment)
                .accessibilityAddTraits(.isHeader)
        }
    }
}

@available(macOS 14.0, iOS 17.0, visionOS 1.0, tvOS 17.0, watchOS 10.0, *)
private struct FigureModifier: ViewModifier {
    let isFigure: Bool
    func body(content: Content) -> some View {
        if isFigure { content.uiFigure() } else { content }
    }
}

@available(macOS 14.0, iOS 17.0, visionOS 1.0, tvOS 17.0, watchOS 10.0, *)
public extension View {
    /// What can be set on a native `Table`: no alternating row backgrounds (macOS) and no scroll-view background, so the page shows
    /// through. Cell content is the app's own views and takes ``uiText(_:)`` and ``uiFigure()``.
    ///
    /// What cannot: the header bar, its column dividers and its text. `TableColumn`'s title is a string, not a view (there is no
    /// `Text` overload), and the header is the system's own control, so it takes no type role. Where the design needs a Swiss
    /// header, use ``SwissTable``. On iPhone a native `Table` shows only its first column.
    func swissTableStyle() -> some View {
        #if os(macOS)
        tableStyle(.inset(alternatesRowBackgrounds: false)).scrollContentBackground(.hidden)
        #else
        scrollContentBackground(.hidden)
        #endif
    }
}
#endif
