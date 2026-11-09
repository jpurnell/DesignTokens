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
    /// Further named colours beyond the twelve roles (a legacy theme's `primary`, `info`, `highlight`,
    /// `subtle`, `emphasis`, `shadow`, and `neutral`), keyed by name. Added in 0.5.0.
    public var extras: [String: Adaptive]
    /// Per-chart colour overrides, keyed by chart colour key (`"tornado.low"`): which role or extra, at
    /// what opacity. Only the legacy themes override. Added in 0.5.0.
    public var colourOverrides: [String: ColourReference]
    /// Per-chart gradient overrides, keyed by chart gradient key (`"efficientfrontier"`): the name of the
    /// ramp (`"sharpe"`) in ``extraRamps``, ``sequential`` or ``diverging``. Added in 0.5.0.
    public var rampOverrides: [String: String]

    /// Creates a palette.
    public init(ink: Adaptive, secondaryInk: Adaptive, background: Adaptive, surface: Adaptive, rule: Adaptive,
                accent: Adaptive, onAccent: Adaptive, link: Adaptive, positive: Adaptive, negative: Adaptive,
                warning: Adaptive, muted: Adaptive, series: [NamedAdaptive], sequential: Ramp, diverging: Ramp,
                extraRamps: [String: Ramp] = [:], extras: [String: Adaptive] = [:],
                colourOverrides: [String: ColourReference] = [:], rampOverrides: [String: String] = [:]) {
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
        self.extras = extras
        self.colourOverrides = colourOverrides
        self.rampOverrides = rampOverrides
    }

    private enum CodingKeys: String, CodingKey {
        case ink, secondaryInk, background, surface, rule, accent, onAccent, link, positive, negative, warning, muted
        case series, sequential, diverging, extraRamps, extras, colourOverrides, rampOverrides
    }

    /// Decodes a palette; the fields added in 0.5.0 default to empty when absent.
    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        ink = try c.decode(Adaptive.self, forKey: .ink)
        secondaryInk = try c.decode(Adaptive.self, forKey: .secondaryInk)
        background = try c.decode(Adaptive.self, forKey: .background)
        surface = try c.decode(Adaptive.self, forKey: .surface)
        rule = try c.decode(Adaptive.self, forKey: .rule)
        accent = try c.decode(Adaptive.self, forKey: .accent)
        onAccent = try c.decode(Adaptive.self, forKey: .onAccent)
        link = try c.decode(Adaptive.self, forKey: .link)
        positive = try c.decode(Adaptive.self, forKey: .positive)
        negative = try c.decode(Adaptive.self, forKey: .negative)
        warning = try c.decode(Adaptive.self, forKey: .warning)
        muted = try c.decode(Adaptive.self, forKey: .muted)
        series = try c.decode([NamedAdaptive].self, forKey: .series)
        sequential = try c.decode(Ramp.self, forKey: .sequential)
        diverging = try c.decode(Ramp.self, forKey: .diverging)
        extraRamps = try c.decode([String: Ramp].self, forKey: .extraRamps)
        extras = try c.decodeIfPresent([String: Adaptive].self, forKey: .extras) ?? [:]
        colourOverrides = try c.decodeIfPresent([String: ColourReference].self, forKey: .colourOverrides) ?? [:]
        rampOverrides = try c.decodeIfPresent([String: String].self, forKey: .rampOverrides) ?? [:]
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
        copy.extras = extras.mapValues { $0.strippingDark() }
        return copy
    }
}
