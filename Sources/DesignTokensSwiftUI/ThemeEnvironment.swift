#if canImport(SwiftUI)
import DesignTokens
import SwiftUI

@available(macOS 14.0, iOS 17.0, visionOS 1.0, tvOS 17.0, watchOS 10.0, *)
private struct ThemeKey: EnvironmentKey {
    /// Swiss, the validated house style (0.9.0; it was ``Theme/legacyDefault`` while the owner had not yet seen the
    /// contact sheets). A view that reads the theme without one injected gets the look an app palette was validated on.
    static let defaultValue: Theme = .swiss
}

@available(macOS 14.0, iOS 17.0, visionOS 1.0, tvOS 17.0, watchOS 10.0, *)
private struct ChartStyleKey: EnvironmentKey {
    static let defaultValue = ChartStyle(theme: .swiss, appearance: .light)
}

@available(macOS 14.0, iOS 17.0, visionOS 1.0, tvOS 17.0, watchOS 10.0, *)
public extension EnvironmentValues {
    /// The active theme. Defaults to ``Theme/swiss`` (0.9.0; it was ``Theme/legacyDefault``). Inject another with
    /// ``SwiftUI/View/chartTheme(_:)``.
    var theme: Theme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }

    /// The active theme resolved for the appearance and contrast it was injected under.
    ///
    /// Set by ``SwiftUI/View/chartTheme(_:)``. It is a snapshot taken where the modifier sits: a subtree that
    /// changes `colorScheme` below it keeps the outer value. Use ``ChartStyleReader`` where the subtree's own
    /// environment must decide.
    var chartStyle: ChartStyle {
        get { self[ChartStyleKey.self] }
        set { self[ChartStyleKey.self] = newValue }
    }
}

/// Reads the environment's theme, colour scheme and contrast and hands the content a resolved ``ChartStyle``.
///
/// Because it reads the environment where it is placed, it is always current for its own subtree.
@available(macOS 14.0, iOS 17.0, visionOS 1.0, tvOS 17.0, watchOS 10.0, *)
public struct ChartStyleReader<Content: View>: View {
    @Environment(\.theme) private var theme
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.colorSchemeContrast) private var contrast
    private let content: (ChartStyle) -> Content

    /// Creates a reader.
    public init(@ViewBuilder content: @escaping (ChartStyle) -> Content) {
        self.content = content
    }

    /// The content, given the style resolved from this view's own environment.
    public var body: some View {
        content(ChartStyle(theme: theme, colorScheme: colorScheme, contrast: contrast))
    }
}

@available(macOS 14.0, iOS 17.0, visionOS 1.0, tvOS 17.0, watchOS 10.0, *)
private struct ChartThemeModifier: ViewModifier {
    let theme: Theme
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.colorSchemeContrast) private var contrast

    func body(content: Content) -> some View {
        content
            .environment(\.theme, theme)
            .environment(\.chartStyle, ChartStyle(theme: theme, colorScheme: colorScheme, contrast: contrast))
    }
}

@available(macOS 14.0, iOS 17.0, visionOS 1.0, tvOS 17.0, watchOS 10.0, *)
public extension View {
    /// Supplies a theme to this view and everything inside it: sets ``EnvironmentValues/theme`` and
    /// ``EnvironmentValues/chartStyle``.
    func chartTheme(_ theme: Theme) -> some View {
        modifier(ChartThemeModifier(theme: theme))
    }
}
#endif
