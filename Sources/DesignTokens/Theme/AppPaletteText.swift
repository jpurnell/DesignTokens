import Foundation

/// The backgrounds an app draws its text roles on, in each appearance: its window, a grouped list, a card, a bar.
///
/// Swiss's text-safe guarantee holds on Swiss's own surfaces. An app draws on its own (a system grouped grey, a
/// dark card), so it declares them here and ``AppPalette/validate(on:)`` measures every text role against every one.
///
/// ```swift
/// TextSurfaces(light: [0xFFFFFF, 0xF2F2F7, 0xECECEC], dark: [0x000000, 0x1C1C1E, 0x323232])
/// ```
///
/// A list that is `nil` falls back as follows: `dark` to the theme's own dark surfaces, `lightIncreased` to
/// `light`, and `darkIncreased` to `dark`. It does not change the composed theme or any chart: it says only what
/// text is drawn on. A translucent surface is composited over white (over black in dark), as the theme's own are.
public struct TextSurfaces: Sendable, Hashable, Codable {
    /// The backgrounds text is drawn on in light.
    public var light: [ColorValue]
    /// The backgrounds in dark, or `nil` for the theme's own dark surfaces.
    public var dark: [ColorValue]?
    /// The backgrounds with Increase Contrast on in light, or `nil` for ``light``.
    public var lightIncreased: [ColorValue]?
    /// The backgrounds with Increase Contrast on in dark, or `nil` for ``dark``.
    public var darkIncreased: [ColorValue]?

    /// Creates a set of surfaces.
    public init(light: [ColorValue], dark: [ColorValue]? = nil, lightIncreased: [ColorValue]? = nil,
                darkIncreased: [ColorValue]? = nil) {
        self.light = light
        self.dark = dark
        self.lightIncreased = lightIncreased
        self.darkIncreased = darkIncreased
    }

    /// Creates a set of surfaces from packed `0xRRGGBB` values, so an app palette file reads as its colours.
    public init(light: [UInt32], dark: [UInt32]? = nil, lightIncreased: [UInt32]? = nil, darkIncreased: [UInt32]? = nil) {
        func values(_ packed: [UInt32]) -> [ColorValue] { packed.map { ColorValue(RGB(rgb: $0)) } }
        self.init(light: values(light), dark: dark.map(values), lightIncreased: lightIncreased.map(values),
                  darkIncreased: darkIncreased.map(values))
    }

    /// The declared list for an appearance, with the increased-contrast fallbacks applied, or `nil` where the
    /// theme's own surfaces apply.
    func list(for appearance: ValidationAppearance) -> [ColorValue]? {
        switch appearance {
        case .light: light
        case .dark: dark
        case .lightIncreased: lightIncreased ?? light
        case .darkIncreased: darkIncreased ?? dark
        }
    }
}

/// A name for each of an app's text roles: the enum an app's views read its colours through.
///
/// ```swift
/// enum Role: String, AppTextRole { case secondary, failure, success }
///
/// enum DashboardPalette: AppPaletteSource {
///     typealias TextRoles = Role
///     static let palette = AppPalette(id: "dashboard", textRoles: [
///         NamedAdaptive("secondary", light: 0x5C5C61, dark: 0xAEAEB2),
///         NamedAdaptive("failure", light: 0xC4161C, dark: 0xFF6961),
///         NamedAdaptive("success", light: 0x1B7030, dark: 0x30D158)])
/// }
/// let failure = DashboardPalette.text(.failure)
/// ```
///
/// The raw value is the role's name in ``AppPalette/textRoles``. ``AppPaletteSource/validate(on:)`` fails when a case
/// has no declared colour or a declared colour has no case, so the enum a view reads and the colours that were
/// validated cannot drift apart.
public protocol AppTextRole: RawRepresentable, CaseIterable, Sendable where RawValue == String {}

/// The ``AppTextRole`` of a source that does not name one: it has no cases and nothing is cross-checked.
public enum NoTextRoles: AppTextRole {
    /// There is no case, so there is no raw value to match.
    public init?(rawValue: String) { nil }

    /// Unreachable: the enum has no values.
    public var rawValue: String {
        switch self {}
    }

    /// Empty.
    public static var allCases: [NoTextRoles] { [] }
}

public extension AppPalette {
    /// The text colour declared under `name`, or `nil`.
    func text(named name: String) -> Adaptive? {
        textRoles.first { $0.name == name }?.color
    }

    /// The roles of Swiss's palette a text role can override by name.
    internal static let overridableTextRoles: [ColorRole] = [.ink, .secondaryInk, .link, .positive, .negative, .warning]
}
