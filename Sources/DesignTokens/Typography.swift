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

    /// Font size as a CSS value.
    public var size: String {
        switch self {
        case .label: "11px"
        case .caption: "13px"
        case .body: "16px"
        case .heading: "28px"
        case .title: "34px"
        case .display: "clamp(64px, 13vw, 168px)"
        }
    }

    /// Unitless line height.
    public var line: String {
        switch self {
        case .label: "1.3"
        case .caption: "1.4"
        case .body: "1.5"
        case .heading: "1.2"
        case .title: "1.12"
        case .display: "0.86"
        }
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
        switch self {
        case .label: "0.08em"
        case .caption, .body: "0"
        case .heading: "-0.02em"
        case .title: "-0.03em"
        case .display: "-0.05em"
        }
    }

    /// Whether the role is set in capitals.
    public var uppercase: Bool {
        self == .label
    }
}
