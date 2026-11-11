import Foundation
import Testing
@testable import DesignTokens

@Suite("ListStyle and the console theme (0.12.0)")
struct ListStyleAndConsoleTests {
    private static func css(_ theme: Theme) throws -> String { try ThemeCSSEmitter.emit(theme) }

    // MARK: ListStyle

    @Test("ListStyle has rows and cards, spelled as in JSON")
    func listStyleCases() throws {
        #expect(ListStyle.allCases == [.rows, .cards])
        #expect(ListStyle.rows.rawValue == "rows")
        #expect(ListStyle.cards.rawValue == "cards")
    }

    @Test("every theme is rows except console, which is cards")
    func themesListStyle() {
        for theme in Theme.all {
            #expect(theme.structure.layout.listStyle == (theme.id == "console" ? .cards : .rows), "\(theme.id)")
        }
    }

    @Test("the JSON carries listStyle and decodes it")
    func jsonCarriesListStyle() throws {
        for id in ["swiss", "console"] {
            let theme = try #require(Theme.named(id))
            let text = String(decoding: try ThemeCodec.encode(theme), as: UTF8.self)
            #expect(text.contains("\"listStyle\" : \"\(theme.structure.layout.listStyle.rawValue)\""), Comment(rawValue: id))
            #expect(try ThemeCodec.decode(try ThemeCodec.encode(theme)).structure.layout.listStyle == theme.structure.layout.listStyle)
        }
    }

    @Test("JSON from before 0.12.0, with no listStyle, still loads and means rows")
    func oldJSONDecodesAsRows() throws {
        var lines = String(decoding: try ThemeCodec.encode(Theme.swiss), as: UTF8.self)
            .split(omittingEmptySubsequences: false, whereSeparator: \.isNewline).map(String.init)
        let before = lines.count
        lines.removeAll { $0.contains("\"listStyle\"") }
        #expect(lines.count == before - 1)
        // the key sorts before `margins`, so the previous line ends in a comma that stays valid
        let decoded = try ThemeCodec.decode(Data(lines.joined(separator: "\n").utf8))
        #expect(decoded.structure.layout.listStyle == .rows)
    }

    @Test("an unknown listStyle value is refused")
    func unknownListStyleRefused() throws {
        let text = String(decoding: try ThemeCodec.encode(Theme.swiss), as: UTF8.self)
            .replacingOccurrences(of: "\"listStyle\" : \"rows\"", with: "\"listStyle\" : \"grid\"")
        #expect(throws: (any Error).self) { try ThemeCodec.decode(Data(text.utf8)) }
    }

    @Test("CSS emits the list style and the tokens components key off: rows are one column with a hairline, cards an auto-fit grid of surfaces")
    func cssListTokens() throws {
        let swiss = try Self.css(.swiss)
        #expect(swiss.contains("  --list-style: rows;"))
        #expect(swiss.contains("  --list-item-min: 100%;"))
        #expect(swiss.contains("  --list-item-rule: var(--rule-hairline);"))
        #expect(swiss.contains("  --list-item-surface: transparent;"))
        #expect(swiss.contains("  --list-gap: 0px;"))
        let console = try Self.css(try #require(Theme.named("console")))
        #expect(console.contains("  --list-style: cards;"))
        #expect(console.contains("  --list-item-min: 384px;"))
        #expect(console.contains("  --list-item-rule: 0px;"))
        #expect(console.contains("  --list-item-surface: var(--surface);"))
        #expect(console.contains("  --list-gap: var(--gutter);"))
    }

    // MARK: Console

    @Test("console is registered after the legacy themes, named Console, fixed dark")
    func consoleRegistered() throws {
        let console = try #require(Theme.named("console"))
        #expect(console.name == "Console")
        #expect(console.appearances == .fixedDark)
        #expect(Theme.all.last?.id == "console")
    }

    @Test("console's colours are the FleetWatch page's own values, in the light slot of a fixed-dark theme")
    func consoleColours() throws {
        let p = try #require(Theme.named("console")).palette
        #expect(p.background.light.hex == "#1A1A2E")
        #expect(p.surface.light.hex == "#16213E")
        #expect(p.rule.light.hex == "#0F3460")
        #expect(p.ink.light.hex == "#E0E0E0")
        #expect(p.secondaryInk.light.hex == "#8888AA")
        #expect(p.positive.light.hex == "#4ADE80")
        #expect(p.warning.light.hex == "#FACC15")
        #expect(p.negative.light.hex == "#F87171")
        #expect(p.link.light.hex == "#60A5FA")
        #expect(p.extras["inset"]?.light.hex == "#0A0A1A")
        for role in ColorRole.allCases { #expect(p[role].dark == nil, "\(role)") }
    }

    @Test("console's structure: cards bordered 1 px, radii 8 and 4, monospaced UI face")
    func consoleStructure() throws {
        let s = try #require(Theme.named("console")).structure
        #expect(s.layout.cardBorder == 1)
        #expect(s.layout.containerRadius == 8)
        #expect(s.layout.controlRadius == 4)
        #expect(s.marks.barCornerRadius == 3)
        #expect(s.layout.cardPadding > 0)
        #expect(s.layout.shadow == nil)
        let mono = FontFamilyRef.named("SF Mono", fallback: .named("Menlo", fallback: .named("Consolas", fallback: .mono)))
        for role in TypeRole.allCases { #expect(s.type[role].family == mono, "\(role)") }
    }

    @Test("console's CSS says the page's font stack and is dark")
    func consoleCSS() throws {
        let css = try Self.css(try #require(Theme.named("console")))
        #expect(css.contains("  color-scheme: dark;"))
        #expect(css.contains("  --type-body-family: \"SF Mono\", \"Menlo\", \"Consolas\", "))
        #expect(css.contains("  --background: #1A1A2E;"))
        #expect(css.contains("  --card-border: 1px;"))
        #expect(css.contains("  --radius-container: 8px;"))
    }

    @Test("console declares every status the components use: warning, the alert extra, positive, negative")
    func consoleStatuses() throws {
        let p = try #require(Theme.named("console")).palette
        #expect(p.extras[ThemePalette.alertName]?.light.hex == "#FB923C")
    }

    @Test("console's ledger is the validator's own measurement, kind ledger, and records what it measures")
    func consoleLedgerIsMeasured() throws {
        let console = try #require(Theme.named("console"))
        #expect(console.conformance.kind == .ledger)
        let measured = ThemeValidator.validate(console)
        #expect(Set(console.conformance.entries) == Set(measured))
        #expect(ThemeValidator.deviations(of: console) == [])
    }
}
