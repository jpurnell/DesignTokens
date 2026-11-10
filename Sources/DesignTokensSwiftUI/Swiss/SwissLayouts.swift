#if canImport(SwiftUI)
import DesignTokens
import SwiftUI

// MARK: Flow

/// The wrapping arithmetic of ``SwissFlowLayout``, separate from SwiftUI so a test can hold it: items are placed left to right and a
/// new line starts when the next item would pass the width (an item wider than the width still takes a line of its own).
@available(macOS 14.0, iOS 17.0, visionOS 1.0, tvOS 17.0, watchOS 10.0, *)
public enum SwissFlowArrangement {
    /// Where each item goes and how large the whole is.
    public struct Result: Sendable, Hashable {
        /// Each item's top-leading corner, in the order given.
        public let origins: [CGPoint]
        /// The line each item is on, from 0.
        public let lines: [Int]
        /// The size the flow takes.
        public let size: CGSize
    }

    /// Places items of the given sizes in a container `width` points wide.
    ///
    /// - Parameters:
    ///   - sizes: Each item's size.
    ///   - width: The container's width; a non-finite width means one unbroken line.
    ///   - spacing: The space between items on a line.
    ///   - lineSpacing: The space between lines.
    ///
    /// Items on a line are centred vertically on it.
    public static func place(sizes: [CGSize], width: CGFloat, spacing: CGFloat, lineSpacing: CGFloat) -> Result {
        let limit = width.isFinite ? width : .greatestFiniteMagnitude
        var rows: [[Int]] = [[]]
        var rowWidth: CGFloat = 0
        for (index, size) in sizes.enumerated() {
            let needed = rows[rows.count - 1].isEmpty ? size.width : rowWidth + spacing + size.width
            if needed > limit, !rows[rows.count - 1].isEmpty {
                rows.append([index])
                rowWidth = size.width
            } else {
                rows[rows.count - 1].append(index)
                rowWidth = needed
            }
        }
        var origins = [CGPoint](repeating: .zero, count: sizes.count)
        var lines = [Int](repeating: 0, count: sizes.count)
        var y: CGFloat = 0
        var widest: CGFloat = 0
        for (line, row) in rows.enumerated() where !row.isEmpty {
            let height = row.map { sizes[$0].height }.max() ?? 0
            var x: CGFloat = 0
            for index in row {
                origins[index] = CGPoint(x: x, y: y + (height - sizes[index].height) / 2)
                lines[index] = line
                x += sizes[index].width + spacing
            }
            widest = max(widest, x - spacing)
            y += height + lineSpacing
        }
        let total = rows.contains { !$0.isEmpty } ? y - lineSpacing : 0
        return Result(origins: origins, lines: lines, size: CGSize(width: widest, height: total))
    }
}

/// Lays its subviews out left to right and wraps onto a new line when the next one would not fit: for chips, platform tags and a
/// card footer's names. Spacing defaults come from the theme through ``SwissFlow``.
@available(macOS 14.0, iOS 17.0, visionOS 1.0, tvOS 17.0, watchOS 10.0, *)
public struct SwissFlowLayout: Layout {
    private let spacing: CGFloat
    private let lineSpacing: CGFloat

    /// Creates a flow.
    ///
    /// - Parameters:
    ///   - spacing: The space between items on a line.
    ///   - lineSpacing: The space between lines; defaults to `spacing`.
    public init(spacing: CGFloat, lineSpacing: CGFloat? = nil) {
        self.spacing = spacing
        self.lineSpacing = lineSpacing ?? spacing
    }

    private func sizes(_ subviews: Subviews, width: CGFloat?) -> [CGSize] {
        let proposal = ProposedViewSize(width: width, height: nil)
        return subviews.map { $0.sizeThatFits(proposal) }
    }

    /// The flow's size for a proposal.
    public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width.flatMap { $0.isFinite ? $0 : nil }
        let result = SwissFlowArrangement.place(sizes: sizes(subviews, width: width), width: width ?? .infinity,
                                                spacing: spacing, lineSpacing: lineSpacing)
        return CGSize(width: width.map { min($0, result.size.width) } ?? result.size.width, height: result.size.height)
    }

    /// Places the subviews.
    public func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let measured = sizes(subviews, width: bounds.width)
        let result = SwissFlowArrangement.place(sizes: measured, width: bounds.width, spacing: spacing, lineSpacing: lineSpacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.origins[index].x, y: bounds.minY + result.origins[index].y),
                          anchor: .topLeading, proposal: ProposedViewSize(measured[index]))
        }
    }
}

/// A ``SwissFlowLayout`` with the theme's spacing: one base-unit step of two between items and lines.
@available(macOS 14.0, iOS 17.0, visionOS 1.0, tvOS 17.0, watchOS 10.0, *)
public struct SwissFlow<Content: View>: View {
    private let content: Content

    /// Creates a flow of the content's views.
    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    /// The flow.
    public var body: some View {
        ChartStyleReader { style in
            let metrics = SwissMetrics(theme: style.theme)
            SwissFlowLayout(spacing: metrics.step(2), lineSpacing: metrics.step(1)) { content }
        }
    }
}

// MARK: Equal-height grid

/// The column and row arithmetic of ``SwissEqualGridLayout``.
@available(macOS 14.0, iOS 17.0, visionOS 1.0, tvOS 17.0, watchOS 10.0, *)
public enum SwissEqualGridArrangement {
    /// How many columns of at least `minimumWidth` fit in `width`, at least one.
    public static func columns(width: CGFloat, minimumWidth: CGFloat, spacing: CGFloat) -> Int {
        guard width.isFinite, minimumWidth > 0 else { return 1 }
        let fit = ((width + spacing) / (minimumWidth + spacing)).rounded(.down)
        guard fit.isFinite, fit >= 1 else { return 1 }
        guard fit < 10_000 else { return 10_000 }
        return Int(fit)
    }

    /// The width of each column when `columns` share `width`.
    public static func columnWidth(width: CGFloat, columns: Int, spacing: CGFloat) -> CGFloat {
        guard columns > 0 else { return width }
        return max(0, (width - spacing * CGFloat(columns - 1)) / CGFloat(columns))
    }

    /// The height of each row: the tallest of its children, `columns` to a row.
    public static func rowHeights(_ heights: [CGFloat], columns: Int) -> [CGFloat] {
        guard columns > 0 else { return [] }
        return stride(from: 0, to: heights.count, by: columns).map { start in
            heights[start..<min(start + columns, heights.count)].max() ?? 0
        }
    }
}

/// Equal-width columns, as many as fit at the minimum width, each row as tall as its tallest child. The children are offered the
/// row's height, so a ``SwissCard`` can pin its footer to the bottom edge, and a last child on its own keeps the width of the others.
@available(macOS 14.0, iOS 17.0, visionOS 1.0, tvOS 17.0, watchOS 10.0, *)
public struct SwissEqualGridLayout: Layout {
    private let minimumColumnWidth: CGFloat
    private let spacing: CGFloat

    /// Creates the layout.
    public init(minimumColumnWidth: CGFloat, spacing: CGFloat) {
        self.minimumColumnWidth = minimumColumnWidth
        self.spacing = spacing
    }

    private func rowHeights(_ subviews: Subviews, width: CGFloat) -> [CGFloat] {
        let columns = SwissEqualGridArrangement.columns(width: width, minimumWidth: minimumColumnWidth, spacing: spacing)
        let columnWidth = SwissEqualGridArrangement.columnWidth(width: width, columns: columns, spacing: spacing)
        let heights = subviews.map { $0.sizeThatFits(ProposedViewSize(width: columnWidth, height: nil)).height }
        return SwissEqualGridArrangement.rowHeights(heights, columns: columns)
    }

    /// The grid's size for a proposal.
    public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let proposed = proposal.width.flatMap { $0.isFinite ? $0 : nil }
        let width = proposed ?? minimumColumnWidth
        let rows = rowHeights(subviews, width: width)
        return CGSize(width: width, height: rows.reduce(0, +) + spacing * CGFloat(max(0, rows.count - 1)))
    }

    /// Places the subviews.
    public func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let columns = SwissEqualGridArrangement.columns(width: bounds.width, minimumWidth: minimumColumnWidth, spacing: spacing)
        let columnWidth = SwissEqualGridArrangement.columnWidth(width: bounds.width, columns: columns, spacing: spacing)
        let rows = rowHeights(subviews, width: bounds.width)
        var y = bounds.minY
        for (rowIndex, rowHeight) in rows.enumerated() {
            for column in 0..<columns {
                let index = rowIndex * columns + column
                guard index < subviews.count else { break }
                subviews[index].place(at: CGPoint(x: bounds.minX + CGFloat(column) * (columnWidth + spacing), y: y),
                                      anchor: .topLeading, proposal: ProposedViewSize(width: columnWidth, height: rowHeight))
            }
            y += rowHeight + spacing
        }
    }
}

@available(macOS 14.0, iOS 17.0, visionOS 1.0, tvOS 17.0, watchOS 10.0, *)
extension SwissMetrics {
    /// The least width of a card column in an equal grid: seventy base units (280 pt in Swiss), so a card keeps a readable measure.
    public var gridMinimumColumnWidth: CGFloat { step(70) }
}

/// A grid of cards: equal-width columns, rows as tall as their tallest card, so top rules line up and the footers of a
/// ``SwissCard`` line up along the bottom of a row. The space between is the theme's gutter.
@available(macOS 14.0, iOS 17.0, visionOS 1.0, tvOS 17.0, watchOS 10.0, *)
public struct SwissEqualGrid<Content: View>: View {
    private let minimumColumnWidth: CGFloat?
    private let spacing: CGFloat?
    private let content: Content

    /// Creates a grid.
    ///
    /// - Parameters:
    ///   - minimumColumnWidth: The narrowest a column may be; `nil` is ``SwissMetrics/gridMinimumColumnWidth``.
    ///   - spacing: The space between columns and rows; `nil` is the theme's gutter.
    ///   - content: The cards.
    public init(minimumColumnWidth: CGFloat? = nil, spacing: CGFloat? = nil, @ViewBuilder content: () -> Content) {
        self.minimumColumnWidth = minimumColumnWidth
        self.spacing = spacing
        self.content = content()
    }

    /// The grid.
    public var body: some View {
        ChartStyleReader { style in
            let metrics = SwissMetrics(theme: style.theme)
            SwissEqualGridLayout(minimumColumnWidth: minimumColumnWidth ?? metrics.gridMinimumColumnWidth,
                                 spacing: spacing ?? metrics.gutter) { content }
                .environment(\.swissFillsHeight, true)
        }
    }
}

@available(macOS 14.0, iOS 17.0, visionOS 1.0, tvOS 17.0, watchOS 10.0, *)
private struct FillsHeightKey: EnvironmentKey {
    static let defaultValue = false
}

@available(macOS 14.0, iOS 17.0, visionOS 1.0, tvOS 17.0, watchOS 10.0, *)
extension EnvironmentValues {
    /// Set by ``SwissEqualGrid``: the cards inside are offered a row's height and pin their footers to its bottom.
    var swissFillsHeight: Bool {
        get { self[FillsHeightKey.self] }
        set { self[FillsHeightKey.self] = newValue }
    }
}
#endif
