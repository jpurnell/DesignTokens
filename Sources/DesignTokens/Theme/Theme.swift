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

    /// Creates a theme.
    public init(id: String, name: String, structure: Structure, palette: ThemePalette,
                appearances: AppearanceSupport) {
        self.id = id
        self.name = name
        self.structure = structure
        self.palette = palette
        self.appearances = appearances
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
            case .lightOnly:
                if adaptive.dark != nil || adaptive.darkIncreased != nil {
                    issues.append(AppearanceIssue(kind: .unexpectedDark, subject: subject))
                }
            }
        }
        for role in ColorRole.allCases { check(palette[role], "palette.\(role.rawValue)") }
        for entry in palette.series { check(entry.color, "palette.series.\(entry.name)") }
        if appearances == .lightOnly {
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
    /// palette leaves `nil` stays as the theme has it. This is a copy; the receiver is unchanged.
    public func composed(with app: AppPalette) -> Theme {
        var copy = self
        copy.id = "\(id)+\(app.id)"
        copy.name = "\(name) (\(app.id))"
        if let accent = app.accent { copy.palette.accent = accent }
        if let series = app.series { copy.palette.series = series }
        if let sequential = app.sequential { copy.palette.sequential = sequential }
        if let diverging = app.diverging { copy.palette.diverging = diverging }
        return copy
    }
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
