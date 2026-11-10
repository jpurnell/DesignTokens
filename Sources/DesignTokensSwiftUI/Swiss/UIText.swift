#if canImport(SwiftUI)
import DesignTokens
import SwiftUI
#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

/// The eight UI text roles of the design system, in the register an app's interface is set in (as against the chart
/// roles, which ``ChartText`` resolves).
///
/// - `label`: small capitals, tracked, in secondary ink; what names a value or a row.
/// - `caption`: metadata and notes, in secondary ink.
/// - `body`: running text and values.
/// - `heading`: a group or row heading, the weight of a value's name rather than a size above it.
/// - `cardTitle`: the title of a card (0.11.0), smaller than a section heading.
/// - `section`: a section's heading (0.11.0), clearly above a value and below the page title.
/// - `title`: a page's title (``TypeRole/uiTitle``).
/// - `display`: the one large statement.
///
/// In order of size: `display` > `title` > `section` > `cardTitle` >= `heading` >= `body` > `caption` >= `label`.
/// ``UITextSpec/pointSize`` measures it and a test holds it.
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
    /// A card's title, smaller than a section heading.
    case cardTitle
    /// A section's heading, between a card title and the page title.
    case section
    /// A page's title.
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
        case .cardTitle: .uiTitle
        case .section: .heading
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
    ///
    /// The two heading roles that sit between the title and the heading differ by platform, because the same style is a
    /// different size: on a Mac `title2` is 17 pt and `title3` 15, on a phone 22 and 20. A Mac's section heading is therefore
    /// `title2` and a phone's `title3`; a Mac's card title is `title3` and a phone's `headline`. At default size that is
    /// 28 / 20 / 17 / 17 on a phone and 22 / 17 / 15 / 13 on a Mac, for the title, section, card title and heading.
    public var textStyle: Font.TextStyle {
        switch self {
        case .label: .caption2
        case .caption: .footnote
        case .body: .body
        case .heading: .headline
        #if os(macOS)
        case .cardTitle: .title3
        case .section: .title2
        #else
        case .cardTitle: .headline
        case .section: .title3
        #endif
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
    /// Whether the text is an accessibility header (the heading, card title, section and title).
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
        isHeader = [.heading, .cardTitle, .section, .title].contains(role)
    }

    /// The role's size in points at the default Dynamic Type size, measured from the platform (`NSFont` or `UIFont`), or `nil`
    /// where neither exists. It is what the size ordering of the roles is tested on; a view's size scales from it.
    public var pointSize: CGFloat? { Self.pointSize(of: textStyle) }

    /// A text style's size in points at the default size on this platform, measured, or `nil` where the platform has no font API here.
    public static func pointSize(of style: Font.TextStyle) -> CGFloat? {
        #if canImport(AppKit)
        guard let mapped = Self.platformStyle(style) else { return nil }
        return NSFont.preferredFont(forTextStyle: mapped).pointSize
        #elseif canImport(UIKit)
        guard let mapped = Self.platformStyle(style) else { return nil }
        return UIFont.preferredFont(forTextStyle: mapped).pointSize
        #else
        return nil
        #endif
    }

    #if canImport(AppKit)
    private static func platformStyle(_ style: Font.TextStyle) -> NSFont.TextStyle? {
        switch style {
        case .largeTitle: .largeTitle
        case .title: .title1
        case .title2: .title2
        case .title3: .title3
        case .headline: .headline
        case .subheadline: .subheadline
        case .body: .body
        case .callout: .callout
        case .footnote: .footnote
        case .caption: .caption1
        case .caption2: .caption2
        default: nil
        }
    }
    #elseif canImport(UIKit)
    private static func platformStyle(_ style: Font.TextStyle) -> UIFont.TextStyle? {
        switch style {
        case .largeTitle: .largeTitle
        case .title: .title1
        case .title2: .title2
        case .title3: .title3
        case .headline: .headline
        case .subheadline: .subheadline
        case .body: .body
        case .callout: .callout
        case .footnote: .footnote
        case .caption: .caption1
        case .caption2: .caption2
        default: nil
        }
    }
    #endif

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

/// The ink a UI role is drawn in: the role's own, or a choice.
///
/// SwiftUI's innermost foreground style wins, so a `.foregroundStyle` written after ``SwiftUI/View/uiText(_:ink:)`` does not
/// override it; choose the ink here.
@available(macOS 14.0, iOS 17.0, visionOS 1.0, tvOS 17.0, watchOS 10.0, *)
public enum UIInk: Sendable, Hashable {
    /// The role's own: secondary ink for the label and caption, ink for the rest.
    case automatic
    /// The theme's `ink`.
    case ink
    /// The theme's `secondaryInk`.
    case secondaryInk
    /// Another colour: an app's status role, a colour measured to read on a fill.
    case custom(Color)
}

@available(macOS 14.0, iOS 17.0, visionOS 1.0, tvOS 17.0, watchOS 10.0, *)
private struct UITextModifier: ViewModifier {
    let role: UIRole
    let ink: UIInk
    @Environment(\.theme) private var theme
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.colorSchemeContrast) private var contrast

    private func foreground(spec: UITextSpec, style: ChartStyle) -> Color {
        switch ink {
        case .automatic: spec.usesSecondaryInk ? style.secondaryInk : style.ink
        case .ink: style.ink
        case .secondaryInk: style.secondaryInk
        case .custom(let colour): colour
        }
    }

    func body(content: Content) -> some View {
        let spec = UITextSpec(role, theme: theme)
        let style = ChartStyle(theme: theme, colorScheme: colorScheme, contrast: contrast)
        return content
            .font(spec.font)
            .tracking(spec.tracking)
            .textCase(spec.isUppercase ? .uppercase : nil)
            .foregroundStyle(foreground(spec: spec, style: style))
            .accessibilityAddTraits(spec.isHeader ? .isHeader : [])
    }
}

@available(macOS 14.0, iOS 17.0, visionOS 1.0, tvOS 17.0, watchOS 10.0, *)
public extension View {
    /// Sets text in a UI role: the font (a Dynamic Type style), tracking and case from the active theme, the foreground in ink or
    /// secondary ink, and the header trait for a heading or title.
    ///
    /// - Parameters:
    ///   - role: The role.
    ///   - ink: The foreground; ``UIInk/automatic`` is the role's own. A `.foregroundStyle` written after this modifier would not
    ///     win (SwiftUI's innermost style does), so another colour is chosen here.
    func uiText(_ role: UIRole, ink: UIInk = .automatic) -> some View {
        modifier(UITextModifier(role: role, ink: ink))
    }

    /// Numbers that line up: monospaced digits. Combine with a role: `.uiText(.body).uiFigure()`.
    func uiFigure() -> some View {
        monospacedDigit()
    }
}
#endif
