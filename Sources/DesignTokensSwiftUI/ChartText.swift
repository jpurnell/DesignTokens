#if canImport(SwiftUI)
import DesignTokens
import SwiftUI
#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

/// How a ``TextSpec`` becomes a font, decided from the spec and which named faces are installed.
///
/// It is a value so the decision can be tested without rendering: a missing licensed face (the Economist's
/// `Econ Sans Cnd`) must fall back to the family the theme declared, and say so, rather than change the look
/// unannounced.
public enum FontPlan: Sendable, Hashable {
    /// A system semantic text style (`.headline`), for the legacy themes.
    case platform(PlatformTextStyle)
    /// The system font, in a design (default, serif, monospaced).
    case system(SystemFontDesign, size: Double, weight: Int)
    /// An installed named face.
    case custom(String, size: Double, weight: Int)

    /// A system font design.
    public enum SystemFontDesign: String, Sendable, Hashable {
        /// SF.
        case standard
        /// New York.
        case serif
        /// SF Mono.
        case monospaced
    }

    /// Decides the plan for a text spec.
    ///
    /// - Parameters:
    ///   - spec: The text style.
    ///   - isInstalled: Whether a font with this name is installed; the default asks the platform.
    public static func make(_ spec: TextSpec, isInstalled: (String) -> Bool = FontPlan.platformHasFont) -> FontPlan {
        if let style = spec.platformStyle { return .platform(style) }
        return resolve(spec.family, size: spec.size, weight: spec.weight, isInstalled: isInstalled)
    }

    private static func resolve(_ family: FontFamilyRef, size: Double, weight: Int, isInstalled: (String) -> Bool) -> FontPlan {
        switch family {
        case .sans: return .system(.standard, size: size, weight: weight)
        case .mono: return .system(.monospaced, size: size, weight: weight)
        case .serifNewYork: return .system(.serif, size: size, weight: weight)
        case .serifGaramond:
            for name in ["EB Garamond", "Garamond"] where isInstalled(name) { return .custom(name, size: size, weight: weight) }
            return .system(.serif, size: size, weight: weight)
        case .named(let name, let fallback):
            if isInstalled(name) { return .custom(name, size: size, weight: weight) }
            return resolve(fallback, size: size, weight: weight, isInstalled: isInstalled)
        }
    }

    /// Whether the platform has a font with this name.
    public static func platformHasFont(_ name: String) -> Bool {
        #if canImport(AppKit)
        return NSFont(name: name, size: 12) != nil
        #elseif canImport(UIKit)
        return UIFont(name: name, size: 12) != nil
        #else
        return false
        #endif
    }
}

/// A text role resolved for SwiftUI: the font and the settings that go with it.
@available(macOS 14.0, iOS 17.0, visionOS 1.0, tvOS 17.0, watchOS 10.0, *)
public struct ChartText: Sendable {
    /// The role.
    public var role: TypeRole
    /// The spec it came from.
    public var spec: TextSpec
    /// How the font was chosen.
    public var plan: FontPlan
    /// The font.
    public var font: Font
    /// Letter spacing in points (the spec's em tracking times its size).
    public var tracking: CGFloat
    /// Extra line spacing in points: the spec's line height beyond one line.
    public var lineSpacing: CGFloat
    /// Whether the text is set in capitals.
    public var isUppercase: Bool

    /// Creates the resolved text for a role.
    public init(role: TypeRole, spec: TextSpec, isInstalled: (String) -> Bool = FontPlan.platformHasFont) {
        self.role = role
        self.spec = spec
        let plan = FontPlan.make(spec, isInstalled: isInstalled)
        self.plan = plan
        var font = Self.font(for: plan)
        if spec.italic { font = font.italic() }
        self.font = font
        self.tracking = CGFloat(spec.tracking * spec.size)
        self.lineSpacing = CGFloat(max(spec.lineHeight - 1, 0) * spec.size)
        self.isUppercase = spec.uppercase
    }

    /// The SwiftUI weight nearest to a numeric weight, 100 to 900.
    public static func weight(_ number: Int) -> Font.Weight {
        switch min(max(number, 100), 900) {
        case ..<150: .ultraLight
        case ..<250: .thin
        case ..<350: .light
        case ..<450: .regular
        case ..<550: .medium
        case ..<650: .semibold
        case ..<750: .bold
        case ..<850: .heavy
        default: .black
        }
    }

    private static func font(for plan: FontPlan) -> Font {
        switch plan {
        case .platform(let style):
            switch style {
            case .title: return .title
            case .headline: return .headline
            case .subheadline: return .subheadline
            case .body: return .body
            case .caption: return .caption
            case .caption2: return .caption2
            }
        case .system(let design, let size, let weight):
            let mapped: Font.Design = switch design {
            case .standard: .default
            case .serif: .serif
            case .monospaced: .monospaced
            }
            return .system(size: CGFloat(size), weight: Self.weight(weight), design: mapped)
        case .custom(let name, let size, let weight):
            return Font.custom(name, fixedSize: CGFloat(size)).weight(Self.weight(weight))
        }
    }
}

@available(macOS 14.0, iOS 17.0, visionOS 1.0, tvOS 17.0, watchOS 10.0, *)
public extension ChartStyle {
    /// The resolved text for a role.
    func text(_ role: TypeRole) -> ChartText {
        ChartText(role: role, spec: theme.structure.type[role])
    }
}

@available(macOS 14.0, iOS 17.0, visionOS 1.0, tvOS 17.0, watchOS 10.0, *)
public extension View {
    /// Sets a text role's font, tracking, line spacing and case. The foreground colour is not touched: pick
    /// `style.ink`, `style.secondaryInk` or another role.
    func chartText(_ role: TypeRole, in style: ChartStyle) -> some View {
        let text = style.text(role)
        return self
            .font(text.font)
            .tracking(text.tracking)
            .lineSpacing(text.lineSpacing)
            .textCase(text.isUppercase ? .uppercase : nil)
    }
}
#endif
