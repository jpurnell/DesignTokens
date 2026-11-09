/// What is known to fall short in the Swiss palette, kept as data so consumers can act on it.
///
/// Swiss keeps Apple's system colours (the HIG says not to re-step them), and they sit outside the dataviz
/// method's bands for some slots: see `project/docs/technical/SwissConformanceLedger.md` for the exact
/// measurements, which tests pin. A finding is recorded, not hidden, and the remedy is a rule for charts:
/// these slots must be labelled directly or have their values printed.
///
/// The slot lists here are derived from Swiss's ledger (`Theme.swissConformance`), so they cannot drift
/// from it: change a ledger row and the list changes with it.
public enum SwissLedger {
    /// The Swiss series slots that fail the OKLCH lightness band or the 3:1 mark contrast against the
    /// background in the **light or the standard dark** appearance, in series order: orange, green, yellow
    /// and cyan. A chart that plots one of them labels it directly, or prints its values, and never relies on
    /// colour alone.
    ///
    /// This is the list for the two standard appearances only. With Increase Contrast on in dark, all eight
    /// series sit above the dark band (the ledger's `darkIncreased` rows), so there every slot needs a label:
    /// use ``slotsNeedingDirectLabels(in:ledger:)`` with `.darkIncreased`.
    public static let directLabelSlots = slotsNeedingDirectLabels(in: [.light, .dark])

    /// The Swiss series slots that fail the lightness band or the 3:1 mark contrast on the background in any of
    /// `appearances`, in series order.
    ///
    /// - Parameters:
    ///   - appearances: The appearances to look at.
    ///   - ledger: The findings to read; defaults to Swiss's own ledger. A parameter so a test can show the
    ///     list follows the ledger.
    public static func slotsNeedingDirectLabels(in appearances: Set<ValidationAppearance>,
                                                ledger: [Finding]? = nil) -> [String] {
        let findings = ledger ?? Theme.swissConformance.entries
        let flagged = Set(findings.compactMap { finding -> String? in
            guard appearances.contains(finding.appearance) else { return nil }
            switch finding.check {
            case .lightnessBand: return finding.subject
            case .markContrast:
                let suffix = " on background"
                return finding.subject.hasSuffix(suffix) ? String(finding.subject.dropLast(suffix.count)) : nil
            default: return nil
            }
        })
        return Palette.seriesNames.filter { flagged.contains($0) }
    }
}
