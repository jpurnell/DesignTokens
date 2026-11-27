#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// A theme's `id` was not safe to write into an emitted file.
///
/// The emitters write an id where a stray character changes what the file means: in a `[data-theme-name="…"]` selector, in
/// the stamp a blog check parses (space-separated), in a comment, and in the name of a generated file. A theme can arrive
/// from outside (DesignTokensWeb accepts custom JSON), so an id is checked, not trusted.
public enum ThemeEmitError: Error, Equatable, Sendable, CustomStringConvertible {
    /// The id is not a slug (see ``ThemeIdentity/isValidID(_:)``). Carries the id as given.
    case invalidID(String)

    /// A sentence saying what was wrong with the id and what an id may be.
    public var description: String {
        switch self {
        case .invalidID(let id):
            "theme id \(String(reflecting: String(id.prefix(40)))) is not a slug: 1 to 64 lower-case letters, digits, '-', '_' or '+', starting with a letter or digit, with no '--'"
        }
    }
}

/// What a theme's identity strings may contain, and how display text is made safe to write.
///
/// **An id is an identifier, so it is refused, not escaped.** It is a selector value, a stamp field, a file name and a
/// comment token at once, and no single escape is right for all four (a CSS escape in a stamp is wrong; a stamp rule in a
/// selector is wrong). A slug is correct in all of them, so an emitter that writes an id throws ``ThemeEmitError`` for
/// anything else.
///
/// **A name is display text, so it is neutralised for the place it is written, never refused.** Control characters, line
/// and paragraph separators and bidirectional controls become spaces everywhere (they start lines, end XML parsing and
/// reorder text); then each context closes its own hole.
public enum ThemeIdentity {
    /// Whether `id` is a slug: 1 to 64 ASCII lower-case letters, digits, `-`, `_` or `+`, starting with a letter or digit,
    /// with no `--`.
    ///
    /// Every built-in id is one, and so is a composed id such as `swiss+princeton`. The limit of 64 keeps a stamp line and a
    /// file name short; the rule has no case-insensitive collisions (`Swiss` and `swiss` would be one file on macOS).
    public static func isValidID(_ id: String) -> Bool {
        let scalars = Array(id.unicodeScalars)
        guard (1...64).contains(scalars.count), isAlphanumeric(scalars[0]) else { return false }
        var previousHyphen = false
        for scalar in scalars {
            let hyphen = scalar == "-"
            guard isAlphanumeric(scalar) || hyphen || scalar == "_" || scalar == "+", !(hyphen && previousHyphen) else { return false }
            previousHyphen = hyphen
        }
        return true
    }

    private static func isAlphanumeric(_ scalar: Unicode.Scalar) -> Bool {
        ("a"..."z").contains(scalar) || ("0"..."9").contains(scalar)
    }

    // MARK: Display text

    /// `text` with every control character, line or paragraph separator and bidirectional control replaced by a space.
    ///
    /// Newlines, carriage returns, NEL, U+2028 and U+2029 start a line in some text format; the rest of the C0 and C1
    /// controls are not allowed in XML 1.0; U+202A to U+202E and U+2066 to U+2069 make a generated file read in a different
    /// order than it is stored.
    static func displayText(_ text: String) -> String {
        var out = String.UnicodeScalarView()
        for scalar in text.unicodeScalars {
            if isUnsafeInText(scalar) { out.append(" ") } else { out.append(scalar) }
        }
        return String(out)
    }

    private static func isUnsafeInText(_ scalar: Unicode.Scalar) -> Bool {
        switch scalar.properties.generalCategory {
        case .control, .lineSeparator, .paragraphSeparator: true
        default: (0x202A...0x202E).contains(scalar.value) || (0x2066...0x2069).contains(scalar.value)
        }
    }

    /// `text` as safe to put inside a CSS comment, also when the stylesheet is inlined in a `<style>` element: the comment
    /// terminator `*/` is spaced out and so is `</`.
    static func cssCommentText(_ text: String) -> String {
        displayText(text).replacingAll("*/", with: "* /").replacingAll("</", with: "< /")
    }

    /// `text` as safe to put inside an HTML or XML comment: no two hyphens in a row (`--` is not allowed inside an XML
    /// comment, and `--!>` closes an HTML one), however long the run.
    static func markupCommentText(_ text: String) -> String {
        var out = String.UnicodeScalarView()
        var previousHyphen = false
        for scalar in displayText(text).unicodeScalars {
            if scalar == "-", previousHyphen { out.append(" ") }
            out.append(scalar)
            previousHyphen = scalar == "-"
        }
        return String(out).replacingAll("</", with: "< /")
    }

    /// `text` as safe to put inside the full Tumblr theme's HTML comment: everything ``markupCommentText(_:)`` does, and no
    /// brace. Tumblr's template engine reads `{Tag}` and `{block:Name}` anywhere in a theme, a comment included, so a brace
    /// in a name could inject a tag; each becomes the parenthesis that looks like it.
    static func tumblrCommentText(_ text: String) -> String {
        markupCommentText(text).replacingAll("{", with: "(").replacingAll("}", with: ")")
    }

    // MARK: CSS escapes

    /// `text` as the inside of a double-quoted CSS string, escaped per CSS Syntax (a backslash, the code point in hex, and one
    /// space that ends the escape).
    ///
    /// Escaped: the quote and the backslash (they end or alter the string), the controls that ``displayText(_:)`` replaces
    /// (a newline is not allowed in a string), and `{`, `}`, `<` and `>`: a brace inside a string is still read as a tag when
    /// the CSS is pasted into a Tumblr theme, and `</style` must not occur in a stylesheet inlined in a page. Every other
    /// character, non-ASCII included, is kept, so an ordinary font name such as `SF Pro Text` is written as it always was.
    static func cssString(_ text: String) -> String {
        var out = ""
        for scalar in text.unicodeScalars {
            switch scalar {
            case "\"", "\\", "{", "}", "<", ">": out += cssEscape(scalar)
            default: out += isUnsafeInText(scalar) ? cssEscape(scalar) : String(scalar)
            }
        }
        return out
    }

    /// `text` as the rest of a CSS identifier (a custom property name or a `var()` argument after its `--prefix`), escaped per
    /// CSS Syntax.
    ///
    /// Kept: ASCII letters, digits, `-` and `_`, and any non-ASCII character that is not a control. Everything else becomes a
    /// hex escape, so a key that holds a `;`, a brace, a paren or a space is still one identifier, and the same key written
    /// where it is defined and where it is referenced is the same identifier.
    static func cssIdentifier(_ text: String) -> String {
        var out = ""
        for scalar in text.unicodeScalars {
            let isKept = scalar.isASCII
                ? (scalar.properties.isAlphabetic || ("0"..."9").contains(scalar) || scalar == "-" || scalar == "_")
                : !isUnsafeInText(scalar)
            out += isKept ? String(scalar) : cssEscape(scalar)
        }
        return out
    }

    /// One code point as a CSS hex escape. NUL, which CSS does not allow, becomes the replacement character's escape.
    private static func cssEscape(_ scalar: Unicode.Scalar) -> String {
        "\\" + String(scalar.value == 0 ? 0xFFFD : scalar.value, radix: 16, uppercase: true) + " "
    }

    /// Throws ``ThemeEmitError/invalidID(_:)`` unless `theme.id` is a slug. Every emitter that writes the id calls this first.
    static func requireValidID(of theme: Theme) throws {
        guard isValidID(theme.id) else { throw ThemeEmitError.invalidID(theme.id) }
    }
}
