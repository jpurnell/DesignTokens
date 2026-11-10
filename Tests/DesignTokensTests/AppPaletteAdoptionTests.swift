import Foundation
import Testing
@testable import DesignTokens

/// A palette shaped like WineTaster's, written for these tests. It is not WineTaster's palette and ships nowhere.
private enum WineShapedPalette: AppPaletteSource {
    static let palette = AppPalette(
        id: "wine-shaped",
        accent: Adaptive(light: 0x7F0017, dark: 0xE0788A),
        onAccent: Adaptive(light: 0xFFFFFF, dark: 0x1A0006),
        series: [NamedAdaptive("red", light: 0x7F0017, dark: 0xE0788A),
                 NamedAdaptive("light white", light: 0xE9D98B, dark: 0xE9D98B),
                 NamedAdaptive("full white", light: 0xE0D07E, dark: 0xE0D07E)],
        seriesOrder: .entityOrder(labelRequired: [SeriesPair("light white", "full white")]),
        maxSeriesPerChart: 5,
        labelTogether: [SeriesPair("light white", "full white")])
}

/// WCAG contrast ratio from the published formula, written independently of the package's own.
private func wcag(_ a: UInt32, _ b: UInt32) -> Double {
    func lum(_ v: UInt32) -> Double {
        func lin(_ c: UInt32) -> Double {
            let s = Double(c) / 255
            return s <= 0.04045 ? s / 12.92 : pow((s + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * lin((v >> 16) & 0xFF) + 0.7152 * lin((v >> 8) & 0xFF) + 0.0722 * lin(v & 0xFF)
    }
    let (hi, lo) = (max(lum(a), lum(b)), min(lum(a), lum(b)))
    return (hi + 0.05) / (lo + 0.05)
}

private func rounded2(_ x: Double) -> Double { (x * 100).rounded() / 100 }

private func hexValue(_ colour: ColorValue) -> UInt32 {
    UInt32(colour.rgb.red) << 16 | UInt32(colour.rgb.green) << 8 | UInt32(colour.rgb.blue)
}

@Suite("App palette adoption")
struct AppPaletteAdoptionTests {
    private let yellow = AppPalette(
        id: "loud", accent: nil,
        series: [NamedAdaptive("yellow", light: 0xFFFF00, dark: 0xFFFF00)],
        seriesOrder: .validatedOrder)

    @Test("an unledgered finding makes a strict palette non-conformant, and the measured value is the WCAG one")
    func strictPaletteWithAFindingIsNotConformant() throws {
        let result = yellow.validate()
        let background = hexValue(Theme.swiss.palette.background.light)
        let expected = rounded2(wcag(0xFFFF00, background))
        let row = try #require(result.findings.first { $0.check == .markContrast && $0.appearance == .light && $0.subject == "yellow on background" })
        #expect(abs(row.measured - expected) < 1e-9)
        #expect(expected < 1.1, "pure yellow on near-white is about 1.07:1 by the formula")
        #expect(!result.isConformant)
        #expect(result.deviations.contains { $0.hasPrefix("unledgered finding: warn markContrast | light | yellow on background") })
        #expect(result.report.contains("yellow on background"), "the report prints the exact finding")
        #expect(result.report.contains("NOT CONFORMANT"))
    }

    @Test("a dark accent needs its own onAccent: Swiss's fails against it by the WCAG formula, and the palette's own does not")
    func onAccentIsThePalettes() throws {
        let accent: UInt32 = 0x7F0017
        let swissOn = hexValue(Theme.swiss.palette.onAccent.light)
        let without = AppPalette(id: "oa", accent: Adaptive(light: accent), series: nil, seriesOrder: .validatedOrder)
        let row = try #require(without.validate().findings.first { $0.check == .textContrast && $0.subject == "onAccent on accent" && $0.appearance == .light })
        #expect(abs(row.measured - rounded2(wcag(swissOn, accent))) < 1e-9)
        #expect(row.measured < 4.5)
        let with = AppPalette(id: "oa", accent: Adaptive(light: accent), onAccent: Adaptive(light: 0xFFFFFF), series: nil, seriesOrder: .validatedOrder)
        #expect(wcag(0xFFFFFF, accent) > 4.5, "white on #7F0017 is about 11:1 by the formula")
        #expect(!with.validate().findings.contains { $0.subject == "onAccent on accent" && $0.appearance == .light })
        #expect(with.theme().palette.onAccent.light.hex == "#FFFFFF")
    }

    @Test("the exact ledger makes it conformant; one value off, one missing, one extra are three distinct deviations")
    func ledgerIsExact() {
        let measured = yellow.validate().findings
        #expect(measured.count >= 3, "the fixture must have findings to ledger, or this test proves nothing")
        var ledgered = yellow
        ledgered.conformance = Conformance(kind: .ledger, entries: measured)
        #expect(ledgered.validate().isConformant)
        #expect(ledgered.validate().deviations.isEmpty)

        var off = measured
        off[0].measured += 0.01
        ledgered.conformance = Conformance(kind: .ledger, entries: off)
        #expect(ledgered.validate().deviations.contains { $0.hasPrefix("ledgered finding changed") })

        ledgered.conformance = Conformance(kind: .ledger, entries: Array(measured.dropFirst()))
        #expect(ledgered.validate().deviations.contains { $0.hasPrefix("unledgered finding") })

        let phantom = Finding(severity: .fail, check: .chromaFloor, appearance: .light, subject: "ghost", measured: 0.01, threshold: 0.1)
        ledgered.conformance = Conformance(kind: .ledger, entries: measured + [phantom])
        #expect(ledgered.validate().deviations.contains { $0.hasPrefix("ledgered finding no longer occurs") })
        #expect(!ledgered.validate().isConformant)
    }

    @Test("a palette that supplies nothing is conformant, and the appearances measured are light and dark, not none")
    func emptyPaletteIsConformantNotVacuous() {
        let none = AppPalette(id: "none", accent: nil, series: nil, seriesOrder: .validatedOrder)
        let result = none.validate()
        #expect(result.appearances == [.light, .dark])
        #expect(result.findings.isEmpty)
        #expect(result.isConformant)
        #expect(result.report.contains("CONFORMANT"))
        #expect(result.themeID == "swiss+none")
        #expect(result.paletteID == "none")
    }

    @Test("appearances follow the values the palette has: no dark values is light only; increased values add an appearance")
    func appearancesFollowValues() {
        let lightOnly = AppPalette(id: "l", accent: nil, series: [NamedAdaptive("a", light: 0x1F4E79)], seriesOrder: .validatedOrder)
        #expect(lightOnly.validate().appearances == [.light])
        let increased = AppPalette(id: "i", accent: nil,
                                   series: [NamedAdaptive("a", light: 0x1F4E79, dark: 0x9CC3E6, lightIncreased: 0x123456)],
                                   seriesOrder: .validatedOrder)
        #expect(increased.validate().appearances == [.light, .dark, .lightIncreased])
    }

    @Test("the wine-shaped palette: its declared pair is a label requirement, both measured and declared")
    func wineShapedLabelRequirements() {
        let result = WineShapedPalette.validate()
        let pair = SeriesPair("light white", "full white")
        let requirement = result.labelRequirements.first { $0.pair == pair }
        #expect(requirement?.reason == .both, "E9D98B and E0D07E are a few percent apart in lightness: measured, and declared")
        #expect(WineShapedPalette.palette.maxSeriesPerChart == 5)
        #expect(result.paletteID == "wine-shaped")
        #expect(result.report.contains("light white / full white"))
    }

    @Test("a declared pair is a requirement even when the colours are far apart, and is not reported as stale")
    func declaredPairNeedsNoFailure() {
        let palette = AppPalette(
            id: "declared", accent: nil,
            series: [NamedAdaptive("black", light: 0x000000, dark: 0xFFFFFF), NamedAdaptive("grey", light: 0x808080, dark: 0x808080)],
            seriesOrder: .entityOrder(labelRequired: []),
            labelTogether: [SeriesPair("black", "grey")])
        let result = palette.validate()
        #expect(result.labelRequirements == [LabelRequirement(pair: SeriesPair("black", "grey"), reason: .declared)])
        #expect(!result.findings.contains { $0.check == .labelRequired })
    }

    @Test("palette-level structure: bad max, unknown pair member and duplicate series names are findings")
    func structureFindings() {
        let bad = AppPalette(
            id: "bad", accent: nil,
            series: [NamedAdaptive("a", light: 0x1F4E79, dark: 0x9CC3E6), NamedAdaptive("a", light: 0x8F2D56, dark: 0xE8A0BF)],
            seriesOrder: .validatedOrder, maxSeriesPerChart: 0, labelTogether: [SeriesPair("a", "zzz")])
        let subjects = bad.validate().findings.filter { $0.check == .structure }.map(\.subject)
        #expect(subjects.contains("maxSeriesPerChart"))
        #expect(subjects.contains("labelTogether a / zzz (unknown series)"))
        #expect(subjects.contains("series a (duplicate name)"))
        #expect(!bad.validate().isConformant)
    }

    @Test("a supplied ramp is validated; a palette that supplies none is measured as before")
    func suppliedRampIsMeasured() {
        // a ramp whose lightness does not run one way: step 2 is lighter than step 1 and step 3
        let zigzag = Ramp(packedLight: [0x1F4E79, 0xBBD3EA, 0x2E75B6, 0xDEEBF7])
        let palette = AppPalette(id: "r", accent: nil, series: nil, sequential: zigzag, seriesOrder: .validatedOrder)
        #expect(palette.validate().findings.contains { $0.check == .rampMonotone && $0.subject == "sequential" })
        #expect(AppPalette(id: "n", accent: nil, series: nil, seriesOrder: .validatedOrder).validate().findings.isEmpty)
    }

    @Test("chart rules: the series cap, unknown names, and a pair that is plotted together without labels")
    func chartRules() {
        let p = WineShapedPalette.palette
        #expect(p.chartViolations(plotting: ["red", "light white"]).isEmpty)
        let three = AppPalette(id: "three", accent: nil,
                               series: [NamedAdaptive("a", light: 0x1F4E79), NamedAdaptive("b", light: 0x8F2D56), NamedAdaptive("c", light: 0x2E7D32)],
                               seriesOrder: .validatedOrder, maxSeriesPerChart: 2)
        #expect(three.chartViolations(plotting: ["a", "b", "c"]) == [.tooManySeries(plotted: 3, max: 2)])
        #expect(three.chartViolations(plotting: ["a", "b", "b"]).isEmpty, "a repeated name is one series")
        #expect(p.chartViolations(plotting: ["red", "claret"]) == [.unknownSeries("claret")])
        let pair = SeriesPair("light white", "full white")
        #expect(p.chartViolations(plotting: ["light white", "full white"]) == [.unlabelledPair(pair)])
        #expect(p.chartViolations(plotting: ["light white", "full white"], labelled: ["light white"]) == [.unlabelledPair(pair)])
        #expect(p.chartViolations(plotting: ["light white", "full white"], labelled: ["light white", "full white"]).isEmpty)
        #expect(p.chartViolations(plotting: ["light white", "red"]).isEmpty, "only one member plotted: nothing to confuse")
        let names = (1...9).map { "s\($0)" }
        let noCap = AppPalette(id: "nc", accent: nil, series: names.map { NamedAdaptive($0, light: 0x1F4E79) }, seriesOrder: .validatedOrder)
        #expect(noCap.chartViolations(plotting: names) == [.tooManySeries(plotted: 9, max: 8)], "no declared cap means the method's eight")
    }

    @Test("0.7.0-shaped JSON (no new keys) decodes with defaults; the new fields round-trip")
    func codec() throws {
        let old = AppPalette(id: "old", accent: nil, series: nil, seriesOrder: .validatedOrder)
        var json = try #require(String(data: ThemeCodec.encode(old), encoding: .utf8))
        for key in ["conformance", "labelTogether"] { #expect(json.contains(key), "the encoder writes \(key)") }
        let legacy = try JSONSerialization.jsonObject(with: Data(json.utf8))
        guard var object = legacy as? [String: Any] else { Issue.record("not an object"); return }
        for key in ["conformance", "labelTogether", "maxSeriesPerChart"] { object[key] = nil }
        json = String(decoding: try JSONSerialization.data(withJSONObject: object), as: UTF8.self)
        let decoded = try ThemeCodec.decodeAppPalette(Data(json.utf8))
        #expect(decoded == old)
        #expect(decoded.conformance == .strict && decoded.labelTogether.isEmpty && decoded.maxSeriesPerChart == nil)
        let wine = WineShapedPalette.palette
        #expect(try ThemeCodec.decodeAppPalette(ThemeCodec.encode(wine)) == wine)
    }

    @Test("the protocol's palette is what validate reads; theme(on:) composes it and keeps Swiss's surfaces")
    func protocolAndTheme() {
        #expect(WineShapedPalette.validate().paletteID == WineShapedPalette.palette.id)
        let theme = WineShapedPalette.palette.theme()
        #expect(theme.id == "swiss+wine-shaped")
        #expect(theme.palette.background == Theme.swiss.palette.background)
        #expect(theme.palette.accent.light.hex == "#7F0017")
    }

    @Test("web and terminal output of an app's theme carries its accent and series, under the composed id")
    func emitters() throws {
        let theme = WineShapedPalette.palette.theme()
        let css = try ThemeCSSEmitter.emit(theme)
        #expect(css.contains("[data-theme-name=\"swiss+wine-shaped\"]"))
        #expect(css.uppercased().contains("#7F0017"))
        #expect(css.uppercased().contains("#E9D98B"))
        let json = try ThemeJSONEmitter.emit(theme)
        #expect(json.contains("\"id\" : \"swiss+wine-shaped\""))
        let ansi = try ANSIEmitter.emit(theme)
        #expect(ansi.contains("swiss+wine-shaped"))
        #expect(ansi.uppercased().contains("#7F0017"))
    }

    @Test("ledgerSource is Swift that lists exactly the measured findings")
    func ledgerSource() {
        let result = yellow.validate()
        let source = result.ledgerSource
        #expect(source.hasPrefix("Conformance(kind: .ledger, entries: ["))
        #expect(source.split(whereSeparator: \.isNewline).filter { $0.contains("Finding(severity:") }.count == result.findings.count)
        #expect(source.contains("\"yellow on background\""))
    }
}

/// The worked example end to end: a palette, its ledger as a person reviewed it, and the one-line test an app writes.
@Suite("App palette adoption: the worked example")
struct WineShapedExampleTests {
    private static func row(_ severity: Severity, _ check: Check, _ appearance: ValidationAppearance, _ subject: String,
                            _ measured: Double, _ threshold: Double) -> Finding {
        Finding(severity: severity, check: check, appearance: appearance, subject: subject, measured: measured, threshold: threshold)
    }

    /// The ledger pasted from `ledgerSource` and reviewed: the two whites are pale, close to each other (the
    /// declared pair, labelled), and below 3:1 on Swiss's surfaces; the red sits just outside the light and dark bands.
    private static let ledger = Conformance(kind: .ledger, entries: [
        row(.fail, .lightnessBand, .light, "red", 0.377, 0.43),
        row(.fail, .lightnessBand, .light, "light white", 0.881, 0.77),
        row(.fail, .lightnessBand, .light, "full white", 0.853, 0.77),
        row(.fail, .chromaFloor, .light, "light white", 0.1, 0.1),
        row(.fail, .cvdSeparation, .light, "light white / full white", 2.8, 6.0),
        row(.fail, .normalSeparation, .light, "light white / full white", 2.9, 15.0),
        row(.warn, .markContrast, .light, "light white on background", 1.36, 3.0),
        row(.warn, .markContrast, .light, "full white on background", 1.49, 3.0),
        row(.warn, .markContrast, .light, "light white on surface", 1.42, 3.0),
        row(.warn, .markContrast, .light, "full white on surface", 1.56, 3.0),
        row(.fail, .lightnessBand, .dark, "red", 0.694, 0.67),
        row(.fail, .lightnessBand, .dark, "light white", 0.881, 0.67),
        row(.fail, .lightnessBand, .dark, "full white", 0.853, 0.67),
        row(.fail, .chromaFloor, .dark, "light white", 0.1, 0.1),
        row(.fail, .cvdSeparation, .dark, "light white / full white", 2.8, 6.0),
        row(.fail, .normalSeparation, .dark, "light white / full white", 2.9, 15.0),
    ])

    @Test("without a ledger the example is not conformant; with the reviewed ledger it is: that is the whole adoption")
    func exampleNeedsItsLedger() {
        #expect(!WineShapedPalette.validate().isConformant)
        var reviewed = WineShapedPalette.palette
        reviewed.conformance = Self.ledger
        #expect(reviewed.validate().isConformant, "\(reviewed.validate().report)")
    }

    @Test("the mark-contrast rows of the ledger are the WCAG ratios of the stated hex values on Swiss's surfaces")
    func markRowsAreClosedForm() {
        let background = hexValue(Theme.swiss.palette.background.light)
        let surface = hexValue(Theme.swiss.palette.surface.light)
        #expect(abs(rounded2(wcag(0xE9D98B, background)) - 1.36) < 1e-9)
        #expect(abs(rounded2(wcag(0xE0D07E, background)) - 1.49) < 1e-9)
        #expect(abs(rounded2(wcag(0xE9D98B, surface)) - 1.42) < 1e-9)
        #expect(abs(rounded2(wcag(0xE0D07E, surface)) - 1.56) < 1e-9)
        let accent: UInt32 = 0x7F0017
        #expect(wcag(accent, background) >= 3, "the red mark is legible, so it has no markContrast row")
        #expect(!WineShapedPalette.validate().findings.contains { $0.check == .markContrast && $0.subject.hasPrefix("red") })
    }

    @Test("an app's own test, as it would write it")
    func theLineAnAppWrites() {
        var reviewed = WineShapedPalette.palette
        reviewed.conformance = Self.ledger
        let result = reviewed.validate()
        #expect(result.isConformant, "\(result.report)")
        #expect(result.labelRequirements.map(\.pair) == [SeriesPair("light white", "full white")])
    }
}
