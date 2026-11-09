/// Font stacks as CSS `font-family` values.
///
/// SF with a Helvetica fallback is the default everywhere. The two serif stacks are a switch for places
/// that want a serif voice, not a second default.
public enum FontStack {
    /// The default text face: the system font, then Helvetica.
    public static let sans = "-apple-system, BlinkMacSystemFont, \"SF Pro Text\", \"SF Pro\", \"Helvetica Neue\", Helvetica, Arial, sans-serif"
    /// Figures and code.
    public static let mono = "ui-monospace, \"SF Mono\", Menlo, Consolas, monospace"
    /// Apple's New York, for long-form reading where a serif is wanted.
    public static let serifNewYork = "ui-serif, \"New York\", \"Iowan Old Style\", Georgia, serif"
    /// Garamond, for the same purpose.
    public static let serifGaramond = "\"EB Garamond\", Garamond, \"Iowan Old Style\", Georgia, serif"
}

/// The type scale: six roles with size, line height, weight and tracking.
///
/// Scale contrast is the point: a small capital label against a large display register, with little
/// in between. Sizes are CSS values so the display role can use `clamp()`.
public enum TypeStyle: Sendable, Hashable, CaseIterable {
    /// Small capitals that name things: section labels, navigation, captions' figure marks.
    case label
    /// Captions and metadata.
    case caption
    /// Running text.
    case body
    /// Group and row headings.
    case heading
    /// Page and section titles.
    case title
    /// The display register: one large statement per page.
    case display

    /// The role name used in generated files.
    public var name: String {
        switch self {
        case .label: "label"
        case .caption: "caption"
        case .body: "body"
        case .heading: "heading"
        case .title: "title"
        case .display: "display"
        }
    }

    /// Font size in points. For ``display`` this is the upper bound of its fluid range; see ``fluid``.
    public var points: Double {
        switch self {
        case .label: 11
        case .caption: 13
        case .body: 16
        case .heading: 28
        case .title: 34
        case .display: 168
        }
    }

    /// The fluid size range for a role that scales with the viewport, or `nil` for a fixed size.
    public var fluid: FluidSize? {
        switch self {
        case .display: FluidSize(min: 64, vw: 13, max: 168)
        default: nil
        }
    }

    /// Unitless line height.
    public var lineHeight: Double {
        switch self {
        case .label: 1.3
        case .caption: 1.4
        case .body: 1.5
        case .heading: 1.2
        case .title: 1.12
        case .display: 0.86
        }
    }

    /// Letter spacing in em.
    public var trackingEm: Double {
        switch self {
        case .label: 0.08
        case .caption, .body: 0
        case .heading: -0.02
        case .title: -0.03
        case .display: -0.05
        }
    }

    /// Font size as a CSS value, written from ``points`` and ``fluid`` so the two cannot disagree.
    public var size: String {
        fluid?.css ?? "\(CSSNumber.string(points))px"
    }

    /// Unitless line height as a CSS value.
    public var line: String {
        CSSNumber.string(lineHeight)
    }

    /// Font weight, 100 to 900.
    public var weight: Int {
        switch self {
        case .label: 600
        case .caption, .body: 400
        case .heading: 700
        case .title, .display: 800
        }
    }

    /// Letter spacing as a CSS value.
    public var tracking: String {
        trackingEm == 0 ? "0" : "\(CSSNumber.string(trackingEm))em"
    }

    /// Whether the role is set in capitals.
    public var uppercase: Bool {
        self == .label
    }
}

/// A font size that scales with the viewport between two bounds: CSS `clamp(min, vw, max)`.
public struct FluidSize: Sendable, Hashable, Codable {
    /// The smallest size, in points.
    public var min: Double
    /// The preferred size, in viewport-width percent.
    public var vw: Double
    /// The largest size, in points.
    public var max: Double

    /// Creates a fluid size.
    public init(min: Double, vw: Double, max: Double) {
        self.min = min
        self.vw = vw
        self.max = max
    }

    /// The CSS value, `clamp(64px, 13vw, 168px)`.
    public var css: String {
        "clamp(\(CSSNumber.string(min))px, \(CSSNumber.string(vw))vw, \(CSSNumber.string(max))px)"
    }
}

/// Writes a number the way the generated CSS has always written it: `16`, not `16.0`.
enum CSSNumber {
    static func string(_ value: Double) -> String {
        guard let whole = Int(exactly: value) else { return "\(value)" }
        return "\(whole)"
    }
}
