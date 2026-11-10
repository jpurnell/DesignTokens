import Foundation

/// The marker of a declared app-palette file.
///
/// An app declares its colours in **one file** by conforming a type to this protocol and returning its
/// ``AppPalette``:
///
/// ```swift
/// import DesignTokens
///
/// enum WinePalette: AppPaletteSource {
///     static let palette = AppPalette(
///         id: "winetaster",
///         accent: Adaptive(light: 0x7F0017, dark: 0xE0788A),
///         series: [NamedAdaptive("red", light: 0x7F0017, dark: 0xE0788A)],
///         seriesOrder: .validatedOrder)
/// }
/// ```
///
/// An app's test target then asserts that `WinePalette.validate().isConformant` is true, printing `report` when it is not.
///
/// The conformance is the machine-readable marker the drift checker looks for: the compiler guarantees a type
/// that claims it supplies a palette, and a syntactic checker sees the name in the inheritance clause. The app's
/// test target then asserts `#expect(WinePalette.validate().isConformant)`. The full contract is
/// `project/plans/proposals/2026-11-10_AppPaletteAdoption.md`, and "How an app adopts the tokens".
public protocol AppPaletteSource: Sendable {
    /// The app's palette.
    static var palette: AppPalette { get }
}

public extension AppPaletteSource {
    /// Validates ``palette`` on `theme` (Swiss by default). See ``AppPalette/validate(on:)``.
    static func validate(on theme: Theme = .swiss) -> AppPaletteConformance {
        palette.validate(on: theme)
    }
}

/// Why a pair of series must be labelled directly.
public struct LabelRequirement: Sendable, Hashable {
    /// Where the requirement comes from.
    public enum Reason: String, Sendable, Hashable {
        /// The colours fail a separation threshold (measured, entity-ordered palettes only).
        case measured
        /// The app's own rule, ``AppPalette/labelTogether``.
        case declared
        /// Both.
        case both
    }

    /// The two series.
    public var pair: SeriesPair
    /// Why.
    public var reason: Reason

    /// Creates a requirement.
    public init(pair: SeriesPair, reason: Reason) {
        self.pair = pair
        self.reason = reason
    }

    /// Two requirements are equal when they name the same two series, in either order, for the same reason.
    public static func == (lhs: LabelRequirement, rhs: LabelRequirement) -> Bool {
        lhs.reason == rhs.reason && Set([lhs.pair.first, lhs.pair.second]) == Set([rhs.pair.first, rhs.pair.second])
    }

    /// Hashes the unordered pair and the reason, consistently with `==`.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(Set([pair.first, pair.second]))
        hasher.combine(reason)
    }
}

/// A chart that breaks one of an app palette's rules.
public enum ChartRuleViolation: Sendable, Hashable {
    /// More distinct series than one chart may plot.
    case tooManySeries(plotted: Int, max: Int)
    /// A series the palette does not have.
    case unknownSeries(String)
    /// Both series of a pair that must be labelled are plotted, and one of them is not labelled.
    case unlabelledPair(SeriesPair)
}

/// The result of validating an app palette: the measurements, how they compare with the palette's ledger, and a
/// report an app's test can print.
///
/// ```swift
/// let palette = AppPalette(id: "demo", accent: nil, series: nil, seriesOrder: .validatedOrder)
/// let result = palette.validate()
/// print(result.isConformant ? "conformant" : result.report)
/// ```
///
/// In a test target: `#expect(result.isConformant, "\(result.report)")`.
public struct AppPaletteConformance: Sendable, Equatable {
    /// The palette's id.
    public let paletteID: String
    /// The id of the theme the palette was composed onto: `swiss+<palette id>`.
    public let themeID: String
    /// The appearances that were measured.
    public let appearances: [ValidationAppearance]
    /// Every measurement that falls short of the method (not decided: see ``deviations``).
    public let findings: [Finding]
    /// Where the findings and the palette's ledger disagree, each described exactly. Empty means they match.
    public let deviations: [String]
    /// The pairs that must be labelled directly wherever a chart plots both.
    public let labelRequirements: [LabelRequirement]
    /// The most series one chart may plot.
    public let maxSeriesPerChart: Int

    /// Whether the measured findings are exactly the palette's ledger. A palette with no ledger must have no findings.
    public var isConformant: Bool { deviations.isEmpty }

    /// A printable report: the verdict, every deviation, every finding with its measured value and threshold, and
    /// the labelling requirements.
    public var report: String {
        var lines = ["App palette \"\(paletteID)\" on \(themeID): \(isConformant ? "CONFORMANT" : "NOT CONFORMANT")",
                     "Measured in: \(appearances.map(\.rawValue).joined(separator: ", "))"]
        lines.append("Deviations from the ledger (\(deviations.count)):")
        lines += deviations.map { "  - \($0)" }
        lines.append("Findings (\(findings.count)):")
        lines += findings.map { "  \($0.severity.rawValue) \($0.check.rawValue) | \($0.appearance.rawValue) | \($0.subject): measured \($0.measured), threshold \($0.threshold)" }
        lines.append("Label together (\(labelRequirements.count)):")
        lines += labelRequirements.map { "  \($0.pair.first) / \($0.pair.second) (\($0.reason.rawValue))" }
        lines.append("Series per chart: at most \(maxSeriesPerChart)")
        return lines.joined(separator: "\n")
    }

    /// The measured findings as Swift source for ``AppPalette/conformance``.
    ///
    /// Write the palette with no ledger, run ``AppPalette/validate(on:)``, paste this, and review each row as a
    /// decision: that is how the built-in themes' ledgers were made. No findings gives `Conformance.strict`.
    public var ledgerSource: String {
        guard !findings.isEmpty else { return "Conformance.strict" }
        var lines = ["Conformance(kind: .ledger, entries: ["]
        for f in findings {
            lines.append("    Finding(severity: .\(f.severity.rawValue), check: .\(f.check.rawValue), appearance: .\(f.appearance.rawValue), subject: \"\(f.subject)\", measured: \(f.measured), threshold: \(f.threshold)),")
        }
        lines.append("])")
        return lines.joined(separator: "\n")
    }
}

public extension AppPalette {
    /// Validates the palette against a theme (Swiss by default) in every appearance it has values for, and
    /// compares the findings with its own ``conformance`` ledger.
    ///
    /// The palette's accent, series and supplied ramps are composed onto the theme (``Theme/composed(with:)``) and
    /// measured by ``ThemeValidator/validate(_:on:)``; the theme's surfaces are the backgrounds. Nothing is
    /// suppressed: a finding that is not in the ledger, a ledgered value that has changed, and a ledgered finding
    /// that no longer occurs are each a deviation.
    func validate(on theme: Theme = .swiss) -> AppPaletteConformance {
        let findings = ThemeValidator.validate(self, on: theme)
        let measured = seriesOrder.mode == .entityOrder ? ThemeValidator.requiresDirectLabels(self, on: theme) : []
        func key(_ pair: SeriesPair) -> Set<String> { [pair.first, pair.second] }
        let declared = Set(labelTogether.map(key))
        var requirements = measured.map {
            LabelRequirement(pair: $0, reason: declared.contains(key($0)) ? .both : .measured)
        }
        let measuredKeys = Set(measured.map(key))
        for pair in labelTogether where !measuredKeys.contains(key(pair)) {
            requirements.append(LabelRequirement(pair: pair, reason: .declared))
        }
        return AppPaletteConformance(
            paletteID: id, themeID: "\(theme.id)+\(id)",
            appearances: ThemeValidator.measuredAppearances(self, on: theme),
            findings: findings,
            deviations: ThemeValidator.deviations(found: findings, against: conformance),
            labelRequirements: requirements,
            maxSeriesPerChart: maxSeriesPerChart ?? ValidationThresholds.maxSeries)
    }

    /// The theme the palette makes on `theme` (Swiss by default): ``Theme/composed(with:)``.
    ///
    /// ``ThemeCSSEmitter``, ``ThemeJSONEmitter`` and ``ANSIEmitter`` take it as they take any theme, which is how an
    /// app that needs web or terminal output gets it in its own colours. The emitted files are the app's, not this
    /// package's.
    func theme(on theme: Theme = .swiss) -> Theme {
        theme.composed(with: self)
    }

    /// The rules a chart plotting `names` breaks, in the order: too many series, unknown series (once each, in
    /// plotting order), then pairs that must be labelled.
    ///
    /// A pair is any of ``labelTogether`` and ``SeriesOrder/labelRequired``; it is a violation when both members
    /// are plotted and either is not in `labelled`. A repeated name is one series. Pure: it measures nothing.
    ///
    /// - Parameters:
    ///   - names: The series the chart plots.
    ///   - labelled: The series the chart labels directly.
    func chartViolations(plotting names: [String], labelled: Set<String> = []) -> [ChartRuleViolation] {
        var out: [ChartRuleViolation] = []
        var distinct: [String] = []
        for name in names where !distinct.contains(name) { distinct.append(name) }
        let limit = maxSeriesPerChart ?? ValidationThresholds.maxSeries
        if distinct.count > limit { out.append(.tooManySeries(plotted: distinct.count, max: limit)) }
        let known = Set((series ?? []).map(\.name))
        for name in distinct where !known.contains(name) { out.append(.unknownSeries(name)) }
        var seen = Set<Set<String>>()
        for pair in labelTogether + seriesOrder.labelRequired {
            guard distinct.contains(pair.first), distinct.contains(pair.second) else { continue }
            guard seen.insert([pair.first, pair.second]).inserted else { continue }
            if !labelled.contains(pair.first) || !labelled.contains(pair.second) { out.append(.unlabelledPair(pair)) }
        }
        return out
    }
}
