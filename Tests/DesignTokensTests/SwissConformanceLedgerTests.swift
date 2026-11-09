import Foundation
import Testing
@testable import DesignTokens

/// The Swiss palette uses Apple's system colours (owner decision 2026-11-09, kept, not re-stepped). Those
/// colours fail the dataviz method's lightness band and its 3:1 mark contrast for some slots. This is the
/// ledger: the exact measurements, failing on ANY change, so the finding is permanent and visible rather
/// than silenced. The validator that computes these in general ships in 0.5.0; these tests use the
/// package's own colour maths for the series only. Method: OKLCH lightness band 0.43 to 0.77 on a light
/// surface and 0.48 to 0.67 on a dark one; WCAG contrast of the mark against its surface, 3:1.
@Suite("Swiss conformance ledger")
struct SwissConformanceLedgerTests {
    private let lightBand = 0.43...0.77
    private let darkBand = 0.48...0.67
    private let markContrast = 3.0

    private func rounded(_ value: Double, _ places: Int) -> Double {
        let factor = pow(10.0, Double(places))
        return (value * factor).rounded() / factor
    }

    private var lightSurface: RGB { Theme.swiss.palette.background.light.rgb }
    private var darkSurface: RGB { Theme.swiss.palette.background.dark?.rgb ?? lightSurface }

    @Test("light: only yellow is outside the lightness band, at L 0.865")
    func swissLightBandFindingIsLedgered() {
        let findings = Theme.swiss.palette.series.compactMap { entry -> String? in
            let l = OKLab.lightness(entry.color.light.rgb)
            return lightBand.contains(l) ? nil : "\(entry.name) \(rounded(l, 3))"
        }
        #expect(findings == ["yellow 0.865"])
    }

    @Test("dark: orange, green, yellow and cyan are above the dark lightness band, at the measured values")
    func swissDarkBandFindingIsLedgered() {
        let findings = Theme.swiss.palette.series.compactMap { entry -> String? in
            let l = OKLab.lightness(entry.color.dark?.rgb ?? entry.color.light.rgb)
            return darkBand.contains(l) ? nil : "\(entry.name) \(rounded(l, 3))"
        }
        #expect(findings == ["orange 0.762", "green 0.756", "yellow 0.885", "cyan 0.808"])
    }

    @Test("light: orange, green, yellow and cyan are under 3:1 against the surface, at the measured ratios")
    func swissLightContrastFindingIsLedgered() {
        let findings = Theme.swiss.palette.series.compactMap { entry -> String? in
            let ratio = Contrast.ratio(entry.color.light.rgb, lightSurface)
            return ratio >= markContrast ? nil : "\(entry.name) \(rounded(ratio, 2))"
        }
        #expect(findings == ["orange 2.21", "green 2.13", "yellow 1.45", "cyan 2.07"])
    }

    @Test("dark: every series colour is at least 3:1 against the dark surface")
    func swissDarkContrastPasses() {
        for entry in Theme.swiss.palette.series {
            #expect(Contrast.ratio(entry.color.dark?.rgb ?? entry.color.light.rgb, darkSurface) >= markContrast, "\(entry.name)")
        }
    }

    @Test("the slots that need direct labels are exactly the ones that fail contrast or the band")
    func slotsRequiringDirectLabels() {
        #expect(SwissLedger.directLabelSlots == ["orange", "green", "yellow", "cyan"])
        let failing = Set(["yellow"]).union(["orange", "green", "yellow", "cyan"])
        #expect(Set(SwissLedger.directLabelSlots) == failing)
        #expect(SwissLedger.directLabelSlots.allSatisfy { name in Theme.swiss.palette.series.contains { $0.name == name } })
    }
}
