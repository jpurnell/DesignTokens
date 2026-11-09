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

    @Test("the legacy themes carry legacy ledgers and nothing was tuned: values equal the BusinessMath-UI sources")
    func legacyLedgersAndUntunedValues() {
        for theme in [Theme.legacyDefault, .legacyDark, .legacyFinancial, .legacyAccessible] {
            #expect(theme.conformance.kind == .legacy, "\(theme.id)")
            #expect(ThemeValidator.deviations(of: theme) == [], "\(theme.id)")
        }
        #expect(Theme.legacyFinancial.palette.series.map(\.color.light.hex)
            == ["#004C99", "#008040", "#CC9933", "#663399", "#B21A1A", "#3380B2", "#996633", "#4C4C80"])
        #expect(Theme.legacyAccessible.palette.series.map(\.color.light.hex)
            == ["#000099", "#CC6600", "#666666", "#990099", "#008080", "#B2B200"])
        #expect(Theme.legacyDark.palette.series.map(\.color.light.hex)
            == ["#66B2FF", "#4CE666", "#FFB24C", "#B280FF", "#FF6666", "#66CCE6", "#FFD94C", "#FF80B2", "#80E6B2", "#9999FF"])
    }

    @Test("Theme.conformance decodes to strict when absent, so 0.4.0 JSON stays readable")
    func conformanceDecodesWithDefault() throws {
        let data = try ThemeCodec.encode(.swiss)
        var object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        _ = try #require(object["conformance"] as? [String: Any], "the encoded theme carries its conformance")
        object["conformance"] = nil
        let old = try JSONSerialization.data(withJSONObject: object)
        let decoded = try ThemeCodec.decode(old)
        #expect(decoded.conformance == .strict)
        #expect(decoded.palette == Theme.swiss.palette)
    }
}
