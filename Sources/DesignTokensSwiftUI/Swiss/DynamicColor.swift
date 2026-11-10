#if canImport(SwiftUI)
import DesignTokens
import SwiftUI
#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

@available(macOS 14.0, iOS 17.0, visionOS 1.0, tvOS 17.0, watchOS 10.0, *)
public extension Adaptive {
    /// A SwiftUI `Color` that follows the appearance when it is drawn: light, dark, and the increased-contrast variants, with no
    /// environment to read and no `@Environment` in the caller. An app's own role (a status colour from its `AppPalette`) can therefore be
    /// a real `Color`, usable wherever a `Color` is, without each app writing the bridge.
    ///
    /// It resolves through `NSColor(name:dynamicProvider:)` on a Mac and `UIColor(dynamicProvider:)` elsewhere, so the system chooses the
    /// variant from the view's appearance and Increase Contrast. A slot the adaptive does not define resolves as ``value(in:increasedContrast:)``
    /// does: a missing dark value is the light one, a missing increased-contrast value the standard one.
    var dynamicColor: Color {
        #if canImport(AppKit)
        Color(nsColor: platformColor)
        #elseif canImport(UIKit)
        Color(uiColor: platformColor)
        #else
        light.color
        #endif
    }
}

#if canImport(AppKit)
@available(macOS 14.0, *)
extension Adaptive {
    /// The dynamic `NSColor` behind ``dynamicColor``: the system hands it the appearance being drawn.
    var platformColor: NSColor {
        let adaptive = self
        return NSColor(name: nil) { appearance in
            NSColor(adaptive.value(for: appearance, systemIncreasesContrast: NSWorkspace.shared.accessibilityDisplayShouldIncreaseContrast).color)
        }
    }

    /// The slot an appearance asks for. Increase Contrast reaches a dynamic colour as the system setting: measured on macOS 27.2,
    /// `NSAppearance(named: .accessibilityHighContrastAqua)` reports itself as plain Aqua, and the provider is handed the plain
    /// appearance in a drawing pass. A high-contrast name, where a system still hands one over, is honoured too.
    func value(for appearance: NSAppearance, systemIncreasesContrast: Bool) -> ColorValue {
        let match = appearance.bestMatch(from: [.darkAqua, .aqua, .accessibilityHighContrastDarkAqua, .accessibilityHighContrastAqua])
        let dark = match == .darkAqua || match == .accessibilityHighContrastDarkAqua
        let increased = match == .accessibilityHighContrastDarkAqua || match == .accessibilityHighContrastAqua || systemIncreasesContrast
        return value(in: dark ? .dark : .light, increasedContrast: increased)
    }
}
#elseif canImport(UIKit)
@available(iOS 17.0, visionOS 1.0, tvOS 17.0, *)
extension Adaptive {
    /// The dynamic `UIColor` behind ``dynamicColor``: the trait collection says dark and Increase Contrast.
    var platformColor: UIColor {
        let adaptive = self
        return UIColor { traits in
            UIColor(adaptive.value(in: traits.userInterfaceStyle == .dark ? .dark : .light,
                                   increasedContrast: traits.accessibilityContrast == .high).color)
        }
    }
}
#endif

@available(macOS 14.0, iOS 17.0, visionOS 1.0, tvOS 17.0, watchOS 10.0, *)
public extension AppPaletteSource {
    /// The declared colour for a text role as a `Color` that follows the appearance (``Adaptive/dynamicColor``).
    ///
    /// For an app whose `Role` enum conforms to `AppTextRole`, `Palette.color(.failure)` is the `Color` a view draws a failure in.
    static func color(_ role: TextRoles) -> Color {
        text(role).dynamicColor
    }
}
#endif
