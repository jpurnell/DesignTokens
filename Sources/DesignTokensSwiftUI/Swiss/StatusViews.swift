#if canImport(SwiftUI)
import DesignTokens
import SwiftUI

/// What an ``OutlinedChip``'s outline says. The words inside always say it too.
@available(macOS 14.0, iOS 17.0, visionOS 1.0, tvOS 17.0, watchOS 10.0, *)
public enum ChipTone: Sendable, Hashable {
    /// Neutral: the secondary ink.
    case neutral
    /// Emphasised: the accent. Use it for the one state that matters, not for decoration.
    case emphasis
    /// Favourable: the theme's text-safe positive.
    case positive
    /// Unfavourable: the theme's text-safe negative.
    case negative
    /// Caution: the theme's warning.
    case warning
    /// An app's own colour (a palette role), for a status the theme has no role for.
    case custom(Color)

    /// The outline colour in a style.
    public func outline(in style: ChartStyle) -> Color {
        switch self {
        case .neutral: style.secondaryInk
        case .emphasis: style.accent
        case .positive: style.positive
        case .negative: style.negative
        case .warning: style.warning
        case .custom(let colour): colour
        }
    }
}

/// A state as words in an outlined chip: ink text, the outline in the colour that carries the state, the control radius, no tinted
/// fill. A glyph may precede the words; it is decoration for the eye and hidden from VoiceOver, which reads the words.
@available(macOS 14.0, iOS 17.0, visionOS 1.0, tvOS 17.0, watchOS 10.0, *)
public struct OutlinedChip: View {
    private let text: String
    private let tone: ChipTone
    private let glyph: String?

    /// Creates a chip.
    ///
    /// - Parameters:
    ///   - text: The words. Always present: colour and glyph only add to them.
    ///   - tone: What the outline says.
    ///   - glyph: An SF Symbol name, or `nil`.
    public init(_ text: String, tone: ChipTone = .neutral, glyph: String? = nil) {
        self.text = text
        self.tone = tone
        self.glyph = glyph
    }

    /// The chip.
    public var body: some View {
        ChartStyleReader { style in
            let metrics = SwissMetrics(theme: style.theme)
            HStack(spacing: metrics.step(1)) {
                if let glyph {
                    Image(systemName: glyph).foregroundStyle(tone.outline(in: style)).accessibilityHidden(true)
                }
                Text(text).foregroundStyle(style.ink)
            }
            .uiText(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, metrics.step(2))
            .padding(.vertical, metrics.unit / 2)
            .overlay(metrics.controlShape.strokeBorder(tone.outline(in: style), lineWidth: metrics.chipOutline))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(text)
        }
    }
}

/// A status banner: a solid fill in the status's role, a glyph and the words, with text measured to read on the fill in the
/// appearance it is drawn in (``StatusBannerStyle``).
@available(macOS 14.0, iOS 17.0, visionOS 1.0, tvOS 17.0, watchOS 10.0, *)
public struct StatusBanner: View {
    private let kind: StatusKind
    private let text: String

    /// Creates a banner.
    ///
    /// - Parameters:
    ///   - kind: The status.
    ///   - text: The words that say it, such as "Healthy, 100% passing".
    public init(_ kind: StatusKind, text: String) {
        self.kind = kind
        self.text = text
    }

    /// The banner.
    public var body: some View {
        ChartStyleReader { style in
            let metrics = SwissMetrics(theme: style.theme)
            let resolved = StatusBannerStyle.resolve(kind, style: style)
            HStack(spacing: metrics.step(2)) {
                Image(systemName: kind.glyph).foregroundStyle(resolved.text.color).accessibilityHidden(true)
                Text(text).uiText(.heading, ink: .custom(resolved.text.color))
                Spacer(minLength: 0)
            }
            .padding(.horizontal, metrics.step(3))
            .padding(.vertical, metrics.step(2))
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(resolved.fill.color, in: metrics.controlShape)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(text)
        }
    }
}
#endif
