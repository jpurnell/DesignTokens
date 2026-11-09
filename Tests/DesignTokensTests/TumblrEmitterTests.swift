import Foundation
import Testing
@testable import DesignTokens

@Suite("Tumblr block emitter")
struct TumblrEmitterTests {
    private let begin = "/* >>> design-tokens block begin */"
    private let end = "/* >>> design-tokens block end */"
    private let templateMarker = "/* >>> Tumblr template: selectors only, no literals */"

    private func block(_ theme: Theme = .swiss) throws -> String { try TumblrEmitter.emit(theme) }

    /// The generated data: everything before the template marker.
    private func data(_ theme: Theme = .swiss) throws -> String {
        let text = try block(theme)
        let parts = text.components(separatedBy: templateMarker)
        try #require(parts.count == 2, "the template marker must appear exactly once")
        return parts[0]
    }

    private func template(_ theme: Theme = .swiss) throws -> String {
        let parts = try block(theme).components(separatedBy: templateMarker)
        try #require(parts.count == 2)
        return parts[1]
    }

    @Test("the block is delimited by the sentinel comments and ends in one newline")
    func sentinels() throws {
        let text = try block()
        #expect(text.hasPrefix(begin + "\n"))
        #expect(text.hasSuffix(end + "\n"))
        #expect(text.components(separatedBy: begin).count == 2)
        #expect(text.components(separatedBy: end).count == 2)
    }

    @Test("stampIsInHeaderCommentAndCustomProperty")
    func stampPlacement() throws {
        let stamp = try TumblrEmitter.stamp(for: .swiss)
        let text = try block()
        #expect(text.contains("--theme-stamp: \"\(stamp.text)\";"))
        let header = lines(text).dropFirst().first ?? ""
        #expect(header.hasPrefix("/* theme: swiss | DesignTokens \(TumblrEmitter.packageVersion) | template \(TumblrEmitter.templateRevision) | hash \(stamp.hash)"))
        #expect(header.hasSuffix("| generated, do not edit */"))
    }

    @Test("stampIsStable: the same theme gives the same bytes and the same stamp, and the hash is the theme's fingerprint")
    func stampStable() throws {
        #expect(try block() == block())
        let stamp = try TumblrEmitter.stamp(for: .swiss)
        #expect(stamp == (try TumblrEmitter.stamp(for: .swiss)))
        #expect(stamp.hash == "fnv1a64:" + (try ThemeCodec.fingerprint(of: .swiss)))
        #expect(stamp.id == "swiss")
        #expect(stamp.version == TumblrEmitter.packageVersion)
        #expect(stamp.version == DesignTokens.version, "one source of truth for the version")
        #expect(stamp.template == TumblrEmitter.templateRevision)
    }

    @Test("the stamp changes when the theme changes, and the block changes with it")
    func stampTracksTheme() throws {
        var changed = Theme.swiss
        changed.palette.accent.light = ColorValue(hex: "#123456") ?? changed.palette.accent.light
        let a = try TumblrEmitter.stamp(for: .swiss)
        let b = try TumblrEmitter.stamp(for: changed)
        #expect(a.hash != b.hash)
        #expect(try block(changed).contains("#123456"))
        #expect(try block() != block(changed))
    }

    @Test("stampParsesAndRoundTrips")
    func stampRoundTrip() throws {
        let stamp = try TumblrEmitter.stamp(for: .swiss)
        #expect(BlogStamp.parse(stamp.text) == stamp)
        #expect(BlogStamp(id: "ft", version: "1.2.3", template: 12, hash: "fnv1a64:0123456789abcdef").text
                == "ft 1.2.3 t12 fnv1a64:0123456789abcdef")
        #expect(BlogStamp.parse("  \(stamp.text) \n") == stamp)
    }

    @Test("a malformed stamp does not parse", arguments: [
        "", "swiss", "swiss 0.6.0", "swiss 0.6.0 t1", "swiss 0.6.0 t1 fnv1a64:xyz",
        "swiss 0.6.0 t1 fnv1a64:0123456789abcde", "swiss 0.5 t1 fnv1a64:0123456789abcdef",
        "swiss 0.6.0 1 fnv1a64:0123456789abcdef", "swiss 0.6.0 t1 sha:0123456789abcdef",
        "swiss 0.6.0 t1 fnv1a64:0123456789abcdef extra", "swiss 0.6.0 tx fnv1a64:0123456789abcdef",
    ])
    func malformedStamp(_ text: String) {
        #expect(BlogStamp.parse(text) == nil)
    }

    @Test("tumblrBlockMatchesCommitted: Generated/themes/swiss.tumblr.css is a fresh emit")
    func matchesCommitted() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        let committed = try String(contentsOf: root.appendingPathComponent("Generated/themes/swiss.tumblr.css"), encoding: .utf8)
        #expect(committed == (try block()))
    }

    @Test("tumblrBlockContainsNoTumblrTags: no {block:...} and no {Tag}, which Tumblr would substitute")
    func noTumblrTags() throws {
        for theme in [Theme.swiss, .ft, .princeton] {
            let text = try block(theme)
            #expect(!text.contains("{block:"))
            #expect(!text.contains("{/block:"))
            #expect(text.range(of: #"\{[A-Za-z][A-Za-z0-9:/_-]*\}"#, options: .regularExpression) == nil)
        }
    }

    @Test("the block is CSS only: no markup that could close the style element or alter the theme's hand-owned parts")
    func cssOnly() throws {
        let text = try block()
        for forbidden in ["<", ">/", "<script", "<link", "<style", "</style", "<!--", "-->"] {
            #expect(!text.contains(forbidden), "block contains \(forbidden)")
        }
    }

    @Test("tumblrBlockHasNoLiterals: the template has no colour literal, and the data has hex only as variable values")
    func noLiterals() throws {
        let tpl = try template()
        #expect(tpl.range(of: #"#[0-9A-Fa-f]{3,8}\b"#, options: .regularExpression) == nil)
        for fn in ["rgb(", "rgba(", "hsl(", "hsla(", "color-mix(", "oklch("] { #expect(!tpl.contains(fn)) }
        for name in ["red", "white", "black", "orange", "gray", "grey", "blue"] {
            #expect(tpl.range(of: "[:\\s]\(name)[;\\s]", options: .regularExpression) == nil, "named colour \(name)")
        }
        let literalLine = lines(try data()).filter {
            $0.range(of: #"#[0-9A-Fa-f]{3,8}\b"#, options: .regularExpression) != nil
        }
        #expect(!literalLine.isEmpty)
        for line in literalLine {
            // every line carrying a colour is a run of `--name: #HEX;` declarations (or the media wrapper around them)
            let stripped = line.replacingOccurrences(of: #"--[a-z0-9-]+: #[0-9A-Fa-f]{6,8};"#, with: "", options: .regularExpression)
            #expect(stripped.range(of: #"#[0-9A-Fa-f]{3,8}\b"#, options: .regularExpression) == nil, "stray literal in: \(line)")
        }
    }

    @Test("every var() the template uses is declared in the generated data")
    func everyVariableIsDeclared() throws {
        // --ar is set per video frame by the draft's script and always read with a fallback, so it is not declared here.
        let used = Set(matches(in: try template(), pattern: #"var\((--[a-z0-9-]+)"#)).subtracting(["--ar"])
        let declared = Set(matches(in: try data(), pattern: #"(--[a-z0-9-]+):"#))
        #expect(!used.isEmpty)
        #expect(used.subtracting(declared).isEmpty, "undeclared: \(used.subtracting(declared).sorted())")
    }

    @Test("tumblrBlockCoversEveryRoleTheDraftUses: the draft's colour and face variables are all declared")
    func coversDraftVariables() throws {
        let declared = Set(matches(in: try data(), pattern: #"(--[a-z0-9-]+):"#))
        for name in ["--bg", "--fg", "--muted", "--hair", "--accent", "--link", "--face", "--mono"] {
            #expect(declared.contains(name), "\(name) missing")
        }
    }

    private static let draftPath = NSHomeDirectory() + "/Desktop/tumblr-swiss.html"
    @Test("the draft's :root variable names are all declared (needs ~/Desktop/tumblr-swiss.html; skipped otherwise)",
          .enabled(if: FileManager.default.fileExists(atPath: draftPath),
                   Comment(rawValue: "~/Desktop/tumblr-swiss.html is absent, so the draft cross-check is skipped")))
    func coversDraftFile() throws {
        let draft = try String(contentsOfFile: Self.draftPath, encoding: .utf8)
        let usedInDraft = Set(matches(in: draft, pattern: #"var\((--[a-z0-9-]+)"#))
        #expect(!usedInDraft.isEmpty)
        let declared = Set(matches(in: try data(), pattern: #"(--[a-z0-9-]+):"#))
        #expect(usedInDraft.subtracting(declared).subtracting(["--ar"]).isEmpty,
                "draft uses undeclared \(usedInDraft.subtracting(declared).sorted()) (--ar is set per element by the draft's script)")
    }

    @Test("the template's selectors are the contract with the theme HTML (proposal Appendix B)")
    func selectorContract() throws {
        let tpl = try template()
        for selector in [".header", ".nav", ".post.newday", ".datetime", ".day", ".my", ".type", ".row", ".k",
                         ".caption", ".video", ".short_quote", ".medium_quote", ".long_quote",
                         "div.npf-link-block", ".tumblr_video_container", ".tumblr_video_container iframe"] {
            #expect(tpl.contains(selector), "selector \(selector) missing")
        }
        #expect(tpl.contains("aspect-ratio: var(--ar, 16 / 9) !important"))
    }

    @Test("the block's header names the class-name contract")
    func headerNamesContract() throws {
        let text = try block()
        #expect(text.contains("contract: the theme HTML must keep these class names"))
    }

    @Test("light values are on :root and the dark values come from the theme's dark Adaptive values")
    func lightAndDark() throws {
        let text = try data()
        let rootBlock = try #require(text.components(separatedBy: "\n:root {\n").dropFirst().first?.components(separatedBy: "\n}\n").first)
        let p = Theme.swiss.palette
        #expect(rootBlock.contains("--bg: \(p.background.light.hex);"))
        #expect(rootBlock.contains("--fg: \(p.ink.light.hex);"))
        #expect(rootBlock.contains("--accent: \(p.accent.light.hex);"))
        #expect(rootBlock.contains("--muted: \(p.secondaryInk.light.hex);"))
        #expect(rootBlock.contains("--hair: \(p.rule.light.hex);"))
        let dark = try #require(text.components(separatedBy: "@media (prefers-color-scheme: dark) {\n  :root {\n").dropFirst().first?.components(separatedBy: "\n  }\n}").first)
        #expect(dark.contains("--bg: \(try #require(p.background.dark).hex);"))
        #expect(dark.contains("--fg: \(try #require(p.ink.dark).hex);"))
        #expect(dark.contains("--accent: \(try #require(p.accent.dark).hex);"))
    }

    @Test("prefers-contrast: more has its own light block and dark block from the increased-contrast values")
    func increasedContrast() throws {
        let text = try data()
        let p = Theme.swiss.palette
        let lightMore = try #require(text.components(separatedBy: "@media (prefers-contrast: more) {\n  :root {\n").dropFirst().first?.components(separatedBy: "\n  }\n}").first)
        #expect(lightMore.contains("--accent: \(try #require(p.accent.lightIncreased).hex);"))
        let darkMore = try #require(text.components(separatedBy: "@media (prefers-contrast: more) and (prefers-color-scheme: dark) {\n  :root {\n").dropFirst().first?.components(separatedBy: "\n  }\n}").first)
        #expect(darkMore.contains("--accent: \(try #require(p.accent.darkIncreased).hex);"))
    }

    @Test("cascade order: light, light contrast, dark, dark contrast, so the dark scheme beats light contrast and dark contrast beats dark")
    func cascadeOrder() throws {
        let text = try data()
        let light = try #require(text.range(of: "\n:root {\n"))
        let lightMore = try #require(text.range(of: "@media (prefers-contrast: more) {"))
        let dark = try #require(text.range(of: "@media (prefers-color-scheme: dark) {"))
        let darkMore = try #require(text.range(of: "@media (prefers-contrast: more) and (prefers-color-scheme: dark) {"))
        #expect(light.lowerBound < lightMore.lowerBound)
        #expect(lightMore.lowerBound < dark.lowerBound)
        #expect(dark.lowerBound < darkMore.lowerBound)
    }

    @Test("a light-only theme has no dark block and declares color-scheme: light")
    func lightOnlyTheme() throws {
        let princeton = Theme.princeton
        try #require(princeton.appearances == .lightOnly)
        let text = try data(princeton)
        #expect(!text.contains("prefers-color-scheme: dark"))
        #expect(text.contains("color-scheme: light;"))
        #expect(!text.contains("color-scheme: light dark"))
        #expect(try data().contains("color-scheme: light dark;"))
    }

    @Test("structure comes from the theme: rule weights, grid, type and fonts, and another theme changes them")
    func structureFromTheme() throws {
        let swiss = try data()
        let s = Theme.swiss.structure
        #expect(swiss.contains("--rule-page: \(CSSNumber.string(s.rules.page))px;"))
        #expect(swiss.contains("--rule-section: \(CSSNumber.string(s.rules.section))px;"))
        #expect(swiss.contains("--rule-hairline: \(CSSNumber.string(s.rules.hairline))px;"))
        #expect(swiss.contains("--gutter: \(CSSNumber.string(s.layout.gutter))px;"))
        #expect(swiss.contains("--columns: \(s.layout.columns);"))
        #expect(swiss.contains("--label-size: \(CSSNumber.string(s.type.label.size))px;"))
        #expect(swiss.contains("--label-weight: \(s.type.label.weight);"))
        #expect(swiss.contains("--face: \(FontStack.sans);"))
        #expect(swiss.contains("--mono: \(FontStack.mono);"))
        #expect(swiss.contains("--display-size: clamp("))
        // a theme with another face gets it, and the swiss stack is gone
        let ft = try data(.ft)
        #expect(!ft.contains("--face: \(FontStack.sans);") || Theme.ft.structure.type.body.family == .sans)
        #expect(ft.contains("--accent: \(Theme.ft.palette.accent.light.hex);"))
        #expect(ft != swiss)
    }

    @Test("a named font is emitted with its fallback stack")
    func namedFont() throws {
        var theme = Theme.swiss
        theme.structure.type.body.family = .named("Econ Sans Cnd", fallback: .sans)
        #expect(try data(theme).contains("--face: \"Econ Sans Cnd\", \(FontStack.sans);"))
    }

    @Test("the template reads every appearance-dependent value through a variable, so the three variants need no template copy")
    func templateUsesVariables() throws {
        let tpl = try template()
        #expect(tpl.contains("border-top: var(--rule-page) solid var(--fg)"))
        #expect(tpl.contains("var(--accent)"))
        #expect(tpl.contains("repeat(var(--columns), minmax(0, 1fr))"))
        #expect(tpl.contains("column-gap: var(--gutter)"))
    }

    private func lines(_ text: String) -> [String] {
        text.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline).map(String.init)
    }

    private func matches(in text: String, pattern: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let ns = text as NSString
        return regex.matches(in: text, range: NSRange(location: 0, length: ns.length)).compactMap {
            $0.numberOfRanges > 1 ? ns.substring(with: $0.range(at: 1)) : nil
        }
    }
}
