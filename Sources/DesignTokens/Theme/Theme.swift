import Foundation

/// A problem with a theme's declared appearance support.
public struct AppearanceIssue: Sendable, Hashable {
    /// What is wrong.
    public enum Kind: String, Sendable, Hashable {
        /// A theme that declares both appearances has no dark value here.
        case missingDark
        /// A light-only theme has a dark value here.
        case unexpectedDark
    }

    /// What is wrong.
    public var kind: Kind
    /// Where, as a path: `palette.ink`, `palette.series.orange`, `palette.sequential`.
    public var subject: String

    /// Creates an issue.
    public init(kind: Kind, subject: String) {
        self.kind = kind
        self.subject = subject
    }
}

/// Why a theme was refused.
public enum ThemeError: Error, Sendable, Equatable {
    /// The theme's values contradict its declared appearance support.
    case invalid([AppearanceIssue])
}

/// A complete visual theme: ``Structure`` plus ``ThemePalette``.
///
/// One typed value holds everything a surface needs to look like the theme. Swift is the source; the
/// canonical JSON (``ThemeCodec``) is an output.
public struct Theme: Sendable, Hashable, Codable, Identifiable {
    /// A short stable identifier: `swiss`.
    public var id: String
    /// The display name.
    public var name: String
    /// Rules, type, labels, layout, marks and number formats.
    public var structure: Structure
    /// Colours.
    public var palette: ThemePalette
    /// Which appearances the theme supports.
    public var appearances: AppearanceSupport
    /// The theme's relationship to the validation method: strict, or a ledger of exact measurements.
    /// Added in 0.5.0 and required in JSON since then; a theme with no ledger says ``Conformance/strict``.
    public var conformance: Conformance

    /// Creates a theme.
    public init(id: String, name: String, structure: Structure, palette: ThemePalette,
                appearances: AppearanceSupport, conformance: Conformance = .strict) {
        self.id = id
        self.name = name
        self.structure = structure
        self.palette = palette
        self.appearances = appearances
        self.conformance = conformance
    }

    private enum CodingKeys: String, CodingKey, CaseIterable { case id, name, structure, palette, appearances, conformance }

    /// Decodes a theme, and refuses one that is not a well-formed theme.
    ///
    /// The plain `Decodable` is as strict as ``ThemeCodec/decode(_:)``; nothing about a theme is checked only
    /// there. It throws
    /// - `DecodingError.dataCorrupted` for a key the format does not have (a misspelling is an error, not a
    ///   silent default), a colour or ramp reference that names nothing, an opacity outside 0 to 1, a negative
    ///   or NaN rule weight, a ramp whose dark and light steps differ in number, and a strict theme that
    ///   carries ledger entries (the message names the path), and
    /// - ``ThemeError/invalid(_:)`` for dark values that contradict ``appearances``.
    ///
    /// Required keys: everything, including `conformance`, `extras`, `colourOverrides` and `rampOverrides`
    /// (added in 0.5.0). Only the fields added after 0.5.0 default when absent: `layout.annotationRadius`
    /// (0), `marks.areaOpacity` (0.22), `marks.fillOpacity` (0.35) and `marks.detailLineWidth` (1.5), all
    /// 0.6.0; and the optionals `shadow`, `tagMark`, `platformStyle`, `system` and the increased-contrast
    /// colours, whose absence means "none".
    public init(from decoder: any Decoder) throws {
        let raw = try RawJSON(from: decoder)
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.id = try container.decode(String.self, forKey: .id)
            self.name = try container.decode(String.self, forKey: .name)
            self.structure = try container.decode(Structure.self, forKey: .structure)
            self.palette = try container.decode(ThemePalette.self, forKey: .palette)
            self.appearances = try container.decode(AppearanceSupport.self, forKey: .appearances)
            self.conformance = try container.decode(Conformance.self, forKey: .conformance)
        } catch let error as DecodingError {
            // a required key that is missing is often a misspelt one: say which keys the input has instead
            if case .object(let given) = raw {
                let known = Set(CodingKeys.allCases.map(\.stringValue))
                let unknown = given.keys.filter { !known.contains($0) }.sorted()
                if !unknown.isEmpty {
                    throw DecodingError.dataCorrupted(.init(
                        codingPath: decoder.codingPath,
                        debugDescription: "unknown key \(unknown.map { "\"\($0)\"" }.joined(separator: ", ")) (a theme has \(CodingKeys.allCases.map(\.stringValue).joined(separator: ", "))); \(Self.describe(error))"))
                }
            }
            throw error
        }
        let reencoded = try JSONEncoder().encode(UncheckedTheme(theme: self))
        let unknown = raw.unknownKeys(comparedWith: try JSONDecoder().decode(RawJSON.self, from: reencoded))
        if !unknown.isEmpty {
            throw DecodingError.dataCorrupted(.init(
                codingPath: decoder.codingPath,
                debugDescription: "unknown key\(unknown.count == 1 ? "" : "s") \(unknown.joined(separator: ", ")): the format has no such field, and a misspelling would be dropped silently"))
        }
        let problems = consistencyProblems
        guard problems.isEmpty else {
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: problems.joined(separator: "; ")))
        }
        let issues = appearanceIssues
        guard issues.isEmpty else { throw ThemeError.invalid(issues) }
    }

    /// Encodes the theme, refusing one that ``init(from:)`` would refuse to read back.
    ///
    /// - Throws: `EncodingError.invalidValue` for the inconsistencies the decoder names, and
    ///   ``ThemeError/invalid(_:)`` for dark values that contradict ``appearances``.
    public func encode(to encoder: any Encoder) throws {
        let problems = consistencyProblems
        guard problems.isEmpty else {
            throw EncodingError.invalidValue(self, .init(codingPath: encoder.codingPath, debugDescription: problems.joined(separator: "; ")))
        }
        let issues = appearanceIssues
        guard issues.isEmpty else { throw ThemeError.invalid(issues) }
        try encodeFields(to: encoder)
    }

    fileprivate func encodeFields(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(structure, forKey: .structure)
        try container.encode(palette, forKey: .palette)
        try container.encode(appearances, forKey: .appearances)
        try container.encode(conformance, forKey: .conformance)
    }

    private static func describe(_ error: DecodingError) -> String {
        switch error {
        case .keyNotFound(let key, _): "missing key \"\(key.stringValue)\""
        case .typeMismatch(_, let context), .valueNotFound(_, let context), .dataCorrupted(let context): context.debugDescription
        @unknown default: "\(error)"
        }
    }

    /// Where the theme's values contradict its declared ``appearances``. Empty means consistent.
    ///
    /// A theme that declares ``AppearanceSupport/both`` must have a dark value on every colour role and
    /// every series entry; a missing one is an issue, not a silent light fallback. A light-only theme must
    /// have none, anywhere (ramps included). Ramps are exempt from the first rule: a dark diverging ramp
    /// does not exist in ``Palette`` and is not invented.
    public var appearanceIssues: [AppearanceIssue] {
        var issues: [AppearanceIssue] = []
        func check(_ adaptive: Adaptive, _ subject: String) {
            switch appearances {
            case .both:
                if adaptive.dark == nil { issues.append(AppearanceIssue(kind: .missingDark, subject: subject)) }
            case .lightOnly, .fixedDark:
                if adaptive.dark != nil || adaptive.darkIncreased != nil {
                    issues.append(AppearanceIssue(kind: .unexpectedDark, subject: subject))
                }
            }
        }
        for role in ColorRole.allCases { check(palette[role], "palette.\(role.rawValue)") }
        for entry in palette.series { check(entry.color, "palette.series.\(entry.name)") }
        for (name, adaptive) in palette.extras.sorted(by: { $0.key < $1.key }) { check(adaptive, "palette.extras.\(name)") }
        if appearances != .both {
            func checkRamp(_ ramp: Ramp, _ subject: String) {
                if ramp.dark != nil { issues.append(AppearanceIssue(kind: .unexpectedDark, subject: subject)) }
            }
            checkRamp(palette.sequential, "palette.sequential")
            checkRamp(palette.diverging, "palette.diverging")
            for name in palette.extraRamps.keys.sorted() {
                if let ramp = palette.extraRamps[name] { checkRamp(ramp, "palette.extraRamps.\(name)") }
            }
        }
        return issues
    }

    /// The theme with an app's own accent and series on top. Structure and surfaces are kept.
    ///
    /// The result's id is `"<theme id>+<app id>"` and its name `"<name> (<app id>)"`. Whatever the app
    /// palette leaves `nil` stays as the theme has it. The result's ``conformance`` is ``Conformance/strict``:
    /// the receiver's ledger describes its own colours, not these. This is a copy; the receiver is unchanged.
    ///
    /// **The result is always a valid theme** (``appearanceIssues`` is empty), and the rule that makes it so is
    /// deterministic:
    /// - A receiver that declares ``AppearanceSupport/both`` stays `both` only if every colour the app palette
    ///   supplies (its accent and each series entry) has a dark value. If any lacks one, the result is
    ///   ``AppearanceSupport/lightOnly`` and every dark value is removed, the receiver's included: a theme with
    ///   some dark colours and some light fallbacks is the half-dark state ``appearanceIssues`` rejects, and no
    ///   dark value is invented. This is how ``Theme/princeton`` is built (Swiss with a light-only palette).
    /// - A receiver that is already ``AppearanceSupport/lightOnly`` or ``AppearanceSupport/fixedDark`` keeps its
    ///   appearance, and any dark values the app palette brings are dropped, because that appearance has no
    ///   `dark` slot.
    /// - Ramps are exempt, as they are in ``appearanceIssues``: an app ramp without a dark version leaves the
    ///   result `both`, and the ramp is used as it is on a dark surface.
    public func composed(with app: AppPalette) -> Theme {
        var copy = self
        copy.id = "\(id)+\(app.id)"
        copy.name = "\(name) (\(app.id))"
        copy.conformance = .strict
        if let accent = app.accent { copy.palette.accent = accent }
        if let series = app.series { copy.palette.series = series }
        if let sequential = app.sequential { copy.palette.sequential = sequential }
        if let diverging = app.diverging { copy.palette.diverging = diverging }
        if appearances == .both {
            let supplied = (app.accent.map { [$0] } ?? []) + (app.series ?? []).map(\.color)
            if supplied.contains(where: { $0.dark == nil }) { copy.appearances = .lightOnly }
        }
        if copy.appearances != .both { copy.palette = copy.palette.strippingDark() }
        return copy
    }
}

/// A theme written without the checks, so the decoder can compare the keys it was given with the keys the
/// model writes.
private struct UncheckedTheme: Encodable {
    let theme: Theme
    func encode(to encoder: any Encoder) throws { try theme.encodeFields(to: encoder) }
}

/// Two series names that must be labelled directly wherever a chart plots both.
public struct SeriesPair: Sendable, Hashable, Codable {
    /// One series.
    public var first: String
    /// The other.
    public var second: String

    /// Creates a pair.
    public init(_ first: String, _ second: String) {
        self.first = first
        self.second = second
    }
}

/// How an app palette's series are ordered.
public struct SeriesOrder: Sendable, Hashable, Codable {
    /// The ordering mode.
    public enum Mode: String, Sendable, Hashable, Codable {
        /// The order was chosen so neighbours separate; checked on adjacent pairs.
        case validatedOrder
        /// The order is the entities' (wine types, teams); checked on every pair.
        case entityOrder
    }

    /// The ordering mode.
    public var mode: Mode
    /// For ``Mode/entityOrder``: the pairs that fail a separation floor and so need direct labels.
    /// They are listed, not suppressed.
    public var labelRequired: [SeriesPair]

    /// The order was validated for neighbours.
    public static var validatedOrder: SeriesOrder { SeriesOrder(mode: .validatedOrder, labelRequired: []) }

    /// The order is the entities', with the pairs that must be labelled directly.
    public static func entityOrder(labelRequired: [SeriesPair]) -> SeriesOrder {
        SeriesOrder(mode: .entityOrder, labelRequired: labelRequired)
    }
}

/// An app's own colours, to be composed onto a theme's structure: WineTaster's wine colours, a team palette.
public struct AppPalette: Sendable, Hashable, Codable {
    /// A short stable identifier.
    public var id: String
    /// The accent, or `nil` to keep the theme's.
    public var accent: Adaptive?
    /// The series, or `nil` to keep the theme's.
    public var series: [NamedAdaptive]?
    /// A sequential ramp, or `nil` to keep the theme's.
    public var sequential: Ramp?
    /// A diverging ramp, or `nil` to keep the theme's.
    public var diverging: Ramp?
    /// How the series are ordered.
    public var seriesOrder: SeriesOrder

    /// Creates an app palette.
    public init(id: String, accent: Adaptive?, series: [NamedAdaptive]?, sequential: Ramp? = nil,
                diverging: Ramp? = nil, seriesOrder: SeriesOrder) {
        self.id = id
        self.accent = accent
        self.series = series
        self.sequential = sequential
        self.diverging = diverging
        self.seriesOrder = seriesOrder
    }
}
