#if canImport(SwiftUI)
import DesignTokens
import SwiftUI

/// The text colour that reads on a fill, chosen by measurement: whichever of the theme's `ink` and `background` has the higher
/// WCAG contrast against it, in the appearance the style resolves for.
///
/// Light and dark differ (a status fill is darker in light and brighter in dark), so the choice is made per appearance and per
/// increased-contrast variant. It is a value, so a test holds it without rendering.
@available(macOS 14.0, iOS 17.0, visionOS 1.0, tvOS 17.0, watchOS 10.0, *)
public struct ReadableText: Sendable, Hashable {
    /// The chosen text colour.
    public let colour: ColorValue
    /// Its contrast against the fill, 1 to 21.
    public let contrast: Double

    /// Chooses the text for a fill.
    ///
    /// - Parameters:
    ///   - fill: The fill the text is drawn on; a translucent fill is composited over white (black in dark).
    ///   - style: The style whose `ink` and `background` are the candidates.
    public static func on(_ fill: ColorValue, style: ChartStyle) -> ReadableText {
        let base = style.appearance == .dark ? ColorValue(RGB(rgb: 0x000000)) : ColorValue(RGB(rgb: 0xFFFFFF))
        let surface = ThemeValidator.resolved(fill, over: base)
        let candidates = [style.value(.ink), ThemeValidator.resolved(style.value(.background), over: base)]
        var best = candidates[0]
        var bestRatio = candidates[0].rgb.contrastRatio(with: surface.rgb)
        for candidate in candidates.dropFirst() {
            let ratio = candidate.rgb.contrastRatio(with: surface.rgb)
            if ratio > bestRatio { (best, bestRatio) = (candidate, ratio) }
        }
        return ReadableText(colour: best, contrast: bestRatio)
    }
}

/// A status a banner or chip can carry. Colour never says it alone: each has its own glyph, and the caller supplies the words.
@available(macOS 14.0, iOS 17.0, visionOS 1.0, tvOS 17.0, watchOS 10.0, *)
public enum StatusKind: Sendable, Hashable, CaseIterable {
    /// Nothing to report, or no data.
    case neutral
    /// Favourable: a pass.
    case positive
    /// Unfavourable: a failure.
    case negative
    /// Caution.
    case warning

    /// The SF Symbol that says the status in a shape of its own.
    public var glyph: String {
        switch self {
        case .neutral: "minus.circle.fill"
        case .positive: "checkmark.circle.fill"
        case .negative: "xmark.octagon.fill"
        case .warning: "exclamationmark.triangle.fill"
        }
    }

    /// The theme role whose colour fills a banner of this status.
    public var role: ColorRole {
        switch self {
        case .neutral: .secondaryInk
        case .positive: .positive
        case .negative: .negative
        case .warning: .warning
        }
    }
}

/// A status banner's fill and the text that reads on it.
@available(macOS 14.0, iOS 17.0, visionOS 1.0, tvOS 17.0, watchOS 10.0, *)
public struct StatusBannerStyle: Sendable, Hashable {
    /// The fill: the theme's role for the status, in the style's appearance.
    public let fill: ColorValue
    /// The text colour measured to read on the fill.
    public let text: ColorValue
    /// The measured contrast of ``text`` on ``fill``.
    public let contrast: Double

    /// Resolves the banner for a status in a style (a theme, an appearance, a contrast setting).
    public static func resolve(_ kind: StatusKind, style: ChartStyle) -> StatusBannerStyle {
        let fill = style.value(kind.role)
        let readable = ReadableText.on(fill, style: style)
        return StatusBannerStyle(fill: fill, text: readable.colour, contrast: readable.contrast)
    }
}
#endif
