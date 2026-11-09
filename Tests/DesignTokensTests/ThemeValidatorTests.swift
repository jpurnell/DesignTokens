import Foundation
import Testing
@testable import DesignTokens

/// The validator is a Swift port of the dataviz skill's `validate_palette.js`. The numbers below are the ones
/// the JavaScript printed for the same hexes on 2026-11-09 (see the proposal, section 4.3), so a wrong
/// Machado matrix or a wrong band fails here even without Node. `JavaScriptCrossCheckTests` runs the
/// script itself.
@Suite("ThemeValidator")
struct ThemeValidatorTests {
    private func series(_ theme: Theme, dark: Bool = false) -> [ColorValue] {
        theme.palette.series.map { dark ? ($0.color.dark ?? $0.color.light) : $0.color.light }
    }

    private func measure(_ theme: Theme, dark: Bool = false) -> SeriesMeasurement {
        let background = dark ? (theme.palette.background.dark ?? theme.palette.background.light) : theme.palette.background.light
        return ThemeValidator.measure(series: series(theme, dark: dark), on: background, dark: dark, pairs: .adjacent)
    }

    @Test("thresholds are the method's, in one place")
    func thresholdsAreTheMethods() {
        #expect(same([ValidationThresholds.lightBand.lowerBound, ValidationThresholds.lightBand.upperBound], [0.43, 0.77]))
        #expect(same([ValidationThresholds.darkBand.lowerBound, ValidationThresholds.darkBand.upperBound], [0.48, 0.67]))
        #expect(same([ValidationThresholds.chromaFloor, ValidationThresholds.cvdTarget, ValidationThresholds.cvdFloor,
                      ValidationThresholds.normalFloor, ValidationThresholds.markContrast, ValidationThresholds.textContrast],
                     [0.10, 8, 6, 15, 3, 4.5]))
        #expect(ValidationThresholds.maxSeries == 8)
    }

    @Test("Swiss light: only yellow is off the band, at 0.865; the four marks under 3:1 are measured")
    func swissLightMeasurements() throws {
        let m = measure(.swiss)
        #expect(m.outOfBand.map(\.index) == [4])
        #expect(same([Rounding.places(m.lightness[4], 3)], [0.865]))
        #expect(m.chromaBelowFloor.isEmpty)
        let cvd = try #require(m.worstCVD)
        let normal = try #require(m.worstNormal)
        #expect(same([Rounding.places(cvd.value, 1)], [22.4]))
        #expect(cvd.kind == .deutan)
        #expect(same([Rounding.places(normal.value, 1)], [37.8]))
        let low = m.contrast.filter { $0 < 3 }.map { Rounding.places($0, 2) }
        #expect(same(low, [2.21, 2.13, 1.45, 2.07]))
    }

    @Test("Swiss dark: orange, green, yellow and cyan are above the dark band; contrast passes")
    func swissDarkMeasurements() throws {
        let m = measure(.swiss, dark: true)
        #expect(same(m.outOfBand.map { Rounding.places($0.value, 3) }, [0.762, 0.756, 0.885, 0.808]))
        let cvd = try #require(m.worstCVD)
        let normal = try #require(m.worstNormal)
        #expect(same([Rounding.places(cvd.value, 1)], [24.1]))
        #expect(same([Rounding.places(normal.value, 1)], [36.1]))
        #expect(m.contrast.allSatisfy { $0 >= 3 })
    }

    @Test("the port reproduces the JavaScript's worst adjacent separations for every shipped palette")
    func worstSeparationsMatchTheRecordedJavaScriptRun() throws {
        // (theme, CVD worst, normal worst) from the 2026-11-09 run recorded in the proposal's section 4.3.
        let expected: [(Theme, Double, Double)] = [
            (.house, 8.6, 19.2), (.economist, 13.5, 23.9), (.ft, 10.5, 16.2),
            (.legacyFinancial, 13.7, 20.2), (.legacyAccessible, 9.6, 19.1), (.legacyDark, 3.6, 22.7),
        ]
        for (theme, cvdExpected, normalExpected) in expected {
            let m = measure(theme, dark: theme.appearances == .fixedDark)
            let cvd = try #require(m.worstCVD, "\(theme.id)")
            let normal = try #require(m.worstNormal, "\(theme.id)")
            #expect(same([Rounding.places(cvd.value, 1)], [cvdExpected]), "\(theme.id) CVD")
            #expect(same([Rounding.places(normal.value, 1)], [normalExpected]), "\(theme.id) normal")
        }
    }

    @Test("the legacy Dark deutan failure is recorded: #FFB24C against #4CE666 at 3.6")
    func legacyDarkCVDFailureIsRecorded() throws {
        let findings = ThemeValidator.validate(.legacyDark)
        let cvd = try #require(findings.first { $0.check == .cvdSeparation && $0.severity == .fail })
        #expect(same([cvd.measured, cvd.threshold], [3.6, 6]))
        #expect(cvd.subject == "orange / green" || cvd.subject == "green / orange")
        #expect(cvd.appearance == .dark)
    }

    @Test("silence is not a result: a deliberately bad palette produces the failures it should")
    func validatorFindsFailureOnBadPalette() {
        var theme = Theme.swiss
        let grey = Adaptive(light: ColorValue(RGB(rgb: 0x808080)), dark: ColorValue(RGB(rgb: 0x808080)))
        theme.palette.series = [
            NamedAdaptive(name: "a", color: grey), NamedAdaptive(name: "b", color: grey),
            NamedAdaptive(name: "c", color: Adaptive(light: ColorValue(RGB(rgb: 0xFFFFFF)), dark: ColorValue(RGB(rgb: 0x101112)))),
        ]
        let findings = ThemeValidator.validate(theme)
        let checks = Set(findings.map(\.check))
        #expect(checks.isSuperset(of: [.chromaFloor, .cvdSeparation, .normalSeparation, .lightnessBand, .markContrast]))
        #expect(findings.contains { $0.check == .normalSeparation && $0.severity == .fail && $0.measured.isEqual(to: 0) })
        #expect(findings.contains { $0.check == .chromaFloor && $0.subject == "a" })
    }

    @Test("a ninth series is a finding, not a generated hue")
    func seriesBeyondEightIsAFinding() {
        let findings = ThemeValidator.validate(.legacyDefault)
        #expect(findings.contains { $0.check == .seriesCount && $0.measured.isEqual(to: 10) && $0.threshold.isEqual(to: 8) })
    }

    @Test("a translucent colour is composited over its surface before it is measured")
    func alphaIsCompositedBeforeMeasuring() {
        let white = ColorValue(RGB(rgb: 0xFFFFFF))
        let black = ColorValue(RGB(rgb: 0x000000))
        let half = ColorValue(RGB(rgb: 0x000000), alpha: 0.5)
        // alpha 0.5 is quantised to 128/255, so the blend over white is 255 * (1 - 128/255) = 127
        #expect(ThemeValidator.resolved(half, over: white).rgb == RGB(rgb: 0x7F7F7F))
        #expect(ThemeValidator.resolved(half, over: black).rgb == RGB(rgb: 0x000000))
        #expect(ThemeValidator.resolved(white, over: black).rgb == RGB(rgb: 0xFFFFFF))
    }

    @Test("ramps: the Swiss sequential ramp passes the ordinal check, a shuffled one does not")
    func rampOrdinalCheck() throws {
        let ok = ThemeValidator.validate(.swiss).filter { $0.check.isRamp && $0.subject == "sequential" }
        // the grey-to-orange ramp passes every ramp check but one: its light grey end is 1.37:1 on #FAFAFA (ledgered; see
        // SwissGreyOrangeRampTests). The dark ramp passes.
        #expect(ok.map(\.check) == [.rampLightEnd])
        #expect(ok.map(\.appearance) == [.light])
        var shuffled = Theme.swiss
        shuffled.palette.sequential.light = [shuffled.palette.sequential.light[1], shuffled.palette.sequential.light[0],
                                             shuffled.palette.sequential.light[2]]
        let bad = ThemeValidator.validate(shuffled).filter { $0.appearance == .light && $0.subject == "sequential" }
        #expect(bad.contains { $0.check == .rampMonotone })
    }

    @Test("text roles: ink on background passes, an invisible link fails the 4.5 text floor")
    func textRoleContrast() throws {
        #expect(!ThemeValidator.validate(.swiss).contains { $0.check == .textContrast && $0.subject == "ink on background" })
        var theme = Theme.swiss
        theme.palette.link = Adaptive(light: theme.palette.background.light, dark: theme.palette.background.dark)
        let finding = ThemeValidator.validate(theme).first { $0.check == .textContrast && $0.subject == "link on background" && $0.appearance == .light }
        let found = try #require(finding)
        #expect(found.severity == .fail)
        #expect(same([found.measured], [1]))
    }

    @Test("structure sanity: a heavy title rule needs a position, weights are not negative")
    func structureSanity() {
        var theme = Theme.swiss
        theme.structure.rules.title.position = .none
        theme.structure.rules.gridline = -1
        let findings = ThemeValidator.validate(theme).filter { $0.check == .structure }
        #expect(findings.contains { $0.subject == "rules.title.position" })
        #expect(findings.contains { $0.subject == "rules.gridline" })
    }

    @Test("a both-theme missing a dark value is a finding too, not a silent light fallback")
    func missingDarkIsAFinding() {
        var theme = Theme.swiss
        theme.palette.ink.dark = nil
        #expect(ThemeValidator.validate(theme).contains { $0.check == .structure && $0.subject == "palette.ink" })
    }

    @Test("a hex that is not a colour is an error, not a silent black")
    func badHexIsAnError() throws {
        #expect(throws: ValidationInputError.invalidHex("#GG0000")) {
            try ThemeValidator.measure(hexes: ["#112233", "#GG0000"], surface: "#FFFFFF", dark: false, pairs: .adjacent)
        }
        #expect(throws: ValidationInputError.invalidHex("white")) {
            try ThemeValidator.measure(hexes: ["#112233", "#445566"], surface: "white", dark: false, pairs: .adjacent)
        }
        #expect(throws: ValidationInputError.invalidHex("#+12345")) {
            try ThemeValidator.measureRamp(hexes: ["#+12345", "#445566"], surface: "#FFFFFF", dark: false)
        }
        #expect(throws: ValidationInputError.invalidHex("")) {
            try ThemeValidator.measureRamp(hexes: ["#112233", "#445566"], surface: "", dark: false)
        }
        // black is a colour, and is measured as black
        let black = try ThemeValidator.measure(hexes: ["#000000", "#FFFFFF"], surface: "#FFFFFF", dark: false, pairs: .adjacent)
        #expect(black.hexes == ["#000000", "#FFFFFF"])
    }

    @Test("a registered id is unique, found by named(), and a lookup returns the same value every time")
    func registryLookups() {
        let ids = Theme.all.map(\.id)
        #expect(Set(ids).count == ids.count)
        for theme in Theme.all { #expect(Theme.named(theme.id) == theme, "\(theme.id)") }
        #expect(Theme.named("nope") == nil)
        #expect(Theme.named("Swiss") == nil, "ids are exact")
        #expect(Theme.swiss == Theme.named("swiss"))
        #expect(Theme.all == Theme.all)
    }
}
