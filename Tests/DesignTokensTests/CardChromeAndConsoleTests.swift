import Foundation
import Testing
@testable import DesignTokens

@Suite("CardChrome and the console theme (0.12.0)")
struct CardChromeAndConsoleTests {
    private static func css(_ theme: Theme) throws -> String { try ThemeCSSEmitter.emit(theme) }

    // MARK: CardChrome

    @Test("CardChrome has ruled and bordered, spelled as in JSON")
    func cardChromeCases() throws {
        #expect(CardChrome.allCases == [.ruled, .bordered])
        #expect(CardChrome.ruled.rawValue == "ruled")
        #expect(CardChrome.bordered.rawValue == "bordered")
    }

    @Test("every theme is ruled except console, which is bordered")
    func themesCardChrome() {
        for theme in Theme.all {
            #expect(theme.structure.layout.cardChrome == (theme.id == "console" ? .bordered : .ruled), Comment(rawValue: theme.id))
        }
    }

    @Test("the JSON carries cardChrome and decodes it")
    func jsonCarriesCardChrome() throws {
        for id in ["swiss", "console"] {
            let theme = try #require(Theme.named(id))
            let text = String(decoding: try ThemeCodec.encode(theme), as: UTF8.self)
            #expect(text.contains("\"cardChrome\" : \"\(theme.structure.layout.cardChrome.rawValue)\""), Comment(rawValue: id))
            #expect(try ThemeCodec.decode(try ThemeCodec.encode(theme)).structure.layout.cardChrome == theme.structure.layout.cardChrome)
        }
    }

    @Test("JSON from before 0.12.0, with no cardChrome, still loads and means ruled")
    func oldJSONDecodesAsRuled() throws {
        var lines = String(decoding: try ThemeCodec.encode(Theme.swiss), as: UTF8.self)
            .split(omittingEmptySubsequences: false, whereSeparator: \.isNewline).map(String.init)
        let before = lines.count
        lines.removeAll { $0.contains("\"cardChrome\"") }
        #expect(lines.count == before - 1)
        let decoded = try ThemeCodec.decode(Data(lines.joined(separator: "\n").utf8))
        #expect(decoded.structure.layout.cardChrome == .ruled)
    }

    @Test("an unknown cardChrome value is refused")
    func unknownCardChromeRefused() throws {
        let text = String(decoding: try ThemeCodec.encode(Theme.swiss), as: UTF8.self)
            .replacingOccurrences(of: "\"cardChrome\" : \"ruled\"", with: "\"cardChrome\" : \"grid\"")
        #expect(throws: (any Error).self) { try ThemeCodec.decode(Data(text.utf8)) }
    }

    @Test("CSS emits the card chrome and the tokens components key off: ruled is a top rule on no surface, bordered a surface; both 352 px minimum")
    func cssCardTokens() throws {
        let swiss = try Self.css(.swiss)
        #expect(swiss.contains("  --card-chrome: ruled;"))
        #expect(swiss.contains("  --card-surface: transparent;"))
        #expect(swiss.contains("  --card-top-rule: var(--rule-section);"))
        #expect(swiss.contains("  --card-top-color: var(--ink);"))
        #expect(swiss.contains("  --card-border: 0px;"))
        #expect(swiss.contains("  --card-min: 352px;"))
        #expect(swiss.contains("  --card-gap: var(--gutter);"))
        let console = try Self.css(try #require(Theme.named("console")))
        #expect(console.contains("  --card-chrome: bordered;"))
        #expect(console.contains("  --card-surface: var(--surface);"))
        #expect(console.contains("  --card-top-rule: 0px;"))
        #expect(console.contains("  --card-top-color: var(--rule);"))
        #expect(console.contains("  --card-border: 1px;"))
        #expect(console.contains("  --card-min: 352px;"))
        #expect(!swiss.contains("--list-"), "the 0.12.0 list-style tokens are gone")
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
