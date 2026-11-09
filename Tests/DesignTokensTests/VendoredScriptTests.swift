import CryptoKit
import Foundation
import Testing
@testable import DesignTokens

/// The vendored `validate_palette.js` is the reference the Swift validator is compared with. These tests need no
/// Node: they pin the file, and read the method's constants out of its text.
@Suite("Vendored validate_palette.js")
struct VendoredScriptTests {
    static let pinnedSHA256 = "25df43beb77674dad34348b9fe338d5a47f568e08bcf51b38780e51386cf866e"

    private func source() throws -> String {
        try String(contentsOf: JavaScriptValidator.vendoredScriptURL, encoding: .utf8)
    }

    @Test("the vendored script is the pinned file: a changed hash fails, deliberately")
    func hashIsPinned() throws {
        let data = try Data(contentsOf: JavaScriptValidator.vendoredScriptURL)
        let digest = SHA256.hash(data: data).map { ($0 < 16 ? "0" : "") + String($0, radix: 16) }.joined()
        #expect(digest == Self.pinnedSHA256,
                "Tests/DesignTokensTests/Vendored/validate_palette.js changed (SHA-256 \(digest)). If that is deliberate, update pinnedSHA256 and Vendored/README.md and re-run the cross-check with Node; otherwise restore the file.")
    }

    @Test("the cross-check reads that file and no other")
    func crossCheckUsesTheVendoredCopy() {
        #expect(JavaScriptValidator.scriptPath() == JavaScriptValidator.vendoredScriptURL.path)
        #expect(JavaScriptValidator.vendoredScriptURL.path.hasSuffix("Tests/DesignTokensTests/Vendored/validate_palette.js"))
    }

    @Test("the Vendored README records the hash that the test pins")
    func readmeRecordsTheHash() throws {
        let readme = JavaScriptValidator.vendoredScriptURL.deletingLastPathComponent().appendingPathComponent("README.md")
        let text = try String(contentsOf: readme, encoding: .utf8)
        #expect(text.contains(Self.pinnedSHA256))
        #expect(text.contains("MIT"), "the licence note is kept next to the file")
    }

    /// The first capture group of `pattern` in the script, as numbers.
    private func numbers(_ pattern: String, in text: String) throws -> [Double] {
        let regex = try NSRegularExpression(pattern: pattern)
        let range = NSRange(text.startIndex..., in: text)
        let match = try #require(regex.firstMatch(in: text, range: range), "pattern not found in the script: \(pattern)")
        return (1..<match.numberOfRanges).compactMap { Range(match.range(at: $0), in: text).flatMap { Double(text[$0]) } }
    }

    @Test("ValidationThresholds are the constants in the script, read from its text")
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

    @Test("the deliberate Swift deviations are real: the script has no chroma exclusion in its hue spread and no text-contrast floor")
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
