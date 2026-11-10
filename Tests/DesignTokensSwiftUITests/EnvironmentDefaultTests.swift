#if canImport(SwiftUI) && os(macOS)
import DesignTokens
import SwiftUI
import Testing
@testable import DesignTokensSwiftUI

/// What a view reads when nothing injected a theme.
@MainActor
@Suite("Environment defaults")
struct EnvironmentDefaultTests {
    @Test("a view with no injected theme reads Swiss, the look the app palettes are validated against")
    func themeDefaultIsSwiss() {
        let environment = EnvironmentValues()
        #expect(environment.theme.id == Theme.swiss.id)
        #expect(environment.theme == Theme.swiss)
    }

    @Test("the resolved chart style defaults to Swiss too, so the two defaults cannot disagree")
    func chartStyleDefaultIsSwiss() {
        let environment = EnvironmentValues()
        #expect(environment.chartStyle.theme == Theme.swiss)
        #expect(environment.chartStyle.theme == environment.theme)
    }

    @Test("injecting another theme still replaces the default")
    func injectionWins() {
        var environment = EnvironmentValues()
        environment.theme = .legacyDefault
        #expect(environment.theme.id == Theme.legacyDefault.id)
    }
}
#endif
