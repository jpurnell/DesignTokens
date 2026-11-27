import Foundation
import Testing
@testable import DesignTokens

/// The core links `FoundationEssentials` alone, so the `NSString`-bridged `String` operations it used to take from full
/// Foundation are written against the standard library. Each is checked here against Foundation's own answer, on the
/// inputs the core feeds it and on the edges where a hand-written version would drift: Unicode spaces, line breaks,
/// empty and overlapping needles, case.
@Suite("Text helpers match Foundation")
struct TextHelpersTests {
    /// Strings that exercise trimming: ASCII and Unicode spaces, every line-break scalar, tabs, interior spaces kept.
    private static let trimInputs: [String] = [
        "", " ", "\t", "\n", "  \t \n ", "plain", "  padded  ", "\tTab\t", "\n\nlines\r\n", "a b  c",
        "\u{00A0}nbsp\u{00A0}", "\u{2003}em space\u{2003}", "\u{2009}thin\u{2009}", "\u{3000}ideographic\u{3000}",
        "\u{0085}nel\u{0085}", "\u{2028}ls\u{2028}", "\u{2029}ps\u{2029}", "\u{000B}vt\u{000C}", "\u{200B}zwsp\u{200B}",
        "\u{FEFF}bom\u{FEFF}", "é é", " \u{0301}combining", "text\u{0301} ", "  \"quoted\"  ",
    ]

    @Test("trimmedSpaces equals trimmingCharacters(in: .whitespaces) on every input")
    func trimSpaces() {
        for input in Self.trimInputs {
            #expect(input.trimmedSpaces() == input.trimmingCharacters(in: .whitespaces), "\(input.debugDescription)")
        }
    }

    @Test("trimmedWhitespace equals trimmingCharacters(in: .whitespacesAndNewlines) on every input")
    func trimWhitespace() {
        for input in Self.trimInputs {
            #expect(input.trimmedWhitespace() == input.trimmingCharacters(in: .whitespacesAndNewlines), "\(input.debugDescription)")
        }
    }

    @Test("trimming keeps interior spaces, and trimming only space leaves nothing")
    func trimShape() {
        #expect("  a  b  ".trimmedSpaces() == "a  b")
        #expect(" \t ".trimmedSpaces().isEmpty)
        #expect(" \n ".trimmedWhitespace().isEmpty)
        #expect("\n x \n".trimmedSpaces() == "\n x \n", "a newline is not a space")
    }

    private static let replaceCases: [(text: String, target: String, with: String)] = [
        ("", "a", "b"), ("abc", "", "x"), ("abc", "z", "y"), ("abcabc", "bc", "-"), ("aaaa", "aa", "b"), ("aaa", "aa", "b"),
        ("a\\b\"c", "\\", "\\\\"), ("a\\\\b\"c", "\"", "\\\""), ("a<b>c#d=e%f", "%", "%25"), ("a<b>c#d=e%25f", "<", "%3C"),
        ("a & b < c > d \"q\"", "&", "&amp;"), ("x&amp;y", "<", "&lt;"), ("Theme -- Name", "--", "- -"), ("a---b", "--", "- -"),
        ("line1\nline2\n", "\n", " "), ("tab\there", "\t", "    "), ("éé", "é", "e"), ("abc", "abc", ""),
        ("abc", "abcd", "x"), ("ABC", "abc", "x"),
        // Multi-byte text, emoji, combining marks, a match at the very start and end, adjacent matches, a replacement containing the target.
        ("日本語日本", "日本", "X"), ("a😀b😀", "😀", ":)"), ("😀😀😀", "😀😀", "x"), ("x\u{0301}y", "y", "z"),
        ("--a--", "--", "-"), ("abab", "ab", "abab"), ("ééé", "é", "é é"), ("end-", "-", ""), ("-start", "-", "+"),
        ("a\u{200B}b", "\u{200B}", ""), ("\r\n\r\n", "\n", "N"),
    ]

    @Test("replacingAll equals replacingOccurrences(of:with:) on every case, including overlaps and the empty target")
    func replace() {
        for c in Self.replaceCases {
            #expect(c.text.replacingAll(c.target, with: c.with) == c.text.replacingOccurrences(of: c.target, with: c.with),
                    "\(c.text.debugDescription) \(c.target.debugDescription) -> \(c.with.debugDescription)")
        }
    }

    @Test("replacingAll gives Foundation's answer on a long text with many matches")
    func replaceLong() {
        let text = String(repeating: "a<b>&\"c é😀 ", count: 20_000)
        let ours = text.replacingAll("&", with: "&amp;")
        #expect(ours == text.replacingOccurrences(of: "&", with: "&amp;"))
    }

    @Test("replacingAll works on a Substring too and returns a String")
    func replaceSubstring() {
        let sub = "a-b-c".dropFirst(2)
        #expect(sub.replacingAll("-", with: "+") == "b+c")
    }

    private static let findCases: [(text: String, needle: String, caseInsensitive: Bool)] = [
        ("<style>a</style>", "<style", true), ("<STYLE>a</STYLE>", "<style", true), ("<STYLE>a</STYLE>", "<style", false),
        ("<p></Style >", "</style", true), ("no needle here", "zzz", false), ("abcabc", "bc", false), ("aaa", "aa", false),
        ("starts", "star", false), ("ends", "nds", false), ("exact", "exact", false), ("short", "longer needle", false),
        ("", "a", false), ("x /* theme: a | b */ y", "/* theme: ", false),
        ("a --theme-stamp: \"x\"", "--theme-stamp:", false), ("body */ tail", "*/", false), ("É", "é", true), ("é", "É", true),
        ("e\u{0301}x", "x", false),
    ]

    private func offsets(_ range: Range<String.Index>?, in text: String) -> Range<Int>? {
        range.map { text.distance(from: text.startIndex, to: $0.lowerBound)..<text.distance(from: text.startIndex, to: $0.upperBound) }
    }

    @Test("firstRange finds the same match as range(of:), with and without case folding, over the whole string")
    func findWhole() {
        for c in Self.findCases {
            let whole = c.text.startIndex..<c.text.endIndex
            let want = c.text.range(of: c.needle, options: c.caseInsensitive ? [.caseInsensitive] : [])
            let got = c.text.firstRange(of: c.needle, in: whole, ignoringCase: c.caseInsensitive)
            #expect(offsets(got, in: c.text) == offsets(want, in: c.text),
                    "\(c.text.debugDescription) / \(c.needle.debugDescription) ci=\(c.caseInsensitive)")
        }
    }

    @Test("an empty needle matches nothing, as in Foundation, so a caller's search loop cannot stall on a zero-width match")
    func findEmptyNeedle() {
        let text = "abc"
        let whole = text.startIndex..<text.endIndex
        #expect(text.firstRange(of: "", in: whole) == nil)
        #expect(text.firstRange(of: "", in: whole, ignoringCase: true) == nil)
        #expect(text.range(of: "") == nil)
    }

    @Test("firstRange honours the search window: it starts at the window, and a match cut by the window's end is not found")
    func findWindow() throws {
        let html = "<style>one</style><style>two</style>"
        let from = html.index(html.startIndex, offsetBy: 1)..<html.endIndex
        let second = try #require(html.firstRange(of: "<style", in: from))
        #expect(html.distance(from: html.startIndex, to: second.lowerBound) == 18)
        #expect(second == html.range(of: "<style", range: from))
        let cut = html.startIndex..<html.index(html.startIndex, offsetBy: 4)
        #expect(html.firstRange(of: "<style", in: cut) == nil)
        #expect(html.range(of: "<style", range: cut) == nil)
    }

    @Test("firstRange on a Substring uses the substring's own indices")
    func findSubstring() throws {
        let text = "xx*/yy*/"
        let tail = text[text.index(text.startIndex, offsetBy: 4)...]
        let hit = try #require(tail.firstRange(of: "*/", in: tail.startIndex..<tail.endIndex))
        #expect(text.distance(from: text.startIndex, to: hit.lowerBound) == 6)
    }

    @Test("a scalar is a control character exactly when Foundation's controlCharacters set says so")
    func controlCharacters() {
        // Latin-1 and the C1 controls through U+02FF, plus format, space, line-break, private-use and emoji scalars.
        let sample: [UInt32] = Array(0...0x2FF) + [0x061C, 0x200B, 0x200E, 0x2028, 0x2029, 0x202F, 0x2060, 0xFEFF, 0xE000, 0x1F600]
        for value in sample {
            guard let scalar = Unicode.Scalar(value) else { continue }
            #expect(scalar.isControlCharacter == CharacterSet.controlCharacters.contains(scalar), "U+\(String(value, radix: 16))")
        }
    }
}

/// Foundation's character sets are the oracle on Apple platforms, but the corelibs implementation on Linux is built on
/// different tables. These closed-form cases pin the helpers' own meaning everywhere, so a platform whose Foundation
/// differs cannot move the answer unnoticed.
@Suite("Text helpers, fixed expectations")
struct TextHelpersFixedTests {
    @Test("control characters are the C0 and C1 controls and the format characters, and nothing printable")
    func controlSet() {
        let controls: [UInt32] = [0x00, 0x09, 0x0A, 0x1F, 0x7F, 0x80, 0x9F, 0xAD, 0x200B, 0x200E, 0x2060, 0xFEFF]
        let notControls: [UInt32] = [0x20, 0x41, 0x7E, 0xA0, 0xA1, 0x2003, 0x2028, 0x3000, 0x1F600]
        for value in controls { #expect(Unicode.Scalar(value)?.isControlCharacter == true, "U+\(String(value, radix: 16)) should be a control") }
        for value in notControls { #expect(Unicode.Scalar(value)?.isControlCharacter == false, "U+\(String(value, radix: 16)) should not be") }
    }

    @Test("trimmedSpaces removes space, tab, no-break and other Zs spaces and the zero-width space, but not line breaks")
    func spacesSet() {
        #expect(" \t\u{00A0}\u{2003}\u{200B}x\u{200B}\u{2003}\u{00A0}\t ".trimmedSpaces() == "x")
        #expect("\u{2028}x\u{2028}".trimmedSpaces() == "\u{2028}x\u{2028}")
        #expect("\nx\n".trimmedSpaces() == "\nx\n")
    }

    @Test("trimmedWhitespace also removes every line-break scalar")
    func whitespaceSet() {
        #expect(" \n\r\u{0085}\u{2028}\u{2029}\u{200B}x\u{200B}\u{2029}\u{2028}\u{0085}\r\n ".trimmedWhitespace() == "x")
        #expect("\u{FEFF}x".trimmedWhitespace() == "\u{FEFF}x", "a byte-order mark is not white space")
    }
}
