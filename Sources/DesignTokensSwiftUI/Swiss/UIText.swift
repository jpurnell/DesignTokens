#if canImport(SwiftUI)
import DesignTokens
import SwiftUI

/// The six UI text roles of the design system, in the register an app's interface is set in (as against the chart
/// roles, which ``ChartText`` resolves).
///
/// - `label`: small capitals, tracked, in secondary ink; what names a value or a section.
/// - `caption`: metadata and notes, in secondary ink.
/// - `body`: running text and values.
/// - `heading`: a section or group heading.
/// - `title`: a page's title (``TypeRole/uiTitle``).
/// - `display`: the one large statement.
///
/// ``UITextSpec`` says what each is set in; ``SwiftUI/View/uiText(_:)`` applies it.
@available(macOS 14.0, iOS 17.0, visionOS 1.0, tvOS 17.0, watchOS 10.0, *)
public enum UIRole: Sendable, Hashable, CaseIterable {
    /// Small capitals that name things.
    case label
    /// Captions and metadata.
    case caption
    /// Running text.
    case body
    /// Group and row headings.
    case heading
    /// Page and section titles.
    case title
    /// The display register.
    case display

    /// The theme's text role this one reads.
    public var typeRole: TypeRole {
        switch self {
        case .label: .label
        case .caption: .caption
        case .body: .body
        case .heading: .heading
        case .title: .uiTitle
        case .display: .display
        }
    }

    /// The Dynamic Type text style the role is set in.
    ///
    /// A stated mapping and not a size lookup: the tokens' sizes are CSS pixels for the web register (heading 28, title 34), and
    /// a platform's text styles differ in size (a body is 17 on iOS, 13 on macOS). The design system's decision is that Dynamic
    /// Type styles carry the UI register, so the style is chosen by role and everything else (weight, design, capitals,
    /// tracking) comes from the theme.
    public var textStyle: Font.TextStyle {
        switch self {
        case .label: .caption2
        case .caption: .footnote
        case .body: .body
        case .heading: .headline
        case .title: .title
        case .display: .largeTitle
        }
    }
}

/// What a UI role is set in, resolved from a theme: a value so a test can hold every property without rendering.
@available(macOS 14.0, iOS 17.0, visionOS 1.0, tvOS 17.0, watchOS 10.0, *)
public struct UITextSpec: Sendable, Hashable {
    /// The role.
    public let role: UIRole
    /// The Dynamic Type text style (``UIRole/textStyle``).
    public let textStyle: Font.TextStyle
    /// The weight, from the theme's weight (100 to 900).
    public let weight: Font.Weight
    /// The font design, from the theme's family: sans is the default design, mono is monospaced, New York and Garamond are serif.
    public let design: Font.Design
    /// Letter spacing in points: the theme's em tracking times its size, **only where positive** (the label). The tokens' negative
    /// tracking is for a fixed point size; the system tracks larger Dynamic Type text itself, so applying it would tighten twice.
    public let tracking: CGFloat
    /// Whether the text is set in capitals.
    public let isUppercase: Bool
    /// Whether the text is drawn in secondary ink (the label and the caption) rather than ink.
    public let usesSecondaryInk: Bool
    /// Whether the text is an accessibility header (the heading and the title).
    public let isHeader: Bool

    /// Resolves a role from a theme.
    public init(_ role: UIRole, theme: Theme) {
        let spec = theme.structure.type[role.typeRole]
        self.role = role
        textStyle = role.textStyle
        weight = ChartText.weight(spec.weight)
        design = Self.design(of: spec.family)
        tracking = spec.tracking > 0 ? CGFloat(spec.tracking * spec.size) : 0
        isUppercase = spec.uppercase
        usesSecondaryInk = role == .label || role == .caption
        isHeader = role == .heading || role == .title
    }

    /// The font.
    public var font: Font {
        .system(textStyle, design: design, weight: weight)
    }

    private static func design(of family: FontFamilyRef) -> Font.Design {
        switch family {
        case .sans: .default
        case .mono: .monospaced
        case .serifNewYork, .serifGaramond: .serif
        case .named(_, let fallback): design(of: fallback)
        }
    }
}

@available(macOS 14.0, iOS 17.0, visionOS 1.0, tvOS 17.0, watchOS 10.0, *)
private struct UITextModifier: ViewModifier {
    let role: UIRole
    @Environment(\.theme) private var theme
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.colorSchemeContrast) private var contrast

    func body(content: Content) -> some View {
        let spec = UITextSpec(role, theme: theme)
        let style = ChartStyle(theme: theme, colorScheme: colorScheme, contrast: contrast)
        return content
            .font(spec.font)
            .tracking(spec.tracking)
            .textCase(spec.isUppercase ? .uppercase : nil)
            .foregroundStyle(spec.usesSecondaryInk ? style.secondaryInk : style.ink)
            .accessibilityAddTraits(spec.isHeader ? .isHeader : [])
    }
}

@available(macOS 14.0, iOS 17.0, visionOS 1.0, tvOS 17.0, watchOS 10.0, *)
public extension View {
    /// Sets text in a UI role: the font (a Dynamic Type style), tracking and case from the active theme, the foreground in ink or
    /// secondary ink, and the header trait for a heading or title. Override the foreground after it where another colour is meant.
    func uiText(_ role: UIRole) -> some View {
        modifier(UITextModifier(role: role))
    }

    /// Numbers that line up: monospaced digits. Combine with a role: `.uiText(.body).uiFigure()`.
    func uiFigure() -> some View {
        monospacedDigit()
    }
}
#endif
