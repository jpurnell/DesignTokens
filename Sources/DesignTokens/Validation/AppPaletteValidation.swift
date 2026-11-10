import Foundation

public extension ThemeValidator {
    /// Validates an app's palette on a theme: the app's series (and accent, if it has one) are composed onto
    /// the theme (``Theme/composed(with:)``) and measured against the theme's own surfaces, in every appearance
    /// the composed theme declares. A palette without dark values on a theme that declares both appearances
    /// therefore yields a light-only composition, measured in light only, rather than a set of missing-dark findings.
    ///
    /// For ``SeriesOrder/Mode/validatedOrder`` the separation checks compare neighbours. For
    /// ``SeriesOrder/Mode/entityOrder`` they compare every pair, and every pair that needs a secondary
    /// encoding (a colour-vision finding, or a normal-vision failure) must be listed in `labelRequired`:
    /// an unlisted one is a failing ``Check/labelRequired`` finding, an entry that does not fail or names an
    /// unknown series is reported as stale or unknown. A listed pair is not suppressed: its separation
    /// findings are still returned, and ``requiresDirectLabels(_:on:)`` returns it for the chart adapters.
    static func validate(_ palette: AppPalette, on theme: Theme) -> [Finding] {
        validate(palette, on: theme, expectedTextRoles: nil)
    }

    internal static func validate(_ palette: AppPalette, on theme: Theme, expectedTextRoles: [String]?) -> [Finding] {
        let composed = theme.composed(with: palette)
        let pairs: PairSelection = palette.seriesOrder.mode == .entityOrder ? .all : .adjacent
        var findings = structureFindings(of: palette) + textStructureFindings(of: palette, expectedRoles: expectedTextRoles)
        findings += composed.appearanceIssues.map {
            Finding(severity: .fail, check: .structure, appearance: composed.appearances == .fixedDark ? .dark : .light,
                    subject: $0.subject, measured: $0.kind == .missingDark ? 0 : 1, threshold: $0.kind == .missingDark ? 1 : 0)
        }
        for (position, appearance) in measuredAppearances(palette, on: theme).enumerated() {
            findings += seriesChecks(composed, palette: palette, appearance: appearance, pairs: pairs, includeCount: position == 0)
        }
        guard palette.seriesOrder.mode == .entityOrder, palette.series != nil else { return findings }
        let required = requiredPairs(composed, pairs: pairs)
        let names = Set(composed.palette.series.map(\.name))
        let listed = palette.seriesOrder.labelRequired
        func key(_ a: String, _ b: String) -> Set<String> { [a, b] }
        let requiredKeys = Set(required.map { key($0.first, $0.second) })
        for pair in required where !listed.contains(where: { key($0.first, $0.second) == key(pair.first, pair.second) }) {
            findings.append(Finding(severity: .fail, check: .labelRequired, appearance: .light,
                                    subject: "\(pair.first) / \(pair.second)", measured: 0, threshold: 1))
        }
        for entry in listed {
            if !names.contains(entry.first) || !names.contains(entry.second) {
                findings.append(Finding(severity: .fail, check: .labelRequired, appearance: .light,
                                        subject: "\(entry.first) / \(entry.second) (unknown series)", measured: 0, threshold: 1))
            } else if !requiredKeys.contains(key(entry.first, entry.second)) {
                findings.append(Finding(severity: .warn, check: .labelRequired, appearance: .light,
                                        subject: "\(entry.first) / \(entry.second) (stale: the pair does not need labels)",
                                        measured: 0, threshold: 1))
            }
        }
        return findings
    }

    /// The pairs of an app palette's series that must be labelled directly wherever a chart plots both,
    /// in series order, on the theme's surfaces. Every pair needing a secondary encoding is returned
    /// whether or not the palette lists it.
    static func requiresDirectLabels(_ palette: AppPalette, on theme: Theme) -> [SeriesPair] {
        guard palette.series != nil else { return [] }
        let composed = theme.composed(with: palette)
        return requiredPairs(composed, pairs: .all)
    }

    /// The appearances an app palette is measured in on a theme: those the composed theme declares, plus an
    /// increased-contrast appearance wherever one of the palette's own series has an increased value. A
    /// theme's series that the palette does not replace are not measured, so they do not add one.
    static func measuredAppearances(_ palette: AppPalette, on theme: Theme) -> [ValidationAppearance] {
        var probe = theme.composed(with: palette)
        probe.palette.series = (palette.series ?? []) + palette.textRoles
        return validatedAppearances(probe)
    }

    /// Findings about the palette's own declarations, before any colour is measured.
    private static func structureFindings(of palette: AppPalette) -> [Finding] {
        var out: [Finding] = []
        func add(_ subject: String) {
            out.append(Finding(severity: .fail, check: .structure, appearance: .light, subject: subject, measured: 0, threshold: 1))
        }
        if let maximum = palette.maxSeriesPerChart, maximum < 1 { add("maxSeriesPerChart") }
        var seen = Set<String>()
        var reported = Set<String>()
        for entry in palette.series ?? [] where !seen.insert(entry.name).inserted && reported.insert(entry.name).inserted {
            add("series \(entry.name) (duplicate name)")
        }
        for pair in palette.labelTogether where !seen.contains(pair.first) || !seen.contains(pair.second) {
            add("labelTogether \(pair.first) / \(pair.second) (unknown series)")
        }
        return out
    }

    private static func requiredPairs(_ theme: Theme, pairs: PairSelection) -> [SeriesPair] {
        var seen = Set<Set<String>>()
        var out: [SeriesPair] = []
        for appearance in validatedAppearances(theme) {
            let background = surface(of: theme, role: .background, appearance: appearance)
            let colours = theme.palette.series.map { value($0.color, theme: theme, appearance: appearance) }
            let m = measure(series: colours, on: background, dark: appearance.isDark, pairs: pairs)
            let failing = Set(m.cvdByPair.filter { $0.value < ValidationThresholds.cvdTarget }.map { [$0.first, $0.second] as Set<Int> })
                .union(m.normalByPair.filter { $0.value < ValidationThresholds.normalFloor }.map { [$0.first, $0.second] as Set<Int> })
            for (i, j) in m.pairs where failing.contains([i, j]) {
                let a = theme.palette.series[i].name, b = theme.palette.series[j].name
                if seen.insert([a, b]).inserted { out.append(SeriesPair(a, b)) }
            }
        }
        return out
    }

    /// The findings for what the palette supplies, and nothing it does not: its series, its accent, its ramps.
    private static func seriesChecks(_ theme: Theme, palette: AppPalette, appearance: ValidationAppearance,
                                     pairs: PairSelection, includeCount: Bool) -> [Finding] {
        var out: [Finding] = []
        if let series = palette.series, !series.isEmpty {
            out += seriesFindings(theme, series: series, appearance: appearance, pairs: pairs, includeCount: includeCount)
        }
        if palette.accent != nil || palette.onAccent != nil {
            out += roleFindings(theme, appearance: appearance).filter { $0.subject.hasPrefix("accent") || $0.subject.hasPrefix("onAccent") }
        }
        out += textRoleFindings(theme, palette: palette, appearance: appearance)
        let supplied: [String] = (palette.sequential == nil ? [] : ["sequential"]) + (palette.diverging == nil ? [] : ["diverging"])
        if !supplied.isEmpty {
            out += rampFindings(theme, appearance: appearance).filter { finding in supplied.contains { finding.subject.hasPrefix($0) } }
        }
        return out
    }
}
