import Foundation
import Testing
@testable import DesignTokens

/// `Theme.composed(with:)` must not return a theme that its own codec refuses. Before 0.6.0's review fixes,
/// `Theme.swiss.composed(with: .princetonPalette)` had nine appearance issues and `ThemeCodec.encode` wrote it.
@Suite("Theme composition and codec symmetry")
struct ThemeCompositionTests {
    private let wine = AppPalette(
        id: "winetaster",
        accent: Adaptive(light: ColorValue(RGB(rgb: 0x7F0017)), dark: ColorValue(RGB(rgb: 0xE0788A))),
        series: [NamedAdaptive(name: "red", color: Adaptive(light: ColorValue(RGB(rgb: 0x7F0017)), dark: ColorValue(RGB(rgb: 0xE0788A)))),
                 NamedAdaptive(name: "white", color: Adaptive(light: ColorValue(RGB(rgb: 0xE9D98B)), dark: ColorValue(RGB(rgb: 0xE9D98B))))],
        seriesOrder: .validatedOrder)

    @Test("a light-only app palette on a both-appearance theme gives a valid, light-only theme, not nine issues")
    func lightOnlyPaletteOnBothTheme() {
        let composed = Theme.swiss.composed(with: Theme.princetonPalette)
        #expect(composed.appearanceIssues.isEmpty, "\(composed.appearanceIssues.map(\.subject))")
        #expect(composed.appearances == .lightOnly)
        #expect(composed.palette.ink.dark == nil)
        #expect(composed.palette.series.allSatisfy { $0.color.dark == nil && $0.color.darkIncreased == nil })
        #expect(composed.palette.sequential.dark == nil)
        #expect(composed.palette.series.map(\.color.light.hex) == Theme.princetonPalette.series?.map(\.color.light.hex))
        #expect(composed.palette.background.light == Theme.swiss.palette.background.light, "surfaces keep their light values")
        #expect(composed.conformance == .strict)
    }

    @Test("composition is deterministic")
    func compositionIsDeterministic() throws {
        let first = Theme.swiss.composed(with: Theme.princetonPalette)
        for _ in 0..<3 { #expect(Theme.swiss.composed(with: Theme.princetonPalette) == first) }
        #expect(try ThemeCodec.encode(first) == ThemeCodec.encode(Theme.swiss.composed(with: Theme.princetonPalette)))
    }

    @Test("an app palette with a dark value for everything it supplies keeps a both-appearance theme both")
    func fullyAdaptivePaletteKeepsBoth() {
        let composed = Theme.swiss.composed(with: wine)
        #expect(composed.appearances == .both)
        #expect(composed.appearanceIssues.isEmpty)
        #expect(composed.palette.ink.dark == Theme.swiss.palette.ink.dark)
        #expect(composed.palette.series.compactMap(\.color.dark?.hex) == ["#E0788A", "#E9D98B"])
    }

    @Test("one series without a dark value is enough to make the result light only")
    func oneMissingDarkValueDemotes() {
        var partial = wine
        partial.series?[1].color.dark = nil
        let composed = Theme.swiss.composed(with: partial)
        #expect(composed.appearances == .lightOnly)
        #expect(composed.appearanceIssues.isEmpty)
        #expect(composed.palette.accent.dark == nil, "every dark value is stripped, none is invented or kept half")
    }

    @Test("an accent without a dark value demotes too, and an app that supplies nothing leaves the theme as it is")
    func accentWithoutDarkAndEmptyPalette() {
        let lightAccent = AppPalette(id: "a", accent: Adaptive(light: ColorValue(RGB(rgb: 0x123456))), series: nil, seriesOrder: .validatedOrder)
        #expect(Theme.swiss.composed(with: lightAccent).appearances == .lightOnly)
        let empty = AppPalette(id: "e", accent: nil, series: nil, seriesOrder: .validatedOrder)
        let same = Theme.swiss.composed(with: empty)
        #expect(same.appearances == .both)
        #expect(same.palette == Theme.swiss.palette)
    }

    @Test("a light-only receiver drops dark values the app palette brings, instead of becoming invalid")
    func lightOnlyReceiverStripsAppDarkValues() {
        let composed = Theme.house.composed(with: wine)
        #expect(composed.appearances == .lightOnly)
        #expect(composed.appearanceIssues.isEmpty, "\(composed.appearanceIssues.map(\.subject))")
        #expect(composed.palette.series.allSatisfy { $0.color.dark == nil })
        #expect(composed.palette.accent.dark == nil)
    }

    @Test("a fixed-dark receiver stays valid when an app palette brings dark values")
    func fixedDarkReceiver() {
        let composed = Theme.legacyDark.composed(with: wine)
        #expect(composed.appearances == .fixedDark)
        #expect(composed.appearanceIssues.isEmpty, "\(composed.appearanceIssues.map(\.subject))")
    }

    @Test("every registered theme composed with every shipped app palette is valid and survives the codec")
    func everyCompositionRoundTrips() throws {
        for theme in Theme.all {
            for app in [wine, Theme.princetonPalette] {
                let composed = theme.composed(with: app)
                #expect(composed.appearanceIssues.isEmpty, "\(theme.id)+\(app.id)")
                let decoded = try ThemeCodec.decode(ThemeCodec.encode(composed))
                #expect(decoded == composed, "\(theme.id)+\(app.id)")
            }
        }
    }

    @Test("Theme.princeton is the supported light-only composition, with the same palette as composing it")
    func princetonIsTheComposedPath() {
        var composed = Theme.swiss.composed(with: Theme.princetonPalette)
        // Swiss's gain and loss became the text-safe pair on 2026-11-09; Princeton did not change and keeps the system pair
        composed.palette.positive = Theme.systemPositive.strippingDark()
        composed.palette.negative = Theme.systemNegative.strippingDark()
        let princeton = Theme.princeton
        #expect(princeton.palette == composed.palette)
        #expect(princeton.structure == composed.structure)
        #expect(princeton.appearances == composed.appearances)
        #expect(princeton.id == "princeton")
    }

    // MARK: encode accepts exactly what decode accepts

    private func broken() -> [(String, Theme)] {
        var missingDark = Theme.swiss
        missingDark.palette.ink.dark = nil
        var unexpectedDark = Theme.house
        unexpectedDark.palette.ink.dark = ColorValue(RGB(rgb: 0xFFFFFF))
        var dangling = Theme.legacyDefault
        dangling.palette.colourOverrides["tornado.low"] = ColourReference(source: "ghost")
        var negative = Theme.swiss
        negative.structure.rules.gridline = -1
        var ramp = Theme.swiss
        ramp.palette.sequential.dark = Array((ramp.palette.sequential.dark ?? []).dropLast())
        var strictWithEntries = Theme.swiss
        strictWithEntries.conformance = Conformance(kind: .strict, entries: Theme.swiss.conformance.entries)
        return [("missing dark", missingDark), ("unexpected dark", unexpectedDark), ("dangling override", dangling),
                ("negative weight", negative), ("ramp length", ramp), ("strict with entries", strictWithEntries)]
    }

    @Test("ThemeCodec.encode throws for every theme that ThemeCodec.decode would refuse")
    func encodeRefusesWhatDecodeRefuses() {
        for (name, theme) in broken() {
            #expect(throws: (any Error).self, "\(name)") { try ThemeCodec.encode(theme) }
        }
    }

    @Test("the appearance case throws ThemeError.invalid with the issues, in both directions")
    func appearanceIssuesAreTheError() throws {
        var theme = Theme.swiss
        theme.palette.ink.dark = nil
        let expected = [AppearanceIssue(kind: .missingDark, subject: "palette.ink")]
        #expect(throws: ThemeError.invalid(expected)) { try ThemeCodec.encode(theme) }
        #expect(throws: ThemeError.invalid(expected)) { try JSONEncoder().encode(theme) }
    }

    @Test("a plain JSONEncoder is held to the same rule, so nothing writes what the codec cannot read")
    func plainEncoderRefuses() {
        for (name, theme) in broken() {
            #expect(throws: (any Error).self, "\(name)") { try JSONEncoder().encode(theme) }
        }
    }

    @Test("valid themes still encode, and the fingerprint of an invalid one throws instead of hashing garbage")
    func validStillEncodes() throws {
        for theme in Theme.all { #expect(try !ThemeCodec.encode(theme).isEmpty, "\(theme.id)") }
        for (name, theme) in broken() {
            #expect(throws: (any Error).self, "\(name)") { try ThemeCodec.fingerprint(of: theme) }
        }
    }
}
