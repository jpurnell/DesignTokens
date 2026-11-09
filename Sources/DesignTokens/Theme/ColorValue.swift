import Foundation

/// An sRGB colour with an alpha, stored as `#RRGGBB` or, when translucent, `#RRGGBBAA`.
///
/// ``RGB`` has no alpha and stays as it is, so the existing tokens are unaffected. `ColorValue` is what a
/// theme stores, which lets borders, shadows and highlights that are a colour at some opacity be written
/// down. Alpha is quantised to a byte on creation, so every value survives a round trip through its hex
/// form exactly. Contrast and distance are measured on the colour composited over the surface, and a
/// translucent colour has no contrast of its own.
public struct ColorValue: Sendable, Hashable, Codable {
    /// The opaque channels.
    public var rgb: RGB
    /// The opacity, 0 to 1, always a multiple of 1/255.
    public private(set) var alpha: Double

    /// Creates a colour.
    ///
    /// - Parameters:
    ///   - rgb: The channels.
    ///   - alpha: The opacity. Values outside 0 to 1 are clamped; NaN is treated as opaque.
    public init(_ rgb: RGB, alpha: Double = 1) {
        self.rgb = rgb
        self.alpha = Self.quantised(alpha)
    }

    /// Parses `#RRGGBB` or `#RRGGBBAA` (the `#` is optional, case is ignored). Returns `nil` for anything else.
    public init?(hex: String) {
        let digits = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        switch digits.count {
        case 6:
            guard let rgb = RGB(hex: digits) else { return nil }
            self.init(rgb)
        case 8:
            guard let rgb = RGB(hex: String(digits.prefix(6))),
                  let byte = UInt8(digits.suffix(2), radix: 16) else { return nil }
            self.init(rgb, alpha: Double(byte) / Self.byteMax)
        default:
            return nil
        }
    }

    /// A colour from a packed `0xRRGGBB` value and an optional alpha byte, for theme definitions.
    static func packed(_ rgb: UInt32, alpha: UInt8 = 0xFF) -> ColorValue {
        ColorValue(RGB(rgb: rgb), alpha: Double(alpha) / byteMax)
    }

    /// The colour as uppercase `#RRGGBB`, or `#RRGGBBAA` when its alpha is below 1.
    public var hex: String {
        guard alpha < 1, let byte = UInt8(exactly: (alpha * Self.byteMax).rounded()) else { return rgb.hex }
        let digits = String(byte, radix: 16, uppercase: true)
        return rgb.hex + (digits.count == 1 ? "0" + digits : digits)
    }

    /// Decodes from the hex string form.
    public init(from decoder: any Decoder) throws {
        let text = try decoder.singleValueContainer().decode(String.self)
        guard let value = ColorValue(hex: text) else {
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath,
                                                    debugDescription: "\(text) is not #RRGGBB or #RRGGBBAA"))
        }
        self = value
    }

    /// Encodes as the hex string form.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(hex)
    }

    private static let byteMax = 255.0

    private static func quantised(_ alpha: Double) -> Double {
        guard !alpha.isNaN else { return 1 }
        return (min(max(alpha, 0), 1) * byteMax).rounded() / byteMax
    }
}

/// The Apple system colours a Swiss slot stands for. Apple adapters defer to the system colour when one is
/// named (the HIG says not to hard-code them); other surfaces use the stored values.
public enum SystemColorName: String, Sendable, Hashable, Codable, CaseIterable {
    /// `Color.orange`.
    case orange
    /// `Color.indigo`.
    case indigo
    /// `Color.green`.
    case green
    /// `Color.purple`.
    case purple
    /// `Color.yellow`.
    case yellow
    /// `Color.blue`.
    case blue
    /// `Color.red`.
    case red
    /// `Color.cyan`.
    case cyan
    /// `Color.pink`. Added in 0.5.0 for the legacy Default theme.
    case pink
    /// `Color.mint`. Added in 0.5.0 for the legacy Default theme.
    case mint
    /// `Color.gray`. Added in 0.5.0 for the legacy Default theme.
    case gray
}

/// A colour for every appearance: light, dark, and an increased-contrast value for each.
///
/// The rule is the one ``ColorToken`` already has. Dark uses its dark value when present. Increased contrast
/// uses its own measured value when present and otherwise the standard value of the same appearance. Nothing
/// is derived from another slot; a theme that declares both appearances must supply `dark` (see
/// ``Theme/appearanceIssues``).
public struct Adaptive: Sendable, Hashable, Codable {
    /// The light-appearance value.
    public var light: ColorValue
    /// The dark-appearance value; `nil` in a light-only theme.
    public var dark: ColorValue?
    /// Light with Increase Contrast on; `nil` means the standard light value carries through.
    public var lightIncreased: ColorValue?
    /// Dark with Increase Contrast on; `nil` means the standard dark value carries through.
    public var darkIncreased: ColorValue?
    /// The Apple system colour this slot stands for, when it is one.
    public var system: SystemColorName?

    /// Creates an adaptive colour.
    public init(light: ColorValue, dark: ColorValue? = nil, lightIncreased: ColorValue? = nil,
                darkIncreased: ColorValue? = nil, system: SystemColorName? = nil) {
        self.light = light
        self.dark = dark
        self.lightIncreased = lightIncreased
        self.darkIncreased = darkIncreased
        self.system = system
    }

    /// The adaptive colour for a ``ColorToken``, with every measured slot it has.
    ///
    /// - Parameters:
    ///   - token: The token whose light, dark and increased-contrast values are used.
    ///   - system: The system colour the token stands for, if any.
    public init(token: ColorToken, system: SystemColorName? = nil) {
        self.init(light: ColorValue(token.light), dark: token.dark.map { ColorValue($0) },
                  lightIncreased: token.increasedContrastLight.map { ColorValue($0) },
                  darkIncreased: token.increasedContrastDark.map { ColorValue($0) }, system: system)
    }

    /// The value for an appearance, optionally with Increase Contrast on.
    ///
    /// A missing dark value resolves to the light one, as ``ColorToken/value(in:)`` does; a missing
    /// increased-contrast value resolves to the standard value of the same appearance.
    public func value(in appearance: Appearance, increasedContrast: Bool) -> ColorValue {
        switch appearance {
        case .light: increasedContrast ? (lightIncreased ?? light) : light
        case .dark: increasedContrast ? (darkIncreased ?? dark ?? light) : (dark ?? light)
        }
    }

    /// The same colour with no dark values, for a light-only theme.
    public func strippingDark() -> Adaptive {
        Adaptive(light: light, dark: nil, lightIncreased: lightIncreased, darkIncreased: nil, system: system)
    }
}

/// A series colour with its name ("orange", "red"), so a theme's order and meaning travel together.
public struct NamedAdaptive: Sendable, Hashable, Codable {
    /// The colour's name.
    public var name: String
    /// The colour.
    public var color: Adaptive

    /// Creates a named colour.
    public init(name: String, color: Adaptive) {
        self.name = name
        self.color = color
    }
}

/// An ordered colour ramp: a light-surface version and, where one has been authored, a dark-surface one.
public struct Ramp: Sendable, Hashable, Codable {
    /// The steps on a light surface.
    public var light: [ColorValue]
    /// The steps on a dark surface; `nil` means the light ramp is used as it is.
    public var dark: [ColorValue]?

    /// Creates a ramp.
    public init(light: [ColorValue], dark: [ColorValue]?) {
        self.light = light
        self.dark = dark
    }
}

/// Which appearances a theme supports.
public enum AppearanceSupport: String, Sendable, Hashable, Codable, CaseIterable {
    /// Light and dark, each with a value for every colour role.
    case both
    /// Light only: no dark values exist, and a dark context shows the theme on its own background.
    case lightOnly
    /// A single, dark appearance: the theme's colours are for a dark surface and are stored in the
    /// `light` slot (the only slot), with no `dark` values. The validator measures it with the dark band.
    /// Added in 0.5.0 for the legacy Dark theme.
    case fixedDark
}

/// A reference to one of a theme's colours by name, optionally at some opacity.
///
/// The source is a ``ColorRole`` raw value (`"accent"`) or a key of ``ThemePalette/extras`` (`"primary"`).
/// It carries the per-chart colour overrides and the shadow colour of the legacy themes, which are role
/// mappings rather than colours of their own. Added in 0.5.0.
public struct ColourReference: Sendable, Hashable, Codable {
    /// A role raw value or an `extras` key.
    public var source: String
    /// Opacity, 0 to 1.
    public var opacity: Double

    /// Creates a reference.
    public init(source: String, opacity: Double = 1) {
        self.source = source
        self.opacity = opacity
    }
}
