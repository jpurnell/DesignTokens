import Foundation

/// One resolved colour state of a theme: an appearance, with Increase Contrast on or off.
///
/// The text emitters for surfaces with no CSS media queries (terminal, slides) cannot adapt at run time, so they
/// write one block per slot. ``slots(for:)`` says which slots a theme has:
///
/// | ``AppearanceSupport`` | slots |
/// |---|---|
/// | `both` | `light`, `light-increased`, `dark`, `dark-increased` |
/// | `lightOnly` | `light`, `light-increased` |
/// | `fixedDark` | `dark`, `dark-increased` |
///
/// A fixed-dark theme stores its colours in the model's `light` slot (it has no other); its slots are named
/// `dark` and read the stored values. An increased-contrast value that a colour does not have carries through from the
/// standard value of the same appearance, as ``Adaptive/value(in:increasedContrast:)`` does everywhere.
public struct ThemeSlot: Sendable, Hashable {
    /// The appearance this slot stands for.
    public let appearance: Appearance
    /// Whether Increase Contrast is on.
    public let increasedContrast: Bool
    /// The model slot the values are read from: differs from ``appearance`` only for a fixed-dark theme.
    private let source: Appearance

    private init(appearance: Appearance, increasedContrast: Bool, source: Appearance) {
        self.appearance = appearance
        self.increasedContrast = increasedContrast
        self.source = source
    }

    /// The slot's name: `light`, `light-increased`, `dark` or `dark-increased`.
    public var name: String {
        (appearance == .dark ? "dark" : "light") + (increasedContrast ? "-increased" : "")
    }

    /// The slots a theme has, in a fixed order: standard before increased, light before dark.
    public static func slots(for theme: Theme) -> [ThemeSlot] {
        switch theme.appearances {
        case .both:
            return [ThemeSlot(appearance: .light, increasedContrast: false, source: .light),
                    ThemeSlot(appearance: .light, increasedContrast: true, source: .light),
                    ThemeSlot(appearance: .dark, increasedContrast: false, source: .dark),
                    ThemeSlot(appearance: .dark, increasedContrast: true, source: .dark)]
        case .lightOnly:
            return [ThemeSlot(appearance: .light, increasedContrast: false, source: .light),
                    ThemeSlot(appearance: .light, increasedContrast: true, source: .light)]
        case .fixedDark:
            return [ThemeSlot(appearance: .dark, increasedContrast: false, source: .light),
                    ThemeSlot(appearance: .dark, increasedContrast: true, source: .light)]
        }
    }

    /// The colour for this slot as opaque channels.
    ///
    /// A colour with alpha below 1 is composited over the slot's `background`, channel by channel and rounded to the
    /// nearest value (`c * a + b * (1 - a)`), because the surfaces that use slots have no alpha.
    public func rgb(_ adaptive: Adaptive, in theme: Theme) -> RGB {
        let value = adaptive.value(in: source, increasedContrast: increasedContrast)
        guard value.alpha < 1 else { return value.rgb }
        let backdrop = theme.palette.background.value(in: source, increasedContrast: increasedContrast).rgb
        let a = value.alpha
        func mix(_ foreground: UInt8, _ background: UInt8) -> UInt8 {
            let blended = (Double(foreground) * a + Double(background) * (1 - a)).rounded()
            return UInt8(exactly: min(max(blended, 0), 255)) ?? background
        }
        return RGB(red: mix(value.rgb.red, backdrop.red), green: mix(value.rgb.green, backdrop.green),
                   blue: mix(value.rgb.blue, backdrop.blue))
    }
}
