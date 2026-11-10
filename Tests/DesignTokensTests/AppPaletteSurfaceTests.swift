import Foundation
import Testing
@testable import DesignTokens

@Suite("App palette: window and surface (0.10.0)")
struct AppPaletteSurfaceTests {
    private let window = Adaptive(light: 0xECECEC, dark: 0x323232)
    private let card = Adaptive(light: 0xFFFFFF, dark: 0x1C1C1E)

    @Test("the composed theme's background and surface are the palette's, in every slot")
    func composedCarriesSurfaces() {
        let palette = AppPalette(id: "s", background: window, surface: card)
        let theme = Theme.swiss.composed(with: palette)
        #expect(theme.palette.background == window)
        #expect(theme.palette.surface == card)
        #expect(theme.appearances == .both)
    }

    @Test("a palette that declares neither leaves Swiss's surfaces, so 0.9.0 palettes compose as before")
    func absentKeepsSwiss() {
        let theme = Theme.swiss.composed(with: AppPalette(id: "plain"))
        #expect(theme.palette.background == Theme.swiss.palette.background)
        #expect(theme.palette.surface == Theme.swiss.palette.surface)
    }

    @Test("a surface with no dark value demotes a both-appearance composition to light only, inventing nothing")
    func darkDemotion() {
        let theme = Theme.swiss.composed(with: AppPalette(id: "s", background: Adaptive(light: 0xECECEC)))
        #expect(theme.appearances == .lightOnly)
        #expect(theme.palette.background.dark == nil)
    }

    @Test("a declared background that Swiss's ink cannot read on is a failing textContrast finding naming ink, per appearance")
    func inkMeasuredOnDeclaredBackground() throws {
        let palette = AppPalette(id: "murky", background: Adaptive(light: 0x555555, dark: 0xCCCCCC))
        let result = palette.validate()
        let light = try #require(result.findings.first { $0.appearance == .light && $0.subject == "ink on background" })
        #expect(light.check == .textContrast && light.severity == .fail)
        #expect(result.findings.contains { $0.appearance == .dark && $0.subject == "ink on background" })
        #expect(result.findings.contains { $0.subject == "secondaryInk on background" })
        #expect(!result.isConformant)
    }

    @Test("window and card greys that Swiss's ink and secondary ink read on declare cleanly")
    func readableSurfacesConform() {
        let result = AppPalette(id: "ok", background: window, surface: card).validate()
        // Swiss's secondary ink is 4.40:1 on #ECECEC (see DashboardShapedExampleTests), so the honest result names it.
        #expect(result.findings.filter { $0.subject.hasPrefix("ink on") }.isEmpty, "\(result.report)")
    }

    @Test("a text role named like a theme role is measured once, not twice")
    func noDuplicateFindings() {
        let palette = AppPalette(id: "d", background: Adaptive(light: 0x555555, dark: 0x323232),
                                 textRoles: [NamedAdaptive("ink", light: 0x666666, dark: 0xF2F2F2)])
        let subjects = palette.validate().findings.filter { $0.appearance == .light }.map(\.subject)
        #expect(subjects.filter { $0 == "ink on background" }.count == 1)
    }

    @Test("text roles with no textSurfaces are measured on the declared background and surface")
    func textRolesUseDeclaredSurfaces() {
        let palette = AppPalette(id: "t", background: Adaptive(light: 0x202020, dark: 0x323232),
                                 textRoles: [NamedAdaptive("note", light: 0x000000, dark: 0xFFFFFF)])
        let findings = palette.validate().findings.filter { $0.subject == "note on background" }
        // Black reads on Swiss's #FAFAFA (so the finding exists only because the declared #202020 is the surface) and not on it.
        #expect(findings.contains { $0.appearance == .light && $0.check == .textContrast })
        #expect(!findings.contains { $0.appearance == .dark }, "white on #323232 is 12:1")
    }

    @Test("Codable: the keys round trip, and 0.9.0 JSON without them decodes to nil")
    func codable() throws {
        let palette = AppPalette(id: "c", background: window, surface: card)
        let data = try JSONEncoder().encode(palette)
        #expect(try JSONDecoder().decode(AppPalette.self, from: data) == palette)
        let old = try JSONEncoder().encode(AppPalette(id: "old"))
        let text = try #require(String(data: old, encoding: .utf8))
        #expect(!text.contains("\"background\""))
        let decoded = try JSONDecoder().decode(AppPalette.self, from: old)
        #expect(decoded.background == nil && decoded.surface == nil)
    }
}
