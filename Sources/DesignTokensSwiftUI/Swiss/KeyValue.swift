#if canImport(SwiftUI)
import DesignTokens
import SwiftUI

/// Where a key/value row puts its label and value on the 12-column grid.
@available(macOS 14.0, iOS 17.0, visionOS 1.0, tvOS 17.0, watchOS 10.0, *)
public enum KeyValueGeometry {
    /// The label column, then the value column: the label in columns 1 to 3, the value in columns 4 to 10.
    public struct Columns: Sendable, Hashable {
        /// The label column's width.
        public let labelWidth: CGFloat
        /// The value column's leading edge.
        public let valueX: CGFloat
        /// The value column's width.
        public let valueWidth: CGFloat
    }

    /// The columns for a container `totalWidth` points wide, or `nil` when the label column would be narrower than
    /// `minimumLabelWidth` (a phone, or large Dynamic Type) and the row should stack its label above its value.
    public static func columns(totalWidth: CGFloat, grid: SwissGrid, minimumLabelWidth: CGFloat) -> Columns? {
        let label = grid.width(of: grid.label, in: totalWidth)
        guard label >= minimumLabelWidth else { return nil }
        return Columns(labelWidth: label, valueX: grid.x(ofColumn: grid.reading.lowerBound, in: totalWidth),
                       valueWidth: grid.width(of: grid.reading, in: totalWidth))
    }
}

/// Lays a label and a value out on the grid, first baselines aligned, or stacked when the container is too narrow.
@available(macOS 14.0, iOS 17.0, visionOS 1.0, tvOS 17.0, watchOS 10.0, *)
private struct KeyValueLayout: Layout {
    let grid: SwissGrid
    let minimumLabelWidth: CGFloat
    let stackedSpacing: CGFloat

    struct Placement {
        var label: CGRect
        var value: CGRect
        var size: CGSize
    }

    private func place(_ subviews: Subviews, width: CGFloat?) -> Placement {
        guard subviews.count == 2 else { return Placement(label: .zero, value: .zero, size: .zero) }
        let label = subviews[0], value = subviews[1]
        guard let width else {
            let l = label.sizeThatFits(.unspecified), v = value.sizeThatFits(.unspecified)
            let gap = grid.gutter
            return Placement(label: CGRect(origin: .zero, size: l), value: CGRect(x: l.width + gap, y: 0, width: v.width, height: v.height),
                             size: CGSize(width: l.width + gap + v.width, height: max(l.height, v.height)))
        }
        guard let columns = KeyValueGeometry.columns(totalWidth: width, grid: grid, minimumLabelWidth: minimumLabelWidth) else {
            let l = label.sizeThatFits(ProposedViewSize(width: width, height: nil))
            let v = value.sizeThatFits(ProposedViewSize(width: width, height: nil))
            return Placement(label: CGRect(origin: .zero, size: l),
                             value: CGRect(x: 0, y: l.height + stackedSpacing, width: v.width, height: v.height),
                             size: CGSize(width: width, height: l.height + stackedSpacing + v.height))
        }
        let l = label.sizeThatFits(ProposedViewSize(width: columns.labelWidth, height: nil))
        let v = value.sizeThatFits(ProposedViewSize(width: columns.valueWidth, height: nil))
        let lb = label.dimensions(in: ProposedViewSize(width: columns.labelWidth, height: nil))[VerticalAlignment.firstTextBaseline]
        let vb = value.dimensions(in: ProposedViewSize(width: columns.valueWidth, height: nil))[VerticalAlignment.firstTextBaseline]
        let labelTop = max(0, vb - lb), valueTop = max(0, lb - vb)
        return Placement(label: CGRect(x: 0, y: labelTop, width: l.width, height: l.height),
                         value: CGRect(x: columns.valueX, y: valueTop, width: v.width, height: v.height),
                         size: CGSize(width: width, height: max(labelTop + l.height, valueTop + v.height)))
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        place(subviews, width: proposal.width).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard subviews.count == 2 else { return }
        let placement = place(subviews, width: bounds.width)
        subviews[0].place(at: CGPoint(x: bounds.minX + placement.label.minX, y: bounds.minY + placement.label.minY),
                          anchor: .topLeading, proposal: ProposedViewSize(placement.label.size))
        subviews[1].place(at: CGPoint(x: bounds.minX + placement.value.minX, y: bounds.minY + placement.value.minY),
                          anchor: .topLeading, proposal: ProposedViewSize(placement.value.size))
    }
}

/// The row both ``KeyValueRow`` and ``SwissLabeledContentStyle`` draw.
@available(macOS 14.0, iOS 17.0, visionOS 1.0, tvOS 17.0, watchOS 10.0, *)
private struct KeyValueContent<Label: View, Value: View>: View {
    let label: Label
    let value: Value
    @Environment(\.theme) private var theme
    @ScaledMetric(relativeTo: .caption2) private var scale: CGFloat = 1

    var body: some View {
        let metrics = SwissMetrics(theme: theme)
        KeyValueLayout(grid: metrics.grid, minimumLabelWidth: metrics.step(24) * scale, stackedSpacing: metrics.step(1)) {
            label.uiText(.label)
            value.uiText(.body)
        }
        .padding(.vertical, metrics.step(2))
        .overlay(alignment: .top) { SwissRule(.hairline) }
        .accessibilityElement(children: .combine)
    }
}

/// A label and its value on the grid: the label in the label role in columns 1 to 3, the value in the body role in columns 4 to 10,
/// first baselines aligned, a neutral hairline above the row. Where the container is too narrow for a legible label column (a
/// phone, large Dynamic Type) the label stacks above the value. VoiceOver reads it as one element.
@available(macOS 14.0, iOS 17.0, visionOS 1.0, tvOS 17.0, watchOS 10.0, *)
public struct KeyValueRow<Value: View>: View {
    private let label: String
    private let value: Value

    /// Creates a row with any value view.
    public init(_ label: String, @ViewBuilder value: () -> Value) {
        self.label = label
        self.value = value()
    }

    /// The row.
    public var body: some View {
        KeyValueContent(label: Text(label), value: value)
    }
}

@available(macOS 14.0, iOS 17.0, visionOS 1.0, tvOS 17.0, watchOS 10.0, *)
public extension KeyValueRow where Value == Text {
    /// A row whose value is text.
    init(_ label: String, text: String) {
        self.init(label) { Text(text) }
    }
}

/// A list of ``KeyValueRow``s: the rows, each with its hairline above, and a closing hairline under the last.
@available(macOS 14.0, iOS 17.0, visionOS 1.0, tvOS 17.0, watchOS 10.0, *)
public struct KeyValueList<Content: View>: View {
    private let content: Content

    /// Creates a list.
    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    /// The list.
    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content
            SwissRule(.hairline)
        }
        .accessibilityElement(children: .contain)
    }
}

/// `LabeledContent` in the Swiss row: `.labeledContentStyle(.swiss)`, so a `Form` or any stack of `LabeledContent` takes the label
/// column and reading column without a second component.
@available(macOS 14.0, iOS 17.0, visionOS 1.0, tvOS 17.0, watchOS 10.0, *)
public struct SwissLabeledContentStyle: LabeledContentStyle {
    /// Creates the style.
    public init() {}

    /// The row.
    public func makeBody(configuration: Configuration) -> some View {
        KeyValueContent(label: configuration.label, value: configuration.content)
    }
}

@available(macOS 14.0, iOS 17.0, visionOS 1.0, tvOS 17.0, watchOS 10.0, *)
public extension LabeledContentStyle where Self == SwissLabeledContentStyle {
    /// The Swiss key/value row.
    static var swiss: SwissLabeledContentStyle { SwissLabeledContentStyle() }
}
#endif
