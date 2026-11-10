import Foundation

public extension ThemeValidator {
    /// Where a theme's measured findings and its declared ``Theme/conformance`` disagree. Empty means the
    /// theme conforms.
    ///
    /// A ``Conformance/Kind/strict`` theme must have no findings. A ledgered or legacy theme must have
    /// exactly its ledger: a finding that is not in it, a ledgered value that has changed, and a ledgered
    /// finding that no longer occurs are each a deviation. Nothing is suppressed and nothing is silent.
    static func deviations(of theme: Theme) -> [String] {
        deviations(found: validate(theme), against: theme.conformance)
    }

    /// Where a list of measured findings and a declared ``Conformance`` disagree. Empty means they match.
    ///
    /// This is the comparison ``deviations(of:)`` makes, for findings that do not come from a whole theme
    /// (an app palette's, see ``AppPalette/validate(on:)``).
    ///
    /// - Parameters:
    ///   - found: The measured findings.
    ///   - conformance: The declared ledger.
    static func deviations(found: [Finding], against conformance: Conformance) -> [String] {
        func key(_ f: Finding) -> String { "\(f.check.rawValue) | \(f.appearance.rawValue) | \(f.subject)" }
        func describe(_ f: Finding) -> String {
            "\(f.severity.rawValue) \(key(f)): measured \(f.measured), threshold \(f.threshold)"
        }
        var ledger: [String: [Finding]] = [:]
        for entry in conformance.entries { ledger[key(entry), default: []].append(entry) }
        var out: [String] = []
        var matched: [String: Int] = [:]
        for finding in found {
            let k = key(finding)
            let index = matched[k, default: 0]
            matched[k] = index + 1
            guard let entries = ledger[k], index < entries.count else {
                out.append("unledgered finding: \(describe(finding))")
                continue
            }
            if entries[index] != finding {
                out.append("ledgered finding changed: ledger says \(describe(entries[index])); measured \(describe(finding))")
            }
        }
        for (k, entries) in ledger.sorted(by: { $0.key < $1.key }) where matched[k, default: 0] < entries.count {
            for entry in entries.dropFirst(matched[k, default: 0]) { out.append("ledgered finding no longer occurs: \(describe(entry))") }
        }
        if conformance.kind == .strict, !conformance.entries.isEmpty { out.append("a strict theme has ledger entries") }
        return out
    }
}
