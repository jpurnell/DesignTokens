import Foundation

/// The colour roles every theme defines, in fixed order. Each is one field of ``ThemePalette``.
public enum ColorRole: String, Sendable, Hashable, Codable, CaseIterable {
    /// Primary content colour.
    case ink
    /// De-emphasised content colour.
    case secondaryInk
    /// The primary surface.
    case background
    /// A secondary surface for panels and cards.
    case surface
    /// Hairlines, borders and faint gridlines.
    case rule
    /// The theme's accent.
    case accent
    /// Text and marks drawn on the accent.
    case onAccent
    /// Link text.
    case link
    /// Success or favourable change.
    case positive
    /// Failure or unfavourable change.
    case negative
    /// Caution.
    case warning
    /// De-emphasised marks.
    case muted

    /// The ``ColorToken`` this role is built from in ``Theme/swiss``, or `nil` when the package holds no token for it.
    public var token: ColorToken? {
        switch self {
        case .ink: .label
        case .secondaryInk: .secondaryLabel
        case .background: .background
        case .surface: .secondaryBackground
        case .rule: .separator
        case .accent: .accent
        case .onAccent: .onAccent
        case .link: .link
        case .positive: .success
        case .negative: .destructive
        case .warning: .warning
        case .muted: nil
        }
    }
}

public extension ColorToken {
    /// The theme role this token fills.
    var themeRole: ColorRole {
        switch self {
        case .label: .ink
        case .secondaryLabel: .secondaryInk
        case .background: .background
        case .secondaryBackground: .surface
        case .separator: .rule
        case .accent: .accent
        case .onAccent: .onAccent
        case .link: .link
        case .success: .positive
        case .warning: .warning
        case .destructive: .negative
        }
    }
}

/// The colour half of a theme: surfaces, text, meanings, the ordered series and the ramps.
///
/// Roles are fixed fields, never a dictionary keyed by an enum, so the encoded form is deterministic.
public struct ThemePalette: Sendable, Hashable, Codable {
    /// Primary content colour.
    public var ink: Adaptive
    /// De-emphasised content colour.
    public var secondaryInk: Adaptive
    /// The primary surface.
    public var background: Adaptive
    /// A secondary surface.
    public var surface: Adaptive
    /// Hairlines and borders.
    public var rule: Adaptive
    /// The accent.
    public var accent: Adaptive
    /// Text and marks on the accent.
    public var onAccent: Adaptive
    /// Link text.
    public var link: Adaptive
    /// Favourable change.
    public var positive: Adaptive
    /// Unfavourable change.
    public var negative: Adaptive
    /// Caution.
    public var warning: Adaptive
    /// De-emphasised marks.
    public var muted: Adaptive
    /// The categorical series, in order.
    public var series: [NamedAdaptive]
    /// The one-hue magnitude ramp.
    public var sequential: Ramp
    /// The two-pole ramp.
    public var diverging: Ramp
    /// Further named ramps (a legacy theme's 3D gradients), keyed by name.
    public var extraRamps: [String: Ramp]

    /// Creates a palette.
    public init(ink: Adaptive, secondaryInk: Adaptive, background: Adaptive, surface: Adaptive, rule: Adaptive,
                accent: Adaptive, onAccent: Adaptive, link: Adaptive, positive: Adaptive, negative: Adaptive,
                warning: Adaptive, muted: Adaptive, series: [NamedAdaptive], sequential: Ramp, diverging: Ramp,
                extraRamps: [String: Ramp] = [:]) {
        self.ink = ink
        self.secondaryInk = secondaryInk
        self.background = background
        self.surface = surface
        self.rule = rule
        self.accent = accent
        self.onAccent = onAccent
        self.link = link
        self.positive = positive
        self.negative = negative
        self.warning = warning
        self.muted = muted
        self.series = series
        self.sequential = sequential
        self.diverging = diverging
        self.extraRamps = extraRamps
    }

    /// The colour for a role.
    public subscript(role: ColorRole) -> Adaptive {
        get {
            switch role {
            case .ink: ink
            case .secondaryInk: secondaryInk
            case .background: background
            case .surface: surface
            case .rule: rule
            case .accent: accent
            case .onAccent: onAccent
            case .link: link
            case .positive: positive
            case .negative: negative
            case .warning: warning
            case .muted: muted
            }
        }
        set {
            switch role {
            case .ink: ink = newValue
            case .secondaryInk: secondaryInk = newValue
            case .background: background = newValue
            case .surface: surface = newValue
            case .rule: rule = newValue
            case .accent: accent = newValue
            case .onAccent: onAccent = newValue
            case .link: link = newValue
            case .positive: positive = newValue
            case .negative: negative = newValue
            case .warning: warning = newValue
            case .muted: muted = newValue
            }
        }
    }

    /// The same palette with every dark value removed, for a light-only theme.
    public func strippingDark() -> ThemePalette {
        var copy = self
        for role in ColorRole.allCases { copy[role] = copy[role].strippingDark() }
        copy.series = series.map { NamedAdaptive(name: $0.name, color: $0.color.strippingDark()) }
        copy.sequential.dark = nil
        copy.diverging.dark = nil
        copy.extraRamps = extraRamps.mapValues { Ramp(light: $0.light, dark: nil) }
        return copy
    }
}
