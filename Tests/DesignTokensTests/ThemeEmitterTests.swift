import CryptoKit
import Foundation
import Testing
@testable import DesignTokens

@Suite("Theme emitters")
struct ThemeEmitterTests {
    private static let root = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()

    private static func sha256(_ text: String) -> String {
        SHA256.hash(data: Data(text.utf8)).map { ($0 < 16 ? "0" : "") + String($0, radix: 16) }.joined()
    }

    /// The text between an exact opening line and the closing line that follows it.
    private static func block(_ css: String, opening: String, closing: String = "\n}\n") -> String? {
        guard let start = css.range(of: opening) else { return nil }
        guard let end = css.range(of: closing, range: start.upperBound..<css.endIndex) else { return nil }
        return String(css[start.upperBound..<end.lowerBound])
    }

    // MARK: Swiss's default files are untouched

    @Test("tokens.css and tokens.json are byte-identical to the 0.5.0 files (SHA-256 of main at 275a75c)")
    func tokensStillEqualToday() throws {
        let css = try String(contentsOf: Self.root.appendingPathComponent("Generated/tokens.css"), encoding: .utf8)
        let json = try String(contentsOf: Self.root.appendingPathComponent("Generated/tokens.json"), encoding: .utf8)
        #expect(Self.sha256(css) == "7f64d385a7ec5b49cddcc2299dbc106d9eccbae36ecf5dea65eb5eb5921a0342")
        #expect(Self.sha256(json) == "9c770feb41aebaa1f167f8bccd20eab0f6e2156276c842ca777247871bb90056")
        #expect(css == CSSEmitter.emit())
        #expect(json == JSONEmitter.emit())
    }

    // MARK: Golden files

    @Test("every committed Generated file equals a fresh emit, and nothing else is in Generated")
    func generatedFilesMatchCommitted() throws {
        let generated = Self.root.appendingPathComponent("Generated")
        let files = try Generator.files()
        for file in files {
            let url = generated.appendingPathComponent(file.path)
            let committed = try String(contentsOf: url, encoding: .utf8)
            #expect(committed == file.contents, "\(file.path) differs from a fresh emit")
        }
        var onDisk: [String] = []
        let enumerator = try #require(FileManager.default.enumerator(atPath: generated.path))
        for case let path as String in enumerator {
            var isDirectory: ObjCBool = false
            FileManager.default.fileExists(atPath: generated.appendingPathComponent(path).path, isDirectory: &isDirectory)
            if !isDirectory.boolValue { onDisk.append(path) }
        }
        #expect(onDisk.sorted() == files.map(\.path).sorted())
    }

    @Test("the file set is the two default files, a CSS and a JSON file per registered theme, and Swiss's Tumblr block")
    func fileSet() throws {
        let paths = try Generator.files().map(\.path)
        var expected = ["tokens.css", "tokens.json"]
        for theme in Theme.all {
            expected += ["themes/\(theme.id).css", "themes/\(theme.id).json"]
            if theme.id == "swiss" { expected.append("themes/swiss.tumblr.css") }
        }
        #expect(paths == expected)
        #expect(paths.count == 2 + 2 * 9 + 1)
    }

    @Test("theme JSON is the canonical codec output and decodes back to the theme")
    func themeJSONIsCanonical() throws {
        for theme in Theme.all {
            let json = try ThemeJSONEmitter.emit(theme)
            #expect(Data(json.utf8) == (try ThemeCodec.encode(theme)), "\(theme.id)")
            #expect(try ThemeCodec.decode(Data(json.utf8)) == theme, "\(theme.id)")
        }
    }

    // MARK: Scoping

    @Test("every selector is scoped to its own theme: no :root, no other theme's name")
    func scopedSelectorsDoNotLeakAcrossThemes() throws {
        for theme in Theme.all {
            let css = try ThemeCSSEmitter.emit(theme)
            let scope = "[data-theme-name=\"\(theme.id)\"]"
            #expect(!css.contains(":root"), "\(theme.id)")
            let selectorLines = css.split(whereSeparator: \.isNewline).filter { line in
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                return trimmed.hasSuffix("{") && !trimmed.hasPrefix("@media")
            }
            #expect(selectorLines.count >= 1, "\(theme.id)")
            for line in selectorLines { #expect(line.contains(scope), "\(theme.id): \(line)") }
            for other in Theme.all where other.id != theme.id {
                #expect(!css.contains("[data-theme-name=\"\(other.id)\"]"), "\(theme.id) leaks \(other.id)")
            }
        }
    }

    @Test("an id that prefixes another does not match it: legacy-default is not legacy")
    func scopeIsAnExactAttributeMatch() throws {
        let css = try ThemeCSSEmitter.emit(Theme.legacyDefault)
        #expect(css.contains("[data-theme-name=\"legacy-default\"] {"))
        #expect(!css.contains("[data-theme-name^="))
        #expect(!css.contains("[data-theme-name*="))
    }

    // MARK: Light, dark, increased contrast (Swiss, values from the 0.3.0 measurements)

    @Test("Swiss: the light block, the dark blocks and both increased-contrast blocks carry the measured values")
    func swissAppearanceBlocks() throws {
        let css = try ThemeCSSEmitter.emit(Theme.swiss)
        let s = "[data-theme-name=\"swiss\"]"
        let notLight = ":not([data-theme=\"light\"]):not([data-bs-theme=\"light\"])"
        let light = try #require(Self.block(css, opening: "\(s) {\n"))
        #expect(light.contains("  color-scheme: light;"))
        #expect(light.contains("  --accent: #FF8D28;"))
        #expect(light.contains("  --accent-rgb: 255, 141, 40;"))
        #expect(light.contains("  --series-8: #00C0E8;"))
        let dark = try #require(Self.block(css, opening: "@media (prefers-color-scheme: dark) {\n  \(s)\(notLight) {\n", closing: "\n  }\n}\n"))
        #expect(dark.contains("--accent: #FF9230;"))
        #expect(dark.contains("--success: #30D158;") == false, "Swiss names the role positive, not success")
        #expect(dark.contains("--positive: #30D158;"))
        #expect(dark.contains("--negative: #FF4245;"))
        #expect(dark.contains("--series-8: #3CD3FE;"))
        #expect(dark.contains("color-scheme: dark;"))
        let explicitDark = try #require(Self.block(
            css, opening: "\(s)[data-theme=\"dark\"],\n\(s)[data-bs-theme=\"dark\"],\n[data-theme=\"dark\"] \(s),\n[data-bs-theme=\"dark\"] \(s) {\n"))
        #expect(explicitDark.contains("--accent: #FF9230;"))
        let hcLight = try #require(Self.block(css, opening: "@media (prefers-contrast: more) {\n  \(s) {\n", closing: "\n  }\n}\n"))
        #expect(hcLight.contains("--accent: #C55300;"))
        #expect(hcLight.contains("--series-8: #007EAE;"))
        #expect(!hcLight.contains("--ink:"), "ink carries alpha and has no measured increased-contrast value")
        #expect(!hcLight.contains("--link:"))
        let hcDark = try #require(Self.block(
            css, opening: "@media (prefers-contrast: more) and (prefers-color-scheme: dark) {\n  \(s)\(notLight) {\n", closing: "\n  }\n}\n"))
        #expect(hcDark.contains("--accent: #FFA056;"))
        #expect(hcDark.contains("--series-2: #A7AAFF;"))
        let hcExplicitDark = try #require(Self.block(
            css, opening: "@media (prefers-contrast: more) {\n  \(s)[data-theme=\"dark\"],\n  \(s)[data-bs-theme=\"dark\"],\n  [data-theme=\"dark\"] \(s),\n  [data-bs-theme=\"dark\"] \(s) {\n",
            closing: "\n  }\n}\n"))
        #expect(hcExplicitDark.contains("--accent: #FFA056;"))
    }

    @Test("the cascade order: light, contrast light, dark scheme, explicit dark, contrast dark scheme, contrast explicit dark")
    func cascadeOrder() throws {
        let css = try ThemeCSSEmitter.emit(Theme.swiss)
        let markers = [
            "[data-theme-name=\"swiss\"] {\n",
            "@media (prefers-contrast: more) {\n  [data-theme-name=\"swiss\"] {",
            "@media (prefers-color-scheme: dark) {",
            "[data-theme-name=\"swiss\"][data-theme=\"dark\"],\n[data-theme-name=\"swiss\"][data-bs-theme=\"dark\"],",
            "@media (prefers-contrast: more) and (prefers-color-scheme: dark) {",
            "@media (prefers-contrast: more) {\n  [data-theme-name=\"swiss\"][data-theme=\"dark\"],",
        ]
        let positions = try markers.map { try #require(css.range(of: $0), "missing \($0)").lowerBound }
        #expect(positions == positions.sorted())
        #expect(Set(positions).count == markers.count)
    }

    @Test("a dark block carries every role and series of a theme that declares both appearances")
    func darkBlockIsComplete() throws {
        for theme in Theme.all where theme.appearances == .both {
            let css = try ThemeCSSEmitter.emit(theme)
            let notLight = ":not([data-theme=\"light\"]):not([data-bs-theme=\"light\"])"
            let dark = try #require(Self.block(
                css, opening: "@media (prefers-color-scheme: dark) {\n  [data-theme-name=\"\(theme.id)\"]\(notLight) {\n",
                closing: "\n  }\n}\n"), "\(theme.id)")
            for role in ColorRole.allCases {
                let name = ThemeCSSEmitter.kebab(role.rawValue)
                let expected = theme.palette[role].value(in: .dark, increasedContrast: false).hex
                #expect(dark.contains("--\(name): \(expected);"), "\(theme.id) \(name)")
            }
            for (index, entry) in theme.palette.series.enumerated() {
                #expect(dark.contains("--series-\(index + 1): \(entry.color.value(in: .dark, increasedContrast: false).hex);"),
                        "\(theme.id) series \(index + 1)")
            }
        }
    }

    @Test("a light-only theme has no dark or increased-dark blocks and says color-scheme: light")
    func lightOnlyTheme() throws {
        let css = try ThemeCSSEmitter.emit(Theme.princeton)
        #expect(Theme.princeton.appearances == .lightOnly)
        #expect(!css.contains("prefers-color-scheme: dark"))
        #expect(!css.contains("[data-theme=\"dark\"]"))
        #expect(css.contains("  color-scheme: light;"))
        #expect(!css.contains("color-scheme: dark"))
    }

    @Test("a fixed-dark theme is dark in its base block and has no dark blocks")
    func fixedDarkTheme() throws {
        let css = try ThemeCSSEmitter.emit(Theme.legacyDark)
        #expect(Theme.legacyDark.appearances == .fixedDark)
        #expect(css.contains("  color-scheme: dark;"))
        #expect(!css.contains("color-scheme: light"))
        #expect(!css.contains("prefers-color-scheme: dark"))
    }

    @Test("a colour with alpha is written as #RRGGBBAA, and its -rgb triple has the channels only")
    func alphaColours() throws {
        let css = try ThemeCSSEmitter.emit(Theme.legacyDark)
        let shadow = try #require(Theme.legacyDark.palette.extras["shadow"]).light
        #expect(shadow.alpha < 1)
        #expect(shadow.hex.count == 9)
        #expect(css.contains("--extra-shadow: \(shadow.hex);"))
        #expect(css.contains("--extra-shadow-rgb: \(shadow.rgb.red), \(shadow.rgb.green), \(shadow.rgb.blue);"))
    }

    // MARK: Structure

    @Test("Swiss structure: rules, layout, marks and type are written from the theme's numbers")
    func swissStructure() throws {
        let css = try ThemeCSSEmitter.emit(Theme.swiss)
        let light = try #require(Self.block(css, opening: "[data-theme-name=\"swiss\"] {\n"))
        #expect(light.contains("  --rule-title: 3px;"))
        #expect(light.contains("  --rule-title-position: below-title;"))
        #expect(light.contains("  --rule-title-color: var(--ink);"))
        #expect(light.contains("  --rule-section: 3px;"))
        #expect(light.contains("  --rule-hairline: 1px;"))
        #expect(light.contains("  --rule-gridline: 1px;"))
        #expect(light.contains("  --rule-baseline: 1px;"))
        #expect(light.contains("  --rule-page: 8px;"))
        #expect(light.contains("  --rule-reference: 1px;"))
        #expect(light.contains("  --rule-reference-dash: 3 3;"))
        #expect(light.contains("  --rule-plot-border: 0px;"))
        #expect(light.contains("  --gutter: 16px;"))
        #expect(light.contains("  --columns: 12;"))
        #expect(light.contains("  --space-unit: 4px;"))
        #expect(light.contains("  --radius-container: 0px;"))
        #expect(light.contains("  --radius-control: 4px;"))
        #expect(light.contains("  --gridlines: horizontal-faint;"))
        #expect(light.contains("  --shadow: none;"))
        #expect(light.contains("  --mark-line-width: 2px;"))
        #expect(light.contains("  --mark-bar-fill: flat;"))
        #expect(light.contains("  --mark-bar-width-ratio: 0.6;"))
        #expect(light.contains("  --mark-area-opacity: 0.22;"))
        #expect(light.contains("  --chart-title-size: 17px;"))
        #expect(light.contains("  --chart-title-weight: 700;"))
        #expect(light.contains("  --type-label-transform: uppercase;"))
        #expect(light.contains("  --type-title-size: 34px;"), "the UI title, as in tokens.css")
        #expect(light.contains("  --type-display-size: clamp(64px, 13vw, 168px);"))
        #expect(light.contains("  --font-sans: \(FontStack.sans);"))
    }

    @Test("a named face is written with its fallback stack; a legacy theme writes its shadow and tag")
    func namedFontsShadowAndTag() throws {
        let economist = try ThemeCSSEmitter.emit(Theme.economist)
        #expect(economist.contains("  --chart-title-family: \"Econ Sans Cnd\", \(FontStack.sans);"))
        #expect(economist.contains("  --rule-title-position: above-title;"))
        #expect(economist.contains("  --mark-tag-width: 28px;"))
        #expect(economist.contains("  --mark-tag-height: 6px;"))
        #expect(economist.contains("  --mark-tag-color: var(--"))
        let legacy = try ThemeCSSEmitter.emit(Theme.legacyDefault)
        #expect(legacy.contains("  --shadow: 0px 2px 4px var(--extra-shadow);"))
        #expect(legacy.contains("  --radius-annotation: 8px;"))
        #expect(legacy.contains("  --gridlines: platform-automatic;"))
    }

    @Test("ramps are written step by step, with the dark ramp in the dark block where one exists")
    func ramps() throws {
        let css = try ThemeCSSEmitter.emit(Theme.swiss)
        for (index, step) in Palette.sequential.enumerated() {
            #expect(css.contains("  --sequential-\(index + 1): \(step.hex);"))
        }
        let notLight = ":not([data-theme=\"light\"]):not([data-bs-theme=\"light\"])"
        let dark = try #require(Self.block(
            css, opening: "@media (prefers-color-scheme: dark) {\n  [data-theme-name=\"swiss\"]\(notLight) {\n", closing: "\n  }\n}\n"))
        for (index, step) in Palette.sequentialDark.enumerated() {
            #expect(dark.contains("--sequential-\(index + 1): \(step.hex);"))
        }
        #expect(!dark.contains("--diverging-"), "Swiss has no dark diverging ramp and none is invented")
    }

    // MARK: Literals and header

    @Test("every colour literal in a theme's CSS is a value of that theme: nothing is typed in the emitter")
    func cssHasNoLiteralOutsideGenerated() throws {
        let pattern = try NSRegularExpression(pattern: "#[0-9A-Fa-f]{6}(?:[0-9A-Fa-f]{2})?\\b")
        for theme in Theme.all {
            let json = String(decoding: try ThemeCodec.encode(theme), as: UTF8.self)
            let allowed = Set(pattern.matches(in: json, range: NSRange(json.startIndex..., in: json)).compactMap {
                Range($0.range, in: json).map { String(json[$0]).uppercased() }
            })
            let css = try ThemeCSSEmitter.emit(theme)
            let found = pattern.matches(in: css, range: NSRange(css.startIndex..., in: css)).compactMap {
                Range($0.range, in: css).map { String(css[$0]).uppercased() }
            }
            #expect(found.count > 20, "\(theme.id)")
            for literal in found { #expect(allowed.contains(literal), "\(theme.id): \(literal) is not in the theme") }
        }
    }

    @Test("the header names the theme, the version, the snapshot and the content hash")
    func header() throws {
        for theme in Theme.all {
            let css = try ThemeCSSEmitter.emit(theme)
            let first = try #require(css.split(whereSeparator: \.isNewline).first)
            let hash = try ThemeCodec.fingerprint(of: theme)
            #expect(first == "/* Generated by design-tokens. Do not edit. Theme: \(theme.id) (\(theme.name)) | DesignTokens \(DesignTokens.version) | System colours: snapshot of \(Snapshot.systemRelease) | hash fnv1a64:\(hash) */")
        }
    }

    @Test("a changed theme changes the CSS, so the golden test can fail for the reason it is named for")
    func emitterReadsTheTheme() throws {
        var changed = Theme.swiss
        changed.palette.accent.light = ColorValue(RGB(red: 1, green: 2, blue: 3))
        let css = try ThemeCSSEmitter.emit(changed)
        #expect(css.contains("--accent: #010203;"))
        #expect(css != (try ThemeCSSEmitter.emit(Theme.swiss)))
    }

    // MARK: Generator

    @Test("the generator writes every file into a directory, creating themes/")
    func generatorWrites() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("design-tokens-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: directory) }
        let written = try Generator.run(arguments: [directory.path])
        #expect(written == (try Generator.files()).map(\.path))
        for file in try Generator.files() {
            let text = try String(contentsOf: directory.appendingPathComponent(file.path), encoding: .utf8)
            #expect(text == file.contents)
        }
    }

    @Test("emit --theme writes one theme's pair, plus nothing else; emit --all is the default")
    func generatorSelections() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("design-tokens-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: directory) }
        let one = try Generator.run(arguments: ["emit", "--theme", "ft", directory.path])
        #expect(one == ["themes/ft.css", "themes/ft.json"])
        #expect(try Generator.run(arguments: ["emit", "--all", directory.path]) == (try Generator.files()).map(\.path))
    }

    @Test("an unknown theme, an unknown flag and a missing value are refused, not ignored")
    func generatorRefusals() throws {
        #expect(throws: GeneratorError.unknownTheme("nord")) { try Generator.run(arguments: ["emit", "--theme", "nord", "x"]) }
        #expect(throws: GeneratorError.unknownArgument("--wat")) { try Generator.run(arguments: ["emit", "--wat"]) }
        #expect(throws: GeneratorError.missingValue("--theme")) { try Generator.run(arguments: ["emit", "--theme"]) }
    }

    @Test("list names every registered theme, one per line")
    func generatorList() throws {
        #expect(try Generator.run(arguments: ["list"]) == Theme.all.map(\.id))
    }
}
