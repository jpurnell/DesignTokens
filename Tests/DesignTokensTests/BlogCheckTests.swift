import Foundation
import Testing
@testable import DesignTokens

/// A fetcher that returns canned HTML (or fails), so the comparison needs no network and no Chrome.
private struct FakeFetcher: BlogFetching {
    var result: Result<String, FakeFailure>
    func fetch(_ url: URL) throws -> String { try result.get() }
}
private struct FakeFailure: Error, CustomStringConvertible { var description: String }

@Suite("Blog staleness check")
struct BlogCheckTests {
    private let expected = BlogStamp(id: "swiss", version: "0.6.0", template: 1, hash: "fnv1a64:0123456789abcdef")
    private let other = BlogStamp(id: "swiss", version: "0.4.0", template: 1, hash: "fnv1a64:fedcba9876543210")

    /// A page shaped like the dumped DOM of the live blog, with the given style text.
    private func page(style: String) -> String {
        "<!DOCTYPE html><html class=\" js\"><head><style>\(style)</style><style type=\"text/css\">a{}</style></head><body><div class=\"post newday\"></div></body></html>"
    }

    private func pasted(_ stamp: BlogStamp, property: Bool = true, comment: Bool = true) -> String {
        var s = "/* >>> design-tokens block begin */\n"
        if comment {
            s += "/* theme: \(stamp.id) | DesignTokens \(stamp.version) | template \(stamp.template) | hash \(stamp.hash) | snapshot x | generated, do not edit */\n"
        }
        if property { s += ":root { --theme-stamp: \"\(stamp.text)\"; --bg: #FFFFFF; }\n" }
        return s + "/* >>> design-tokens block end */"
    }

    @Test("currentStampIsAccepted")
    func current() {
        let status = BlogChecker.compare(html: page(style: pasted(expected)), expected: expected)
        #expect(status == .current(expected))
        #expect(status.exitCode == 0)
        #expect(status.message == "blog is current (\(expected.text))")
    }

    @Test("a stamp that differs only in the package version is current: the block would be the same")
    func versionOnlyIsCurrent() {
        var older = expected; older.version = "0.4.0"
        let status = BlogChecker.compare(html: page(style: pasted(older)), expected: expected)
        #expect(status == .currentContent(found: older, expected: expected))
        #expect(status.exitCode == 0)
        #expect(status.message.hasPrefix("blog is current: the theme, template and hash are unchanged"))
        #expect(status.message.contains(older.text))
        #expect(status.message.contains("this package is 0.6.0"))
    }

    @Test("a stamp whose version AND hash differ is stale, with both stamps in the message")
    func staleVersion() {
        let status = BlogChecker.compare(html: page(style: pasted(other)), expected: expected)
        #expect(status == .stale(found: other, expected: expected))
        #expect(status.exitCode == 1)
        #expect(status.message == "blog is stale: re-paste  (blog has \(other.text), current is \(expected.text))")
    }

    @Test("a stamp that differs only in the hash, or only in the template revision, is stale")
    func staleHashOrTemplate() {
        var hash = expected; hash.hash = "fnv1a64:aaaaaaaaaaaaaaaa"
        var tpl = expected; tpl.template = 2
        var id = expected; id.id = "ft"
        for found in [hash, tpl, id] {
            #expect(BlogChecker.compare(html: page(style: pasted(found)), expected: expected)
                    == .stale(found: found, expected: expected))
        }
    }

    @Test("missingStampIsReported: the live blog today has the Swiss draft and no stamp, which is unstamped")
    func unstamped() {
        let live = page(style: "/* Swiss structure on Apple's system */ :root { --bg: #fafafa; --accent: #FF8D28; }")
        let status = BlogChecker.compare(html: live, expected: expected)
        #expect(status == .unstamped)
        #expect(status.exitCode == 2)
        #expect(status.message == "blog is unstamped: no design-tokens stamp found; paste the block")
        #expect(BlogChecker.compare(html: "", expected: expected) == .unstamped)
    }

    @Test("a stamp in the header comment alone is read when the custom property is absent")
    func commentOnly() {
        let status = BlogChecker.compare(html: page(style: pasted(expected, property: false)), expected: expected)
        #expect(status == .current(expected))
    }

    @Test("a stamp in the custom property alone is read when the comment was deleted")
    func propertyOnly() {
        #expect(BlogChecker.compare(html: page(style: pasted(other, comment: false)), expected: expected)
                == .stale(found: other, expected: expected))
    }

    @Test("garbledStampIsReported: a property that does not parse", arguments: [
        "--theme-stamp: \"swiss 0.6.0 t1 fnv1a64:zzzz\";",
        "--theme-stamp: \"\";",
        "--theme-stamp: swiss;",
        "--theme-stamp: \"swiss 0.6.0 t1 fnv1a64:0123456789abcdef",
        "--theme-stamp:",
    ])
    func garbledProperty(_ declaration: String) {
        let status = BlogChecker.compare(html: page(style: ":root { \(declaration) }"), expected: expected)
        guard case .garbled = status else {
            Issue.record("expected garbled, got \(status)")
            return
        }
        #expect(status.exitCode == 3)
        #expect(status.message.hasPrefix("blog stamp is garbled"))
    }

    @Test("garbled: the block sentinel is present but no stamp is readable (a hand edit removed it)")
    func garbledSentinelOnly() {
        let html = page(style: "/* >>> design-tokens block begin */\n:root { --bg: #fff; }\n/* >>> design-tokens block end */")
        let status = BlogChecker.compare(html: html, expected: expected)
        guard case .garbled = status else {
            Issue.record("expected garbled, got \(status)")
            return
        }
        #expect(status.exitCode == 3)
    }

    @Test("garbled: the property and the comment disagree (someone edited one of them)")
    func garbledDisagreement() {
        let html = page(style: pasted(expected, property: false)
                        + ":root { --theme-stamp: \"\(other.text)\"; }")
        guard case .garbled(let why) = BlogChecker.compare(html: html, expected: expected) else {
            Issue.record("expected garbled")
            return
        }
        #expect(why.contains("disagree"))
    }

    @Test("garbled text in the message is shortened, so a page cannot flood the terminal")
    func garbledMessageIsBounded() {
        let long = String(repeating: "x", count: 5000)
        let status = BlogChecker.compare(html: page(style: ":root { --theme-stamp: \"\(long)\"; }"), expected: expected)
        #expect(status.message.count < 400)
    }

    @Test("a stamp quoted in a post body, outside any style element, is not the theme's stamp")
    func stampInBodyTextIgnored() {
        let html = "<html><head><style>:root{}</style></head><body><p>try --theme-stamp: \"\(other.text)\";</p></body></html>"
        #expect(BlogChecker.compare(html: html, expected: expected) == .unstamped)
    }

    @Test("the bot-challenge page is unreadable, not unstamped: it says nothing about the blog")
    func challengePage() {
        let challenge = "<!DOCTYPE html><title>Checking your browser...</title><script src=\"/__challenge/challenge.js\"></script>"
        let status = BlogChecker.compare(html: challenge, expected: expected)
        guard case .unreadable(let why) = status else {
            Issue.record("expected unreadable, got \(status)")
            return
        }
        #expect(why.contains("challenge"))
        #expect(status.exitCode == 4)
    }

    @Test("the real challenge page carries its own style element and is still unreadable, not unstamped")
    func challengePageWithStyle() {
        let challenge = "<!DOCTYPE html><title>Checking your browser...</title><style>body{margin:0}</style>"
            + "<script src=\"/__challenge/probes.js?v=c3301fdb5ac5\"></script>"
        let status = BlogChecker.compare(html: challenge, expected: expected)
        guard case .unreadable = status else {
            Issue.record("expected unreadable, got \(status)")
            return
        }
        #expect(status.exitCode == 4)
    }

    @Test("check() fetches through the protocol and compares")
    func checkUsesFetcher() throws {
        let url = try #require(URL(string: "https://blog.example/"))
        let ok = BlogChecker.check(url: url, expected: expected, fetcher: FakeFetcher(result: .success(page(style: pasted(expected)))))
        #expect(ok == .current(expected))
        let stale = BlogChecker.check(url: url, expected: expected, fetcher: FakeFetcher(result: .success(page(style: pasted(other)))))
        #expect(stale == .stale(found: other, expected: expected))
    }

    @Test("a fetch failure is unreadable, with the reason, and exit 4")
    func fetchFailure() throws {
        let url = try #require(URL(string: "https://blog.example/"))
        let status = BlogChecker.check(url: url, expected: expected, fetcher: FakeFetcher(result: .failure(FakeFailure(description: "no chrome"))))
        #expect(status == .unreadable("could not fetch https://blog.example/: no chrome"))
        #expect(status.exitCode == 4)
        #expect(status.message == "blog could not be checked: could not fetch https://blog.example/: no chrome")
    }

    @Test("the Chrome fetcher asks for the headless DOM with a virtual-time budget, and puts the URL last")
    func chromeArguments() throws {
        let url = try #require(URL(string: "https://blog.justinpurnell.com/page/2"))
        let args = ChromeBlogFetcher().arguments(for: url)
        #expect(args == ["--headless=new", "--disable-gpu", "--virtual-time-budget=20000", "--dump-dom",
                         "https://blog.justinpurnell.com/page/2"])
        #expect(ChromeBlogFetcher(virtualTimeBudgetMs: 5000).arguments(for: url).contains("--virtual-time-budget=5000"))
    }

    @Test("the Chrome fetcher says so when Chrome is not installed, instead of returning empty HTML")
    func chromeMissing() throws {
        let fetcher = ChromeBlogFetcher(chromePath: "/nonexistent/Chrome")
        let url = try #require(URL(string: "https://example.com/"))
        #expect(throws: ChromeFetchError.notInstalled("/nonexistent/Chrome")) { try fetcher.fetch(url) }
    }

    @Test("Chrome's exit status 2 after a complete dump is accepted; a failure with no complete page is not")
    func chromeExitStatusRule() throws {
        let complete = Data("<!DOCTYPE html><html><head></head><body></body></html>\n".utf8)
        // observed 2026-11-09: --dump-dom prints the whole DOM, then Chrome logs "Teardown watchdog expired" and exits 2
        #expect(try ChromeBlogFetcher.interpret(status: 2, output: complete).hasSuffix("</html>\n"))
        #expect(try ChromeBlogFetcher.interpret(status: 0, output: complete).hasPrefix("<!DOCTYPE html>"))
        #expect(throws: ChromeFetchError.failed(status: 2)) { try ChromeBlogFetcher.interpret(status: 2, output: Data()) }
        #expect(throws: ChromeFetchError.failed(status: 2)) {
            try ChromeBlogFetcher.interpret(status: 2, output: Data("<html><head>".utf8))
        }
        #expect(throws: ChromeFetchError.undecodable) { try ChromeBlogFetcher.interpret(status: 0, output: Data([0xFF, 0xFE, 0xFD])) }
    }

    // MARK: command line

    @Test("check-blog prints the status and exits with its code (current)")
    func commandCurrent() throws {
        let stamp = try TumblrEmitter.stamp(for: .swiss)
        let html = page(style: ":root { --theme-stamp: \"\(stamp.text)\"; }")
        let result = TumblrCommand.run(["check-blog", "--theme", "swiss", "--url", "https://blog.example/"],
                                       fetcher: FakeFetcher(result: .success(html)))
        #expect(result.exitCode == 0)
        #expect(result.stdout == "blog is current (\(stamp.text))\n")
        #expect(result.stderr.isEmpty)
    }

    @Test("check-blog reports an unstamped live blog with exit 2, and a stale one with exit 1")
    func commandUnstampedAndStale() throws {
        let unstamped = TumblrCommand.run(["check-blog", "--theme", "swiss"],
                                          fetcher: FakeFetcher(result: .success(page(style: ":root{}"))))
        #expect(unstamped.exitCode == 2)
        #expect(unstamped.stdout.hasPrefix("blog is unstamped"))
        let stale = TumblrCommand.run(["check-blog", "--theme", "swiss"],
                                      fetcher: FakeFetcher(result: .success(page(style: pasted(other)))))
        #expect(stale.exitCode == 1)
        #expect(stale.stdout.contains("blog is stale: re-paste"))
        #expect(stale.stdout.contains(try TumblrEmitter.stamp(for: .swiss).text))
    }

    @Test("check-blog exits 0 for a block pasted by an older package version when the hash is the same")
    func commandVersionOnly() throws {
        var older = try TumblrEmitter.stamp(for: .swiss)
        older.version = "0.1.0"
        let html = page(style: ":root { --theme-stamp: \"\(older.text)\"; }")
        let result = TumblrCommand.run(["check-blog", "--theme", "swiss", "--url", "https://blog.example/"],
                                       fetcher: FakeFetcher(result: .success(html)))
        #expect(result.exitCode == 0)
        #expect(result.stdout.hasPrefix("blog is current: the theme, template and hash are unchanged"))
    }

    @Test("check-blog --html-file reads a saved page and never touches the fetcher")
    func commandHTMLFile() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("blogcheck-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        let file = dir.appendingPathComponent("page.html")
        try page(style: ":root{}").write(to: file, atomically: true, encoding: .utf8)
        let result = TumblrCommand.run(["check-blog", "--html-file", file.path],
                                       fetcher: FakeFetcher(result: .failure(FakeFailure(description: "must not be called"))))
        #expect(result.exitCode == 2)
    }

    @Test("check-blog defaults to the Swiss theme and the blog's address")
    func commandDefaults() {
        let result = TumblrCommand.run(["check-blog"], fetcher: FakeFetcher(result: .failure(FakeFailure(description: "boom"))))
        #expect(result.exitCode == 4)
        #expect(result.stdout.contains("https://blog.justinpurnell.com/"))
    }

    @Test("usage errors exit 64 and write to standard error")
    func commandUsage() {
        let fetcher = FakeFetcher(result: .success(""))
        for args in [[String](), ["frobnicate"], ["check-blog", "--theme"], ["check-blog", "--theme", "nonesuch"],
                     ["check-blog", "--url", "not a url"], ["check-blog", "--bogus"], ["tumblr", "--theme", "nonesuch"]] {
            let result = TumblrCommand.run(args, fetcher: fetcher)
            #expect(result.exitCode == 64, "args \(args)")
            #expect(!result.stderr.isEmpty)
            #expect(result.stdout.isEmpty)
        }
    }

    @Test("tumblr writes themes/<id>.tumblr.css under the output directory")
    func commandWritesBlock() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("tumblr-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: dir) }
        let result = TumblrCommand.run(["tumblr", "--theme", "ft", "--out", dir.path], fetcher: FakeFetcher(result: .success("")))
        #expect(result.exitCode == 0)
        let written = try String(contentsOf: dir.appendingPathComponent("themes/ft.tumblr.css"), encoding: .utf8)
        #expect(written == (try TumblrEmitter.emit(.ft)))
    }
}
