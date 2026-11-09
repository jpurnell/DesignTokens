import Foundation
import Testing
@testable import DesignTokens

/// The reference `validate_palette.js` is what the method's constants are read from. It is not in this repository
/// (see `Vendored/README.md`), so these tests run where `ReferenceScript` finds a copy with the pinned hash and are
/// skipped, with the reason, elsewhere. The recorded-run test in `ValidationThresholdTests` runs everywhere. They need
/// no Node.
@Suite("Reference validate_palette.js thresholds")
struct ReferenceScriptThresholdTests {
    static let skipReason = Comment(rawValue: ReferenceScript.skipReason ?? "")
    static let available = ReferenceScript.current.path != nil

    private func source() throws -> String {
        let path = try #require(ReferenceScript.current.path)
        return try String(contentsOfFile: path, encoding: .utf8)
    }

    /// The first capture group of `pattern` in the script, as numbers.
    private func numbers(_ pattern: String, in text: String) throws -> [Double] {
        let regex = try NSRegularExpression(pattern: pattern)
        let range = NSRange(text.startIndex..., in: text)
        let match = try #require(regex.firstMatch(in: text, range: range), "pattern not found in the script: \(pattern)")
        return (1..<match.numberOfRanges).compactMap { Range(match.range(at: $0), in: text).flatMap { Double(text[$0]) } }
    }

    @Test("ValidationThresholds are the constants in the script, read from its text", .enabled(if: available, skipReason))
    func thresholdsMatchTheScript() throws {
        let text = try source()
        let number = #"(\d+(?:\.\d+)?)"#
        let band = try numbers(#"const BAND = \{ light: \[\#(number), \#(number)\], dark: \[\#(number), \#(number)\] \}"#, in: text)
        #expect(same(band, [ValidationThresholds.lightBand.lowerBound, ValidationThresholds.lightBand.upperBound,
                            ValidationThresholds.darkBand.lowerBound, ValidationThresholds.darkBand.upperBound]), "BAND \(band)")
        #expect(same(try numbers(#"const CHROMA_FLOOR = \#(number)"#, in: text), [ValidationThresholds.chromaFloor]))
        #expect(same(try numbers(#"const CVD_TARGET = \#(number), CVD_FLOOR = \#(number)"#, in: text), [ValidationThresholds.cvdTarget, ValidationThresholds.cvdFloor]))
        #expect(same(try numbers(#"const NORMAL_FLOOR = \#(number)"#, in: text), [ValidationThresholds.normalFloor]))
        #expect(same(try numbers(#"const CONTRAST_MIN = \#(number)"#, in: text), [ValidationThresholds.markContrast]))
        #expect(same(try numbers(#"const ORDINAL_MIN_DL = \#(number)"#, in: text), [ValidationThresholds.rampMinStep]))
        #expect(same(try numbers(#"const ORDINAL_LIGHT_FLOOR = \#(number)"#, in: text), [ValidationThresholds.rampEndContrast]))
        #expect(same(try numbers(#"const oneHue = spread <= \#(number)"#, in: text), [ValidationThresholds.rampMaxHueSpread]))
    }

    @Test("the deliberate Swift deviations are real: the script has no chroma exclusion in its hue spread and no text-contrast floor", .enabled(if: available, skipReason))
    func swiftOnlyThresholdsAreNotInTheScript() throws {
        let text = try source()
        // validateOrdinal takes the hue of every step: `const hues = palette.map(okhue);`
        #expect(text.contains("const hues = palette.map(okhue);"), "the script's hue spread includes every step")
        // so ValidationThresholds.achromaticChroma (0.02) is ours: steps below it are left out of the spread
        #expect(same([ValidationThresholds.achromaticChroma], [0.02]))
        // and the text floor (4.5) is a Swift extension: the script measures marks only
        #expect(!text.contains("4.5"), "the script has no text-contrast check; ValidationThresholds.textContrast is ours")
        #expect(same([ValidationThresholds.textContrast], [4.5]))
    }
}
