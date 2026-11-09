import Foundation
import Testing
@testable import DesignTokens

/// Each threshold is pinned by what it does at its edge, not only by the literal it is declared with, so a
/// change to the constant fails a test whose name says which behaviour moved. The constants are also read out
/// of the vendored `validate_palette.js` (`VendoredScriptTests`), which needs no Node.
@Suite("Validation thresholds act at their edges")
struct ValidationThresholdTests {
    private func lightness(_ grey: UInt32) -> Double { ColorAnalysis.lightness(RGB(rgb: grey * 0x010101)) }

    private func outOfBand(_ greys: [UInt32], dark: Bool) -> [Int] {
        let colours = greys.map { RGB(rgb: $0 * 0x010101) }
        return ThemeValidator.measure(colours: colours, surface: RGB(rgb: dark ? 0x101112 : 0xFFFFFF), dark: dark, pairs: .adjacent)
            .outOfBand.map(\.index)
    }

    // Greys chosen from the OKLCH lightness of every grey, each straddling a band edge by at least 0.003.
    @Test("light band: #4F (L 0.4276) and #B5 (L 0.7731) are out, #50 (L 0.4313) and #B4 (L 0.7699) are in")
    func lightBandEdges() {
        #expect(same([lightness(0x4F), lightness(0x50), lightness(0xB4), lightness(0xB5)].map { Rounding.places($0, 4) },
                     [0.4276, 0.4313, 0.7699, 0.7731]), "the fixtures are what the comments say")
        #expect(outOfBand([0x4F, 0x50, 0xB4, 0xB5], dark: false) == [0, 3])
    }

    @Test("dark band: #5D (L 0.4784) and #96 (L 0.6731) are out, #5E (L 0.4819) and #95 (L 0.6698) are in")
    func darkBandEdges() {
        #expect(same([lightness(0x5D), lightness(0x5E), lightness(0x95), lightness(0x96)].map { Rounding.places($0, 4) },
                     [0.4784, 0.4819, 0.6698, 0.6731]), "the fixtures are what the comments say")
        #expect(outOfBand([0x5D, 0x5E, 0x95, 0x96], dark: true) == [0, 3])
    }

    @Test("the bands are the method's, as numbers, and the light band is wider than the dark one at both ends")
    func bandValues() {
        #expect(same([ValidationThresholds.lightBand.lowerBound, ValidationThresholds.lightBand.upperBound,
                      ValidationThresholds.darkBand.lowerBound, ValidationThresholds.darkBand.upperBound], [0.43, 0.77, 0.48, 0.67]))
    }

    @Test("rampMinStep: a 0.0592 lightness gap is a thin step, a 0.0619 gap is not")
    func rampMinStepEdge() {
        // greys #64 to #75 differ by 0.0592 in L, #6B to #7D by 0.0619
        #expect(same([lightness(0x75) - lightness(0x64), lightness(0x7D) - lightness(0x6B)].map { Rounding.places($0, 4) }, [0.0592, 0.0619]))
        let thin = ThemeValidator.measureRamp(colours: [RGB(rgb: 0x646464), RGB(rgb: 0x757575)], surface: RGB(rgb: 0xFFFFFF), dark: false)
        let fine = ThemeValidator.measureRamp(colours: [RGB(rgb: 0x6B6B6B), RGB(rgb: 0x7D7D7D)], surface: RGB(rgb: 0xFFFFFF), dark: false)
        #expect(thin.thinSteps.count == 1)
        #expect(fine.thinSteps.isEmpty)
        #expect(same([ValidationThresholds.rampMinStep], [0.06]))
    }

    @Test("achromaticChroma (Swift only): a step under 0.02 chroma has no hue and is left out; one over it counts")
    func achromaticChromaEdge() {
        // #3A6EA5 is a blue (hue about 255 degrees); #777168 (C 0.0156) and #7A7064 (C 0.0220) are warm near-greys (hue about 75)
        let blue = RGB(rgb: 0x3A6EA5), lowChroma = RGB(rgb: 0x777168), highChroma = RGB(rgb: 0x7A7064)
        #expect(ColorAnalysis.chroma(lowChroma) < ValidationThresholds.achromaticChroma)
        #expect(ColorAnalysis.chroma(highChroma) > ValidationThresholds.achromaticChroma)
        let ignored = ThemeValidator.measureRamp(colours: [blue, lowChroma], surface: RGB(rgb: 0xFFFFFF), dark: false)
        let counted = ThemeValidator.measureRamp(colours: [blue, highChroma], surface: RGB(rgb: 0xFFFFFF), dark: false)
        #expect(same([ignored.hueSpread], [0]), "one chromatic step has no spread")
        #expect(counted.hueSpread > ValidationThresholds.rampMaxHueSpread, "\(counted.hueSpread)")
        #expect(same([ValidationThresholds.achromaticChroma], [0.02]))
    }

    @Test("the remaining constants: chroma floor, CVD, normal, contrast, ramp end and hue spread, each at its edge")
    func remainingConstants() {
        #expect(same([ValidationThresholds.chromaFloor, ValidationThresholds.cvdTarget, ValidationThresholds.cvdFloor,
                      ValidationThresholds.normalFloor, ValidationThresholds.markContrast, ValidationThresholds.textContrast,
                      ValidationThresholds.rampEndContrast, ValidationThresholds.rampMaxHueSpread],
                     [0.10, 8, 6, 15, 3, 4.5, 2, 40]))
        // chroma floor: the Swiss blue is above 0.10, a mid grey is below
        let m = ThemeValidator.measure(colours: [RGB(rgb: 0x0088FF), RGB(rgb: 0x808080)], surface: RGB(rgb: 0xFFFFFF), dark: false, pairs: .adjacent)
        #expect(m.chromaBelowFloor.map(\.index) == [1])
    }
}
