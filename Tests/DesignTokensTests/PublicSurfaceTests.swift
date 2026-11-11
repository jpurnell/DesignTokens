import Testing
import DesignTokens

/// This file imports `DesignTokens` without `@testable`, so it sees only what a package consumer sees. Each registered theme is
/// reachable as a static property, and `Theme.all` and `Theme.named(_:)` agree with them.
@Suite("Public theme surface (0.13.0)")
struct PublicSurfaceTests {
    @Test("every registered theme is a public static property, and the registry returns the same values")
    func themesArePublic() {
        let direct = [Theme.swiss, .house, .princeton, .ft, .economist, .legacyDefault, .legacyDark, .legacyFinancial, .legacyAccessible, .console]
        #expect(direct.map(\.id) == ["swiss", "house", "princeton", "ft", "economist", "legacy-default", "legacy-dark", "legacy-financial", "legacy-accessible", "console"])
        #expect(Theme.all == direct)
        for theme in direct { #expect(Theme.named(theme.id) == theme) }
    }
}
