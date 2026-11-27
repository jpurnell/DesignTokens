import Foundation
import Testing
@testable import DesignTokens

// The validator reports what an emitter will do to a theme's identity strings, so a theme supplied from outside is told
// before it is emitted: an id that is not a slug is a failure (every emitter refuses it); a name with characters that
// cannot be written to a generated file is a warning (the emitters write them as spaces, so the text changes).

private func structureFindings(_ theme: Theme, subject: String) -> [Finding] {
    ThemeValidator.validate(theme).filter { $0.check == .structure && $0.subject == subject }
}

@Suite("Theme identity in the validator")
struct ThemeIdentityValidationTests {
    @Test("a built-in theme has no identity finding")
    func builtInsAreClean() {
        for theme in Theme.all {
            #expect(structureFindings(theme, subject: "id").isEmpty, "\(theme.id)")
            #expect(structureFindings(theme, subject: "name").isEmpty, "\(theme.id)")
        }
    }

    @Test("an id that is not a slug is one failure, and a slug is none")
    func idIsAFailure() {
        for id in ["", "A b", "a\"b", "../x", "a--b", "é", "a;b", String(repeating: "a", count: 65)] {
            var theme = Theme.platinum
            theme.id = id
            let found = structureFindings(theme, subject: "id")
            #expect(found.count == 1, "\(id.debugDescription.prefix(30))")
            #expect(found.first?.severity == .fail)
        }
        for id in ["a", "swiss+princeton", "x1-y2", "a_b"] {
            var theme = Theme.platinum
            theme.id = id
            #expect(structureFindings(theme, subject: "id").isEmpty, "\(id)")
        }
    }

    @Test("a name the emitters would rewrite is one warning, and ordinary text is none")
    func nameIsAWarning() {
        for name in ["a\nb", "x\u{0}y", "\u{1B}[31mred", "line\u{2028}sep", "\u{202E}rtl"] {
            var theme = Theme.platinum
            theme.name = name
            let found = structureFindings(theme, subject: "name")
            #expect(found.count == 1, "\(name.debugDescription)")
            #expect(found.first?.severity == .warn)
        }
        // Ordinary text, including text that is only adjusted inside a comment, is not a finding.
        for name in ["Plain", "", "a */ b", "x -- y", "日本語 é ✓", "{Title}", "</style>"] {
            var theme = Theme.platinum
            theme.name = name
            #expect(structureFindings(theme, subject: "name").isEmpty, "\(name.debugDescription)")
        }
    }

    @Test("a finding about the identity does not disturb the other findings")
    func otherFindingsAreUnchanged() {
        var theme = Theme.platinum
        let before = ThemeValidator.validate(theme)
        theme.id = "bad id"
        theme.name = "bad\nname"
        let extra = ThemeValidator.validate(theme).filter { !before.contains($0) }
        #expect(extra.count == 2)
        #expect(Set(extra.map(\.subject)) == ["id", "name"])
    }
}
