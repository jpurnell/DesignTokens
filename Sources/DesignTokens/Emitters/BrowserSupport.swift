import Foundation

/// The browser floor of the CSS the package emits: each modern feature it uses, the first version of each engine that ships it, and
/// where it is used. Added in 0.12.0.
///
/// The CSS the package emits (`tokens.css`, `themes/<id>.css`, `components.css`, and the Tumblr block) uses no fallbacks: a browser
/// older than the floor does not get a degraded layout on purpose, it gets whatever its parser makes of the rules it does not know. The
/// table is data so that the generated `components.css` header, the README and the tests read one source, and a test checks that each
/// listed feature really appears in the CSS it is listed for and that none appears unlisted.
///
/// **Source of the numbers:** `@mdn/browser-compat-data` 8.1.8 (the data behind MDN's compatibility tables), read from the npm registry
/// on 2026-11-10; the `version_added` of the unprefixed, unflagged support statement, the latest one where a feature has more than one.
/// MDN's pages for `color-mix()` and `@container` were read as a cross-check: both are marked Baseline "widely available", since May
/// 2023 and February 2023, which agrees with the versions below. Edge is Chromium-based from 79; an Edge number below 79 is the legacy
/// engine's and is not a floor anyone needs.
public enum BrowserSupport {
    /// A group of emitted files a feature is used in.
    public enum Scope: String, Sendable, Hashable, CaseIterable {
        /// `tokens.css` and every `themes/<id>.css`.
        case themes
        /// `components.css`.
        case components
        /// The Tumblr block (`themes/swiss.tumblr.css`), which is separate from the rest and has its own floor.
        case tumblr
    }

    /// The first version of each engine's browsers that ships a feature.
    public struct Versions: Sendable, Hashable {
        /// Chrome.
        public var chrome: Double
        /// Edge (Chromium).
        public var edge: Double
        /// Safari (macOS and iOS share a version number).
        public var safari: Double
        /// Firefox.
        public var firefox: Double

        /// Creates a set of versions.
        public init(chrome: Double, edge: Double, safari: Double, firefox: Double) {
            self.chrome = chrome
            self.edge = edge
            self.safari = safari
            self.firefox = firefox
        }

        /// The newest of each engine: the version that supports every feature of both.
        func newest(with other: Versions) -> Versions {
            Versions(chrome: max(chrome, other.chrome), edge: max(edge, other.edge),
                     safari: max(safari, other.safari), firefox: max(firefox, other.firefox))
        }
    }

    /// One modern CSS feature.
    public struct Feature: Sendable, Hashable {
        /// What it is called.
        public var name: String
        /// A regular expression that finds it in emitted CSS; a test holds it against the emitted files.
        public var pattern: String
        /// The first versions that ship it.
        public var versions: Versions
        /// Where the package uses it.
        public var scopes: Set<Scope>
        /// A note, or an empty string.
        public var note: String
    }

    private static func feature(_ name: String, _ pattern: String, _ chrome: Double, _ edge: Double, _ safari: Double, _ firefox: Double,
                                _ scopes: Set<Scope>, note: String = "") -> Feature {
        Feature(name: name, pattern: pattern, versions: Versions(chrome: chrome, edge: edge, safari: safari, firefox: firefox),
                scopes: scopes, note: note)
    }

    /// Every feature, newest requirement first within no particular order; see ``floor(for:)`` for the result.
    public static let features: [Feature] = [
        feature("color-mix()", #"color-mix\("#, 111, 111, 16.2, 113, [.components],
                note: "ThemeCSSEmitter writes it for a translucent shadow reference; no registered theme has one, so no themes file uses it today"),
        feature("@container size queries, container-type", #"container-type|@container"#, 105, 105, 16, 110, [.components]),
        feature(":focus-visible", #":focus-visible"#, 86, 86, 15.4, 85, [.components, .tumblr]),
        feature("@media (prefers-contrast)", #"prefers-contrast"#, 96, 96, 14.1, 101, [.themes, .components, .tumblr]),
        feature("@media (prefers-reduced-motion)", #"prefers-reduced-motion"#, 74, 79, 10.1, 63, [.components, .tumblr]),
        feature("@media (prefers-color-scheme)", #"prefers-color-scheme"#, 76, 79, 12.1, 67, [.themes, .tumblr]),
        feature("color-scheme property", #"color-scheme:"#, 81, 81, 13, 96, [.themes, .tumblr]),
        feature("clamp()", #"clamp\("#, 79, 79, 13.1, 75, [.themes, .tumblr]),
        feature("min() and max()", #"\b(min|max)\("#, 79, 79, 11.1, 75, [.components, .tumblr]),
        feature("Custom properties and var()", #"var\(--"#, 49, 15, 9.1, 31, [.themes, .components, .tumblr]),
        feature("calc()", #"calc\("#, 26, 12, 7, 16, [.components, .tumblr]),
        feature("Grid with minmax() and repeat(auto-fit)", #"auto-fit"#, 57, 16, 10.1, 76, [.components],
                note: "Firefox 76 is when repeat(auto-fit) takes more than one column in a repeated track"),
        feature("gap in flex layouts", #"(?<![-a-z])gap:"#, 84, 84, 14.1, 63, [.components, .tumblr]),
        feature("Logical sizes (inline-size, block-size, min-inline-size, min-block-size)", #"(?<![-a-z])(min-)?(inline|block)-size"#,
                57, 79, 12.1, 41, [.components]),
        feature("padding-inline, padding-block", #"padding-(inline|block)\s*:"#, 87, 87, 14.1, 66, [.components]),
        feature("border-inline-start, padding-inline-start and -end", #"border-inline-start|padding-inline-(start|end)"#, 69, 79, 12.1, 41, [.components]),
        feature("clip-path: inset()", #"clip-path"#, 55, 79, 10.1, 54, [.components]),
        feature("accent-color", #"accent-color"#, 93, 93, 15.4, 92, [.components],
                note: "Safari 15.4 to 26.1 implements it without keeping a minimum contrast for the control (MDN lists that as partial); full from 26.2"),
        feature("appearance", #"appearance:"#, 84, 84, 15.4, 80, [.components]),
        feature("overflow-wrap: anywhere", #"overflow-wrap:\s*anywhere"#, 80, 80, 15.4, 65, [.components]),
        feature("font-variant-numeric", #"font-variant-numeric"#, 52, 79, 9.1, 34, [.components, .tumblr]),
        feature("attr() in content", #"attr\(data-"#, 2, 12, 3.1, 1, [.components]),
        feature("#RRGGBBAA hexadecimal colours", #"#[0-9A-Fa-f]{8}\b"#, 62, 79, 10, 49, [.themes]),
        feature(":has()", #":has\("#, 105, 105, 15.4, 121, [.tumblr]),
        feature("aspect-ratio", #"aspect-ratio"#, 88, 88, 15, 89, [.tumblr]),
        feature("env() safe-area insets", #"env\("#, 69, 79, 11.1, 65, [.tumblr]),
    ]

    /// Features the emitted CSS must not use, because their floor is not in ``features`` and no one has decided to pay it. A test fails if
    /// one appears.
    public static let notUsed: [String] = [
        #"@layer"#, #"@scope"#, #"@supports"#, #"light-dark\("#, #"oklch\("#, #"oklab\("#, #":is\("#, #":where\("#, #"subgrid"#,
        #"\bdvh\b"#, #"\bsvh\b"#, #"text-wrap"#, #"field-sizing"#, #"@starting-style"#, #"anchor-name"#, #"@property"#,
    ]

    /// The version of each engine that supports every feature used in `scopes`: the browser floor.
    public static func floor(for scopes: Set<Scope>) -> Versions {
        features.filter { !$0.scopes.isDisjoint(with: scopes) }.map(\.versions)
            .reduce(Versions(chrome: 0, edge: 0, safari: 0, firefox: 0)) { $0.newest(with: $1) }
    }

    /// The floor of `tokens.css`, the theme files and `components.css` together: the CSS a page links.
    public static var pageFloor: Versions { floor(for: [.themes, .components]) }

    /// The size thresholds in the emitted CSS. Each is the value written into the CSS, so a test can hold the documentation to it.
    public enum Breakpoints {
        /// `components.css` stacks the table into labelled blocks, and collapses the grid helpers to one column, below this viewport
        /// width: `@media (max-width: 600px)`. It is `SwissMetrics.tableStackedBelow`'s 600 pt.
        public static let tableStackBelowPixels = 600
        /// A key and value row stacks (label above value) when its container is narrower than this, in `rem`:
        /// `@container (max-width: 30rem)`.
        public static let keyValueStackBelowRem = 30
        /// A card in an auto-fit grid (a theme whose ``ListStyle`` is `cards`) is at least this many base units wide: `--list-item-min`,
        /// 384 px at the 4 px base unit.
        public static let cardMinimumWidthInBaseUnits = 96
        /// The Tumblr block's own `max-width` media queries, in pixels, in the order they appear.
        public static let tumblrPixels = [960, 720]
    }

    /// `12`, `16.2`: a version as CSS documentation writes it.
    static func text(_ version: Double) -> String { CSSNumber.string(version) }

    /// The one-line floor: `Chrome 111, Edge 111, Safari 16.2, Firefox 113`.
    static func floorText(_ versions: Versions) -> String {
        "Chrome \(text(versions.chrome)), Edge \(text(versions.edge)), Safari \(text(versions.safari)), Firefox \(text(versions.firefox))"
    }

    /// A feature's row of the README table: `| name | Chrome / Edge | Safari | Firefox | where used |`, ending without a newline.
    ///
    /// The README holds these rows as written here, and a test fails if it does not, so the documentation cannot drift from the table.
    public static func markdownRow(_ feature: Feature) -> String {
        let v = feature.versions
        let places = Scope.allCases.filter { feature.scopes.contains($0) }.map(\.rawValue).joined(separator: ", ")
        let note = feature.note.isEmpty ? "" : " (\(feature.note))"
        return "| \(feature.name)\(note) | \(text(v.chrome)) / \(text(v.edge)) | \(text(v.safari)) | \(text(v.firefox)) | \(places) |"
    }
}
