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

/// Values read from a running System 7.0 (Infinite Mac, 2026-11-18); see `project/docs/technical/SkinMeasurements.md`.
@Suite("System 7 oracle measurements")
struct System7OracleTests {
    /// Whole pixels, so the comparison is between integers.
    private func edgeWidths(_ role: SurfaceRole) -> [Int]? {
        Theme.system7.surfaces?.recipe(for: role, in: .rest)?.edges?.top.compactMap { Int(exactly: $0.width) }
    }

    @Test("a button has a one-pixel outline and a three-pixel corner")
    func button() {
        #expect(edgeWidths(.button) == [1])
        #expect(Theme.system7.surfaces?.recipe(for: .button, in: .rest)?.radius == .uniform(3))
    }

    @Test("the default button has a three-pixel ring, one pixel of white, then the outline")
    func defaultRing() {
        #expect(edgeWidths(.buttonDefault) == [3, 1, 1])
    }
}

@Suite("Control height")
struct ControlHeightTests {
    @Test("a theme with no control height writes no --control-height and keeps the 44 px floor as the fallback")
    func absentByDefault() throws {
        let css = try ThemeCSSEmitter.emit(.swiss)
        #expect(!css.contains("--control-height"))
        #expect(ComponentsCSSEmitter.emit().contains("min-block-size: var(--control-height, calc(var(--space-unit) * 11));"))
    }

    @Test("System 7 declares the measured 20 px control height")
    func system7Height() throws {
        #expect(Theme.system7.structure.layout.controlHeight == 20)
        #expect(try ThemeCSSEmitter.emit(.system7).contains("--control-height: 20px;"))
    }

    @Test("the control height survives the codec")
    func roundTrip() throws {
        let data = try ThemeCodec.encode(.system7)
        #expect(try ThemeCodec.decode(data).structure.layout.controlHeight == 20)
    }
}

@Suite("System 7 type and control padding")
struct System7TypeTests {
    private func value(_ name: String, in css: String) -> String? {
        for line in css.split(whereSeparator: \.isNewline) {
            let text = line.trimmingCharacters(in: .whitespaces)
            if text.hasPrefix("\(name):") { return String(text.dropFirst(name.count + 1)).trimmingCharacters(in: CharacterSet(charactersIn: "; ")) }
        }
        return nil
    }

    @Test("UI text is 12 px, the size of Chicago on a Macintosh, with a 15 px line")
    func uiSizes() throws {
        let css = try ThemeCSSEmitter.emit(.system7)
        #expect(value("--type-body-size", in: css) == "12px")
        #expect(value("--type-body-line", in: css) == "1.25")
        #expect(value("--type-label-size", in: css) == "12px")
        #expect(value("--type-body-family", in: css)?.hasPrefix("\"Chicago\", \"Geneva\"") == true)
    }

    @Test("a fixed control height pads the label block-wise to (height - line) / 2: (20 - 15) / 2 = 2.5 px")
    func controlPadding() throws {
        let css = try ThemeCSSEmitter.emit(.system7)
        #expect(value("--control-pad-y", in: css) == "2.5px")
        #expect(try ThemeCSSEmitter.emit(.swiss).contains("--control-pad-y") == false)
        #expect(ComponentsCSSEmitter.emit().contains("padding: var(--control-pad-y, calc(var(--space-unit) * 1)) calc(var(--space-unit) * 4);"))
    }
}

@Suite("Default button ring takes room")
struct DefaultRingRoomTests {
    private func rule(_ selector: String, in css: String) -> [String] {
        var lines: [String] = []
        var inside = false
        for line in css.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline) {
            if line == "\(selector) {" { inside = true; continue }
            if inside, line == "}" { return lines }
            if inside { lines.append(line.trimmingCharacters(in: .whitespaces)) }
        }
        return lines
    }

    @Test("the ring is the default button's edge depth beyond the ordinary button's: System 7 3+1+1 over 1 is 4, Platinum 6 over 3 is 3")
    func extraDepth() throws {
        #expect(Theme.system7.surfaces?.defaultRingExtra == 4)
        #expect(Theme.platinum.surfaces?.defaultRingExtra == 3)
        #expect(Theme.swiss.surfaces == nil)
    }

    @Test("web: the default button grows by the ring on every side, so the label keeps its room")
    func webGrows() throws {
        let css = try ThemeCSSEmitter.emit(.system7)
        let primary = rule("[data-theme-name=\"system7\"] .dt-button--primary", in: css)
        #expect(primary.contains("min-block-size: calc(var(--control-height, calc(var(--space-unit) * 11)) + 8px);"))
        #expect(primary.contains("padding: var(--control-pad-y, calc(var(--space-unit) * 1)) calc(var(--space-unit) * 4 + 4px);"))
        #expect(rule("[data-theme-name=\"platinum\"] .dt-button--primary", in: try ThemeCSSEmitter.emit(.platinum)).contains("min-block-size: calc(var(--control-height, calc(var(--space-unit) * 11)) + 6px);"))
    }

    @Test("GTK: the default button is the control height plus the ring on each side, with the ring added to the side padding")
    func gtkGrows() throws {
        let slot = try #require(ThemeSlot.slots(for: .system7).first)
        let css = try GTKEmitter.emit(.system7, slot: slot)
        let lines = rule("button.suggested-action, button.default", in: css)
        #expect(lines.contains("min-height: 28px;"))
        #expect(lines.contains("padding: 0 20px;"))
    }
}
