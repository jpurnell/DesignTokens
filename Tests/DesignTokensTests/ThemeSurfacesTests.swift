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

@Suite("Theme surfaces in CSS")
struct ThemeSurfacesCSSTests {
    private func ref(_ name: String) -> ColourReference { ColourReference(source: name) }

    private func themed() throws -> Theme {
        let outline = try EdgeStep(colour: ref("ink"), width: 1)
        let sides = Edges(top: [outline], leading: [outline], bottom: [outline], trailing: [outline])
        let checker = try PatternSpec(width: 2, height: 2, cells: [ref("ink"), ref("background"), ref("background"), ref("ink")])
        let button = SurfaceRecipe(layers: [.fill(ref("background"))], edges: sides, radius: .uniform(0), backdropBlur: nil,
                                   ink: ref("ink"), scale: .integer)
        let pressed = SurfaceRecipe(layers: [.fill(ref("ink"))], edges: sides, radius: .uniform(0), backdropBlur: nil,
                                    ink: ref("background"), scale: .integer)
        let window = SurfaceRecipe(layers: [.pattern(checker)], edges: nil, radius: .uniform(0), backdropBlur: nil,
                                   ink: ref("ink"), scale: .integer)
        var theme = Theme.swiss
        theme.surfaces = SurfaceSet(recipes: [.button: [.rest: button, .active: pressed], .window: [.rest: window]])
        return theme
    }

    @Test("a theme without surfaces emits nothing about them")
    func none() throws {
        #expect(try !ThemeCSSEmitter.emit(Theme.swiss).contains(".dt-button"))
    }

    @Test("a button recipe becomes scoped rules for dt-button, its states and no border")
    func buttonRules() throws {
        let css = try ThemeCSSEmitter.emit(themed())
        #expect(css.contains("[data-theme-name=\"swiss\"] .dt-button {"))
        #expect(css.contains("box-shadow: inset 0 1px 0 0 var(--ink), inset 1px 0 0 0 var(--ink), inset 0 -1px 0 0 var(--ink), inset -1px 0 0 0 var(--ink)"))
        #expect(css.contains("[data-theme-name=\"swiss\"] .dt-button:not(:disabled):active {"))
        #expect(css.contains("border: 0"))
    }

    @Test("a pattern is drawn in literal colours, not custom properties")
    func patternLiteral() throws {
        let css = try ThemeCSSEmitter.emit(themed())
        let page = try #require(css.components(separatedBy: "[data-theme-name=\"swiss\"] .dt-page {").last)
        let rule = String(page.prefix { $0 != "}" })
        #expect(rule.contains("data:image/svg+xml"))
        let image = try #require(rule.split(whereSeparator: \.isNewline).first { $0.contains("background-image") })
        #expect(!image.contains("var(--"))
    }
}

@Suite("Surface set encoding")
struct SurfaceSetEncodingTests {
    @Test("the wire form is objects keyed by role and state, so it is stable and the strict decoder can compare keys")
    func wireForm() throws {
        let recipe = SurfaceRecipe(layers: [.fill(ColourReference(source: "ink"))], edges: nil, radius: .capsule, backdropBlur: nil,
                                   ink: ColourReference(source: "background"), scale: .free)
        let set = SurfaceSet(recipes: [.field: [.rest: recipe], .button: [.active: recipe, .rest: recipe]])
        let json = try String(decoding: JSONEncoder().encode(set), as: UTF8.self)
        #expect(json.hasPrefix("{\"recipes\":{\""))
        #expect(try JSONDecoder().decode(SurfaceSet.self, from: Data(json.utf8)) == set)
    }

    @Test("an unknown role or state is an error, not a dropped entry")
    func unknownNames() {
        let role = Data(#"{"recipes":{"toolbar":{}}}"#.utf8)
        let state = Data(#"{"recipes":{"button":{"pressed":{}}}}"#.utf8)
        #expect(throws: DecodingError.self) { try JSONDecoder().decode(SurfaceSet.self, from: role) }
        #expect(throws: DecodingError.self) { try JSONDecoder().decode(SurfaceSet.self, from: state) }
    }
}
