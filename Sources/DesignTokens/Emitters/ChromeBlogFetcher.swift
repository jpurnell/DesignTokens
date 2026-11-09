import Foundation

/// Why Chrome could not produce a page.
public enum ChromeFetchError: Error, Sendable, Equatable, CustomStringConvertible {
    /// No executable at the path.
    case notInstalled(String)
    /// Chrome ran and failed.
    case failed(status: Int32)
    /// Chrome printed something that is not UTF-8.
    case undecodable
    /// Chrome did not finish in time and was killed.
    case timedOut(seconds: Double)

    /// A sentence for the terminal.
    public var description: String {
        switch self {
        case .notInstalled(let path): "Google Chrome is not installed at \(path)"
        case .failed(let status): "Chrome exited with status \(status)"
        case .undecodable: "Chrome's output was not UTF-8"
        case .timedOut(let seconds): "Chrome did not finish within \(Int(seconds)) seconds and was stopped"
        }
    }
}

/// Fetches a page's rendered DOM with headless Chrome.
///
/// **Needs a local Google Chrome.** `https://blog.justinpurnell.com` answers a plain HTTP request with 403 and a
/// JavaScript challenge, so the page has to be loaded by a browser that runs the challenge. Run as
/// `Chrome --headless=new --disable-gpu --virtual-time-budget=20000 --dump-dom URL`, that browser returned the real page
/// on the home page and `/page/2` (2026-11-09; see the proposal). It is not exercised by the test suite, which has
/// no network and no browser guarantee: the tests cover the arguments and the missing-Chrome error, and the
/// comparison is tested through a fake ``BlogFetching``.
public struct ChromeBlogFetcher: BlogFetching {
    /// The path of the Chrome executable.
    public var chromePath: String
    /// How much virtual time Chrome may spend letting the page's scripts run, in milliseconds.
    public var virtualTimeBudgetMs: Int
    /// A wall-clock limit in seconds, after which Chrome is terminated.
    public var timeoutSeconds: Double

    /// Creates a fetcher.
    public init(chromePath: String = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
                virtualTimeBudgetMs: Int = 20_000, timeoutSeconds: Double = 120) {
        self.chromePath = chromePath
        self.virtualTimeBudgetMs = virtualTimeBudgetMs
        self.timeoutSeconds = timeoutSeconds
    }

    /// The command-line arguments for a page.
    public func arguments(for url: URL) -> [String] {
        ["--headless=new", "--disable-gpu", "--virtual-time-budget=\(virtualTimeBudgetMs)", "--dump-dom", url.absoluteString]
    }

    /// The rendered DOM of `url`.
    ///
    /// - Throws: ``ChromeFetchError``.
    public func fetch(_ url: URL) throws -> String {
        guard FileManager.default.isExecutableFile(atPath: chromePath) else {
            throw ChromeFetchError.notInstalled(chromePath)
        }
        let output: BoundedProcess.Output
        do {
            output = try BoundedProcess.run(chromePath, arguments: arguments(for: url), timeout: timeoutSeconds)
        } catch BoundedProcess.Failure.timedOut {
            throw ChromeFetchError.timedOut(seconds: timeoutSeconds)
        } catch {
            throw ChromeFetchError.notInstalled(chromePath)
        }
        return try Self.interpret(status: output.exitCode, output: output.stdout)
    }

    /// Decides whether Chrome's run produced a page.
    ///
    /// Observed on 2026-11-09: `--dump-dom` prints the whole DOM and then Chrome logs "Teardown watchdog expired" and
    /// exits with status 2. So a non-zero status is not a failure by itself; a failure is a non-zero status with no
    /// complete document (one that does not end in `</html>`).
    static func interpret(status: Int32, output: Data) throws -> String {
        guard let html = String(data: output, encoding: .utf8) else { throw ChromeFetchError.undecodable }
        guard status == 0 || html.trimmingCharacters(in: .whitespacesAndNewlines).hasSuffix("</html>") else {
            throw ChromeFetchError.failed(status: status)
        }
        return html
    }
}
