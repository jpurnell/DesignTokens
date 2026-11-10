import Foundation
import Testing
@testable import DesignTokens

/// Swiss's palette after the chart alignment (owner decisions 2026-11-09): neutral marks in the approved greys,
/// a one-hue blue sequential ramp and a dark diverging ramp, both authored with the method the series use and
/// validated; the muted role checked as a mark colour where it is the default fill.
@Suite("Swiss palette: chart alignment")
struct SwissPaletteAlignmentTests {
    private let swiss = Theme.swiss

    // MARK: The neutral grey

    @Test("muted is the approved grey in all four slots: #B9BBBD, #4E5053, and #8E9196, #6F7176 with Increase Contrast")
    func mutedValues() {
        let muted = swiss.palette.muted
        #expect(muted.light.hex == "#B9BBBD")
        #expect(muted.dark?.hex == "#4E5053")
        #expect(muted.lightIncreased?.hex == "#8E9196")
        #expect(muted.darkIncreased?.hex == "#6F7176")
        #expect(muted.system == nil, "a neutral grey names no system colour, so it is never deferred to Apple's")
    }

    @Test("the approved grey is color-mix(muted 45%, background): 45% of the secondary ink over the surface, per channel")
    func mutedIsAMix() {
        func mix(_ ink: ColorValue, _ background: ColorValue) -> RGB {
            func channel(_ a: UInt8, _ b: UInt8) -> UInt8 { UInt8((0.45 * Double(a) + 0.55 * Double(b)).rounded()) }
            return RGB(red: channel(ink.rgb.red, background.rgb.red), green: channel(ink.rgb.green, background.rgb.green),
                       blue: channel(ink.rgb.blue, background.rgb.blue))
        }
        let p = swiss.palette
        #expect(swiss.palette.muted.light.rgb == mix(p.secondaryInk.light, p.background.light))
        if let ink = p.secondaryInk.dark, let background = p.background.dark {
            #expect(swiss.palette.muted.dark?.rgb == mix(ink, background))
        } else {
            Issue.record("Swiss declares both appearances, so the secondary ink and the background have dark values")
        }
    }

    @Test("the Increase Contrast greys are 3:1 on the background and the card surface; the defaults are the measured 1.84, 1.93, 2.34 and 2.20")
    func mutedContrast() {
        func ratio(_ colour: ColorValue?, _ surface: ColorValue?) -> Double {
            guard let colour, let surface else { return 0 }
            return Contrast.ratio(colour.rgb, surface.rgb)
        }
        let p = swiss.palette
        #expect(same([Rounding.places(ratio(p.muted.light, p.background.light), 2),
                      Rounding.places(ratio(p.muted.light, p.surface.light), 2),
                      Rounding.places(ratio(p.muted.dark, p.background.dark), 2),
                      Rounding.places(ratio(p.muted.dark, p.surface.dark), 2)], [1.84, 1.93, 2.34, 2.20]))
        #expect(ratio(p.muted.lightIncreased, p.background.lightIncreased ?? p.background.light) >= 3)
        #expect(ratio(p.muted.lightIncreased, p.surface.lightIncreased ?? p.surface.light) >= 3)
        #expect(ratio(p.muted.darkIncreased, p.background.darkIncreased ?? p.background.dark) >= 3)
        #expect(ratio(p.muted.darkIncreased, p.surface.darkIncreased ?? p.surface.dark) >= 3)
    }

    @Test("emphasis stays visible against the grey: accent versus muted clears the normal floor 15 and the CVD target 8, in all four appearances")
    func emphasisSeparatesFromGrey() throws {
        let cases: [(ValidationAppearance, Bool)] = [(.light, false), (.dark, true), (.lightIncreased, false), (.darkIncreased, true)]
        for (appearance, dark) in cases {
            let background = ThemeValidator.surface(of: swiss, role: .background, appearance: appearance)
            let colours = [ThemeValidator.value(swiss.palette.accent, theme: swiss, appearance: appearance),
                           ThemeValidator.value(swiss.palette.muted, theme: swiss, appearance: appearance)]
            let m = ThemeValidator.measure(series: colours, on: background, dark: dark, pairs: .all)
            let normal = try #require(m.worstNormal)
            let cvd = try #require(m.worstCVD)
            #expect(normal.value >= ValidationThresholds.normalFloor, "\(appearance) normal")
            #expect(cvd.value >= ValidationThresholds.cvdTarget, "\(appearance) CVD")
        }
    }

    // MARK: Validator: the muted mark-contrast check

    @Test("Swiss's validation reports muted under 3:1 as a warning, on the background and the surface, light and dark; none with Increase Contrast")
    func validatorFindsMuted() {
        let rows = ThemeValidator.validate(swiss).filter { $0.subject.hasPrefix("muted") }
        let summary = rows.map { "\($0.appearance.rawValue) \($0.subject) \($0.measured) \($0.severity.rawValue)" }
        #expect(summary == ["light muted on background 1.84 warn", "light muted on surface 1.93 warn",
                            "dark muted on background 2.34 warn", "dark muted on surface 2.2 warn"])
        #expect(rows.allSatisfy { $0.check == .markContrast && $0.threshold == ValidationThresholds.markContrast })
    }

    @Test("the check applies only where muted is the default mark fill: House's pale grey is not flagged")
    func checkIsScopedToNeutralMarks() {
        #expect(Theme.house.structure.marks.defaultFill == .series)
        #expect(!ThemeValidator.validate(.house).contains { $0.subject.hasPrefix("muted") })
        var neutral = Theme.house
        neutral.structure.marks.defaultFill = .muted
        #expect(ThemeValidator.validate(neutral).contains { $0.check == .markContrast && $0.subject == "muted on background" })
        // and a 3:1 grey passes where it is the default
        var passing = Theme.swiss
        passing.palette.muted = Adaptive(light: ColorValue(RGB(rgb: 0x8E9196)), dark: ColorValue(RGB(rgb: 0x6F7176)))
        #expect(!ThemeValidator.validate(passing).contains { $0.subject.hasPrefix("muted") })
    }

    @Test("the ledger records the four muted rows and, since the grey-to-orange ramp, one light sequential row; it still equals the validator")
    func ledgerChanges() {
        let rows = Theme.swissConformance.entries
        #expect(rows.filter { $0.subject.hasPrefix("muted") }.count == 4)
        #expect(rows.filter { $0.check == .rampLightEnd }.map(\.appearance) == [.light], "the orange dark row left; the light grey end arrived")
        #expect(rows.count == 29)
        #expect(rows.filter { $0.severity == .fail }.count == 15)
        #expect(ThemeValidator.deviations(of: .swiss).isEmpty)
    }

    @Test("Princeton, built on Swiss's structure and muted, ledgers the same two light muted rows; its other rows are unchanged")
    func princetonLedger() {
        let rows = Theme.princetonConformance.entries
        #expect(same(rows.filter { $0.subject.hasPrefix("muted") }.map(\.measured), [1.84, 1.93]))
        // 12 rows before the chart alignment, 14 with muted, 10 once Princeton follows Swiss's text-safe gain and loss, 11 with Swiss's inherited sequential ramp row
        #expect(rows.count == 11)
        // its own accent and series rows are untouched: orange 2.9, sky 2.15, teal 2.09, periwinkle 2.27 on the background
        let own = rows.filter { !$0.subject.hasPrefix("muted") && !$0.subject.hasPrefix("sequential") }.map { "\($0.subject) \($0.measured)" }
        #expect(own == ["orange on background 2.9", "sky on background 2.15", "teal on background 2.09", "periwinkle on background 2.27",
                        "sky on surface 2.25", "teal on surface 2.18", "periwinkle on surface 2.37", "accent on background 2.9"])
        #expect(ThemeValidator.deviations(of: .princeton).isEmpty)
        #expect(Theme.princeton.palette.muted.light == Theme.swiss.palette.muted.light)
        #expect(Theme.princeton.palette.muted.dark == nil)
    }

    // MARK: The ramps
    // Swiss's default ramps are grey to orange (SwissGreyOrangeRampTests); the blue ramps are named alternates there.

    @Test("Palette.sequential and Palette.diverging, and so tokens.css, are unchanged: the orange ramp is only Swiss's no longer")
    func paletteConstantsUntouched() {
        #expect(Palette.sequential.map(\.hex) == ["#FF9134", "#DF7502", "#B85F01", "#924A01", "#6E3700"])
        #expect(Palette.diverging.map(\.hex) == ["#0088FF", "#8ABBF8", "#E8E8E8", "#F7BD95", "#FF8D28"])
        #expect(swiss.palette.sequential.light.map(\.rgb) != Palette.sequential)
    }

    @Test("the orange ramp, measured as it always was, still has a darkest dark step at 1.99:1: the finding that left Swiss's ledger was about a ramp Swiss no longer uses")
    func orangeRampStillMeasuresAsBefore() throws {
        let m = try ThemeValidator.measureRamp(hexes: Palette.sequentialDark.map(\.hex), surface: "#101112", dark: true)
        #expect(same([Rounding.places(m.lightEndContrast, 2)], [1.99]))
    }

}
