import Foundation
import Testing
@testable import DesignTokens

private struct NoFetch: BlogFetching {
    func fetch(_ url: URL) throws -> String { throw NSError(domain: "must not be called", code: 1) }
}

@Suite("Tumblr full theme")
struct TumblrThemeEmitterTests {
    private static func count(_ needle: String, in text: String) -> Int {
        text.components(separatedBy: needle).count - 1
    }

    /// The `{block:Name}` / `{/block:Name}` tags in document order, as a stack walk: nil if unbalanced or misnested.
    private static func blocksBalance(_ html: String) -> Bool {
        var stack: [String] = []
        var rest = html[...]
        while let open = rest.range(of: "{") {
            rest = rest[open.lowerBound...]
            guard let close = rest.range(of: "}") else { return false }
            let tag = String(rest[rest.index(after: rest.startIndex)..<close.lowerBound])
            if tag.hasPrefix("block:") { stack.append(String(tag.dropFirst(6))) }
            else if tag.hasPrefix("/block:") {
                guard stack.popLast() == String(tag.dropFirst(7)) else { return false }
            }
            rest = rest[close.upperBound...]
        }
        return stack.isEmpty
    }

    private func swiss(_ parameters: TumblrThemeParameters = .placeholders) throws -> String {
        try TumblrThemeEmitter.emit(.swiss, parameters: parameters)
    }

    // MARK: Structure

    @Test("exactly one style element, and it holds the generated block verbatim")
    func oneStyleElementWithTheBlock() throws {
        for theme in Theme.all {
            let html = try TumblrThemeEmitter.emit(theme)
            #expect(Self.count("<style", in: html) == 1, "\(theme.id)")
            #expect(Self.count("</style>", in: html) == 1, "\(theme.id)")
            #expect(html.contains("<style>\n" + (try TumblrEmitter.emit(theme)) + "</style>"), "\(theme.id)")
        }
    }

    @Test("the stamp is found by the blog checker: current for the theme, stale for another")
    func stampIsFound() throws {
        for theme in Theme.all {
            let html = try TumblrThemeEmitter.emit(theme)
            let stamp = try TumblrEmitter.stamp(for: theme)
            #expect(BlogChecker.compare(html: html, expected: stamp) == .current(stamp), "\(theme.id)")
            var other = stamp
            other.version = "0.0.1"
            guard case .stale = BlogChecker.compare(html: html, expected: other) else {
                Issue.record("\(theme.id): expected stale"); continue
            }
        }
        #expect(DesignTokens.version == "0.7.0")
        #expect(try TumblrEmitter.stamp(for: .swiss).text.hasPrefix("swiss 0.7.0 t1 fnv1a64:"))
    }

    @Test("check-blog --html-file accepts the generated document: exit 0, current")
    func checkBlogAccepts() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("tumblr-full-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        let file = dir.appendingPathComponent("theme.html")
        try swiss().write(to: file, atomically: true, encoding: .utf8)
        let result = TumblrCommand.run(["check-blog", "--html-file", file.path], fetcher: NoFetch())
        #expect(result.exitCode == 0)
        #expect(result.stdout.contains("blog is current"))
    }

    @Test("every {block:...} has its closing tag, in nesting order")
    func blocksAreBalanced() throws {
        let html = try swiss()
        #expect(Self.count("{block:", in: html) > 30)
        #expect(Self.blocksBalance(html))
        #expect(Self.blocksBalance("{block:A}{block:B}{/block:B}{/block:A}"))
        #expect(!Self.blocksBalance("{block:A}"))
        #expect(!Self.blocksBalance("{block:A}{block:B}{/block:A}{/block:B}"))
        #expect(!Self.blocksBalance("{/block:A}"))
    }

    @Test("every div opened is closed, outside comments and the script")
    func divsBalance() throws {
        var html = try swiss()
        for (open, close) in [("<!--", "-->"), ("<script", "</script>"), ("<style", "</style>")] {
            while let start = html.range(of: open), let end = html.range(of: close, range: start.upperBound..<html.endIndex) {
                html.removeSubrange(start.lowerBound..<end.upperBound)
            }
        }
        #expect(Self.count("<div", in: html) == Self.count("</div>", in: html))
    }

    @Test("the markup has the contract's classes: the ones the document supplies, and Tumblr's {Length} for the quote sizes")
    func contractClasses() throws {
        let html = try swiss()
        for name in ["wrapper", "header", "nav", "post", "newday", "datetime", "day", "my", "type", "row", "k", "caption", "video", "long_quote", "pager"] {
            #expect(html.contains("class=\"\(name)\"") || html.contains("class=\"\(name) ") || html.contains(" \(name)\"")
                    || html.contains(" \(name) ") || html.contains(" \(name){") , "missing class \(name)")
        }
        #expect(html.contains("{Length}_quote"))   // short_quote, medium_quote and long_quote, by Tumblr
        #expect(html.contains("class=\"post{block:NewDayDate} newday{/block:NewDayDate}\""))
        #expect(html.contains("{block:NewDayDate}<span class=\"day\">{DayOfMonth}</span><span class=\"my\">"))
    }

    @Test("a complete document: doctype, html, head, body, and the Tumblr tags the page needs")
    func completeDocument() throws {
        let html = try swiss()
        #expect(html.hasPrefix("<!DOCTYPE html"))
        #expect(html.hasSuffix("</body>\n</html>\n"))
        for needle in ["<head>", "</head>", "<body>", "{Title}", "{Favicon}", "{RSS}", "{block:Posts}", "{/block:Posts}",
                       "{block:Pagination}", "{block:PermalinkPage}", "{block:SearchPage}", "{block:Photoset}", "{block:Video}",
                       "{block:Answer}", "{PostNotes}", "<meta name=\"viewport\"", "<meta name=\"description\" content=\"{Description}\"/>"] {
            #expect(html.contains(needle), Comment(rawValue: needle))
        }
        #expect(Self.count("<body>", in: html) == 1 && Self.count("</body>", in: html) == 1)
    }

    @Test("with the placeholders no owner or analytics value is in the document")
    func noOwnerData() throws {
        let html = try swiss()
        for banned in ["GTM-", "googletagmanager", "Purns", "justinpurnell", "micro.blog", "googlesyndication", "ca-pub", "purns"] {
            #expect(!html.contains(banned), Comment(rawValue: banned))
        }
        #expect(html.contains("<a href=\"/\"><h1>{Title}</h1></a>"))
    }

    @Test("the colour-scheme meta follows the theme's appearances")
    func colourSchemeMeta() throws {
        #expect(try TumblrThemeEmitter.emit(.swiss).contains("<meta name=\"color-scheme\" content=\"light dark\"/>"))
        #expect(try TumblrThemeEmitter.emit(.princeton).contains("<meta name=\"color-scheme\" content=\"light\"/>"))
        #expect(try TumblrThemeEmitter.emit(.legacyDark).contains("<meta name=\"color-scheme\" content=\"dark\"/>"))
    }

    // MARK: Parameters

    @Test("parameters are filled in: wordmark escaped, parent link, rel=me, and the tag manager id in head and noscript")
    func parametersFilled() throws {
        let parameters = try TumblrThemeParameters(wordmark: "R&D <blog>", wordmarkURL: "https://example.org/",
                                                   parentSite: TumblrParentSite(url: "https://example.org/about", label: "Example"),
                                                   relMeURL: "https://social.example/me", analyticsID: "GTM-ABC123")
        let html = try swiss(parameters)
        #expect(html.contains("<a href=\"https://example.org/\"><h1>R&amp;D &lt;blog&gt;</h1></a>"))
        #expect(html.contains("<a href=\"https://example.org/about\">Example</a></div>"))
        #expect(html.contains("<link href=\"https://social.example/me\" rel=\"me\" />"))
        #expect(Self.count("GTM-ABC123", in: html) == 2)
        #expect(Self.blocksBalance(html))
        #expect(BlogChecker.compare(html: html, expected: try TumblrEmitter.stamp(for: .swiss)) == .current(try TumblrEmitter.stamp(for: .swiss)))
    }

    @Test("values that could break out of an attribute, an element or a Tumblr tag are refused, naming the parameter")
    func refusals() {
        func refused(_ build: () throws -> TumblrThemeParameters, _ name: String) {
            do {
                _ = try build()
                Issue.record("accepted a bad \(name)")
            } catch let error as TumblrThemeError {
                guard case .invalid(let parameter, let reason) = error else { return }
                #expect(parameter == name)
                #expect(!reason.isEmpty)
            } catch { Issue.record("wrong error \(error)") }
        }
        refused({ try TumblrThemeParameters(wordmark: "a{block:Posts}b") }, "wordmark")
        refused({ try TumblrThemeParameters(wordmark: "two\nlines") }, "wordmark")
        refused({ try TumblrThemeParameters(wordmark: "") }, "wordmark")
        refused({ try TumblrThemeParameters(wordmarkURL: "javascript:alert(1)") }, "wordmarkURL")
        refused({ try TumblrThemeParameters(wordmarkURL: "https://x.org/\" onclick=\"y") }, "wordmarkURL")
        refused({ try TumblrThemeParameters(wordmarkURL: "https://x.org/ a") }, "wordmarkURL")
        refused({ try TumblrThemeParameters(parentSite: TumblrParentSite(url: "ftp://x", label: "x")) }, "parentSite.url")
        refused({ try TumblrThemeParameters(parentSite: TumblrParentSite(url: "https://x.org", label: "a{b")) }, "parentSite.label")
        refused({ try TumblrThemeParameters(relMeURL: "https://x.org/<") }, "relMeURL")
        refused({ try TumblrThemeParameters(analyticsID: "GTM-abc") }, "analyticsID")
        refused({ try TumblrThemeParameters(analyticsID: "UA-12345") }, "analyticsID")
        refused({ try TumblrThemeParameters(analyticsID: "GTM-ABC');alert(1);//") }, "analyticsID")
        refused({ try TumblrThemeParameters(analyticsID: "GTM-1234567890123") }, "analyticsID")
    }

    @Test("a tag manager id of 4 to 12 capitals and digits is accepted, at both ends")
    func analyticsBounds() throws {
        #expect(try TumblrThemeParameters(analyticsID: "GTM-ABCD").analyticsID == "GTM-ABCD")
        #expect(try TumblrThemeParameters(analyticsID: "GTM-ABCDEFGH1234").analyticsID == "GTM-ABCDEFGH1234")
    }

    // MARK: Command

    @Test("tumblr --full writes the css block and the html; the options only apply with --full")
    func commandFull() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("tumblr-cmd-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: dir) }
        let result = TumblrCommand.run(["tumblr", "--full", "--out", dir.path, "--wordmark", "Mine", "--gtm", "GTM-TEST1"], fetcher: NoFetch())
        #expect(result.exitCode == 0, "\(result.stderr)")
        let page = try String(contentsOf: dir.appendingPathComponent("themes/swiss.tumblr.html"), encoding: .utf8)
        #expect(page.contains("<h1>Mine</h1>") && page.contains("GTM-TEST1"))
        #expect(FileManager.default.fileExists(atPath: dir.appendingPathComponent("themes/swiss.tumblr.css").path))

        let loose = TumblrCommand.run(["tumblr", "--out", dir.path, "--gtm", "GTM-TEST1"], fetcher: NoFetch())
        #expect(loose.exitCode == 64)
        let bad = TumblrCommand.run(["tumblr", "--full", "--out", dir.path, "--gtm", "nope"], fetcher: NoFetch())
        #expect(bad.exitCode == 64)
        #expect(bad.stderr.contains("analyticsID"))
        let half = TumblrCommand.run(["tumblr", "--full", "--out", dir.path, "--parent-url", "https://x.org"], fetcher: NoFetch())
        #expect(half.exitCode == 64)
    }

    @Test("emitting is deterministic, and the placeholder document equals the default parameters")
    func deterministic() throws {
        #expect(try swiss() == swiss(try TumblrThemeParameters()))
    }
}
