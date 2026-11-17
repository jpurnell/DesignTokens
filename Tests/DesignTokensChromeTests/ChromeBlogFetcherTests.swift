#if os(macOS) || os(Linux)
import Foundation
import Testing
import DesignTokens
@testable import DesignTokensChrome

@Suite("Chrome blog fetcher")
struct ChromeBlogFetcherTests {
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
}
#endif
