import Foundation
import Testing
@testable import DesignTokens

/// A theme may carry a ``SurfaceSet``; a theme without one must read and write exactly as before.
@Suite("Theme surfaces")
struct ThemeSurfacesTests {
    private func recipe(fill source: String) -> SurfaceRecipe {
        SurfaceRecipe(layers: [.fill(ColourReference(source: source))], edges: nil, radius: .uniform(0),
                      backdropBlur: nil, ink: ColourReference(source: "ink"), scale: .integer)
    }

    private func themeWithSurfaces(fill source: String) -> Theme {
        var theme = Theme.swiss
        theme.surfaces = SurfaceSet(recipes: [.button: [.rest: recipe(fill: source)]])
        return theme
    }

    @Test("a theme without surfaces writes no surfaces key")
    func absentStaysAbsent() throws {
        let json = try String(decoding: ThemeCodec.encode(Theme.swiss), as: UTF8.self)
        #expect(!json.contains("surfaces"))
        #expect(Theme.swiss.surfaces == nil)
    }

    @Test("surfaces survive the canonical codec")
    func roundTrip() throws {
        let theme = themeWithSurfaces(fill: "surface")
        let decoded = try ThemeCodec.decode(ThemeCodec.encode(theme))
        #expect(decoded == theme)
        #expect(decoded.surfaces?.recipe(for: .button, in: .active) == recipe(fill: "surface"))
    }

    @Test("a surface that names no colour is refused")
    func unknownColour() throws {
        let theme = themeWithSurfaces(fill: "no-such-colour")
        #expect(throws: (any Error).self) { try ThemeCodec.encode(theme) }
    }
}
