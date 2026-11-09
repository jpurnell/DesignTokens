#if canImport(SwiftUI)
import DesignTokens
import SwiftUI

/// A ``Theme`` resolved for one appearance and contrast setting, in SwiftUI types.
///
/// This is the projection BusinessMath-UI's standard views, its Editorial charts and its SVG exporters read:
/// colours (roles, series, extras, ramps, per-chart overrides), rule weights (including the title rule),
/// type roles, value-label and series-label flags, layout, marks, shadows, tag marks and number formats.
/// Nothing here is computed from a colour: every value is the theme's own, so a number that is wrong here is
/// wrong in the theme, and the theme is what the validator and the generated CSS and JSON also read.
///
/// ### Colours
/// A colour that stands for an Apple system colour (``Adaptive/system``) defers to it when the style
/// ``defersToSystemColors`` and the theme declares both appearances (the HIG says not to hard-code system
/// colours). Every other colour is the theme's stored value for the style's appearance and contrast. A
/// light-only theme keeps its light values in a dark context, because it is drawn on its own background.
///
/// A style built from an explicit appearance describes that appearance. When it defers to system colours it
/// is only right when rendered in the matching environment: build it with ``init(theme:colorScheme:contrast:defersToSystemColors:)``
/// from the environment's own values, or use ``ChartStyleReader``, which does.
@available(macOS 14.0, iOS 17.0, visionOS 1.0, tvOS 17.0, watchOS 10.0, *)
public struct ChartStyle: Sendable {
    /// The theme this style resolves.
    public let theme: Theme
    /// The appearance the style resolves for.
    public let appearance: Appearance
    /// Whether Increase Contrast is on.
    public let increasedContrast: Bool
    /// Whether colours that stand for a system colour use the system's own.
    public let defersToSystemColors: Bool

    /// Creates a style for an appearance.
    public init(theme: Theme, appearance: Appearance, increasedContrast: Bool = false, defersToSystemColors: Bool = true) {
        self.theme = theme
        self.appearance = appearance
        self.increasedContrast = increasedContrast
        self.defersToSystemColors = defersToSystemColors
    }

    /// Creates a style from the environment's colour scheme and contrast.
    public init(theme: Theme, colorScheme: ColorScheme, contrast: ColorSchemeContrast, defersToSystemColors: Bool = true) {
        self.init(theme: theme, appearance: colorScheme == .dark ? .dark : .light,
                  increasedContrast: contrast == .increased, defersToSystemColors: defersToSystemColors)
    }

    // MARK: Colours

    /// The colour for an adaptive value in this style.
    public func color(_ adaptive: Adaptive) -> Color {
        if defersToSystemColors, theme.appearances == .both, let system = adaptive.system {
            return system.color
        }
        return adaptive.value(in: appearance, increasedContrast: increasedContrast).color
    }

    /// The stored value (hex, alpha) for an adaptive colour in this style, for renderers that write strings
    /// (SVG). It is never the system colour: a system colour has no hex until it is resolved.
    public func value(_ adaptive: Adaptive) -> ColorValue {
        adaptive.value(in: appearance, increasedContrast: increasedContrast)
    }

    /// The colour of a role.
    public func color(_ role: ColorRole) -> Color { color(theme.palette[role]) }
    /// The stored value of a role, for string renderers.
    public func value(_ role: ColorRole) -> ColorValue { value(theme.palette[role]) }
    /// The stored value of a role as `#RRGGBB` or `#RRGGBBAA`.
    public func hex(_ role: ColorRole) -> String { value(role).hex }

    /// Primary content colour.
    public var ink: Color { color(.ink) }
    /// De-emphasised content colour.
    public var secondaryInk: Color { color(.secondaryInk) }
    /// The primary surface.
    public var background: Color { color(.background) }
    /// The card surface.
    public var surface: Color { color(.surface) }
    /// Hairlines, borders and faint gridlines.
    public var rule: Color { color(.rule) }
    /// The accent.
    public var accent: Color { color(.accent) }
    /// Text and marks on the accent.
    public var onAccent: Color { color(.onAccent) }
    /// Link text.
    public var link: Color { color(.link) }
    /// Favourable change (a gain).
    public var positive: Color { color(.positive) }
    /// Unfavourable change (a loss).
    public var negative: Color { color(.negative) }
    /// Caution.
    public var warning: Color { color(.warning) }
    /// De-emphasised marks.
    public var muted: Color { color(.muted) }

    /// A named colour beyond the twelve roles (`primary`, `info`, `highlight`, `subtle`, `emphasis`, `neutral`,
    /// `shadow` in the legacy themes), or `nil` when the theme has none by that name.
    public func extra(_ name: String) -> Color? { theme.palette.extras[name].map(color) }

    /// The neutral colour: the theme's `neutral` extra, else its muted role.
    public var neutral: Color { extra("neutral") ?? muted }

    /// The colour a ``ColourReference`` names (a role or an extra), at its opacity, or `nil` for an unknown name.
    public func color(_ reference: ColourReference) -> Color? {
        let base: Color?
        if let role = ColorRole(rawValue: reference.source) {
            base = color(role)
        } else {
            base = extra(reference.source)
        }
        return base.map { reference.opacity < 1 ? $0.opacity(reference.opacity) : $0 }
    }

    /// The theme's override for a per-chart colour key (`"tornado.low"`), or `nil` when the theme has none and
    /// the view should use its own standard mapping.
    public func override(forKey key: String) -> Color? {
        theme.palette.colourOverrides[key].flatMap { color($0) }
    }

    // MARK: Series and ramps

    /// The number of series colours.
    public var seriesCount: Int { theme.palette.series.count }
    /// The series names, in order.
    public var seriesNames: [String] { theme.palette.series.map(\.name) }

    /// The series colour at an index; the index wraps. A theme with no series returns the accent.
    public func series(_ index: Int) -> Color {
        let series = theme.palette.series
        guard !series.isEmpty else { return accent }
        let wrapped = ((index % series.count) + series.count) % series.count
        return color(series[wrapped].color)
    }

    /// Every series colour, in order.
    public var seriesColors: [Color] { theme.palette.series.map { color($0.color) } }

    /// The stored value of a series colour; the index wraps. A theme with no series returns the accent.
    public func seriesValue(_ index: Int) -> ColorValue {
        let series = theme.palette.series
        guard !series.isEmpty else { return value(.accent) }
        let wrapped = ((index % series.count) + series.count) % series.count
        return value(series[wrapped].color)
    }

    /// A point on the sequential ramp, 0 to 1. Uses the dark ramp in dark when the theme has one.
    public func sequential(_ position: Double) -> Color {
        (theme.palette.sequential.sample(position, dark: appearance == .dark)?.color) ?? neutral
    }

    /// A point on the diverging ramp, 0 to 1.
    public func diverging(_ position: Double) -> Color {
        (theme.palette.diverging.sample(position, dark: appearance == .dark)?.color) ?? neutral
    }

    /// A point on a ramp by name (`"sequential"`, `"diverging"`, or an extra ramp such as `"sharpe"`).
    public func ramp(named name: String, _ position: Double) -> Color? {
        let ramp: Ramp?
        switch name {
        case "sequential": ramp = theme.palette.sequential
        case "diverging": ramp = theme.palette.diverging
        default: ramp = theme.palette.extraRamps[name]
        }
        return ramp?.sample(position, dark: appearance == .dark)?.color
    }

    /// The ramp a per-chart gradient key maps to in this theme (`"efficientfrontier"` to `"sharpe"`), or `nil`.
    public func rampName(forKey key: String) -> String? { theme.palette.rampOverrides[key] }

    /// The stops of a ramp as colours, for a gradient.
    public func rampStops(named name: String) -> [Color]? {
        let ramp: Ramp?
        switch name {
        case "sequential": ramp = theme.palette.sequential
        case "diverging": ramp = theme.palette.diverging
        default: ramp = theme.palette.extraRamps[name]
        }
        guard let ramp else { return nil }
        return ((appearance == .dark ? ramp.dark : nil) ?? ramp.light).map(\.color)
    }

    // MARK: Rules

    /// A rule: its weight, colour and, for the title rule, where it is drawn.
    public struct Rule: Sendable {
        /// Weight in points.
        public var weight: CGFloat
        /// The rule's colour.
        public var color: Color
        /// Where the title rule is drawn.
        public var position: TitleRulePosition
        /// Inset from each edge, in points.
        public var inset: CGFloat
        /// The space between the rule and the title when the rule is above the title: the theme's `gapAfter`, else
        /// the title gap.
        public var gap: CGFloat
    }

    /// The heavy title rule, or `nil` when the theme has none (weight 0 or position `.none`).
    public var titleRule: Rule? {
        let rule = theme.structure.rules.title
        guard rule.weight > 0, rule.position != .none else { return nil }
        return Rule(weight: CGFloat(rule.weight), color: color(rule.colour), position: rule.position, inset: CGFloat(rule.inset),
                    gap: CGFloat(rule.gapAfter ?? theme.structure.layout.gaps.title))
    }

    /// The space between a title rule above the title and the title, in points: the theme's `gapAfter`, else the
    /// title gap. Meaningful for a rule that is ``TitleRulePosition/aboveTitle``.
    public var titleRuleGap: CGFloat { CGFloat(theme.structure.rules.title.gapAfter ?? theme.structure.layout.gaps.title) }

    /// The new-section rule weight.
    public var sectionRuleWeight: CGFloat { CGFloat(theme.structure.rules.section) }
    /// The hairline weight.
    public var hairlineWeight: CGFloat { CGFloat(theme.structure.rules.hairline) }
    /// The gridline weight.
    public var gridlineWeight: CGFloat { CGFloat(theme.structure.rules.gridline) }
    /// The gridline colour: the `rule` role.
    public var gridlineColor: Color { rule }
    /// The baseline weight.
    public var baselineWeight: CGFloat { CGFloat(theme.structure.rules.baseline) }
    /// The page-header rule weight.
    public var pageRuleWeight: CGFloat { CGFloat(theme.structure.rules.page) }
    /// The plot border weight; 0 is none.
    public var plotBorderWeight: CGFloat { CGFloat(theme.structure.rules.plotBorder) }
    /// Whether a plot border is drawn.
    public var hasPlotBorder: Bool { theme.structure.rules.plotBorder > 0 }

    /// The baseline's colour: ink in Swiss, the `rule` role in the themes that did not say.
    public var baselineColor: Color { color(theme.structure.rules.baselineColour) }
    /// The colour of a reference (target) line.
    public var referenceColor: Color { color(theme.structure.rules.referenceColour) }
    /// The colour of a reference line's direct label: ink in Swiss, so it reads on the line.
    public var referenceLabelColor: Color { color(theme.structure.rules.referenceLabelColour) }
    /// The gap between a reference line and its label, in points.
    public var referenceLabelGap: CGFloat { CGFloat(theme.structure.layout.gaps.referenceLabel) }

    /// The stroke of a reference line. Solid (no dash) in Swiss, a hairline.
    public var referenceStroke: StrokeStyle {
        let line = theme.structure.rules.reference
        return StrokeStyle(lineWidth: CGFloat(line.weight), dash: line.dash.map { CGFloat($0) })
    }

    // MARK: Labels

    /// How the theme labels values on data.
    public var valueLabels: ValueLabels { theme.structure.labels.values }

    /// Whether to draw value labels: a view's own setting when it has one, otherwise the theme's.
    ///
    /// - Parameter override: The view's `showValues`, `nil` when the caller did not say.
    public func showsValueLabels(override: Bool? = nil) -> Bool {
        override ?? (theme.structure.labels.values != .off)
    }

    /// How series are named: a legend, direct labels, or both.
    public var seriesLabeling: SeriesLabeling { theme.structure.labels.series }
    /// The side the value axis is on.
    public var axisSide: Side { theme.structure.labels.axisSide }
    /// Where axis labels sit relative to their gridline.
    public var axisLabelPlacement: AxisLabelPlacement { theme.structure.labels.axisLabelPlacement }
    /// Whether a source line is drawn.
    public var showsSourceLine: Bool { theme.structure.labels.sourceLine }

    /// Points of background-coloured stroke behind value and reference labels; 0 is none.
    public var valueHalo: CGFloat { CGFloat(theme.structure.labels.valueHalo) }
    /// Whether value labels get a halo.
    public var hasValueHalo: Bool { theme.structure.labels.valueHalo > 0 }
    /// The halo's colour: the theme's background, so the stroke hides the gridline or target line behind the text.
    ///
    /// **The rule: the halo must match the surface actually painted behind the text.** This is the theme's background,
    /// which is right when the chart paints that background itself. A light-only theme (Princeton) in a dark context
    /// keeps its light colours (dark ink, light background); drawn on a transparent surface over a dark page, the halo
    /// is then a thick white shadow. Either paint the background (``paintsOwnSurface`` says when it is needed), or pass
    /// the surface that is behind the text to ``valueHaloColor(over:)``.
    public var valueHaloColor: Color { background }

    /// The halo's colour over a surface the caller paints behind the text (`nil`: the theme's own background).
    public func valueHaloColor(over surface: Color) -> Color { surface }

    /// The stored value of the halo's colour, for string renderers: `surface` when the caller paints one behind the
    /// text, else the theme's background.
    public func valueHaloValue(over surface: ColorValue? = nil) -> ColorValue { surface ?? value(.background) }

    /// Whether the chart must paint its own background to be legible: the theme has no dark values (light-only or
    /// fixed-dark) and the style is for a dark context, so its colours are not the surround's. Princeton in dark is the
    /// case. A renderer that leaves the surface transparent in this case draws dark ink and a light halo on a dark page.
    public var paintsOwnSurface: Bool { theme.appearances != .both && appearance == .dark }

    // MARK: Layout

    /// Margins around a chart.
    public var margins: EdgeInsets {
        let m = theme.structure.layout.margins
        return EdgeInsets(top: CGFloat(m.top), leading: CGFloat(m.leading), bottom: CGFloat(m.bottom), trailing: CGFloat(m.trailing))
    }
    /// Gap between the title and subtitle.
    public var titleGap: CGFloat { CGFloat(theme.structure.layout.gaps.title) }
    /// Gap between the subtitle and the plot.
    public var subtitleGap: CGFloat { CGFloat(theme.structure.layout.gaps.subtitle) }
    /// Gap around the plot.
    public var plotGap: CGFloat { CGFloat(theme.structure.layout.gaps.plot) }
    /// Gap between the plot and the source line.
    public var sourceGap: CGFloat { CGFloat(theme.structure.layout.gaps.source) }
    /// Gutter between grid columns.
    public var gutter: CGFloat { CGFloat(theme.structure.layout.gutter) }
    /// Number of grid columns.
    public var columns: Int { theme.structure.layout.columns }
    /// The base spacing unit.
    public var baseUnit: CGFloat { CGFloat(theme.structure.layout.baseUnit) }
    /// Container corner radius.
    public var containerRadius: CGFloat { CGFloat(theme.structure.layout.containerRadius) }
    /// Control corner radius.
    public var controlRadius: CGFloat { CGFloat(theme.structure.layout.controlRadius) }
    /// Annotation and tooltip card corner radius.
    public var annotationRadius: CGFloat { CGFloat(theme.structure.layout.annotationRadius) }
    /// Gridline style.
    public var gridlines: GridlineStyle { theme.structure.layout.gridlines }
    /// The weight of the card border; 0 is none (Swiss's default: an option, see ``Theme/withCardBorder(_:padding:)``).
    public var cardBorderWeight: CGFloat { CGFloat(theme.structure.layout.cardBorder) }
    /// Whether the card has a border.
    public var hasCardBorder: Bool { theme.structure.layout.cardBorder > 0 }
    /// The card border's colour: the `rule` role.
    public var cardBorderColor: Color { rule }
    /// Padding inside the card border, in points.
    public var cardPadding: CGFloat { CGFloat(theme.structure.layout.cardPadding) }

    /// A drop shadow.
    public struct Shadow: Sendable {
        /// The shadow colour, at its opacity.
        public var color: Color
        /// Blur radius.
        public var radius: CGFloat
        /// Horizontal offset.
        public var x: CGFloat
        /// Vertical offset.
        public var y: CGFloat
    }

    /// The card shadow, or `nil` for flat surfaces.
    public var shadow: Shadow? {
        guard let spec = theme.structure.layout.shadow, let color = color(spec.colour) else { return nil }
        return Shadow(color: color, radius: CGFloat(spec.radius), x: CGFloat(spec.x), y: CGFloat(spec.y))
    }

    // MARK: Marks

    /// Line width.
    public var lineWidth: CGFloat { CGFloat(theme.structure.marks.lineWidth) }
    /// Point size, in square points.
    public var pointSize: CGFloat { CGFloat(theme.structure.marks.pointSize) }
    /// Opacity of confidence bands.
    public var bandOpacity: Double { theme.structure.marks.bandOpacity }
    /// Opacity of an area fill.
    public var areaOpacity: Double { theme.structure.marks.areaOpacity }
    /// Opacity of box and slice fills.
    public var fillOpacity: Double { theme.structure.marks.fillOpacity }
    /// Line width of detail strokes.
    public var detailLineWidth: CGFloat { CGFloat(theme.structure.marks.detailLineWidth) }
    /// Line width of a selected series.
    public var selectedLineWidth: CGFloat { CGFloat(theme.structure.marks.selectedLineWidth) }
    /// How bars are filled.
    public var barFill: BarFill { theme.structure.marks.barFill }
    /// Bar width as a fraction of its slot.
    public var barWidthRatio: CGFloat { CGFloat(theme.structure.marks.barWidthRatio) }
    /// Bar corner radius.
    public var barCornerRadius: CGFloat { CGFloat(theme.structure.marks.barCornerRadius) }
    /// The end of a line series.
    public var lineEnd: LineEnd { theme.structure.marks.lineEnd }

    /// A block in the chart's top-left corner.
    public struct Tag: Sendable {
        /// Width.
        public var width: CGFloat
        /// Height.
        public var height: CGFloat
        /// Fill colour.
        public var color: Color
    }

    /// The corner tag block, or `nil` when the theme has none.
    public var tag: Tag? {
        guard let mark = theme.structure.marks.tagMark else { return nil }
        return Tag(width: CGFloat(mark.width), height: CGFloat(mark.height), color: color(mark.colour))
    }

    // MARK: Fills and emphasis

    /// What an un-emphasised mark is filled with: the series colours, or the neutral grey.
    public var defaultMarkFill: MarkFill { theme.structure.marks.defaultFill }
    /// Which mark the theme emphasises when the author names none.
    public var defaultEmphasis: EmphasisDefault { theme.structure.marks.defaultEmphasis }
    /// The colour of an emphasised mark: the theme's `emphasisFill` role (the accent).
    public var emphasisColour: Color { color(theme.structure.marks.emphasisFill) }
    /// The stored value of ``emphasisColour``, for string renderers.
    public var emphasisValue: ColorValue { value(theme.structure.marks.emphasisFill) }

    /// The index of the mark the theme emphasises when the author names none, or `nil` (see ``MarkSpec/defaultEmphasisIndex(count:isVertical:)``).
    public func defaultEmphasisIndex(count: Int, isVertical: Bool) -> Int? {
        theme.structure.marks.defaultEmphasisIndex(count: count, isVertical: isVertical)
    }

    /// The fill of a mark.
    ///
    /// An emphasised mark takes ``emphasisColour``. Any other takes the neutral grey when the theme's default fill is
    /// neutral, or when the author named an emphasis (naming emphasis always greys the rest, whatever the theme's
    /// default), and the series colour otherwise.
    ///
    /// - Parameters:
    ///   - emphasised: Whether this mark is emphasised.
    ///   - emphasisNamed: Whether the author named an emphasis for the chart (so the others are greyed).
    ///   - series: The series index, for a theme whose default fill is the series colours; it wraps.
    public func markFill(emphasised: Bool, emphasisNamed: Bool = false, series index: Int = 0) -> Color {
        if emphasised { return emphasisColour }
        if emphasisNamed || defaultMarkFill == .muted { return muted }
        return series(index)
    }

    /// The stored value of ``markFill(emphasised:emphasisNamed:series:)``, for string renderers.
    public func markFillValue(emphasised: Bool, emphasisNamed: Bool = false, series index: Int = 0) -> ColorValue {
        if emphasised { return emphasisValue }
        if emphasisNamed || defaultMarkFill == .muted { return value(.muted) }
        return seriesValue(index)
    }

    /// The grey of the nth non-emphasised series when two or three series are drawn and some are emphasised: the
    /// secondary ink, then the muted grey, which it stays at from then on (the audit's ladder: #6A6D72 then #B9BBBD
    /// in light, #9A9DA2 then #4E5053 in dark).
    public func neutralLadder(_ rank: Int) -> Color { rank <= 0 ? secondaryInk : muted }

    /// The stored value of ``neutralLadder(_:)``.
    public func neutralLadderValue(_ rank: Int) -> ColorValue { rank <= 0 ? value(.secondaryInk) : value(.muted) }

    // MARK: Numbers

    /// The number format for a kind of quantity. It is a specification; formatting stays in the renderer.
    public func numberFormat(_ kind: NumberKind) -> NumberFormatSpec { theme.structure.numbers[kind] }

    /// The fraction digits to show for a kind of quantity (see ``NumberFormatSpec/fractionDigits``), or `nil` for the
    /// renderer's default.
    public func fractionDigits(_ kind: NumberKind) -> ClosedRange<Int>? { theme.structure.numbers[kind].fractionDigits }
}

@available(macOS 14.0, iOS 17.0, visionOS 1.0, tvOS 17.0, watchOS 10.0, *)
extension ColorValue {
    /// The SwiftUI colour, in sRGB, with the value's alpha.
    public var color: Color {
        Color(.sRGB, red: Double(rgb.red) / 255, green: Double(rgb.green) / 255, blue: Double(rgb.blue) / 255, opacity: alpha)
    }
}

@available(macOS 14.0, iOS 17.0, visionOS 1.0, tvOS 17.0, watchOS 10.0, *)
extension SystemColorName {
    /// The SwiftUI system colour this name stands for.
    public var color: Color {
        switch self {
        case .orange: .orange
        case .indigo: .indigo
        case .green: .green
        case .purple: .purple
        case .yellow: .yellow
        case .blue: .blue
        case .red: .red
        case .cyan: .cyan
        case .pink: .pink
        case .mint: .mint
        case .gray: .gray
        }
    }
}

@available(macOS 14.0, iOS 17.0, visionOS 1.0, tvOS 17.0, watchOS 10.0, *)
extension Color {
    /// A theme's colour for a role, in an appearance.
    public init(theme: Theme, role: ColorRole, appearance: Appearance, increasedContrast: Bool = false,
                defersToSystemColors: Bool = true) {
        self = ChartStyle(theme: theme, appearance: appearance, increasedContrast: increasedContrast,
                          defersToSystemColors: defersToSystemColors).color(role)
    }
}
#endif
