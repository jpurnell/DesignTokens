import Foundation
import Testing
@testable import DesignTokens

/// Swiss's magnitude and signed ramps are grey to orange, the family of the bars (owner decision 2026-11-09, "Heatmaps and scatter
/// grey-to-orange"): neutral for low, the accent for high. The blue ramps stay available as named alternates.
@Suite("Swiss ramps: grey to orange")
struct SwissGreyOrangeRampTests {
    private let swiss = Theme.swiss

    private func hexes(_ colours: [ColorValue]?) -> [String] { (colours ?? []).map(\.hex) }

    // MARK: Sequential

    @Test("sequential is the light neutral grey to orange, with a dark variant that increases toward orange on the dark surface")
    func sequentialValues() {
        #expect(hexes(swiss.palette.sequential.light) == ["#D6D8DB", "#F0B58B", "#FF8D28"])
        #expect(hexes(swiss.palette.sequential.dark) == ["#4E5053", "#A6714A", "#FF9230"])
    }

    @Test("the orange end is the system orange of the series, light and dark; the grey end is the Swiss neutral family (the hairline, the dark muted)")
    func sequentialEndpoints() {
        #expect(swiss.palette.sequential.light.last?.rgb == Palette.series[0])
        #expect(swiss.palette.sequential.dark?.last?.rgb == Palette.seriesDark[0])
        #expect(swiss.palette.sequential.light.first == swiss.palette.rule.light)
        #expect(swiss.palette.sequential.dark?.first == swiss.palette.muted.dark)
    }

    @Test("the sequential ramps are monotone in OKLCH lightness with no thin step, in light and in dark")
    func sequentialLightness() throws {
        let light = try ThemeValidator.measureRamp(hexes: hexes(swiss.palette.sequential.light), surface: "#FAFAFA", dark: false)
        #expect(light.monotone && light.thinSteps.isEmpty)
        let dark = try ThemeValidator.measureRamp(hexes: hexes(swiss.palette.sequential.dark), surface: "#101112", dark: true)
        #expect(dark.monotone && dark.thinSteps.isEmpty)
        #expect(dark.lightEndContrast >= ValidationThresholds.rampEndContrast)
        #expect(dark.hueSpread <= ValidationThresholds.rampMaxHueSpread)
        #expect(light.hueSpread <= ValidationThresholds.rampMaxHueSpread)
    }

    @Test("the one ramp finding: the light grey end is 1.37:1 on the background, under the 2:1 floor, ledgered; values are printed in the cells")
    func sequentialLightEndIsLedgered() {
        let rows = ThemeValidator.validate(swiss).filter { $0.check.isRamp }
        #expect(rows.map { "\($0.check.rawValue) \($0.appearance.rawValue) \($0.subject)" } == ["rampLightEnd light sequential"])
        #expect(same(rows.map(\.measured), [1.37]))
        #expect(Theme.swissConformance.entries.contains { $0.check == .rampLightEnd && $0.subject == "sequential" })
    }

    // MARK: Diverging

    @Test("diverging is the dark neutral at the negative pole, a light neutral midpoint and orange at the positive pole")
    func divergingValues() {
        #expect(hexes(swiss.palette.diverging.light) == ["#6A6D72", "#A6A8AA", "#E8E8E8", "#F7BD95", "#FF8D28"])
        #expect(hexes(swiss.palette.diverging.dark) == ["#4E5053", "#66686A", "#7E8082", "#C78859", "#FF9230"])
        #expect(swiss.palette.diverging.light.first == swiss.palette.secondaryInk.light, "the negative pole is the secondary ink")
        #expect(swiss.palette.diverging.dark?.first == swiss.palette.muted.dark)
        #expect(swiss.palette.diverging.light.last?.rgb == Palette.series[0])
        #expect(swiss.palette.diverging.dark?.last?.rgb == Palette.seriesDark[0])
    }

    @Test("both arms of both diverging ramps are monotone with no thin step, ends clear 2:1, and the validator reports no diverging finding")
    func divergingArms() throws {
        for (dark, surface, colours) in [(false, "#FAFAFA", hexes(swiss.palette.diverging.light)),
                                         (true, "#101112", hexes(swiss.palette.diverging.dark))] {
            for (name, arm) in [("negative", Array(colours[0...2])), ("positive", Array(colours[2...4]))] {
                let m = try ThemeValidator.measureRamp(hexes: arm, surface: surface, dark: dark)
                #expect(m.monotone && m.thinSteps.isEmpty, "\(name) dark=\(dark)")
            }
            for pole in [colours[0], colours[4]] {
                let m = try ThemeValidator.measureRamp(hexes: [pole], surface: surface, dark: dark)
                #expect(m.lightEndContrast >= ValidationThresholds.rampEndContrast, "\(pole) dark=\(dark)")
            }
        }
        #expect(!ThemeValidator.validate(swiss).contains { $0.check.isRamp && $0.subject.hasPrefix("diverging") })
    }

    @Test("the two poles stay distinguishable under protan, deutan and tritan simulation, and in normal vision, light and dark")
    func divergingPolesSeparate() throws {
        for (dark, surface, colours) in [(false, "#FAFAFA", hexes(swiss.palette.diverging.light)),
                                         (true, "#101112", hexes(swiss.palette.diverging.dark))] {
            let m = try ThemeValidator.measure(hexes: [colours[0], colours[4]], surface: surface, dark: dark, pairs: .all)
            let normal = try #require(m.worstNormal), cvd = try #require(m.worstCVD)
            #expect(normal.value >= ValidationThresholds.normalFloor, "normal dark=\(dark)")
            #expect(cvd.value >= ValidationThresholds.cvdTarget, "protan/deutan dark=\(dark)")
            #expect(m.worstTritan >= ValidationThresholds.cvdTarget, "tritan dark=\(dark)")
        }
    }

    @Test("the midpoint sits near the surface, by design: 1.17:1 on the light background; and well off it on dark (4.77:1)")
    func midpointVersusSurface() {
        let p = swiss.palette
        #expect(same([Rounding.places(Contrast.ratio(p.diverging.light[2].rgb, p.background.light.rgb), 2)], [1.17]))
        if let dark = p.diverging.dark, let background = p.background.dark {
            #expect(same([Rounding.places(Contrast.ratio(dark[2].rgb, background.rgb), 2)], [4.77]))
        } else {
            Issue.record("Swiss's diverging ramp has a dark version")
        }
    }

    // MARK: The blue alternates

    @Test("the blue and blue-orange ramps are named alternates in extraRamps, with dark versions, and pass the ramp checks")
    func alternates() throws {
        let blue = try #require(swiss.palette.extraRamps["sequentialBlue"])
        #expect(hexes(blue.light) == ["#6AB0FF", "#2E92F5", "#0A74D6", "#0757A6", "#053C73"])
        #expect(hexes(blue.dark) == ["#064E8B", "#0167B8", "#1382E1", "#449FFA", "#7FBCFE"])
        let pair = try #require(swiss.palette.extraRamps["divergingBlueOrange"])
        #expect(pair.light.map(\.rgb) == Palette.diverging)
        #expect(hexes(pair.dark) == ["#0091FF", "#246BB1", "#414344", "#AB6224", "#FF9230"])
        #expect(Set(swiss.palette.extraRamps.keys) == ["sequentialBlue", "divergingBlueOrange"])
        #expect(!ThemeValidator.validate(swiss).contains { $0.subject.hasPrefix("extraRamps") })
    }

    @Test("a key beginning diverging is validated as a two-pole ramp, so a diverging alternate is not mistaken for a broken ordinal ramp")
    func divergingAlternateIsValidatedAsArms() {
        var theme = Theme.swiss
        // an unordered middle breaks an arm, which the arms-based check reports under the alternate's own name
        let blueOrange = Palette.diverging.map { ColorValue($0) }
        theme.palette.extraRamps["divergingBlueOrange"]?.light = [blueOrange[0], blueOrange[2], blueOrange[1], blueOrange[3], blueOrange[4]]
        let subjects = ThemeValidator.validate(theme).filter { $0.subject.hasPrefix("extraRamps.divergingBlueOrange") }.map(\.subject)
        #expect(subjects.contains { $0.hasPrefix("extraRamps.divergingBlueOrange.") }, "\(subjects)")
    }

    @Test("Palette.sequential and Palette.diverging, and so tokens.css and tokens.json, are untouched")
    func paletteConstantsUntouched() {
        #expect(Palette.sequential.map(\.hex) == ["#FF9134", "#DF7502", "#B85F01", "#924A01", "#6E3700"])
        #expect(Palette.diverging.map(\.hex) == ["#0088FF", "#8ABBF8", "#E8E8E8", "#F7BD95", "#FF8D28"])
    }

    @Test("Princeton follows Swiss's grey-to-orange ramps (owner decision 2026-11-09): its palette defines none, and it inherits the named alternates")
    func princetonRamps() {
        let princeton = Theme.princeton.palette
        #expect(Theme.princetonPalette.sequential == nil)
        #expect(Theme.princetonPalette.diverging == nil)
        #expect(princeton.sequential.light == swiss.palette.sequential.light)
        #expect(princeton.diverging.light == swiss.palette.diverging.light)
        #expect(Set(princeton.extraRamps.keys) == ["sequentialBlue", "divergingBlueOrange"])
        #expect(princeton.extraRamps.values.allSatisfy { $0.dark == nil }, "light only")
    }

    // MARK: Scatter

    @Test("scatter points follow the marks: neutral, the emphasised point in the accent; a third variable uses the sequential ramp")
    func scatterGuidance() {
        let marks = swiss.structure.marks
        #expect(marks.defaultFill == .muted)
        #expect(marks.emphasisFill == .accent)
        // no scatter-specific field is needed: points take the same fills as bars, and the ramp is `sequential`
        #expect(swiss.palette.sequential.light.first == swiss.palette.rule.light)
    }
}
