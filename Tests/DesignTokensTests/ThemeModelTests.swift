import Foundation
import Testing
@testable import DesignTokens

@Suite("Theme model")
struct ThemeModelTests {
    /// Every token with its theme role, light/dark and with Increase Contrast on or off.
    private static let appearances: [(Appearance, Bool)] = [(.light, false), (.dark, false), (.light, true), (.dark, true)]

    @Test("Theme.swiss is built from ColorToken, Palette and Rule")
    func swissIsBuiltFromTokens() {
        let swiss = Theme.swiss
        #expect(swiss.id == "swiss")
        #expect(swiss.appearances == .both)
        // Palette half: series are Palette's series, in order, with names, in all four slots.
        #expect(swiss.palette.series.map(\.name) == Palette.seriesNames)
        #expect(swiss.palette.series.map(\.color.light.rgb) == Palette.series)
        #expect(swiss.palette.series.compactMap(\.color.dark?.rgb) == Palette.seriesDark)
        #expect(swiss.palette.series.compactMap(\.color.lightIncreased?.rgb) == Palette.seriesIncreasedContrast)
        #expect(swiss.palette.series.compactMap(\.color.darkIncreased?.rgb) == Palette.seriesIncreasedContrastDark)
        #expect(swiss.palette.sequential.light.map(\.rgb) == Palette.sequential)
        #expect(swiss.palette.sequential.dark?.map(\.rgb) == Palette.sequentialDark)
        #expect(swiss.palette.diverging.light.map(\.rgb) == Palette.diverging)
        #expect(swiss.palette.diverging.dark == nil)
        // Structure half: weights come from Rule, layout from Grid and Radius.
        #expect(swiss.structure.rules.title.weight.isEqual(to: Double(Rule.section.points)))
        // the approved Hybrid chart sets the rule above the title (chart alignment, 2026-11-09)
        #expect(swiss.structure.rules.title.position == .aboveTitle)
        #expect(swiss.structure.rules.section.isEqual(to: Double(Rule.section.points)))
        #expect(swiss.structure.rules.hairline.isEqual(to: Double(Rule.hairline.points)))
        #expect(swiss.structure.rules.page.isEqual(to: Double(Rule.page.points)))
        #expect(swiss.structure.rules.gridline == 1)
        #expect(swiss.structure.rules.baseline.isEqual(to: 1.5))
        #expect(swiss.structure.layout.columns == Grid.columns)
        #expect(swiss.structure.layout.gutter.isEqual(to: Double(Grid.gutter)))
        #expect(swiss.structure.layout.containerRadius.isEqual(to: Double(Radius.container)))
        #expect(swiss.structure.layout.controlRadius.isEqual(to: Double(Radius.control)))
        #expect(swiss.structure.marks.barFill == .flat)
        #expect(swiss.structure.labels.values == .aboveOrEnd)
    }

    @Test("Adaptive resolves exactly as ColorToken does, for nine of the eleven roles in all four slots; success and destructive are deliberately not Swiss's positive and negative")
    func adaptiveAgreesWithColorTokenForAllRoles() {
        #expect(ColorToken.allCases.count == 11)
        for token in ColorToken.allCases where token != .success && token != .destructive {
            let adaptive = Theme.swiss.palette[token.themeRole]
            for (appearance, increased) in Self.appearances {
                let resolved = adaptive.value(in: appearance, increasedContrast: increased)
                let expected = token.value(in: appearance, increasedContrast: increased)
                #expect(resolved.rgb == expected, "\(token) \(appearance) increased=\(increased)")
                #expect(resolved.alpha == 1)
            }
        }
        // owner decision 2026-11-09: gain and loss are the text-safe pair; the tokens stay the system colours
        for token in [ColorToken.success, .destructive] {
            let adaptive = Theme.swiss.palette[token.themeRole]
            #expect(adaptive.value(in: .light, increasedContrast: false).rgb != token.value(in: .light, increasedContrast: false), "\(token) light")
            #expect(adaptive.value(in: .light, increasedContrast: true).rgb != token.value(in: .light, increasedContrast: true), "\(token) light increased")
            // the dark standard value is the same system dark colour, on purpose (9.35:1 and 5.51:1 as text)
            #expect(adaptive.value(in: .dark, increasedContrast: false).rgb == token.value(in: .dark, increasedContrast: false), "\(token) dark")
            #expect(adaptive.value(in: .dark, increasedContrast: true).rgb == token.value(in: .dark, increasedContrast: true), "\(token) dark increased")
        }
    }

    @Test("Adaptive increased-contrast falls back to the standard value, never to the other appearance")
    func adaptiveFallbackRule() {
        let a = Adaptive(light: ColorValue(RGB(rgb: 0x111111)), dark: ColorValue(RGB(rgb: 0xEEEEEE)),
                         lightIncreased: nil, darkIncreased: ColorValue(RGB(rgb: 0xFFFFFF)))
        #expect(a.value(in: .light, increasedContrast: true).rgb == RGB(rgb: 0x111111))
        #expect(a.value(in: .dark, increasedContrast: true).rgb == RGB(rgb: 0xFFFFFF))
        let lightOnly = Adaptive(light: ColorValue(RGB(rgb: 0x123456)))
        #expect(lightOnly.value(in: .dark, increasedContrast: false).rgb == RGB(rgb: 0x123456))
    }

    @Test("system colour names mark the slots that Apple adapters defer to")
    func swissSystemNames() {
        #expect(Theme.swiss.palette.series.map(\.color.system) == [.orange, .indigo, .green, .purple, .yellow, .blue, .red, .cyan])
        #expect(Theme.swiss.palette.accent.system == .orange)
        #expect(Theme.swiss.palette.ink.system == nil)
    }

    @Test("the existing tokens.css is unchanged: byte-identical to the 0.3.0 file")
    func existingTokensCSSUnchanged() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        let css = try Data(contentsOf: root.appendingPathComponent("Generated/tokens.css"))
        let json = try Data(contentsOf: root.appendingPathComponent("Generated/tokens.json"))
        #expect(Data(CSSEmitter.emit().utf8) == css)
        #expect(Data(JSONEmitter.emit().utf8) == json)
        // FNV-1a 64 of the 0.3.0 files, computed before any 0.4.0 change.
        #expect(Fingerprint.fnv1a64(css) == "e369026e87dc1c4e")
        #expect(Fingerprint.fnv1a64(json) == "1212e00e2d6ae09c")
    }

    @Test("an alpha colour round-trips as #RRGGBBAA, an opaque one as #RRGGBB")
    func alphaColourRoundTripsAsRRGGBBAA() throws {
        let translucent = try #require(ColorValue(hex: "#FFFFFF26"))
        #expect(translucent.rgb == RGB(rgb: 0xFFFFFF))
        #expect(translucent.alpha.isEqual(to: Double(0x26) / 255))
        #expect(translucent.hex == "#FFFFFF26")
        let opaque = try #require(ColorValue(hex: "#ff8d28"))
        #expect(opaque.alpha == 1)
        #expect(opaque.hex == "#FF8D28")
        #expect(ColorValue(hex: "#FF8D28FF")?.hex == "#FF8D28")
        #expect(ColorValue(hex: "#12345") == nil)
        #expect(ColorValue(hex: "#GG0000") == nil)
        // through JSON
        let data = try JSONEncoder().encode([translucent])
        #expect(String(decoding: data, as: UTF8.self) == "[\"#FFFFFF26\"]")
        #expect(try JSONDecoder().decode([ColorValue].self, from: data) == [translucent])
        // alpha is quantised to a byte, so any alpha survives the trip
        let odd = ColorValue(RGB(rgb: 0x102030), alpha: 0.3)
        #expect(try JSONDecoder().decode([ColorValue].self, from: JSONEncoder().encode([odd])) == [odd])
    }

    @Test("alpha is clamped to 0...1 and a NaN alpha is opaque")
    func alphaIsClamped() {
        #expect(ColorValue(RGB(rgb: 0), alpha: 2).alpha == 1)
        #expect(ColorValue(RGB(rgb: 0), alpha: -1).alpha == 0)
        #expect(ColorValue(RGB(rgb: 0), alpha: .nan).alpha == 1)
    }
}

@Suite("Theme appearance rule")
struct ThemeAppearanceTests {
    @Test("a light-only theme rejects a dark value on any role")
    func lightOnlyThemeRejectsDarkValue() throws {
        var theme = Theme.swiss
        theme.appearances = .lightOnly
        // Swiss carries dark everywhere, so declared light-only it is wrong on every Adaptive.
        let issues = theme.appearanceIssues
        #expect(!issues.isEmpty)
        #expect(issues.allSatisfy { $0.kind == .unexpectedDark })
        #expect(issues.contains { $0.subject == "palette.ink" })
        #expect(issues.contains { $0.subject == "palette.series.orange" })
        // and the codec refuses it in both directions: it will not write it, and it will not read it
        #expect(throws: ThemeError.self) { try ThemeCodec.encode(theme) }
        let valid = try ThemeCodec.encode(.swiss)
        let flipped = Data(String(decoding: valid, as: UTF8.self)
            .replacingOccurrences(of: "\"appearances\" : \"both\"", with: "\"appearances\" : \"lightOnly\"").utf8)
        #expect(flipped != valid, "the fixture really changed")
        #expect(throws: ThemeError.self) { try ThemeCodec.decode(flipped) }

        // A genuinely light-only theme is clean.
        var clean = Theme.swiss
        clean.appearances = .lightOnly
        clean.palette = clean.palette.strippingDark()
        #expect(clean.appearanceIssues.isEmpty)
        #expect(clean.palette.ink.value(in: .dark, increasedContrast: false) == clean.palette.ink.light)
    }

    @Test("a both-appearance theme requires a dark value on every role and every series entry")
    func bothThemeRequiresDarkOnEveryRole() throws {
        #expect(Theme.swiss.appearanceIssues.isEmpty)
        for role in ColorRole.allCases {
            var theme = Theme.swiss
            theme.palette[role].dark = nil
            let issues = theme.appearanceIssues
            #expect(issues.map(\.kind) == [.missingDark], "role \(role)")
            #expect(issues.first?.subject == "palette.\(role.rawValue)")
        }
        var seriesTheme = Theme.swiss
        seriesTheme.palette.series[2].color.dark = nil
        #expect(seriesTheme.appearanceIssues.map(\.subject) == ["palette.series.green"])
        #expect(throws: ThemeError.self) { try ThemeCodec.decode(ThemeCodec.encode(seriesTheme)) }
    }
}

@Suite("Theme canonical JSON")
struct ThemeCodecTests {
    private func sampleWithExtras() -> Theme {
        var theme = Theme.swiss
        theme.palette.extraRamps = [
            "volatility": Ramp(light: [ColorValue(RGB(rgb: 0x0000FF)), ColorValue(RGB(rgb: 0xFF0000))], dark: nil),
            "sharpe": Ramp(light: [ColorValue(RGB(rgb: 0x00FF00))], dark: [ColorValue(RGB(rgb: 0x112233), alpha: 0.5)]),
            "alpha": Ramp(light: [], dark: nil),
        ]
        return theme
    }

    @Test("encode(decode(encode(t))) == encode(t), byte for byte")
    func themeRoundTripsDeterministically() throws {
        for theme in [Theme.swiss, sampleWithExtras()] {
            let first = try ThemeCodec.encode(theme)
            let decoded = try ThemeCodec.decode(first)
            #expect(decoded == theme)
            let second = try ThemeCodec.encode(decoded)
            #expect(first == second)
            // stable across repeated encodes in one process, too
            for _ in 0..<5 { #expect(try ThemeCodec.encode(theme) == first) }
        }
    }

    @Test("dictionaries encode as JSON objects with String keys, never as enum-keyed arrays")
    func dictionaryKeysAreStringsNotEnums() throws {
        let data = try ThemeCodec.encode(sampleWithExtras())
        let object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let palette = try #require(object["palette"] as? [String: Any])
        // an enum-keyed dictionary would arrive as an array; a String-keyed one is an object
        let extra = try #require(palette["extraRamps"] as? [String: Any])
        #expect(Set(extra.keys) == ["volatility", "sharpe", "alpha"])
        // Roles are fixed fields, not a role-keyed dictionary
        for role in ColorRole.allCases { #expect(palette[role.rawValue] is [String: Any], "\(role)") }
        // Keys are emitted sorted: "alpha" before "sharpe" before "volatility" in the text
        let text = String(decoding: data, as: UTF8.self)
        let a = try #require(text.range(of: "\"alpha\""))
        let s = try #require(text.range(of: "\"sharpe\""))
        let v = try #require(text.range(of: "\"volatility\""))
        #expect(a.lowerBound < s.lowerBound && s.lowerBound < v.lowerBound)
    }

    @Test("the canonical text ends with a newline, has no escaped slashes and is stable under reordering")
    func canonicalFormat() throws {
        let data = try ThemeCodec.encode(Theme.swiss)
        let text = String(decoding: data, as: UTF8.self)
        #expect(text.hasSuffix("}\n"))
        #expect(!text.contains("\\/"))
        #expect(text.contains("\"id\" : \"swiss\""))
        #expect(text.contains("\"ink\""))
    }

    /// The same JSON written with its object keys in descending order, at every depth.
    private func descendingKeyJSON(_ node: Any) -> String {
        if let dictionary = node as? [String: Any] {
            let members = dictionary.keys.sorted(by: >).map { key in
                "\(descendingKeyJSON(key)):\(descendingKeyJSON(dictionary[key] ?? NSNull()))"
            }
            return "{" + members.joined(separator: ",") + "}"
        }
        if let array = node as? [Any] { return "[" + array.map(descendingKeyJSON).joined(separator: ",") + "]" }
        if let text = node as? String {
            return (try? String(decoding: JSONEncoder().encode(text), as: UTF8.self)) ?? "\"\""
        }
        if let number = node as? NSNumber {
            return (number === NSNumber(value: true) || number === NSNumber(value: false)) ? number.boolValue.description : "\(number)"
        }
        return "null"
    }

    @Test("the canonical bytes do not depend on the order of the keys in the input")
    func canonicalBytesIgnoreInputKeyOrder() throws {
        for theme in [Theme.swiss, Theme.legacyDefault, sampleWithExtras()] {
            let canonical = try ThemeCodec.encode(theme)
            let object = try JSONSerialization.jsonObject(with: canonical)
            let reversed = descendingKeyJSON(object)
            #expect(reversed != String(decoding: canonical, as: UTF8.self), "\(theme.id): the input really is reordered")
            #expect(reversed.contains("\"series\""))
            let decoded = try ThemeCodec.decode(Data(reversed.utf8))
            #expect(decoded == theme, "\(theme.id)")
            #expect(try ThemeCodec.encode(decoded) == canonical, "\(theme.id)")
        }
    }

    @Test("decoding junk throws instead of returning a default theme")
    func decodeJunkThrows() {
        #expect(throws: (any Error).self) { try ThemeCodec.decode(Data("{}".utf8)) }
        #expect(throws: (any Error).self) { try ThemeCodec.decode(Data("not json".utf8)) }
    }

    @Test("a named font keeps its fallback through the codec")
    func namedFontKeepsFallback() throws {
        var theme = Theme.swiss
        theme.structure.type.title.family = .named("Econ Sans Cnd", fallback: .sans)
        theme.structure.type.tag.family = .named("Fancy", fallback: .named("Less Fancy", fallback: .serifNewYork))
        let decoded = try ThemeCodec.decode(ThemeCodec.encode(theme))
        #expect(decoded.structure.type.title.family == .named("Econ Sans Cnd", fallback: .sans))
        #expect(decoded.structure.type.tag.family == .named("Fancy", fallback: .named("Less Fancy", fallback: .serifNewYork)))
    }

    @Test("a stable content hash identifies the canonical bytes")
    func fingerprint() throws {
        let data = try ThemeCodec.encode(Theme.swiss)
        #expect(try ThemeCodec.fingerprint(of: Theme.swiss) == Fingerprint.fnv1a64(data))
        #expect(Fingerprint.fnv1a64(Data()) == "cbf29ce484222325")
        #expect(Fingerprint.fnv1a64(Data("a".utf8)) == "af63dc4c8601ec8c")
        var changed = Theme.swiss
        changed.structure.rules.title.weight = 8
        #expect(try ThemeCodec.fingerprint(of: changed) != ThemeCodec.fingerprint(of: Theme.swiss))
        var broken = Theme.swiss
        broken.structure.rules.title.weight = .nan
        #expect(throws: (any Error).self) { try ThemeCodec.fingerprint(of: broken) }
    }
}

@Suite("AppPalette")
struct AppPaletteTests {
    private let wine = AppPalette(
        id: "winetaster",
        accent: Adaptive(light: ColorValue(RGB(rgb: 0x7F0017)), dark: ColorValue(RGB(rgb: 0xE0788A))),
        series: [NamedAdaptive(name: "red", color: Adaptive(light: ColorValue(RGB(rgb: 0x7F0017)), dark: ColorValue(RGB(rgb: 0xE0788A)))),
                 NamedAdaptive(name: "light white", color: Adaptive(light: ColorValue(RGB(rgb: 0xE9D98B)), dark: ColorValue(RGB(rgb: 0xE9D98B))))],
        seriesOrder: .entityOrder(labelRequired: [SeriesPair("light white", "full white")]))

    @Test("composing replaces accent and series and keeps structure and surfaces")
    func composedKeepsStructure() {
        let themed = Theme.swiss.composed(with: wine)
        #expect(themed.structure == Theme.swiss.structure)
        #expect(themed.palette.background == Theme.swiss.palette.background)
        #expect(themed.palette.ink == Theme.swiss.palette.ink)
        #expect(themed.palette.accent == wine.accent)
        #expect(themed.palette.series.map(\.name) == ["red", "light white"])
        #expect(themed.palette.sequential == Theme.swiss.palette.sequential)
        #expect(themed.id == "swiss+winetaster")
        #expect(themed.appearances == .both)
    }

    @Test("a palette that supplies nothing leaves the theme's own colours, and composing is not mutation")
    func composedWithEmptyPalette() {
        let none = AppPalette(id: "none", accent: nil, series: nil, seriesOrder: .validatedOrder)
        #expect(Theme.swiss.composed(with: none).palette == Theme.swiss.palette)
        _ = Theme.swiss.composed(with: wine)
        #expect(Theme.swiss.palette.series.count == 8)
    }

    @Test("an app palette round-trips through the codec with its entity-order pairs")
    func codecRoundTrip() throws {
        let data = try ThemeCodec.encode(wine)
        #expect(try ThemeCodec.decodeAppPalette(data) == wine)
        #expect(try ThemeCodec.encode(ThemeCodec.decodeAppPalette(data)) == data)
        #expect(wine.seriesOrder.labelRequired == [SeriesPair("light white", "full white")])
        #expect(AppPalette(id: "x", accent: nil, series: nil, seriesOrder: .validatedOrder).seriesOrder.labelRequired.isEmpty)
    }
}

@Suite("Numeric TypeStyle")
struct NumericTypeStyleTests {
    @Test("numeric size, line height and tracking per role")
    func numericAccessors() {
        #expect(TypeStyle.label.points == 11)
        #expect(TypeStyle.caption.points == 13)
        #expect(TypeStyle.body.points == 16)
        #expect(TypeStyle.heading.points == 28)
        #expect(TypeStyle.title.points == 34)
        #expect(TypeStyle.body.lineHeight.isEqual(to: 1.5))
        #expect(TypeStyle.display.lineHeight.isEqual(to: 0.86))
        #expect(TypeStyle.label.trackingEm.isEqual(to: 0.08))
        #expect(TypeStyle.title.trackingEm == -0.03)
        #expect(TypeStyle.body.trackingEm == 0)
    }

    @Test("display is fluid, and its numeric size is the clamp's upper bound")
    func displayIsFluid() {
        let fluid = TypeStyle.display.fluid
        #expect(fluid == FluidSize(min: 64, vw: 13, max: 168))
        #expect(TypeStyle.display.points == 168)
        #expect(TypeStyle.label.fluid == nil)
        #expect(fluid?.css == "clamp(64px, 13vw, 168px)")
    }

    @Test("the CSS strings agree with the numbers, for every role")
    func stringsAgreeWithNumbers() {
        for style in TypeStyle.allCases {
            if let fluid = style.fluid {
                #expect(style.size == fluid.css)
            } else {
                #expect(style.size == "\(Int(style.points))px")
            }
            #expect((Double(style.line) ?? .nan).isEqual(to: style.lineHeight))
            let em = style.trackingEm == 0 ? "0" : "\(style.trackingEm)em"
            #expect(style.tracking == em)
        }
    }

    @Test("Swiss type roles carry the TypeStyle numbers")
    func swissTypeRolesFromTypeStyle() {
        let roles = Theme.swiss.structure.type
        #expect(roles.label.size == TypeStyle.label.points)
        #expect(roles.label.uppercase)
        #expect(roles.body.lineHeight == TypeStyle.body.lineHeight)
        #expect(roles.heading.tracking == TypeStyle.heading.trackingEm)
        #expect(roles.uiTitle.weight == TypeStyle.title.weight)
        #expect(roles.display.size == TypeStyle.display.points)
        #expect(roles.title.size == 17)
        #expect(roles.source.size == 11)
        #expect(roles.tag.weight == 700)
    }
}
