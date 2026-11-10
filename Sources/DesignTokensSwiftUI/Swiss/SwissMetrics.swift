#if canImport(SwiftUI)
import DesignTokens
import SwiftUI

/// Spacing, rule weights, radii and the 12-column grid of a theme, in points: the numbers every Swiss component reads, so no view
/// contains one.
@available(macOS 14.0, iOS 17.0, visionOS 1.0, tvOS 17.0, watchOS 10.0, *)
public struct SwissMetrics: Sendable, Hashable {
    /// The base unit every spacing is a multiple of (the theme's `baseUnit`; 4 pt in Swiss).
    public let unit: CGFloat
    /// The gutter between grid columns (16 pt).
    public let gutter: CGFloat
    /// The hairline: captions, row separation (1 pt).
    public let hairline: CGFloat
    /// The section rule (3 pt).
    public let sectionRule: CGFloat
    /// The page rule (8 pt).
    public let pageRule: CGFloat
    /// A container's corner radius (0: square).
    public let containerRadius: CGFloat
    /// A control's corner radius (4 pt).
    public let controlRadius: CGFloat
    /// An outlined chip's outline: twice the hairline, so a state reads at a glance without being a section rule.
    public let chipOutline: CGFloat
    /// The theme's 12-column grid.
    public let grid: SwissGrid

    /// Reads the metrics from a theme's structure.
    public init(theme: Theme) {
        let layout = theme.structure.layout
        let rules = theme.structure.rules
        unit = CGFloat(layout.baseUnit)
        gutter = CGFloat(layout.gutter)
        hairline = CGFloat(rules.hairline)
        sectionRule = CGFloat(rules.section)
        pageRule = CGFloat(rules.page)
        containerRadius = CGFloat(layout.containerRadius)
        controlRadius = CGFloat(layout.controlRadius)
        chipOutline = 2 * CGFloat(rules.hairline)
        grid = SwissGrid(columns: layout.columns, gutter: CGFloat(layout.gutter))
    }

    /// The space between a segmented control's border and its selected segment, on every side: one base unit (4 pt in Swiss). The
    /// border's own line is added to it by the control, so the gap that is seen is this value.
    public var segmentInset: CGFloat { step(1) }

    /// The selected segment's corner radius: concentric with the control's border, so the outer radius less the inset and the border
    /// (floored at 0: square in Swiss, where 4 pt minus 5 pt is nothing).
    public var segmentRadius: CGFloat { max(controlRadius - segmentInset - hairline, 0) }

    /// `count` base units.
    public func step(_ count: Int) -> CGFloat { unit * CGFloat(count) }

    /// A container's shape: square in Swiss (a card, a panel).
    public var containerShape: RoundedRectangle { RoundedRectangle(cornerRadius: containerRadius) }
    /// A control's shape: the control radius (a chip, a segment, a field).
    public var controlShape: RoundedRectangle { RoundedRectangle(cornerRadius: controlRadius) }
}

/// The 12-column grid: where a column starts and how wide a span is, for a container of a given width. The label column is
/// columns 1 to 3 and the reading column 4 to 10 (``Grid/label``, ``Grid/reading``).
@available(macOS 14.0, iOS 17.0, visionOS 1.0, tvOS 17.0, watchOS 10.0, *)
public struct SwissGrid: Sendable, Hashable {
    /// The number of columns.
    public let columns: Int
    /// The gutter between columns, in points.
    public let gutter: CGFloat

    /// Creates a grid.
    public init(columns: Int, gutter: CGFloat) {
        self.columns = columns
        self.gutter = gutter
    }

    /// The label column: columns 1 to 3.
    public var label: ClosedRange<Int> { Grid.label }
    /// The reading column: columns 4 to 10.
    public var reading: ClosedRange<Int> { Grid.reading }

    /// One column's width in a container `total` points wide; 0 when the gutters leave no room.
    public func columnWidth(in total: CGFloat) -> CGFloat {
        guard columns > 0 else { return 0 }
        return max((total - gutter * CGFloat(columns - 1)) / CGFloat(columns), 0)
    }

    /// The leading edge of a column (1-based).
    public func x(ofColumn column: Int, in total: CGFloat) -> CGFloat {
        CGFloat(max(column - 1, 0)) * (columnWidth(in: total) + gutter)
    }

    /// The width of a span of columns, including the gutters between them.
    public func width(of span: ClosedRange<Int>, in total: CGFloat) -> CGFloat {
        let count = span.count
        guard count > 0 else { return 0 }
        return CGFloat(count) * columnWidth(in: total) + CGFloat(count - 1) * gutter
    }
}

/// A rule: a weight from the theme's rule scale, in a colour.
@available(macOS 14.0, iOS 17.0, visionOS 1.0, tvOS 17.0, watchOS 10.0, *)
public struct SwissRule: View {
    /// The weight, by its place in the hierarchy.
    public enum Weight: Sendable, Hashable, CaseIterable {
        /// Row separation, captions.
        case hairline
        /// A new section.
        case section
        /// The page header.
        case page
    }

    /// The colour.
    public enum Tone: Sendable, Hashable {
        /// The theme's `rule` colour: between rows, around a card.
        case neutral
        /// Ink: a section's heavy rule, a card's footer rule.
        case ink
    }

    private let weight: Weight
    private let tone: Tone
    @Environment(\.theme) private var theme
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.colorSchemeContrast) private var contrast

    /// Creates a rule. The default is a neutral hairline.
    public init(_ weight: Weight = .hairline, tone: Tone? = nil) {
        self.weight = weight
        self.tone = tone ?? (weight == .hairline ? .neutral : .ink)
    }

    /// The rule's thickness in a theme, in points.
    public static func thickness(_ weight: Weight, theme: Theme) -> CGFloat {
        let metrics = SwissMetrics(theme: theme)
        switch weight {
        case .hairline: return metrics.hairline
        case .section: return metrics.sectionRule
        case .page: return metrics.pageRule
        }
    }

    /// The rule.
    public var body: some View {
        let style = ChartStyle(theme: theme, colorScheme: colorScheme, contrast: contrast)
        Rectangle()
            .fill(tone == .ink ? style.ink : style.rule)
            .frame(height: Self.thickness(weight, theme: theme))
            .accessibilityHidden(true)
    }
}
#endif
