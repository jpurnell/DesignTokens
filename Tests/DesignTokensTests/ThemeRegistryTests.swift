import Foundation
import Testing
@testable import DesignTokens

@Suite("Theme registry and themes")
struct ThemeRegistryTests {
    @Test("the registry has a stable order and unique ids")
    func registryOrderIsStable() {
        #expect(Theme.all.map(\.id) == ["swiss", "house", "princeton", "ft", "economist",
                                        "legacy-default", "legacy-dark", "legacy-financial", "legacy-accessible"])
        #expect(Set(Theme.all.map(\.id)).count == Theme.all.count)
        #expect(Theme.all.map(\.id) == Theme.all.map(\.id))
    }

    @Test("every registered theme is consistent, round-trips deterministically and conforms to its ledger")
    func everyRegisteredThemeValidates() throws {
        for theme in Theme.all {
            #expect(theme.appearanceIssues.isEmpty, "\(theme.id): \(theme.appearanceIssues)")
            #expect(ThemeValidator.deviations(of: theme) == [], "\(theme.id)")
            let once = try ThemeCodec.encode(theme)
            let decoded = try ThemeCodec.decode(once)
            #expect(decoded == theme, "\(theme.id) decodes equal")
            #expect(try ThemeCodec.encode(decoded) == once, "\(theme.id) re-encodes to the same bytes")
            #expect(try ThemeCodec.encode(theme) == once, "\(theme.id) encodes the same bytes twice")
        }
    }

    @Test("every theme has a supported series count no more than eight except the two legacy ten")
    func seriesCounts() {
        #expect(Theme.all.filter { $0.palette.series.count > 8 }.map(\.id) == ["legacy-default", "legacy-dark"])
    }

    @Test("House, Economist and FT carry their current EditorialTheme light values")
    func lightValuesAreTheCurrentOnes() {
        #expect(Theme.house.palette.series.map(\.color.light.hex) == ["#2B6CB0", "#DD6B20", "#38A169", "#805AD5", "#D53F8C", "#00A3C4"])
        #expect(Theme.house.palette.background.light.hex == "#FFFFFF")
        #expect(Theme.house.palette.accent.light.hex == "#2B6CB0")
        #expect(Theme.economist.palette.series.map(\.color.light.hex) == ["#006BA2", "#3EBCD2", "#E3120B", "#379A8B", "#EBB434", "#9A607F"])
        #expect(Theme.economist.palette.surface.light.hex == "#F3F2F0")
        #expect(Theme.ft.palette.background.light.hex == "#FFF1E5")
        #expect(Theme.ft.palette.series.map(\.color.light.hex) == ["#0F5499", "#990F3D", "#0D7680", "#FF8833", "#593380", "#9E2F50"])
        #expect(Theme.ft.structure.type.title.family == .serifNewYork)
        #expect(Theme.economist.structure.type.title.family == .named("Econ Sans Cnd", fallback: .sans))
        #expect(Theme.house.appearances == .lightOnly)
    }

    @Test("FT and Economist have an authored dark variant on every role, series and the sequential ramp")
    func ftAndEconomistHaveAuthoredDark() throws {
        for theme in [Theme.ft, Theme.economist] {
            #expect(theme.appearances == .both)
            for role in ColorRole.allCases { _ = try #require(theme.palette[role].dark, "\(theme.id) \(role)") }
            _ = try #require(theme.palette.sequential.dark, "\(theme.id) sequential")
        }
        #expect(Theme.ft.palette.series.compactMap(\.color.dark?.hex) == ["#498AED", "#B83955", "#049EA8", "#B65E02", "#7E4BC6", "#ED446D"])
        #expect(Theme.economist.palette.series.compactMap(\.color.dark?.hex) == ["#0769A8", "#10A4B2", "#E35C42", "#089C85", "#865D00", "#AA3B7D"])
        #expect(Theme.ft.palette.sequential.dark?.map(\.hex) == ["#992A34", "#D13D44", "#EA725E", "#F7A885", "#F2DDCD"])
        #expect(Theme.economist.palette.sequential.dark?.map(\.hex) == ["#295E7E", "#3880B8", "#57A6CC", "#95C6DD", "#D3E4ED"])
    }

    @Test("the authored dark variants are in the dark band and clear the separation floors; they are not tuned to pass anything else")
    func authoredDarkSeriesPassBandAndSeparation() {
        for theme in [Theme.ft, Theme.economist] {
            let dark = ThemeValidator.validate(theme).filter { $0.appearance == .dark }
            #expect(!dark.contains { [.lightnessBand, .chromaFloor, .cvdSeparation, .normalSeparation].contains($0.check) }, "\(theme.id)")
            #expect(!dark.contains { $0.severity == .fail }, "\(theme.id) dark has no failing finding")
        }
    }

    @Test("a theme can be looked up by id, and an unknown id is nil")
    func lookupByID() {
        #expect(Theme.named("ft")?.name == "Financial Times")
        #expect(Theme.named("nope") == nil)
    }

    @Test("the houses' vocabulary gaps are filled in the model: G2 tag and rule above, G4 axis side, G9 end dot")
    func houseVocabularyIsUsed() {
        #expect(Theme.economist.structure.rules.title.position == .aboveTitle)
        #expect(Theme.economist.structure.marks.tagMark == TagMark(width: 28, height: 6, colour: .negative))
        #expect(Theme.economist.structure.labels.axisSide == .trailing)
        #expect(Theme.economist.structure.labels.axisLabelPlacement == .aboveGridline)
        #expect(Theme.ft.structure.marks.lineEnd == .dot)
        #expect(Theme.ft.structure.labels.series == .direct)
        #expect(Theme.house.structure.rules.title.position == TitleRulePosition.none)
        #expect(Theme.house.structure.labels.values == .off)
    }

    @Test("Princeton is an AppPalette composed on Swiss and keeps Swiss's structure")
    func princetonComposesOnSwissKeepingStructure() {
        let composed = Theme.swiss.composed(with: Theme.princetonPalette)
        #expect(composed.structure == Theme.swiss.structure)
        #expect(composed.palette.accent.light.rgb == Palette.princetonAccent)
        #expect(composed.palette.series.map(\.color.light.hex)
            == ["#E77500", "#03B9FC", "#AD274F", "#03C4BB", "#A34AAC", "#007912", "#98A1FF", "#867500"])
        #expect(composed.palette.background == Theme.swiss.palette.background)
        #expect(composed.conformance == .strict, "composition drops the receiver's ledger; the result must be measured on its own")
        let princeton = Theme.princeton
        #expect(princeton.id == "princeton")
        #expect(princeton.structure == Theme.swiss.structure)
        #expect(princeton.appearances == .lightOnly)
        #expect(princeton.palette.series.allSatisfy { $0.color.dark == nil })
    }

    @Test("the entity-order mode: every failing pair must be listed, and listing is not suppression")
    func entityOrderRequiresEveryFailingPairListed() {
        let near = NamedAdaptive(name: "light white", color: Adaptive(light: ColorValue(RGB(rgb: 0xE9D98B)), dark: ColorValue(RGB(rgb: 0xE9D98B))))
        let nearer = NamedAdaptive(name: "full white", color: Adaptive(light: ColorValue(RGB(rgb: 0xE0D07E)), dark: ColorValue(RGB(rgb: 0xE0D07E))))
        let red = NamedAdaptive(name: "red", color: Adaptive(light: ColorValue(RGB(rgb: 0x7F0017)), dark: ColorValue(RGB(rgb: 0xE0788A))))
        func palette(_ listed: [SeriesPair]) -> AppPalette {
            AppPalette(id: "wine", accent: nil, series: [red, near, nearer], seriesOrder: .entityOrder(labelRequired: listed))
        }
        // unlisted: the pair that fails is a failure of the palette
        let unlisted = ThemeValidator.validate(palette([]), on: .swiss)
        #expect(unlisted.contains { $0.check == .labelRequired && $0.severity == .fail && $0.subject == "light white / full white" })
        #expect(ThemeValidator.requiresDirectLabels(palette([]), on: .swiss).contains(SeriesPair("light white", "full white")))
        // listed in either order: no labelRequired failure, and the pair is still reported (not suppressed)
        for pair in [SeriesPair("light white", "full white"), SeriesPair("full white", "light white")] {
            let listed = ThemeValidator.validate(palette([pair]), on: .swiss)
            #expect(!listed.contains { $0.check == .labelRequired && $0.severity == .fail })
            #expect(listed.contains { $0.check == .normalSeparation })
            #expect(ThemeValidator.requiresDirectLabels(palette([pair]), on: .swiss).count == 1)
        }
        // a listed pair that does not fail, or names an unknown series, is stale
        let stale = ThemeValidator.validate(palette([SeriesPair("red", "full white"), SeriesPair("nope", "red")]), on: .swiss)
        #expect(stale.filter { $0.check == .labelRequired && $0.subject.contains("stale") || $0.subject.contains("unknown") }.count >= 2)
        // entity order checks every pair, adjacent mode only the neighbours
        let all = ThemeValidator.validate(palette([]), on: .swiss).filter { $0.check == .normalSeparation }
        #expect(all.count >= 1)
    }

    @Test("the legacy Default is a labelled snapshot, marked legacy, with the system names set")
    func legacyDefaultIsASnapshot() {
        let theme = Theme.legacyDefault
        #expect(theme.conformance.kind == .legacy)
        #expect(theme.appearances == .both)
        #expect(theme.palette.series.map(\.name) == ["blue", "green", "orange", "purple", "red", "cyan", "yellow", "pink", "mint", "indigo"])
        // macOS 27.2, NSColor system colours resolved in the named appearances, Increase Contrast off
        #expect(theme.palette.series.map(\.color.light.hex) == ["#0088FF", "#34C759", "#FF8D28", "#CB30E0", "#FF383C", "#00C0E8", "#FFCC00", "#FF2D55", "#00C8B3", "#6155F5"])
        #expect(theme.palette.series.compactMap(\.color.dark?.hex) == ["#0091FF", "#30D158", "#FF9230", "#DB34F2", "#FF4245", "#3CD3FE", "#FFD600", "#FF375F", "#00DAC3", "#6D7CFF"])
        #expect(theme.palette.series.first?.color.system == .blue)
        #expect(theme.palette.ink.light.hex == "#000000D8")
        #expect(theme.palette.ink.dark?.hex == "#FFFFFFD8")
        #expect(theme.palette.rule.light.hex == "#0000001A")
        #expect(theme.palette.background.dark?.hex == "#1E1E1E")
        #expect(theme.structure.layout.gridlines == .platformAutomatic)
        #expect(theme.structure.marks.barFill == .autoGradient)
        #expect(theme.structure.layout.shadow == LegacyThemes.structure.layout.shadow)
    }

    @Test("every legacy theme is platform-automatic and gradient-filled; none has a title rule or value labels")
    func legacyStructure() {
        for theme in [Theme.legacyDefault, .legacyDark, .legacyFinancial, .legacyAccessible] {
            #expect(theme.structure.layout.gridlines == .platformAutomatic, "\(theme.id)")
            #expect(theme.structure.marks.barFill == .autoGradient, "\(theme.id)")
            #expect(theme.structure.rules.title.position == TitleRulePosition.none, "\(theme.id)")
            #expect(theme.structure.labels.values == .off, "\(theme.id)")
            #expect(theme.structure.layout.shadow == ShadowSpec(colour: ColourReference(source: "shadow"), radius: 4, x: 0, y: 2), "\(theme.id)")
            #expect(theme.structure.type.title.platformStyle == .headline, "\(theme.id)")
        }
        #expect(Theme.legacyDark.appearances == .fixedDark)
        #expect(Theme.legacyFinancial.appearances == .lightOnly)
    }

    @Test("legacy extras and overrides carry what the 15-colour theme protocol had beyond the 12 roles")
    func legacyExtrasAndOverrides() {
        let theme = Theme.legacyAccessible
        #expect(Set(theme.palette.extras.keys) == ["primary", "info", "highlight", "subtle", "emphasis", "shadow", "neutral"])
        #expect(theme.palette.colourOverrides["tornado.low"] == ColourReference(source: "accent"))
        #expect(theme.palette.colourOverrides["tornado.high"] == ColourReference(source: "primary"))
        #expect(Theme.legacyDefault.palette.colourOverrides["montecarlo.optimistic"] == ColourReference(source: "positive", opacity: 0.7))
        #expect(Set(theme.palette.extraRamps.keys) == ["volatility", "sharpe", "distribution"])
        #expect(theme.palette.diverging.light.count == 3)
        #expect(Theme.legacyDefault.palette.rampOverrides["efficientfrontier"] == "sharpe")
    }
}
