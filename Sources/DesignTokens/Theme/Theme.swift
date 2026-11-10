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
    ///   supplies (its accent, each series entry, its background and surface, and each text role) has a dark value. If any lacks one, the result is
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
        if let onAccent = app.onAccent { copy.palette.onAccent = onAccent }
        if let series = app.series { copy.palette.series = series }
        if let background = app.background { copy.palette.background = background }
        if let surface = app.surface { copy.palette.surface = surface }
        if let sequential = app.sequential { copy.palette.sequential = sequential }
        if let diverging = app.diverging { copy.palette.diverging = diverging }
        for text in app.textRoles {
            if let role = ColorRole(rawValue: text.name), AppPalette.overridableTextRoles.contains(role) {
                copy.palette[role] = text.color
            } else {
                copy.palette.extras[text.name] = text.color
            }
        }
        if appearances == .both {
            let supplied = (app.accent.map { [$0] } ?? []) + (app.onAccent.map { [$0] } ?? []) + (app.series ?? []).map(\.color)
                + (app.background.map { [$0] } ?? []) + (app.surface.map { [$0] } ?? [])
                + app.textRoles.map(\.color)
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
    /// The colour of text and marks on the accent, or `nil` to keep the theme's. A dark accent such as WineTaster's
    /// `#7F0017` needs its own: Swiss's `onAccent` is chosen for Swiss's orange and fails against it
    /// (added in 0.8.0).
    public var onAccent: Adaptive?
    /// The series, or `nil` to keep the theme's.
    public var series: [NamedAdaptive]?
    /// The window or page the app draws on, or `nil` to keep the theme's (added in 0.10.0).
    ///
    /// ``Theme/composed(with:)`` makes it the composed theme's `background`, so everything measured against the theme's
    /// background (marks, ink, secondary ink, link, the text roles when ``textSurfaces`` is `nil`) is measured against the
    /// app's own. A translucent value (alpha below 1) lets the window show through; it is measured composited over white
    /// (black in dark), so declare ``textSurfaces`` with the real colours as well.
    public var background: Adaptive?
    /// A card or raised surface, or `nil` to keep the theme's (added in 0.10.0). See ``background``.
    public var surface: Adaptive?
    /// A sequential ramp, or `nil` to keep the theme's.
    public var sequential: Ramp?
    /// A diverging ramp, or `nil` to keep the theme's.
    public var diverging: Ramp?
    /// The app's text colours by what they mean (status, secondary text), or empty to keep the theme's. Added in 0.9.0.
    ///
    /// Each is measured as **text** (4.5:1, ``Check/textContrast``) against ``textSurfaces``, and as nothing else: no
    /// lightness band, separation or mark contrast, so a colour that is printed with a word and never plotted
    /// does not belong in ``series``. A role named `ink`, `secondaryInk`, `link`, `positive`, `negative` or `warning`
    /// overrides that role of the theme the palette is composed onto; any other name becomes an extra of it.
    public var textRoles: [NamedAdaptive]
    /// The backgrounds the text roles are drawn on, or `nil` for the theme's own `background` and `surface`.
    /// Added in 0.9.0. See ``TextSurfaces``.
    public var textSurfaces: TextSurfaces?
    /// How the series are ordered.
    public var seriesOrder: SeriesOrder
    /// The most series one chart may plot, or `nil` for the method's eight (``ValidationThresholds/maxSeries``).
    ///
    /// This is a limit per chart, not a palette size: WineTaster has more wine types than the five it allows in
    /// one chart. ``chartViolations(plotting:labelled:)`` applies it.
    public var maxSeriesPerChart: Int?
    /// Pairs that must be labelled directly wherever a chart plots both, by the app's own rule, whether or not
    /// the colours fail a threshold (WineTaster: Light White and Full White).
    ///
    /// Unlike ``SeriesOrder/labelRequired``, which records measured failures and is checked for staleness, this
    /// is a declared rule and is never stale.
    public var labelTogether: [SeriesPair]
    /// The palette's ledger: the exact findings the owner keeps, as the built-in themes have. ``Conformance/strict``
    /// (the default) allows none. See ``validate(on:)``.
    public var conformance: Conformance

    /// Creates an app palette.
    ///
    /// Everything but `id` is defaulted (0.9.0), so a palette of text roles only is
    /// `AppPalette(id: "x", textRoles: [...], textSurfaces: ...)`.
    public init(id: String, accent: Adaptive? = nil, onAccent: Adaptive? = nil, series: [NamedAdaptive]? = nil,
                background: Adaptive? = nil, surface: Adaptive? = nil,
                sequential: Ramp? = nil, diverging: Ramp? = nil, textRoles: [NamedAdaptive] = [],
                textSurfaces: TextSurfaces? = nil, seriesOrder: SeriesOrder = .validatedOrder,
                maxSeriesPerChart: Int? = nil, labelTogether: [SeriesPair] = [], conformance: Conformance = .strict) {
        self.id = id
        self.accent = accent
        self.onAccent = onAccent
        self.series = series
        self.background = background
        self.surface = surface
        self.sequential = sequential
        self.diverging = diverging
        self.textRoles = textRoles
        self.textSurfaces = textSurfaces
        self.seriesOrder = seriesOrder
        self.maxSeriesPerChart = maxSeriesPerChart
        self.labelTogether = labelTogether
        self.conformance = conformance
    }

    private enum CodingKeys: String, CodingKey {
        case id, accent, onAccent, series, background, surface, sequential, diverging, textRoles, textSurfaces, seriesOrder, maxSeriesPerChart, labelTogether, conformance
    }

    /// Decodes an app palette. The keys added in 0.8.0 (`onAccent`, `maxSeriesPerChart`, `labelTogether`, `conformance`)
    /// and 0.9.0 (`textRoles`, `textSurfaces`) default when absent, so JSON written by 0.7.0 or 0.8.0 still reads.
    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(id: try c.decode(String.self, forKey: .id),
                  accent: try c.decodeIfPresent(Adaptive.self, forKey: .accent),
                  onAccent: try c.decodeIfPresent(Adaptive.self, forKey: .onAccent),
                  series: try c.decodeIfPresent([NamedAdaptive].self, forKey: .series),
                  background: try c.decodeIfPresent(Adaptive.self, forKey: .background),
                  surface: try c.decodeIfPresent(Adaptive.self, forKey: .surface),
                  sequential: try c.decodeIfPresent(Ramp.self, forKey: .sequential),
                  diverging: try c.decodeIfPresent(Ramp.self, forKey: .diverging),
                  textRoles: try c.decodeIfPresent([NamedAdaptive].self, forKey: .textRoles) ?? [],
                  textSurfaces: try c.decodeIfPresent(TextSurfaces.self, forKey: .textSurfaces),
                  seriesOrder: try c.decode(SeriesOrder.self, forKey: .seriesOrder),
                  maxSeriesPerChart: try c.decodeIfPresent(Int.self, forKey: .maxSeriesPerChart),
                  labelTogether: try c.decodeIfPresent([SeriesPair].self, forKey: .labelTogether) ?? [],
                  conformance: try c.decodeIfPresent(Conformance.self, forKey: .conformance) ?? .strict)
    }

    /// Encodes the palette. The three 0.8.0 keys are always written, so a round trip is exact.
    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encodeIfPresent(accent, forKey: .accent)
        try c.encodeIfPresent(onAccent, forKey: .onAccent)
        try c.encodeIfPresent(series, forKey: .series)
        try c.encodeIfPresent(background, forKey: .background)
        try c.encodeIfPresent(surface, forKey: .surface)
        try c.encodeIfPresent(sequential, forKey: .sequential)
        try c.encodeIfPresent(diverging, forKey: .diverging)
        try c.encode(textRoles, forKey: .textRoles)
        try c.encodeIfPresent(textSurfaces, forKey: .textSurfaces)
        try c.encode(seriesOrder, forKey: .seriesOrder)
        try c.encodeIfPresent(maxSeriesPerChart, forKey: .maxSeriesPerChart)
        try c.encode(labelTogether, forKey: .labelTogether)
        try c.encode(conformance, forKey: .conformance)
    }
}
