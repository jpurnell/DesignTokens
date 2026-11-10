import Foundation
import Testing
@testable import DesignTokens

/// The quality-gate dashboard's `DashboardChartTheme.swift`, re-expressed on 0.10.0: it cloned Swiss, zeroed the background's alpha
/// and swapped `secondaryInk` by hand, and could then not run `ThemeValidator` on the result. Now the palette declares both and
/// the package composes and measures them.
@Suite("Dashboard shaped: a palette that declares its own window")
struct DashboardWindowSurfaceTests {
    private static let palette = AppPalette(
        id: "ijs-dashboard-window",
        background: Adaptive(light: ColorValue(RGB(rgb: 0xECECEC), alpha: 0), dark: ColorValue(RGB(rgb: 0x323232), alpha: 0)),
        textRoles: [NamedAdaptive("secondaryInk", light: 0x5C5C61, dark: 0xAEAEB2),
                    NamedAdaptive("failure", light: 0xC4161C, dark: 0xFF6961)],
        textSurfaces: TextSurfaces(light: [0xFFFFFF, 0xF2F2F7, 0xECECEC], dark: [0x000000, 0x1C1C1E, 0x323232]))

    @Test("the composed theme has a clear background in both appearances and the app's secondary ink, as the hand-built one did")
    func composes() throws {
        let theme = Theme.swiss.composed(with: Self.palette)
        let dark = try #require(theme.palette.background.dark)
        #expect(abs(theme.palette.background.light.alpha) < 1e-12)
        #expect(abs(dark.alpha) < 1e-12)
        #expect(theme.palette.secondaryInk == Adaptive(light: 0x5C5C61, dark: 0xAEAEB2))
        #expect(theme.id == "swiss+ijs-dashboard-window")
        #expect(theme.appearanceIssues.isEmpty)
    }

    @Test("and it validates, which the hand-built theme could not: ink and the secondary ink read on every window grey")
    func validates() {
        let result = Self.palette.validate()
        #expect(result.isConformant, "\(result.report)")
        #expect(result.findings.isEmpty, "\(result.report)")
    }
}
