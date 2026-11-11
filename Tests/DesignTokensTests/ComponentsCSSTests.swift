import Foundation
import Testing
@testable import DesignTokens

@Suite("components.css (0.12.0)")
struct ComponentsCSSTests {
    private static let root = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()

    private static var css: String { ComponentsCSSEmitter.emit() }

    private static func matches(_ pattern: String, in text: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let range = NSRange(text.startIndex..., in: text)
        return regex.matches(in: text, range: range).compactMap { Range($0.range, in: text).map { String(text[$0]) } }
    }

    /// The custom properties a stylesheet declares: `--name:` at the start of a declaration.
    private static func declared(in text: String) -> Set<String> {
        Set(matches(#"(?m)^\s*(--[a-z0-9-]+)\s*:"#, in: text).map { $0.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ":", with: "") })
    }

    /// The custom properties a stylesheet reads: `var(--name`.
    private static func read(in text: String) -> Set<String> {
        Set(matches(#"var\(--[a-z0-9-]+"#, in: text).map { String($0.dropFirst(4)) })
    }

    // MARK: Files

    @Test("the committed Generated/components.css equals a fresh emit, and the emit is deterministic")
    func committedEqualsFresh() throws {
        let committed = try String(contentsOf: Self.root.appendingPathComponent("Generated/components.css"), encoding: .utf8)
        #expect(committed == Self.css)
        #expect(Self.css == ComponentsCSSEmitter.emit())
        #expect(Self.css.hasSuffix("\n"))
    }

    @Test("the generator plans components.css after the two default files, and --components writes only it")
    func generatorPlansIt() throws {
        let paths = try Generator.files().map(\.path)
        #expect(Array(paths.prefix(3)) == ["tokens.css", "tokens.json", "components.css"])
        #expect(try Generator.files(formats: [.components]).map(\.path) == ["components.css"])
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("components-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: directory) }
        let written = try Generator.run(arguments: ["emit", "--components", directory.path])
        #expect(written == ["components.css"])
        #expect(try String(contentsOf: directory.appendingPathComponent("components.css"), encoding: .utf8) == Self.css)
    }

    // MARK: Only tokens

    @Test("no hex colour, rgb(), hsl(), font name, theme name or px radius is written in the file")
    func noLiterals() {
        let css = Self.css
        #expect(Self.matches(#"#[0-9a-fA-F]{3,8}\b"#, in: css) == [])
        #expect(Self.matches(#"\b(rgb|rgba|hsl|hsla)\("#, in: css) == [])
        for name in ["SF Mono", "Menlo", "Consolas", "Helvetica", "Arial", "-apple-system", "sans-serif", "monospace", "serif"] {
            #expect(!css.contains(name), "\(name)")
        }
        for name in ["swiss", "console", "fleetwatch", "Swiss", "Console", "FleetWatch", "data-theme-name"] {
            #expect(!css.contains(name), "\(name)")
        }
        #expect(Self.matches(#"radius\s*:[^;]*\d+(\.\d+)?px"#, in: css) == [])
        for declaration in Self.matches(#"(border-radius|border-[a-z-]*-radius)\s*:[^;]*;"#, in: css) {
            #expect(declaration.contains("var(--radius-") || declaration.contains("inherit") || declaration.contains(": 0;"), "\(declaration)")
        }
        for declaration in Self.matches(#"font-family\s*:[^;]*;"#, in: css) {
            #expect(declaration.contains("var(--type-") || declaration.contains("inherit"), "\(declaration)")
        }
    }

    @Test("every class is prefixed dt-")
    func prefix() {
        var classes: [String] = []
        for line in Self.css.split(whereSeparator: \.isNewline) where line.hasSuffix("{") || line.hasSuffix(",") {
            guard !line.contains("@") else { continue }
            classes += Self.matches(#"\.[A-Za-z_-][A-Za-z0-9_-]*"#, in: String(line))
        }
        #expect(classes.count > 40)
        #expect(classes.filter { !$0.hasPrefix(".dt-") } == [])
    }

    @Test("every custom property components.css reads is declared by the Swiss theme and by Console")
    func everyReadPropertyIsDeclared() throws {
        let read = Self.read(in: Self.css)
        #expect(read.count > 30, "the stylesheet reads the theme's properties")
        for id in ["swiss", "console"] {
            let theme = try #require(Theme.named(id))
            let declared = Self.declared(in: try ThemeCSSEmitter.emit(theme))
            #expect(read.subtracting(declared) == [], "\(id) is missing \(read.subtracting(declared).sorted())")
        }
        // and nothing the file declares itself is read as a theme property
        #expect(Self.declared(in: Self.css).intersection(read) == [])
    }

    // MARK: The key requirement

    @Test("one markup, two looks: list and item read the list tokens, so rows and cards come from the theme alone")
    func listIsDrivenByTokens() {
        let css = Self.css
        for token in ["--list-item-min", "--list-gap", "--list-item-surface", "--list-item-rule", "--card-border", "--card-padding",
                      "--card-top-rule", "--radius-container"] {
            #expect(css.contains("var(\(token)"), "\(token)")
        }
        #expect(css.contains("auto-fit"))
    }

    // MARK: Components

    @Test("each component of the SwiftUI set has a class")
    func components() {
        let css = Self.css
        for name in [".dt-page", ".dt-section", ".dt-rule", ".dt-kv", ".dt-kv__row", ".dt-table", ".dt-chip", ".dt-banner",
                     ".dt-segmented", ".dt-button", ".dt-input", ".dt-select", ".dt-field", ".dt-card", ".dt-list", ".dt-item",
                     ".dt-grid", ".dt-col-12", ".dt-label", ".dt-heading", ".dt-title"] {
            #expect(css.contains(name), "\(name)")
        }
        for tone in ["success", "caution", "warning", "destructive", "neutral"] {
            #expect(css.contains(".dt-chip--\(tone)"), Comment(rawValue: tone))
            #expect(css.contains(".dt-banner--\(tone)"), Comment(rawValue: tone))
        }
    }

    @Test("a chip says its state with a glyph as well as a colour, and a different glyph per tone")
    func chipGlyphs() {
        let glyphs = Self.matches(#"\.dt-chip--[a-z]+::before\s*\{[^}]*content:\s*"[^"]+""#, in: Self.css)
        #expect(glyphs.count == 5)
        let contents = glyphs.compactMap { Self.matches(#"content:\s*"[^"]+""#, in: $0).first }
        #expect(Set(contents).count == 5, "five tones, five shapes")
    }

    @Test("the table stacks to labelled blocks below 600 px, using each cell's data-label")
    func tableStacks() {
        let css = Self.css
        #expect(css.contains("@media (max-width: 600px)"))
        #expect(css.contains("attr(data-label)"))
        #expect(css.contains("[aria-selected=\"true\"]"))
        #expect(css.contains("[aria-sort="))
    }

    @Test("it supports increased contrast, keyboard focus and reduced motion")
    func accessibility() {
        let css = Self.css
        #expect(css.contains("@media (prefers-contrast: more)"))
        #expect(css.contains(":focus-visible"))
        #expect(css.contains("@media (prefers-reduced-motion: reduce)"))
        #expect(Self.matches(#"transition\s*:"#, in: css).count >= 1)
        // a transition only inside the no-preference query, or switched off by the reduce one
        #expect(css.contains("@media (prefers-reduced-motion: no-preference)"))
    }

    @Test("the header names the package version and says it is generated")
    func header() {
        #expect(Self.css.hasPrefix("/* Generated by design-tokens. Do not edit. Web components | DesignTokens \(DesignTokens.version)"))
    }
}
