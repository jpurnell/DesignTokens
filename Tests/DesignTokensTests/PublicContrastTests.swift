import Foundation
import Testing
import DesignTokens

/// WCAG relative-luminance contrast from the published formula, written independently of the package's.
private func published(_ a: UInt32, _ b: UInt32) -> Double {
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

@Suite("Public WCAG contrast on RGB")
struct PublicContrastTests {
    private let white = RGB(rgb: 0xFFFFFF)
    private let black = RGB(rgb: 0x000000)

    @Test("WCAG's anchors: black on white is 21, a colour on itself is 1, and the order does not matter")
    func anchors() {
        #expect(abs(white.contrastRatio(with: black) - 21) < 1e-9)
        #expect(abs(black.contrastRatio(with: white) - 21) < 1e-9)
        #expect(abs(white.contrastRatio(with: white) - 1) < 1e-12)
        #expect(abs(white.relativeLuminance - 1) < 1e-12)
        #expect(abs(black.relativeLuminance) < 1e-12)
    }

    @Test("#777777 on white is 4.48:1, just short of AA; #767676 is 4.54, just over")
    func knownPair() {
        let grey = RGB(rgb: 0x777777)
        #expect(abs(grey.contrastRatio(with: white) - 4.48) < 0.01)
        #expect(!grey.meetsAA(on: white))
        #expect(RGB(rgb: 0x767676).meetsAA(on: white))
    }

    @Test("it equals the published formula for the dashboard's measured pairs, not only the anchors")
    func matchesPublishedFormula() {
        for (a, b): (UInt32, UInt32) in [(0xDB2C2C, 0xECECEC), (0xFF4245, 0x323232), (0x268053, 0xECECEC), (0x5C5C61, 0xF2F2F7)] {
            #expect(abs(RGB(rgb: a).contrastRatio(with: RGB(rgb: b)) - published(a, b)) < 1e-12)
        }
        #expect(abs((RGB(rgb: 0xDB2C2C).contrastRatio(with: RGB(rgb: 0xECECEC)) * 100).rounded() / 100 - 4.03) < 1e-9,
                "Swiss's negative is 4.03:1 on the system grey: the measured figure that motivated host surfaces")
    }

    @Test("large text is held to 3:1, normal text to 4.5:1, and the threshold itself passes")
    func thresholds() {
        let c = RGB(rgb: 0x949494)  // about 3.03:1 on white
        #expect(c.contrastRatio(with: white) > 3 && c.contrastRatio(with: white) < 4.5)
        #expect(c.meetsAA(on: white, largeText: true))
        #expect(!c.meetsAA(on: white))
        #expect(abs(ValidationThresholds.largeTextContrast - 3.0) < 1e-12)
        #expect(abs(ValidationThresholds.textContrast - 4.5) < 1e-12)
    }
}
