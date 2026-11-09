import Foundation

/// The thresholds of the dataviz method, in one place so a change to the method is one edit.
///
/// Source: the dataviz skill's `validate_palette.js`. CVD thresholds are calibrated to the
/// Machado-Oliveira-Fernandes (2009) severity-1.0 simulation.
public enum ValidationThresholds {
    /// OKLCH lightness band for marks on a light surface.
    public static let lightBand: ClosedRange<Double> = 0.43...0.77
    /// OKLCH lightness band for marks on a dark surface.
    public static let darkBand: ClosedRange<Double> = 0.48...0.67
    /// OKLCH chroma below which a hue reads as grey.
    public static let chromaFloor = 0.10
    /// Target OKLab distance (times 100) between compared series under protan and deutan simulation.
    public static let cvdTarget = 8.0
    /// Below the target and at or above this, a pair is legal only with secondary encoding (direct labels).
    public static let cvdFloor = 6.0
    /// Hard floor for the OKLab distance (times 100) under normal vision.
    public static let normalFloor = 15.0
    /// WCAG contrast a mark needs against its surface; below it labels or a table are required.
    public static let markContrast = 3.0
    /// WCAG contrast text needs against its surface.
    public static let textContrast = 4.5
    /// The most series the method allows; a ninth hue is never generated.
    public static let maxSeries = 8
    /// Minimum OKLCH lightness gap between adjacent ramp steps.
    public static let rampMinStep = 0.06
    /// Minimum contrast of a ramp's end step against the surface.
    public static let rampEndContrast = 2.0
    /// Maximum hue spread, in degrees, of a one-hue ramp.
    public static let rampMaxHueSpread = 40.0
    /// OKLCH chroma below which a ramp step has no hue and is left out of the hue spread.
    public static let achromaticChroma = 0.02
}

/// How serious a finding is.
public enum Severity: String, Sendable, Hashable, Codable, CaseIterable {
    /// The theme fails the method.
    case fail
    /// Legal only with labels, a table or another secondary encoding.
    case warn
}

/// Which check produced a finding.
public enum Check: String, Sendable, Hashable, Codable, CaseIterable {
    /// OKLCH lightness outside the band.
    case lightnessBand
    /// OKLCH chroma under the floor.
    case chromaFloor
    /// Two compared series too close under protan or deutan simulation.
    case cvdSeparation
    /// Two compared series too close under normal vision.
    case normalSeparation
    /// A mark with less than 3:1 against a surface.
    case markContrast
    /// Text with less than 4.5:1 against a surface.
    case textContrast
    /// A ramp whose lightness does not run in one direction.
    case rampMonotone
    /// Adjacent ramp steps too close in lightness.
    case rampStepGap
    /// A ramp end step too close to the surface.
    case rampLightEnd
    /// A ramp that spans more than one hue.
    case rampSingleHue
    /// More than eight series.
    case seriesCount
    /// A failing pair of entity-ordered series that is not listed in `labelRequired`, or a stale entry.
    case labelRequired
    /// A structural inconsistency.
    case structure

    /// Whether this is one of the ramp checks.
    public var isRamp: Bool {
        switch self {
        case .rampMonotone, .rampStepGap, .rampLightEnd, .rampSingleHue: true
        default: false
        }
    }
}

/// The appearance a finding was measured in.
public enum ValidationAppearance: String, Sendable, Hashable, Codable, CaseIterable {
    /// Light.
    case light
    /// Dark.
    case dark
    /// Light with Increase Contrast on.
    case lightIncreased
    /// Dark with Increase Contrast on.
    case darkIncreased

    /// Whether the surface is dark and the dark lightness band applies.
    public var isDark: Bool { self == .dark || self == .darkIncreased }
    /// Whether the increased-contrast values apply.
    public var isIncreased: Bool { self == .lightIncreased || self == .darkIncreased }
}

/// One measured result that falls short of the method.
///
/// `measured` is rounded to the number of places the JavaScript validator displays, so a finding is
/// exactly comparable to a ledger entry.
public struct Finding: Sendable, Hashable, Codable {
    /// How serious it is.
    public var severity: Severity
    /// The check.
    public var check: Check
    /// The appearance.
    public var appearance: ValidationAppearance
    /// What was measured: a series name, a pair `"a / b"`, `"ink on background"`, a ramp, a field path.
    public var subject: String
    /// The measured value.
    public var measured: Double
    /// The threshold it is held to (for a band, the bound that was crossed).
    public var threshold: Double

    /// Creates a finding.
    public init(severity: Severity, check: Check, appearance: ValidationAppearance, subject: String,
                measured: Double, threshold: Double) {
        self.severity = severity
        self.check = check
        self.appearance = appearance
        self.subject = subject
        self.measured = measured
        self.threshold = threshold
    }
}

/// A theme's declared relationship to the method.
///
/// A ledger is a record of exact measurements, not an annotation: a test fails if a finding appears that is
/// not in it, if a ledgered value changes, or if a ledgered finding disappears without the ledger being
/// updated.
public struct Conformance: Sendable, Hashable, Codable {
    /// The kind of conformance.
    public enum Kind: String, Sendable, Hashable, Codable, CaseIterable {
        /// No findings at all.
        case strict
        /// The owner keeps the theme despite its findings (Apple's system colours; a house's own palette).
        case ledger
        /// A legacy theme carried as it is, with its findings recorded.
        case legacy
    }

    /// The kind.
    public var kind: Kind
    /// The exact findings. Empty for ``Kind/strict``.
    public var entries: [Finding]

    /// Creates a conformance.
    public init(kind: Kind, entries: [Finding]) {
        self.kind = kind
        self.entries = entries
    }

    /// No findings are allowed.
    public static let strict = Conformance(kind: .strict, entries: [])
}

/// Which pairs of series a separation check compares.
public enum PairSelection: Sendable, Hashable {
    /// Neighbours only: bars, lines and stacks.
    case adjacent
    /// Every pair: scatter, heatmaps, small multiples, and entity-ordered palettes.
    case all
}

/// The result of the CVD check's state, as the JavaScript names it.
public enum CVDState: String, Sendable, Hashable {
    /// At or above the target.
    case pass
    /// Between the floor and the target: legal only with secondary encoding.
    case floor
    /// Below the floor.
    case fail
}

/// A value for the series at an index.
public struct IndexedValue: Sendable, Hashable {
    /// The series index.
    public var index: Int
    /// The value.
    public var value: Double
}

/// A pair of series and the distance between them.
public struct PairMeasurement: Sendable, Hashable {
    /// Index of the first series.
    public var first: Int
    /// Index of the second.
    public var second: Int
    /// OKLab distance times 100.
    public var value: Double
    /// The simulated deficiency, or `nil` for normal vision.
    public var kind: CVDKindName?

    init(first: Int, second: Int, value: Double, kind: CVDKindName?) {
        self.first = first
        self.second = second
        self.value = value
        self.kind = kind
    }
}

/// A deficiency the validator simulates, as a public name.
public enum CVDKindName: String, Sendable, Hashable {
    /// Protanopia.
    case protan
    /// Deuteranopia.
    case deutan
}

/// The raw measurements of a categorical series on one surface.
public struct SeriesMeasurement: Sendable {
    /// The colours measured, as `#RRGGBB`.
    public var hexes: [String]
    /// OKLCH lightness of each.
    public var lightness: [Double]
    /// OKLCH chroma of each.
    public var chroma: [Double]
    /// Contrast of each against the surface.
    public var contrast: [Double]
    /// The series outside the lightness band: index and L.
    public var outOfBand: [IndexedValue]
    /// The series under the chroma floor: index and C.
    public var chromaBelowFloor: [IndexedValue]
    /// The compared pairs.
    public var pairs: [(Int, Int)]
    /// Every compared pair's distance under the worse of protan and deutan simulation.
    public var cvdByPair: [PairMeasurement]
    /// Every compared pair's distance under normal vision.
    public var normalByPair: [PairMeasurement]
    /// The worst pair under protan or deutan, first found on ties, as the JavaScript reports it.
    public var worstCVD: PairMeasurement?
    /// The worst pair under normal vision.
    public var worstNormal: PairMeasurement?
    /// The worst distance under tritan simulation, 99 if there are no pairs.
    public var worstTritan: Double

    /// Where ``worstCVD`` falls against the target and floor.
    public var cvdState: CVDState {
        guard let worst = worstCVD else { return .pass }
        if worst.value >= ValidationThresholds.cvdTarget { return .pass }
        return worst.value >= ValidationThresholds.cvdFloor ? .floor : .fail
    }
}

/// The raw measurements of an ordinal ramp on one surface.
public struct RampMeasurement: Sendable {
    /// Whether lightness runs one way from end to end.
    public var monotone: Bool
    /// Number of adjacent reversals of direction.
    public var reversals: Int
    /// Adjacent steps closer than the minimum, as (from, to, gap).
    public var thinSteps: [(Int, Int, Double)]
    /// Contrast of the step that must clear the surface (the lightest on a light surface, the darkest on a dark one).
    public var lightEndContrast: Double
    /// Hue spread in degrees across the chromatic steps.
    public var hueSpread: Double
}
