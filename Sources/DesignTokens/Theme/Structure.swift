import Foundation

// MARK: - Rules

/// Where a theme draws its title rule relative to the chart title.
public enum TitleRulePosition: String, Sendable, Hashable, Codable, CaseIterable {
    /// No title rule.
    case none
    /// A rule above the title (the Economist's red rule).
    case aboveTitle
    /// A rule between the title block and the plot (Swiss).
    case belowTitle
}

/// The heavy rule that sets a chart's title off from its plot.
public struct TitleRule: Sendable, Hashable, Codable {
    /// Weight in points. 0 means none; a weight above 0 needs a position other than ``TitleRulePosition/none``.
    public var weight: Double
    /// Where the rule is drawn.
    public var position: TitleRulePosition
    /// The colour role the rule is drawn in.
    public var colour: ColorRole
    /// Inset from each edge, in points.
    public var inset: Double

    /// Creates a title rule.
    public init(weight: Double, position: TitleRulePosition, colour: ColorRole, inset: Double) {
        self.weight = weight
        self.position = position
        self.colour = colour
        self.inset = inset
    }
}

/// A line's weight and dash pattern.
public struct LineSpec: Sendable, Hashable, Codable {
    /// Weight in points.
    public var weight: Double
    /// Dash pattern in points, alternating on and off; empty is a solid line.
    public var dash: [Double]

    /// Creates a line.
    public init(weight: Double, dash: [Double]) {
        self.weight = weight
        self.dash = dash
    }
}

/// Rule weights in points. Weight is information: heavier means higher in the hierarchy.
public struct RuleSpec: Sendable, Hashable, Codable {
    /// The chart title rule.
    public var title: TitleRule
    /// The new-section rule.
    public var section: Double
    /// Hairlines.
    public var hairline: Double
    /// Gridlines.
    public var gridline: Double
    /// The baseline of a plot.
    public var baseline: Double
    /// The page-header rule. Not a chart weight; here so one theme describes the whole page.
    public var page: Double
    /// Reference lines.
    public var reference: LineSpec
    /// The border around a plot; 0 is none.
    public var plotBorder: Double

    /// Creates the rule weights.
    public init(title: TitleRule, section: Double, hairline: Double, gridline: Double, baseline: Double,
                page: Double, reference: LineSpec, plotBorder: Double) {
        self.title = title
        self.section = section
        self.hairline = hairline
        self.gridline = gridline
        self.baseline = baseline
        self.page = page
        self.reference = reference
        self.plotBorder = plotBorder
    }
}

// MARK: - Type

/// A font family, with a fallback for a named face, because a licensed face may not be installed.
public indirect enum FontFamilyRef: Sendable, Hashable, Codable {
    /// The system sans (``FontStack/sans``).
    case sans
    /// The system monospace (``FontStack/mono``).
    case mono
    /// New York (``FontStack/serifNewYork``).
    case serifNewYork
    /// Garamond (``FontStack/serifGaramond``).
    case serifGaramond
    /// A named face and what to use when it is missing.
    case named(String, fallback: FontFamilyRef)

    private enum CodingKeys: String, CodingKey { case kind, name, fallback }

    /// Decodes the fixed `{kind, name?, fallback?}` form.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        switch try container.decode(String.self, forKey: .kind) {
        case "sans": self = .sans
        case "mono": self = .mono
        case "serifNewYork": self = .serifNewYork
        case "serifGaramond": self = .serifGaramond
        case "named":
            self = .named(try container.decode(String.self, forKey: .name),
                          fallback: try container.decode(FontFamilyRef.self, forKey: .fallback))
        case let other:
            throw DecodingError.dataCorruptedError(forKey: .kind, in: container, debugDescription: "unknown font kind \(other)")
        }
    }

    /// Encodes the fixed `{kind, name?, fallback?}` form.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .sans: try container.encode("sans", forKey: .kind)
        case .mono: try container.encode("mono", forKey: .kind)
        case .serifNewYork: try container.encode("serifNewYork", forKey: .kind)
        case .serifGaramond: try container.encode("serifGaramond", forKey: .kind)
        case .named(let name, let fallback):
            try container.encode("named", forKey: .kind)
            try container.encode(name, forKey: .name)
            try container.encode(fallback, forKey: .fallback)
        }
    }
}

/// A platform text style, for the legacy themes whose views use the system's semantic styles rather than
/// numbers. When set, a renderer on a platform that has the style uses it; the numeric fields are the
/// fallback. Added in 0.5.0.
public enum PlatformTextStyle: String, Sendable, Hashable, Codable, CaseIterable {
    /// `.title`.
    case title
    /// `.headline`.
    case headline
    /// `.subheadline`.
    case subheadline
    /// `.body`.
    case body
    /// `.caption`.
    case caption
    /// `.caption2`.
    case caption2
}

/// One text style, in numbers a renderer can use.
public struct TextSpec: Sendable, Hashable, Codable {
    /// The family.
    public var family: FontFamilyRef
    /// Size in points. For a fluid role this is the upper bound; see ``TypeStyle/fluid``.
    public var size: Double
    /// Weight, 100 to 900.
    public var weight: Int
    /// Letter spacing in em.
    public var tracking: Double
    /// Whether it is italic.
    public var italic: Bool
    /// Whether it is set in capitals.
    public var uppercase: Bool
    /// Unitless line height.
    public var lineHeight: Double
    /// The platform text style this role stands for, when the theme defers to the platform. `nil` otherwise.
    public var platformStyle: PlatformTextStyle?

    /// Creates a text style.
    public init(family: FontFamilyRef, size: Double, weight: Int, tracking: Double, italic: Bool,
                uppercase: Bool, lineHeight: Double, platformStyle: PlatformTextStyle? = nil) {
        self.platformStyle = platformStyle
        self.family = family
        self.size = size
        self.weight = weight
        self.tracking = tracking
        self.italic = italic
        self.uppercase = uppercase
        self.lineHeight = lineHeight
    }
}

/// Every text role: the nine chart roles and the six UI roles of ``TypeStyle``.
public struct TypeRoles: Sendable, Hashable, Codable {
    /// Chart title.
    public var title: TextSpec
    /// Chart subtitle.
    public var subtitle: TextSpec
    /// Axis title.
    public var axisTitle: TextSpec
    /// Axis tick label.
    public var axisLabel: TextSpec
    /// Direct series label.
    public var seriesLabel: TextSpec
    /// Annotation.
    public var annotation: TextSpec
    /// Source line.
    public var source: TextSpec
    /// Note.
    public var note: TextSpec
    /// Tag.
    public var tag: TextSpec
    /// ``TypeStyle/label``.
    public var label: TextSpec
    /// ``TypeStyle/caption``.
    public var caption: TextSpec
    /// ``TypeStyle/body``.
    public var body: TextSpec
    /// ``TypeStyle/heading``.
    public var heading: TextSpec
    /// ``TypeStyle/title``: the page and section title (not the chart title).
    public var uiTitle: TextSpec
    /// ``TypeStyle/display``.
    public var display: TextSpec

    /// Creates the roles.
    public init(title: TextSpec, subtitle: TextSpec, axisTitle: TextSpec, axisLabel: TextSpec, seriesLabel: TextSpec,
                annotation: TextSpec, source: TextSpec, note: TextSpec, tag: TextSpec, label: TextSpec,
                caption: TextSpec, body: TextSpec, heading: TextSpec, uiTitle: TextSpec, display: TextSpec) {
        self.title = title
        self.subtitle = subtitle
        self.axisTitle = axisTitle
        self.axisLabel = axisLabel
        self.seriesLabel = seriesLabel
        self.annotation = annotation
        self.source = source
        self.note = note
        self.tag = tag
        self.label = label
        self.caption = caption
        self.body = body
        self.heading = heading
        self.uiTitle = uiTitle
        self.display = display
    }
}

public extension TypeRoles {
    /// The text style for a role.
    subscript(role: TypeRole) -> TextSpec {
        switch role {
        case .title: title
        case .subtitle: subtitle
        case .axisTitle: axisTitle
        case .axisLabel: axisLabel
        case .seriesLabel: seriesLabel
        case .annotation: annotation
        case .source: source
        case .note: note
        case .tag: tag
        case .label: label
        case .caption: caption
        case .body: body
        case .heading: heading
        case .uiTitle: uiTitle
        case .display: display
        }
    }
}

/// The fifteen text roles of ``TypeRoles``, in field order: the nine chart roles, then the six UI roles.
/// Added in 0.6.0 so a renderer or emitter can loop over them.
public enum TypeRole: String, Sendable, Hashable, Codable, CaseIterable {
    /// Chart title.
    case title
    /// Chart subtitle.
    case subtitle
    /// Axis title.
    case axisTitle
    /// Axis tick label.
    case axisLabel
    /// Direct series label.
    case seriesLabel
    /// Annotation.
    case annotation
    /// Source line.
    case source
    /// Note.
    case note
    /// Tag.
    case tag
    /// UI label.
    case label
    /// UI caption.
    case caption
    /// UI body.
    case body
    /// UI heading.
    case heading
    /// UI page and section title.
    case uiTitle
    /// UI display.
    case display

    /// Whether this is one of the six UI roles (``TypeStyle``) rather than a chart role.
    public var isUIRole: Bool {
        switch self {
        case .label, .caption, .body, .heading, .uiTitle, .display: true
        default: false
        }
    }
}

// MARK: - Labels

/// Whether and where value labels are drawn on data.
public enum ValueLabels: String, Sendable, Hashable, Codable, CaseIterable {
    /// No value labels.
    case off
    /// Above a bar, at the end of a line.
    case aboveOrEnd
    /// Inside the end of a bar.
    case insideEnd
}

/// How series are named on a chart.
public enum SeriesLabeling: String, Sendable, Hashable, Codable, CaseIterable {
    /// A legend.
    case legend
    /// Labels at the data.
    case direct
    /// Both.
    case both
}

/// A side of the plot.
public enum Side: String, Sendable, Hashable, Codable, CaseIterable {
    /// The leading edge.
    case leading
    /// The trailing edge.
    case trailing
}

/// Where axis labels sit relative to their gridline.
public enum AxisLabelPlacement: String, Sendable, Hashable, Codable, CaseIterable {
    /// Beside the axis.
    case besideAxis
    /// Above their gridline.
    case aboveGridline
}

/// How a theme labels a chart.
public struct LabelSpec: Sendable, Hashable, Codable {
    /// Value labels on data. A view's own setting overrides this when it has one.
    public var values: ValueLabels
    /// How series are named.
    public var series: SeriesLabeling
    /// The side the value axis is on.
    public var axisSide: Side
    /// Where axis labels sit.
    public var axisLabelPlacement: AxisLabelPlacement
    /// Whether a source line is drawn.
    public var sourceLine: Bool

    /// Creates label settings.
    public init(values: ValueLabels, series: SeriesLabeling, axisSide: Side,
                axisLabelPlacement: AxisLabelPlacement, sourceLine: Bool) {
        self.values = values
        self.series = series
        self.axisSide = axisSide
        self.axisLabelPlacement = axisLabelPlacement
        self.sourceLine = sourceLine
    }
}

// MARK: - Layout

/// How gridlines are drawn.
public enum GridlineStyle: String, Sendable, Hashable, Codable, CaseIterable {
    /// None.
    case none
    /// The baseline only.
    case baselineOnly
    /// Faint horizontal lines.
    case horizontalFaint
    /// Horizontal and vertical.
    case both
    /// Whatever the platform's chart framework draws by default. Named honestly: it is not a style.
    case platformAutomatic
}

/// Margins around a chart, in points.
public struct Insets: Sendable, Hashable, Codable {
    /// Top margin.
    public var top: Double
    /// Leading margin.
    public var leading: Double
    /// Bottom margin.
    public var bottom: Double
    /// Trailing margin.
    public var trailing: Double

    /// Creates insets.
    public init(top: Double, leading: Double, bottom: Double, trailing: Double) {
        self.top = top
        self.leading = leading
        self.bottom = bottom
        self.trailing = trailing
    }
}

/// The vertical gaps between a chart's parts, in points.
public struct Gaps: Sendable, Hashable, Codable {
    /// Between the title and the subtitle.
    public var title: Double
    /// Between the subtitle and the plot.
    public var subtitle: Double
    /// Around the plot.
    public var plot: Double
    /// Between the plot and the source line.
    public var source: Double

    /// Creates gaps.
    public init(title: Double, subtitle: Double, plot: Double, source: Double) {
        self.title = title
        self.subtitle = subtitle
        self.plot = plot
        self.source = source
    }
}

/// A drop shadow under a card or tooltip. Added in 0.5.0 for the legacy themes.
public struct ShadowSpec: Sendable, Hashable, Codable {
    /// The shadow colour, a role or extra.
    public var colour: ColourReference
    /// Blur radius in points.
    public var radius: Double
    /// Horizontal offset in points.
    public var x: Double
    /// Vertical offset in points.
    public var y: Double

    /// Creates a shadow.
    public init(colour: ColourReference, radius: Double, x: Double, y: Double) {
        self.colour = colour
        self.radius = radius
        self.x = x
        self.y = y
    }
}

/// Margins, gaps, the page grid, radii and gridlines.
public struct LayoutSpec: Sendable, Hashable, Codable {
    /// Margins around a chart.
    public var margins: Insets
    /// Gaps between a chart's parts.
    public var gaps: Gaps
    /// Gutter between grid columns, in points.
    public var gutter: Double
    /// Number of grid columns.
    public var columns: Int
    /// The base spacing unit, in points.
    public var baseUnit: Double
    /// Container corner radius, in points.
    public var containerRadius: Double
    /// Control corner radius, in points.
    public var controlRadius: Double
    /// Gridline style.
    public var gridlines: GridlineStyle
    /// A drop shadow under cards, or `nil` for flat surfaces (Swiss). Added in 0.5.0.
    public var shadow: ShadowSpec?
    /// Corner radius of annotation and tooltip cards, in points. Added in 0.6.0: the legacy views draw 8 as a
    /// literal while their ``containerRadius`` is 0, so the two are different quantities.
    public var annotationRadius: Double

    private enum CodingKeys: String, CodingKey {
        case margins, gaps, gutter, columns, baseUnit, containerRadius, controlRadius, gridlines, shadow
        case annotationRadius
    }

    /// Decodes a layout; a missing `annotationRadius` (JSON before 0.6.0) is 0.
    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        margins = try c.decode(Insets.self, forKey: .margins)
        gaps = try c.decode(Gaps.self, forKey: .gaps)
        gutter = try c.decode(Double.self, forKey: .gutter)
        columns = try c.decode(Int.self, forKey: .columns)
        baseUnit = try c.decode(Double.self, forKey: .baseUnit)
        containerRadius = try c.decode(Double.self, forKey: .containerRadius)
        controlRadius = try c.decode(Double.self, forKey: .controlRadius)
        gridlines = try c.decode(GridlineStyle.self, forKey: .gridlines)
        shadow = try c.decodeIfPresent(ShadowSpec.self, forKey: .shadow)
        annotationRadius = try c.decodeIfPresent(Double.self, forKey: .annotationRadius) ?? 0
    }

    /// Creates a layout.
    public init(margins: Insets, gaps: Gaps, gutter: Double, columns: Int, baseUnit: Double,
                containerRadius: Double, controlRadius: Double, gridlines: GridlineStyle,
                shadow: ShadowSpec? = nil, annotationRadius: Double = 0) {
        self.annotationRadius = annotationRadius
        self.shadow = shadow
        self.margins = margins
        self.gaps = gaps
        self.gutter = gutter
        self.columns = columns
        self.baseUnit = baseUnit
        self.containerRadius = containerRadius
        self.controlRadius = controlRadius
        self.gridlines = gridlines
    }
}

// MARK: - Marks

/// How bars are filled.
public enum BarFill: String, Sendable, Hashable, Codable, CaseIterable {
    /// A flat colour.
    case flat
    /// The platform's automatic gradient (legacy views).
    case autoGradient
}

/// The end of a line series.
public enum LineEnd: String, Sendable, Hashable, Codable, CaseIterable {
    /// Plain.
    case none
    /// A dot at the last point.
    case dot
}

/// A block drawn in the chart's top-left corner (the Economist's red tab).
public struct TagMark: Sendable, Hashable, Codable {
    /// Width in points.
    public var width: Double
    /// Height in points.
    public var height: Double
    /// The colour role it is filled with.
    public var colour: ColorRole

    /// Creates a tag mark.
    public init(width: Double, height: Double, colour: ColorRole) {
        self.width = width
        self.height = height
        self.colour = colour
    }
}

/// Mark dimensions and treatment.
public struct MarkSpec: Sendable, Hashable, Codable {
    /// Line width in points.
    public var lineWidth: Double
    /// Point size, in square points.
    public var pointSize: Double
    /// Opacity of confidence bands.
    public var bandOpacity: Double
    /// Line width of a selected series.
    public var selectedLineWidth: Double
    /// How bars are filled.
    public var barFill: BarFill
    /// Bar width as a fraction of its slot.
    public var barWidthRatio: Double
    /// Bar corner radius in points.
    public var barCornerRadius: Double
    /// The end of a line.
    public var lineEnd: LineEnd
    /// A corner tag block, if the theme has one.
    public var tagMark: TagMark?
    /// Opacity of the fill under an area series. Added in 0.6.0 (BusinessMath-UI's SVG renderer draws 0.22).
    public var areaOpacity: Double
    /// Opacity of the fill of a box, a pie slice or a violin. Added in 0.6.0 (the SVG renderer draws 0.35).
    public var fillOpacity: Double
    /// Line width of detail strokes: whiskers, box outlines, the separators between slices. Added in 0.6.0
    /// (the SVG renderer draws 1.5).
    public var detailLineWidth: Double

    /// The area opacity BusinessMath-UI draws today.
    public static let defaultAreaOpacity = 0.22
    /// The box and slice fill opacity BusinessMath-UI draws today.
    public static let defaultFillOpacity = 0.35
    /// The detail stroke width BusinessMath-UI draws today.
    public static let defaultDetailLineWidth = 1.5

    private enum CodingKeys: String, CodingKey {
        case lineWidth, pointSize, bandOpacity, selectedLineWidth, barFill, barWidthRatio, barCornerRadius
        case lineEnd, tagMark, areaOpacity, fillOpacity, detailLineWidth
    }

    /// Decodes mark settings; the three fields added in 0.6.0 take BusinessMath-UI's current values when absent.
    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        lineWidth = try c.decode(Double.self, forKey: .lineWidth)
        pointSize = try c.decode(Double.self, forKey: .pointSize)
        bandOpacity = try c.decode(Double.self, forKey: .bandOpacity)
        selectedLineWidth = try c.decode(Double.self, forKey: .selectedLineWidth)
        barFill = try c.decode(BarFill.self, forKey: .barFill)
        barWidthRatio = try c.decode(Double.self, forKey: .barWidthRatio)
        barCornerRadius = try c.decode(Double.self, forKey: .barCornerRadius)
        lineEnd = try c.decode(LineEnd.self, forKey: .lineEnd)
        tagMark = try c.decodeIfPresent(TagMark.self, forKey: .tagMark)
        areaOpacity = try c.decodeIfPresent(Double.self, forKey: .areaOpacity) ?? Self.defaultAreaOpacity
        fillOpacity = try c.decodeIfPresent(Double.self, forKey: .fillOpacity) ?? Self.defaultFillOpacity
        detailLineWidth = try c.decodeIfPresent(Double.self, forKey: .detailLineWidth) ?? Self.defaultDetailLineWidth
    }

    /// Creates mark settings.
    public init(lineWidth: Double, pointSize: Double, bandOpacity: Double, selectedLineWidth: Double,
                barFill: BarFill, barWidthRatio: Double, barCornerRadius: Double, lineEnd: LineEnd,
                tagMark: TagMark? = nil, areaOpacity: Double = MarkSpec.defaultAreaOpacity,
                fillOpacity: Double = MarkSpec.defaultFillOpacity,
                detailLineWidth: Double = MarkSpec.defaultDetailLineWidth) {
        self.areaOpacity = areaOpacity
        self.fillOpacity = fillOpacity
        self.detailLineWidth = detailLineWidth
        self.lineWidth = lineWidth
        self.pointSize = pointSize
        self.bandOpacity = bandOpacity
        self.selectedLineWidth = selectedLineWidth
        self.barFill = barFill
        self.barWidthRatio = barWidthRatio
        self.barCornerRadius = barCornerRadius
        self.lineEnd = lineEnd
        self.tagMark = tagMark
    }
}

// MARK: - Number formats

/// The specification of a number format: style, decimals and abbreviation. It is never the formatted
/// string, because formatting is locale- and platform-dependent and belongs to the renderer.
public struct NumberFormatSpec: Sendable, Hashable, Codable {
    /// The kind of number.
    public enum Style: String, Sendable, Hashable, Codable, CaseIterable {
        /// A plain decimal.
        case decimal
        /// A currency amount; the symbol is the prefix.
        case currency
        /// A proportion shown as a percentage.
        case percent
    }

    /// The kind of number.
    public var style: Style
    /// Fixed decimals; `nil` means the renderer's default for the style.
    public var decimals: Int?
    /// Whether to abbreviate thousands, millions, billions.
    public var abbreviate: Bool
    /// Text before the number.
    public var prefix: String
    /// Text after the number.
    public var suffix: String
    /// Whether a percent value is a proportion that must be multiplied by 100.
    public var percentScales: Bool

    /// Creates a number format.
    public init(style: Style = .decimal, decimals: Int? = nil, abbreviate: Bool = false, prefix: String = "",
                suffix: String = "", percentScales: Bool = true) {
        self.style = style
        self.decimals = decimals
        self.abbreviate = abbreviate
        self.prefix = prefix
        self.suffix = suffix
        self.percentScales = percentScales
    }
}

/// One number format per kind of quantity, so the same kind of value formats the same on every chart.
public struct NumberFormats: Sendable, Hashable, Codable {
    /// Money.
    public var currency: NumberFormatSpec
    /// Proportions.
    public var percent: NumberFormatSpec
    /// Counts.
    public var count: NumberFormatSpec
    /// Index values.
    public var index: NumberFormatSpec
    /// Ratios.
    public var ratio: NumberFormatSpec
    /// Temperatures.
    public var temperature: NumberFormatSpec
    /// Anything else.
    public var plain: NumberFormatSpec

    /// Creates the formats.
    public init(currency: NumberFormatSpec, percent: NumberFormatSpec, count: NumberFormatSpec,
                index: NumberFormatSpec, ratio: NumberFormatSpec, temperature: NumberFormatSpec,
                plain: NumberFormatSpec) {
        self.currency = currency
        self.percent = percent
        self.count = count
        self.index = index
        self.ratio = ratio
        self.temperature = temperature
        self.plain = plain
    }
}

/// The seven kinds of quantity in ``NumberFormats``. Added in 0.6.0 so a renderer can pick a format by kind.
public enum NumberKind: String, Sendable, Hashable, Codable, CaseIterable {
    /// Money.
    case currency
    /// Proportions.
    case percent
    /// Counts.
    case count
    /// Index values.
    case index
    /// Ratios.
    case ratio
    /// Temperatures.
    case temperature
    /// Anything else.
    case plain
}

public extension NumberFormats {
    /// The format for a kind of quantity.
    subscript(kind: NumberKind) -> NumberFormatSpec {
        switch kind {
        case .currency: currency
        case .percent: percent
        case .count: count
        case .index: index
        case .ratio: ratio
        case .temperature: temperature
        case .plain: plain
        }
    }
}

// MARK: - Structure

/// The half of a theme that is not colour: rules, type, labels, layout, marks and number formats.
public struct Structure: Sendable, Hashable, Codable {
    /// Rule weights.
    public var rules: RuleSpec
    /// Text styles.
    public var type: TypeRoles
    /// Label placement.
    public var labels: LabelSpec
    /// Layout.
    public var layout: LayoutSpec
    /// Marks.
    public var marks: MarkSpec
    /// Number formats.
    public var numbers: NumberFormats

    /// Creates a structure.
    public init(rules: RuleSpec, type: TypeRoles, labels: LabelSpec, layout: LayoutSpec, marks: MarkSpec,
                numbers: NumberFormats) {
        self.rules = rules
        self.type = type
        self.labels = labels
        self.layout = layout
        self.marks = marks
        self.numbers = numbers
    }
}
