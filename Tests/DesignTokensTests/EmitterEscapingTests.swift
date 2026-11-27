import Foundation
#if canImport(FoundationXML)
import FoundationXML
#endif
import Testing
@testable import DesignTokens

// A theme can be supplied at runtime (DesignTokensWeb takes custom JSON), so its `id` and `name` are not trusted. The
// emitters write the id into a selector, a stamp and comments, and the name into comments and an XML attribute.
//
// The oracle is structural, not a string match on whatever escape was chosen: the stylesheet of a theme with a hostile
// name must have exactly the shape of the stylesheet of the same theme with a harmless name (same rules, same
// declarations, same number of comments), and a text output must have the same lines. If a name could close a comment,
// start a rule or begin a new line, the shape would differ.

/// What a CSS text is made of, with comment text and string contents left out of the comparison.
private indirect enum Piece: Equatable {
    case comment
    case statement(String)
    case block(prelude: String, body: [Piece])
}

/// The structure of `css`, or `nil` if a comment or string is unterminated or the braces do not balance.
private func shape(_ css: String) -> [Piece]? {
    let scalars = Array(css.unicodeScalars)
    var stack: [[Piece]] = [[]]
    var preludes: [String] = []
    var text = ""
    var index = 0
    func flush() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { stack[stack.count - 1].append(.statement(trimmed)) }
        text = ""
    }
    while index < scalars.count {
        let c = scalars[index]
        if c == "/", index + 1 < scalars.count, scalars[index + 1] == "*" {
            var end = index + 2
            var closed = false
            while end + 1 < scalars.count {
                if scalars[end] == "*", scalars[end + 1] == "/" { closed = true; break }
                end += 1
            }
            guard closed else { return nil }
            flush()
            stack[stack.count - 1].append(.comment)
            index = end + 2
            continue
        }
        if c == "\"" || c == "'" {
            var end = index + 1
            var closed = false
            while end < scalars.count {
                if scalars[end] == "\\" { end += 2; continue }
                if scalars[end] == c { closed = true; break }
                if scalars[end] == "\n" { return nil }
                end += 1
            }
            guard closed else { return nil }
            text += "\(c)\(c)"
            index = end + 1
            continue
        }
        switch c {
        case "{":
            preludes.append(text.trimmingCharacters(in: .whitespacesAndNewlines))
            text = ""
            stack.append([])
        case "}":
            flush()
            guard stack.count > 1, let prelude = preludes.popLast() else { return nil }
            let body = stack.removeLast()
            stack[stack.count - 1].append(.block(prelude: prelude, body: body))
        case ";":
            flush()
        default:
            text.unicodeScalars.append(c)
        }
        index += 1
    }
    flush()
    return stack.count == 1 ? stack[0] : nil
}

/// The lines of `text`, splitting on any line break (a `\r\n` is one), keeping empty lines.
private func lines(_ text: String) -> [String] {
    text.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline).map(String.init)
}

/// How many times `needle` occurs in `text`, not overlapping.
private func occurrences(of needle: String, in text: String) -> Int { text.ranges(of: needle).count }

private func with(name: String, of theme: Theme = .platinum) -> Theme {
    var copy = theme
    copy.name = name
    return copy
}

private func with(id: String, of theme: Theme = .platinum) -> Theme {
    var copy = theme
    copy.id = id
    return copy
}

/// Names that try to leave the comment, the line or the attribute they are written into.
private let hostileNames: [String] = [
    "Plain", "", "*/", "/*", "a */ b { color: red } /* c", "*/ body { display: none } /*", "**//**/", "x\nbody { display: none }",
    "x\r\ny", "x\u{85}y", "x\u{2028}y", "x\u{2029}y", "}", "{", ";", "\"", "'", "\\", "<", ">", "&", "&amp;",
    "</style><script>alert(1)</script>", "--", "---", "-->", "--!>", "<!--", "\u{0}", "\u{7}", "\u{1B}[31m", "tab\there",
    "\u{202E}reversed", "\u{2066}isolate\u{2069}", "日本語 é ✓ 🙂", String(repeating: "a", count: 5000), "# comment\n[Settings]",
]

/// Strings that are not a slug: they carry a character that means something in a selector, a stamp, a path or a comment.
private let invalidIDs: [String] = [
    "", "A", "Swiss", "a b", "a\tb", "a\"b", "a'b", "a]b", "a[b", "a\\b", "a/b", "../x", "..", "a.b", "a\nb", "a\r\nb", "é", "日本",
    "a--b", "-a", "+a", "_a", "a;b", "a}b", "a{b", "</style>", "a\u{0}b", "a*/b", "a/*b", "a|b", "a,b", "a:b", "a=b", "a#b",
    String(repeating: "a", count: 65),
]

private let validIDs: [String] = [
    "a", "swiss", "legacy-default", "swiss+princeton", "a_b", "x1-y2+z3", "0", "9lives", String(repeating: "a", count: 64),
]

/// Counts the elements of an XML text and records whether it parsed.
private final class ElementCounter: NSObject, XMLParserDelegate {
    var count = 0
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?,
                qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
        count += 1
    }
}

private func elementCount(_ xml: String) -> Int? {
    let parser = XMLParser(data: Data(xml.utf8))
    let counter = ElementCounter()
    parser.delegate = counter
    return parser.parse() ? counter.count : nil
}

/// The structure of `css` with every declaration reduced to "there is one here": what a property or value says is allowed to
/// differ between a harmless and a hostile key, how many rules and declarations there are is not.
private func outline(_ css: String) -> [Piece]? {
    func reduce(_ pieces: [Piece]) -> [Piece] {
        pieces.map { piece in
            switch piece {
            case .comment: .comment
            case .statement: .statement("declaration")
            case .block(let prelude, let body): .block(prelude: prelude, body: reduce(body))
            }
        }
    }
    return shape(css).map(reduce)
}

/// Text that is a font name or a palette key in a hostile theme: it tries to close the string, the declaration, the rule or
/// the line it is written into.
private let hostileStrings: [String] = hostileNames + [
    "Foo\", sans-serif; } body { display: none } /*", "a\"b", "a')b", "x) ; } .evil { background: url(https://example.test/x) } /*",
    "a\\\"b", "a\\", "{Title}", "{block:Posts}", "9starts-with-digit", "has space", "UPPER", "a;b", "--double", "a.b", "e\u{301}",
]

private let colour = Adaptive(light: ColorValue(RGB(rgb: 0x123456)))

private func textSpec(family: FontFamilyRef) -> TextSpec {
    TextSpec(family: family, size: 12, weight: 400, tracking: 0, italic: false, uppercase: false, lineHeight: 1.4)
}

/// Any control character other than a line feed: nothing a text output should carry (an escape would reach a terminal).
private func hasStrayControl(_ text: String) -> Bool {
    text.unicodeScalars.contains { $0 != "\n" && $0.properties.generalCategory == .control }
}

@Suite("Theme strings that reach a CSS string, a CSS identifier or a text line")
struct EmitterStringSinkTests {
    // MARK: Named fonts: a CSS string

    @Test("a hostile font name stays inside its string in the stylesheet")
    func cssFontNameStaysInItsString() throws {
        func css(_ name: String) throws -> String {
            var theme = Theme.platinum
            theme.structure.type.body.family = .named(name, fallback: .sans)
            theme.structure.monospace = textSpec(family: .named(name, fallback: .mono))
            return try ThemeCSSEmitter.emit(theme)
        }
        let baseline = try #require(outline(try css("Plain Face")))
        for name in hostileStrings {
            let out = try css(name)
            #expect(outline(out) == baseline, "\(name.debugDescription.prefix(40)) changed the structure of the stylesheet")
        }
    }

    @Test("a hostile font name stays inside its string in the Tumblr block, with no brace or closing tag")
    func tumblrFontNameStaysInItsString() throws {
        func block(_ name: String) throws -> String {
            var theme = Theme.platinum
            theme.structure.type.body.family = .named(name, fallback: .sans)
            return try TumblrEmitter.emit(theme)
        }
        let baseline = try block("Plain Face")
        let baselineShape = try #require(outline(baseline))
        for name in hostileStrings {
            let out = try block(name)
            #expect(outline(out) == baselineShape, "\(name.debugDescription.prefix(40)) changed the structure of the block")
            for needle in ["{", "}", "</"] {
                #expect(occurrences(of: needle, in: out) == occurrences(of: needle, in: baseline),
                        "\(name.debugDescription.prefix(40)) added \(needle.debugDescription)")
            }
        }
    }

    // MARK: Palette keys and colour references: a CSS identifier

    @Test("a hostile extras key becomes one custom property, not a new rule or declaration")
    func cssExtrasKeyCannotLeaveItsName() throws {
        func css(_ key: String) throws -> String {
            var theme = Theme.platinum
            theme.palette.extras[key] = colour
            return try ThemeCSSEmitter.emit(theme)
        }
        let baseline = try #require(outline(try css("plainKey")))
        for key in hostileStrings where !key.isEmpty {
            #expect(outline(try css(key)) == baseline, "\(key.debugDescription.prefix(40)) changed the structure of the stylesheet")
        }
    }

    @Test("a hostile extra-ramp name becomes one custom property family, not a new rule")
    func cssRampNameCannotLeaveItsName() throws {
        func css(_ name: String) throws -> String {
            var theme = Theme.platinum
            theme.palette.extraRamps[name] = Ramp(packedLight: [0x111111, 0x888888, 0xEEEEEE])
            return try ThemeCSSEmitter.emit(theme)
        }
        let baseline = try #require(outline(try css("plainRamp")))
        for name in hostileStrings where !name.isEmpty {
            #expect(outline(try css(name)) == baseline, "\(name.debugDescription.prefix(40)) changed the structure of the stylesheet")
        }
    }

    @Test("a hostile extras key that a surface refers to stays inside its var(), and is spelled the same where defined and used")
    func cssReferenceSourceStaysInItsVar() throws {
        // A reference to a name that is neither a role nor an extras key is already refused by the theme's own consistency
        // check, so the only way a hostile source reaches the stylesheet is as an extras key that exists and is referenced.
        func css(_ source: String) throws -> String {
            var theme = Theme.platinum
            theme.palette.extras[source] = colour
            theme.surfaces?.recipes[.button]?[.rest]?.layers = [.fill(ColourReference(source: source, opacity: 0.5))]
            return try ThemeCSSEmitter.emit(theme)
        }
        let baseline = try #require(outline(try css("plainSource")))
        for source in hostileStrings where !source.isEmpty {
            let out = try css(source)
            #expect(outline(out) == baseline, "\(source.debugDescription.prefix(40)) changed the structure of the stylesheet")
            // Every custom property the stylesheet reads with var(--extra-...) is one it declares, spelled the same way:
            // an escape applied at the use and not at the definition would leave the reference pointing at nothing.
            var rest = Substring(out)
            var checked = 0
            while let start = rest.firstRange(of: "var(--extra-") {
                let afterOpen = rest[start.lowerBound...].dropFirst(4)
                guard let close = afterOpen.firstIndex(of: ")") else { break }
                let name = String(afterOpen[afterOpen.startIndex..<close])
                #expect(out.contains(name + ":"), "\(source.debugDescription.prefix(40)) is read as \(name) but never declared")
                checked += 1
                rest = rest[close...]
            }
            #expect(checked > 0, "\(source.debugDescription.prefix(40)) was never referenced, so the test checked nothing")
        }
    }

    @Test("a plain extras key keeps its exact spelling, so the committed stylesheets do not move")
    func plainKeysAreUnchanged() throws {
        var theme = Theme.platinum
        theme.palette.extras["lavenderShade2"] = colour
        let css = try ThemeCSSEmitter.emit(theme)
        #expect(css.contains("--extra-lavender-shade2:"))
    }

    // MARK: Text lines

    @Test("a hostile series name, extras key or font name adds no line and no control character to the ANSI and slides lists")
    func textListsKeepTheirLines() throws {
        func theme(_ text: String) -> Theme {
            var copy = Theme.platinum
            copy.palette.series[0].name = text
            copy.palette.extras[text.isEmpty ? "k" : text] = colour
            copy.structure.type.body.family = .named(text, fallback: .sans)
            return copy
        }
        let ansi = lines(try ANSIEmitter.emit(theme("Plain")))
        let list = lines(try SlidesEmitter.emitList(theme("Plain")))
        for text in hostileStrings {
            let a = try ANSIEmitter.emit(theme(text))
            let s = try SlidesEmitter.emitList(theme(text))
            #expect(lines(a).count == ansi.count,"\(text.debugDescription.prefix(40)) changed the ANSI line count")
            #expect(lines(s).count == list.count, "\(text.debugDescription.prefix(40)) changed the slides line count")
            #expect(!hasStrayControl(a), "\(text.debugDescription.prefix(40)) put a control character in the ANSI table")
            #expect(!hasStrayControl(s), "\(text.debugDescription.prefix(40)) put a control character in the slides list")
        }
    }

    @Test("a hostile font name leaves the font scheme XML well-formed, with the same elements")
    func fontSchemeStaysWellFormed() throws {
        func xml(_ name: String) throws -> String {
            var theme = Theme.platinum
            theme.structure.type.heading.family = .named(name, fallback: .sans)
            theme.structure.type.body.family = .named(name, fallback: .sans)
            return try SlidesEmitter.emitFontScheme(theme)
        }
        let baseline = try #require(elementCount(try xml("Plain Face")))
        for name in hostileStrings {
            #expect(elementCount(try xml(name)) == baseline, "\(name.debugDescription.prefix(40)) broke the font scheme")
        }
    }
}

@Suite("Theme identity: what a supplied id and name cannot do to an emitter")
struct EmitterEscapingTests {
    // MARK: The identity rules

    @Test("an id is a slug: lower-case letters, digits, hyphen, underscore and plus, 1 to 64, no double hyphen")
    func slugRule() {
        for id in validIDs { #expect(ThemeIdentity.isValidID(id), "\(id.prefix(20)) should be valid") }
        for id in invalidIDs { #expect(!ThemeIdentity.isValidID(id), "\(id.debugDescription.prefix(30)) should be invalid") }
    }

    @Test("every built-in theme, and every composed one, has a valid id")
    func builtInsAreValid() {
        for theme in Theme.all { #expect(ThemeIdentity.isValidID(theme.id), "\(theme.id)") }
        #expect(ThemeIdentity.isValidID(Theme.swiss.composed(with: Theme.princetonPalette).id))
    }

    // MARK: ThemeCSSEmitter: the id is in a selector and a comment, the name in a comment

    @Test("a hostile name changes nothing in the stylesheet but the text of one comment")
    func cssNameCannotLeaveItsComment() throws {
        let baseline = try #require(shape(try ThemeCSSEmitter.emit(with(name: "Plain"))))
        for name in hostileNames {
            let css = try ThemeCSSEmitter.emit(with(name: name))
            let got = try #require(shape(css), "\(name.debugDescription.prefix(40)) left the stylesheet unbalanced")
            #expect(got == baseline, "\(name.debugDescription.prefix(40)) changed the structure")
            #expect(!css.contains("</"), "\(name.debugDescription.prefix(40)) put a closing tag in the stylesheet")
        }
    }

    @Test("an id that is not a slug is refused, never written")
    func cssRefusesBadIDs() {
        for id in invalidIDs {
            #expect(throws: ThemeEmitError.invalidID(id)) { try ThemeCSSEmitter.emit(with(id: id)) }
        }
    }

    @Test("a valid id gives the same stylesheet shape whatever it is, scoped to that id alone")
    func cssValidIDsKeepTheShape() throws {
        func normalised(_ id: String) throws -> [Piece] {
            // Only the selector scope is normalised: an id such as "a" or "0" also occurs elsewhere in a stylesheet.
            let css = try ThemeCSSEmitter.emit(with(id: id)).replacingAll("[data-theme-name=\"\(id)\"]", with: "[data-theme-name=\"ID\"]")
            return try #require(shape(css))
        }
        let baseline = try normalised("zid")
        for id in validIDs { #expect(try normalised(id) == baseline, "\(id.prefix(20))") }
    }

    // MARK: The Tumblr block and full theme

    @Test("the Tumblr block and the full theme refuse a bad id")
    func tumblrRefusesBadIDs() {
        for id in invalidIDs {
            #expect(throws: ThemeEmitError.invalidID(id)) { try TumblrEmitter.emit(with(id: id)) }
            #expect(throws: ThemeEmitError.invalidID(id)) { try TumblrThemeEmitter.emit(with(id: id)) }
        }
    }

    @Test("a hostile name cannot end the Tumblr page's comment, add a closing tag, add a line or add a Tumblr tag")
    func tumblrNameCannotEscapeTheComment() throws {
        // Tumblr's template engine reads {Tag} and {block:Name} anywhere in the page, a comment included, so a brace in a
        // name is a way to inject a template tag. Text such as "<script" is inert inside a comment and is not counted.
        let names = hostileNames + ["{Title}", "{block:Posts}", "{/block:Posts}", "{text:Anything}", "a } b { c"]
        let baseline = try TumblrThemeEmitter.emit(with(name: "Plain"))
        for name in names {
            let page = try TumblrThemeEmitter.emit(with(name: name))
            for needle in ["<!--", "-->", "</", "{", "}"] {
                #expect(occurrences(of: needle, in: page) == occurrences(of: needle, in: baseline),
                        "\(name.debugDescription.prefix(40)) changed the count of \(needle.debugDescription)")
            }
            #expect(lines(page).count == lines(baseline).count, "\(name.debugDescription.prefix(40)) added a line")
        }
    }

    // MARK: Line-oriented outputs

    @Test("a hostile name adds no line to the ANSI table")
    func ansiNameCannotStartALine() throws {
        let baseline = lines(try ANSIEmitter.emit(with(name: "Plain")))
        for name in hostileNames {
            let got = lines(try ANSIEmitter.emit(with(name: name)))
            #expect(got.count == baseline.count, "\(name.debugDescription.prefix(40)) changed the line count")
            #expect(Array(got.dropFirst()) == Array(baseline.dropFirst()), "\(name.debugDescription.prefix(40)) changed a later line")
            #expect(got[0].hasPrefix("# "))
        }
    }

    @Test("ANSI, the slides list and the GTK stylesheet and settings refuse a bad id")
    func lineOutputsRefuseBadIDs() throws {
        let slot = try #require(ThemeSlot.slots(for: .platinum).first)
        for id in invalidIDs {
            #expect(throws: ThemeEmitError.invalidID(id)) { try ANSIEmitter.emit(with(id: id)) }
            #expect(throws: ThemeEmitError.invalidID(id)) { try SlidesEmitter.emitList(with(id: id)) }
            #expect(throws: ThemeEmitError.invalidID(id)) { try GTKEmitter.emit(with(id: id), slot: slot) }
        }
    }

    @Test("a hostile name adds no line to the slides list")
    func slidesListNameCannotStartALine() throws {
        let baseline = lines(try SlidesEmitter.emitList(with(name: "Plain")))
        for name in hostileNames {
            let got = lines(try SlidesEmitter.emitList(with(name: name)))
            #expect(got.count == baseline.count, "\(name.debugDescription.prefix(40)) changed the line count")
            #expect(Array(got.dropFirst()) == Array(baseline.dropFirst()), "\(name.debugDescription.prefix(40)) changed a later line")
        }
    }

    @Test("a hostile name changes nothing in the GTK stylesheet but one comment, and adds no line to the settings")
    func gtkNameCannotLeaveItsComment() throws {
        let slot = try #require(ThemeSlot.slots(for: .platinum).first)
        let baseline = try #require(shape(try GTKEmitter.emit(with(name: "Plain"), slot: slot)))
        let baselineSettings = try #require(GTKEmitter.settings(with(name: "Plain")))
        for name in hostileNames {
            let css = try GTKEmitter.emit(with(name: name), slot: slot)
            #expect(shape(css) == baseline, "\(name.debugDescription.prefix(40)) changed the structure")
            let settings = try #require(GTKEmitter.settings(with(name: name)))
            #expect(lines(settings).count == lines(baselineSettings).count, "\(name.debugDescription.prefix(40)) added a settings line")
            #expect(Array(lines(settings).dropFirst()) == Array(lines(baselineSettings).dropFirst()))
        }
    }

    @Test("the GTK settings comment cannot carry a bad id into a new line")
    func gtkSettingsNeutralisesAnID() throws {
        let baseline = try #require(GTKEmitter.settings(with(id: "plain")))
        for id in invalidIDs {
            let settings = try #require(GTKEmitter.settings(with(id: id)))
            #expect(lines(settings).count == lines(baseline).count, "\(id.debugDescription.prefix(30)) added a line")
        }
    }

    // MARK: XML

    @Test("a hostile name leaves the colour and font scheme XML well-formed, with the same elements")
    func xmlSchemesStayWellFormed() throws {
        let slot = try #require(ThemeSlot.slots(for: .platinum).first)
        let colour = try #require(elementCount(try SlidesEmitter.emitColourScheme(with(name: "Plain"), slot: slot)))
        let font = try #require(elementCount(try SlidesEmitter.emitFontScheme(with(name: "Plain"))))
        for name in hostileNames {
            let c = try SlidesEmitter.emitColourScheme(with(name: name), slot: slot)
            let f = try SlidesEmitter.emitFontScheme(with(name: name))
            #expect(elementCount(c) == colour, "\(name.debugDescription.prefix(40)) broke the colour scheme")
            #expect(elementCount(f) == font, "\(name.debugDescription.prefix(40)) broke the font scheme")
        }
    }

    // MARK: JSON

    @Test("the JSON emitter keeps any name, since the encoder escapes it, and the id still round-trips")
    func jsonRoundTripsAnyName() throws {
        for name in hostileNames {
            let json = try ThemeJSONEmitter.emit(with(name: name))
            let decoded = try JSONDecoder().decode(Theme.self, from: Data(json.utf8))
            #expect(decoded.name == name)
        }
    }
}
