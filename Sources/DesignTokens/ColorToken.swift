/// The light or dark appearance a colour is resolved for.
public enum Appearance: Sendable, Hashable, CaseIterable {
    /// Light appearance.
    case light
    /// Dark appearance.
    case dark
}

/// The colour roles: the nine SwiftGUIKit roles plus `onAccent` and `link`, each with a light and a dark value.
///
/// A dark value is `nil` when it has not been measured on the snapshot release. It is listed in
/// ``unmeasuredDark`` rather than guessed, and emitters leave it out so the light value carries through.
public enum ColorToken: String, Sendable, Hashable, CaseIterable {
    /// Primary content colour.
    case label
    /// De-emphasised content colour.
    case secondaryLabel
    /// The primary surface behind content.
    case background
    /// A secondary surface for panels and cards.
    case secondaryBackground
    /// Hairlines and borders.
    case separator
    /// The application tint: Apple's system orange.
    case accent
    /// Text and marks drawn on the accent: ink in both appearances, so it stays readable on orange.
    case onAccent
    /// Link text.
    case link
    /// Success status.
    case success
    /// Warning status.
    case warning
    /// Destructive or error status.
    case destructive

    /// The light-appearance value.
    public var light: RGB {
        switch self {
        case .label: RGB(rgb: 0x111214)
        case .secondaryLabel: RGB(rgb: 0x6A6D72)
        case .background: RGB(rgb: 0xFAFAFA)
        case .secondaryBackground: RGB(rgb: 0xFFFFFF)
        case .separator: RGB(rgb: 0xD6D8DB)
        case .accent: RGB(rgb: 0xFF8D28)
        case .onAccent: RGB(rgb: 0x111214)
        case .link: RGB(rgb: 0x1F57D6)
        case .success: RGB(rgb: 0x34C759)
        case .warning: RGB(rgb: 0x9A6A00)
        case .destructive: RGB(rgb: 0xFF383C)
        }
    }

    /// The dark-appearance value, or `nil` when it has not been measured on ``Snapshot/systemRelease``.
    public var dark: RGB? {
        switch self {
        case .label: RGB(rgb: 0xF2F2EF)
        case .secondaryLabel: RGB(rgb: 0x9A9DA2)
        case .background: RGB(rgb: 0x101112)
        case .secondaryBackground: RGB(rgb: 0x17181A)
        case .separator: RGB(rgb: 0x2E3033)
        case .accent: RGB(rgb: 0xFF9230)
        case .onAccent: RGB(rgb: 0x111214)
        case .link: RGB(rgb: 0x7BA3FF)
        case .warning: RGB(rgb: 0xF2C14E)
        case .success: RGB(rgb: 0x30D158)
        case .destructive: RGB(rgb: 0xFF4245)
        }
    }

    /// The value for an appearance; an unmeasured dark value falls back to the light one.
    public func value(in appearance: Appearance) -> RGB {
        switch appearance {
        case .light: light
        case .dark: dark ?? light
        }
    }

    /// The roles whose dark value has not been measured yet.
    public static var unmeasuredDark: [ColorToken] {
        allCases.filter { $0.dark == nil }
    }
}
