import Foundation
import Testing
@testable import DesignTokens

@Suite("Conformance ledgers")
struct ConformanceTests {
    @Test("Swiss's ledger is exactly what the validator finds, including the 0.4.0 rows")
    func swissConformanceMatchesValidator() {
        #expect(Theme.swiss.conformance.kind == .ledger)
        #expect(ThemeValidator.deviations(of: .swiss) == [])
        let ledger = Theme.swiss.conformance.entries
        #expect(same(ledger.filter { $0.check == .lightnessBand && $0.appearance == .light }.map(\.measured), [0.865]))
        #expect(ledger.filter { $0.check == .lightnessBand && $0.appearance == .light }.map(\.subject) == ["yellow"])
        #expect(same(ledger.filter { $0.check == .lightnessBand && $0.appearance == .dark }.map(\.measured), [0.762, 0.756, 0.885, 0.808]))
        let marks = ["orange", "green", "yellow", "cyan"].map { "\($0) on background" }
        #expect(same(ledger.filter { $0.check == .markContrast && $0.appearance == .light && marks.contains($0.subject) }.map(\.measured),
                     [2.21, 2.13, 1.45, 2.07]))
    }

    @Test("any change to a ledgered measurement fails: changed, new and vanished findings are all reported")
    func ledgerFailsOnAnyChange() throws {
        var changed = Theme.swiss
        var entries = changed.conformance.entries
        let index = try #require(entries.firstIndex { $0.check == .lightnessBand && $0.appearance == .light })
        entries[index].measured += 0.001
        changed.conformance = Conformance(kind: .ledger, entries: entries)
        #expect(ThemeValidator.deviations(of: changed).count == 1)

        var vanished = Theme.swiss
        vanished.conformance = Conformance(kind: .ledger, entries: Array(Theme.swiss.conformance.entries.dropFirst()))
        #expect(ThemeValidator.deviations(of: vanished).count == 1)

        var extra = Theme.swiss
        extra.conformance = Conformance(kind: .ledger, entries: Theme.swiss.conformance.entries + [
            Finding(severity: .fail, check: .chromaFloor, appearance: .light, subject: "ghost", measured: 0.01, threshold: 0.1)])
        #expect(ThemeValidator.deviations(of: extra).count == 1)

        var strict = Theme.swiss
        strict.conformance = .strict
        #expect(!ThemeValidator.deviations(of: strict).isEmpty)
    }

    @Test("FT and Economist findings are exactly their ledgers, light and authored dark")
    func ftAndEconomistFindingsAreExactlyTheLedger() {
        for theme in [Theme.ft, Theme.economist] {
            #expect(ThemeValidator.deviations(of: theme) == [], "\(theme.id)")
            #expect(theme.appearances == .both)
            #expect(theme.conformance.entries.contains { $0.appearance == .light }, "\(theme.id) light findings are real")
        }
    }

    @Test("the legacy themes carry legacy ledgers that match the validator, and three series arrays are pinned to the BusinessMath-UI values")
    func legacyLedgersAndThreeSeriesArrays() {
        for theme in [Theme.legacyDefault, .legacyDark, .legacyFinancial, .legacyAccessible] {
            #expect(theme.conformance.kind == .legacy, "\(theme.id)")
            #expect(ThemeValidator.deviations(of: theme) == [], "\(theme.id)")
        }
        // Only the light series of these three themes are written out here. Every other legacy value (extras,
        // surfaces, ramps, structure) is pinned by the committed Generated/themes/<id>.json and .css files, which
        // `ThemeEmitterTests.generatedFilesMatchCommitted` compares with a fresh emit; there is no BusinessMath-UI
        // source in this repository to compare them with, so "equal to the sources" is not something a test here proves.
        #expect(Theme.legacyFinancial.palette.series.map(\.color.light.hex)
            == ["#004C99", "#008040", "#CC9933", "#663399", "#B21A1A", "#3380B2", "#996633", "#4C4C80"])
        #expect(Theme.legacyAccessible.palette.series.map(\.color.light.hex)
            == ["#000099", "#CC6600", "#666666", "#990099", "#008080", "#B2B200"])
        #expect(Theme.legacyDark.palette.series.map(\.color.light.hex)
            == ["#66B2FF", "#4CE666", "#FFB24C", "#B280FF", "#FF6666", "#66CCE6", "#FFD94C", "#FF80B2", "#80E6B2", "#9999FF"])
    }

    @Test("Theme.conformance is required in JSON since 0.5.0: absent is an error, not a silent strict")
    func conformanceIsRequired() throws {
        let data = try ThemeCodec.encode(.swiss)
        var object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        _ = try #require(object["conformance"] as? [String: Any], "the encoded theme carries its conformance")
        object["conformance"] = nil
        let old = try JSONSerialization.data(withJSONObject: object)
        #expect(throws: DecodingError.self) { try ThemeCodec.decode(old) }
        #expect(throws: DecodingError.self) { try JSONDecoder().decode(Theme.self, from: old) }
        // a theme whose conformance is strict says so, and that is what Theme.init defaults to in Swift
        var strict = Theme.house
        strict.conformance = .strict
        #expect(try ThemeCodec.decode(ThemeCodec.encode(strict)).conformance == .strict)
    }
}
