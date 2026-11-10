import Foundation

/// What a staleness check found on the blog.
public enum BlogStatus: Sendable, Equatable {
    /// The pasted stamp equals the current one.
    case current(BlogStamp)
    /// The pasted stamp has the current theme, template revision and hash, and only the package version differs. The
    /// version moves with every release of the package whether or not the theme changed, and the hash is what says the
    /// generated block would be the same, so this is current: a re-paste would change nothing.
    case currentContent(found: BlogStamp, expected: BlogStamp)
    /// The pasted stamp parses and differs from the current one in the theme, the template revision or the hash: the
    /// generated block is not the one pasted.
    case stale(found: BlogStamp, expected: BlogStamp)
    /// The page carries no design-tokens stamp and no block: nothing has been pasted.
    case unstamped
    /// A stamp, or the block that should carry one, is present and unreadable: a hand edit, or a partial paste.
    case garbled(String)
    /// The page could not be read (no Chrome, a fetch error, the bot-challenge page): the check says nothing about
    /// the blog.
    case unreadable(String)

    /// The line to print.
    public var message: String {
        switch self {
        case .current(let stamp): "blog is current (\(stamp.text))"
        case .currentContent(let found, let expected):
            "blog is current: the theme, template and hash are unchanged (blog has \(found.text); this package is \(expected.version)); a re-paste would change nothing"
        case .stale(let found, let expected): "blog is stale: re-paste  (blog has \(found.text), current is \(expected.text))"
        case .unstamped: "blog is unstamped: no design-tokens stamp found; paste the block"
        case .garbled(let why): "blog stamp is garbled: \(BlogChecker.bounded(why)); re-paste the block"
        case .unreadable(let why): "blog could not be checked: \(BlogChecker.bounded(why, limit: 300))"
        }
    }

    /// The process exit code: 0 current, 1 stale, 2 unstamped, 3 garbled, 4 unreadable.
    public var exitCode: Int32 {
        switch self {
        case .current, .currentContent: 0
        case .stale: 1
        case .unstamped: 2
        case .garbled: 3
        case .unreadable: 4
        }
    }
}

/// Fetches the rendered HTML of a page.
///
/// The real implementation needs a browser: the blog answers a plain HTTP request with 403 and a JavaScript
/// challenge (``ChromeBlogFetcher``). Tests use a fake.
public protocol BlogFetching: Sendable {
    /// The rendered HTML of `url`.
    func fetch(_ url: URL) throws -> String
}

/// Reads the stamp out of a page's HTML and compares it with the current theme's.
///
/// Only `<style>` elements are read, so a stamp quoted in a post's text is not mistaken for the theme's. The stamp is
/// looked for in the `--theme-stamp` custom property and in the header comment; when both are present they must
/// agree, since a disagreement means one of them was edited by hand.
public enum BlogChecker {
    /// Compares a page's HTML with the expected stamp.
    public static func compare(html: String, expected: BlogStamp) -> BlogStatus {
        let styles = styleText(in: html)
        if looksLikeChallenge(html) {
            return .unreadable("the page is the bot-challenge page, not the blog (the browser challenge was not passed)")
        }
        let property = propertyStamp(in: styles)
        let comment = commentStamp(in: styles)
        switch (property, comment) {
        case (.none, .none):
            return styles.contains("design-tokens block begin")
                ? .garbled("the block's sentinel comment is present but no stamp can be read")
                : .unstamped
        case (.garbled(let why), _), (_, .garbled(let why)):
            return .garbled(why)
        case (.found(let a), .found(let b)):
            return a == b ? decide(a, expected) : .garbled("the stamp property (\(a.text)) and the header comment (\(b.text)) disagree")
        case (.found(let stamp), .none), (.none, .found(let stamp)):
            return decide(stamp, expected)
        }
    }

    /// Fetches `url` through `fetcher` and compares. A fetch error, or an empty page, is ``BlogStatus/unreadable(_:)``.
    public static func check(url: URL, expected: BlogStamp, fetcher: any BlogFetching) -> BlogStatus {
        let html: String
        do {
            html = try fetcher.fetch(url)
        } catch {
            return .unreadable("could not fetch \(url.absoluteString): \(error)")
        }
        guard !html.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return .unreadable("could not fetch \(url.absoluteString): the page was empty")
        }
        return compare(html: html, expected: expected)
    }

    static func bounded(_ text: String, limit: Int = 120) -> String {
        let flat = text.replacingOccurrences(of: "\n", with: " ")
        return flat.count <= limit ? flat : String(flat.prefix(limit)) + "..."
    }

    // MARK: Reading

    private enum Reading {
        case none
        case found(BlogStamp)
        case garbled(String)
    }

    private static func decide(_ found: BlogStamp, _ expected: BlogStamp) -> BlogStatus {
        if found == expected { return .current(expected) }
        // Only the version differs: the block is the same, and the version is not what the blog's look depends on.
        if found.id == expected.id, found.template == expected.template, found.hash == expected.hash {
            return .currentContent(found: found, expected: expected)
        }
        return .stale(found: found, expected: expected)
    }

    private static func looksLikeChallenge(_ html: String) -> Bool {
        // Neither marker appeared in the real blog's DOM (home page and /page/2, 2026-11-09), and the challenge page
        // carries both, along with a style element of its own, so a style element does not make it the blog.
        html.contains("/__challenge/") || html.contains("<title>Checking your browser")
    }

    /// The text of every `<style>` element, joined by newlines.
    private static func styleText(in html: String) -> String {
        var pieces: [String] = []
        var cursor = html.startIndex
        while let open = html.range(of: "<style", options: .caseInsensitive, range: cursor..<html.endIndex),
              let close = html.range(of: ">", range: open.upperBound..<html.endIndex) {
            guard let end = html.range(of: "</style", options: .caseInsensitive, range: close.upperBound..<html.endIndex) else {
                pieces.append(String(html[close.upperBound...]))
                break
            }
            pieces.append(String(html[close.upperBound..<end.lowerBound]))
            cursor = end.upperBound
        }
        return pieces.joined(separator: "\n")
    }

    /// The `--theme-stamp` custom property: quoted (the emitted form) or bare.
    private static func propertyStamp(in styles: String) -> Reading {
        guard let key = styles.range(of: "--theme-stamp:") else { return .none }
        let rest = styles[key.upperBound...].drop(while: { $0 == " " || $0 == "\t" })
        let value: Substring
        if rest.hasPrefix("\"") {
            let body = rest.dropFirst()
            guard let closing = body.firstIndex(of: "\"") else {
                return .garbled("--theme-stamp has an unterminated value: \(rest.prefix(80))")
            }
            value = body[body.startIndex..<closing]
        } else {
            value = rest.prefix(while: { $0 != ";" && $0 != "}" && $0 != "\n" })
        }
        guard let stamp = BlogStamp.parse(String(value)) else {
            return .garbled("--theme-stamp is not a stamp: \"\(value.prefix(80))\"")
        }
        return .found(stamp)
    }

    /// The header comment: `/* theme: swiss | DesignTokens 0.5.0 | template 1 | hash fnv1a64:... | ... */`.
    private static func commentStamp(in styles: String) -> Reading {
        guard let open = styles.range(of: "/* theme: ") else { return .none }
        let body = styles[open.upperBound...]
        let line = body[body.startIndex..<(body.range(of: "*/")?.lowerBound ?? body.endIndex)]
        let fields = line.components(separatedBy: " | ").map { $0.trimmingCharacters(in: .whitespaces) }
        guard fields.count >= 4, fields[1].hasPrefix("DesignTokens "), fields[2].hasPrefix("template "),
              fields[3].hasPrefix("hash ") else {
            return .garbled("the header comment is not a design-tokens header: \(line.prefix(80))")
        }
        let text = "\(fields[0]) \(fields[1].dropFirst("DesignTokens ".count)) t\(fields[2].dropFirst("template ".count)) "
            + fields[3].dropFirst("hash ".count)
        guard let stamp = BlogStamp.parse(text) else {
            return .garbled("the header comment's stamp is not well formed: \(line.prefix(80))")
        }
        return .found(stamp)
    }
}
