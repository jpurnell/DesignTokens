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

    /// The light-appearance value with Increase Contrast on, or `nil` when it was not measured.
    ///
    /// Measured on ``Snapshot/systemRelease`` from the system colours under the increased-contrast
    /// appearances. Only the colours with an opaque system value are here; see ``unmeasuredIncreasedContrast``.
    public var increasedContrastLight: RGB? {
        switch self {
        case .accent: RGB(rgb: 0xC55300)
        case .success: RGB(rgb: 0x008932)
        case .destructive: RGB(rgb: 0xE9152D)
        default: nil
        }
    }

    /// The dark-appearance value with Increase Contrast on, or `nil` when it was not measured.
    public var increasedContrastDark: RGB? {
        switch self {
        case .accent: RGB(rgb: 0xFFA056)
        case .success: RGB(rgb: 0x4AD968)
        case .destructive: RGB(rgb: 0xFF6165)
        default: nil
        }
    }

    /// The value for an appearance, optionally with Increase Contrast on.
    ///
    /// With `increasedContrast` true, a role that was not measured falls back to the standard value.
    public func value(in appearance: Appearance, increasedContrast: Bool) -> RGB {
        guard increasedContrast else { return value(in: appearance) }
        switch appearance {
        case .light: return increasedContrastLight ?? value(in: .light)
        case .dark: return increasedContrastDark ?? value(in: .dark)
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

    /// The roles with no increased-contrast value. `link` was measured (system link #0068DA light,
    /// #419CFF dark) but is left out on purpose: this package's own link (#1F57D6, #7BA3FF) has more contrast
    /// against the background than the system's increased-contrast link (5.9 to 1 against 5.0, 7.7 against 6.7),
    /// so adopting it would lower contrast. `separator`, `secondaryLabel` and `label` have
    /// alpha, which a hex readout loses; `background`, `secondaryBackground` and `onAccent` are this
    /// package's own values rather than a system colour, and `warning` has no system counterpart.
    public static var unmeasuredIncreasedContrast: [ColorToken] {
        allCases.filter { $0.increasedContrastLight == nil || $0.increasedContrastDark == nil }
    }
}
