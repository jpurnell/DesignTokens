import Foundation

/// The result of running a subcommand: what to print and how to exit.
public struct CommandResult: Sendable, Equatable {
    /// The process exit code.
    public var exitCode: Int32
    /// Text for standard output.
    public var stdout: String
    /// Text for standard error.
    public var stderr: String

    /// Creates a result.
    public init(exitCode: Int32, stdout: String = "", stderr: String = "") {
        self.exitCode = exitCode
        self.stdout = stdout
        self.stderr = stderr
    }
}

/// The `tumblr` and `check-blog` subcommands of `design-tokens`.
///
/// ```
/// design-tokens tumblr [--theme ID] [--out DIR] [--full [--wordmark TEXT] [--wordmark-url URL] [--parent-url URL --parent-label TEXT] [--rel-me URL] [--gtm GTM-XXXX]]
/// design-tokens check-blog [--theme ID] [--url URL] [--html-file PATH]
/// ```
///
/// `tumblr` writes `DIR/themes/ID.tumblr.css` (default `Generated`); with `--full` it also writes the complete theme document
/// `DIR/themes/ID.tumblr.html` (``TumblrThemeEmitter``), filling the per-blog values from the options (none given: placeholders). `check-blog` prints one line and exits 0 (current),
/// 1 (stale), 2 (unstamped), 3 (garbled stamp) or 4 (page could not be read); usage errors exit 64. The page comes
/// from `--html-file` when given, otherwise from the fetcher, which the executable makes a ``ChromeBlogFetcher``.
public enum TumblrCommand {
    /// The subcommand names this type handles.
    public static let names: Set<String> = ["tumblr", "check-blog"]

    /// The blog's address, the default for `check-blog`.
    public static let defaultURL = "https://blog.justinpurnell.com/"

    private static let usage = "usage: design-tokens tumblr [--theme ID] [--out DIR] [--full [--wordmark TEXT] [--wordmark-url URL]\n"
        + "           [--parent-url URL --parent-label TEXT] [--rel-me URL] [--gtm GTM-XXXX]]\n"
        + "       design-tokens check-blog [--theme ID] [--url URL] [--html-file PATH]"

    /// Runs a subcommand. `arguments` starts with the subcommand's name.
    public static func run(_ arguments: [String], fetcher: any BlogFetching) -> CommandResult {
        guard let name = arguments.first, names.contains(name) else {
            return usageError("unknown or missing subcommand")
        }
        let fullOptions = ["--wordmark", "--wordmark-url", "--parent-url", "--parent-label", "--rel-me", "--gtm"]
        let allowed = name == "tumblr" ? ["--theme", "--out"] + fullOptions : ["--theme", "--url", "--html-file"]
        var options: [String: String] = [:]
        var full = false
        var rest = arguments.dropFirst()
        while let flag = rest.popFirst() {
            if flag == "--full", name == "tumblr" {
                full = true
                continue
            }
            guard allowed.contains(flag) else { return usageError("unknown option \(flag)") }
            guard let value = rest.popFirst() else { return usageError("\(flag) needs a value") }
            options[flag] = value
        }
        let themeID = options["--theme"] ?? "swiss"
        guard let theme = Theme.named(themeID) else {
            return usageError("no theme named \(themeID); known: \(Theme.all.map(\.id).joined(separator: ", "))")
        }
        guard name == "tumblr" else { return check(theme, options, fetcher) }
        guard full || !options.keys.contains(where: { fullOptions.contains($0) }) else {
            return usageError("\(options.keys.filter { fullOptions.contains($0) }.sorted().joined(separator: ", ")) only apply with --full")
        }
        var html: String?
        if full {
            do {
                html = try TumblrThemeEmitter.emit(theme, parameters: parameters(options))
            } catch {
                return CommandResult(exitCode: error is TumblrThemeError ? 64 : 1, stderr: "design-tokens: \(error)\n")
            }
        }
        return write(theme, to: options["--out"] ?? "Generated", html: html)
    }

    private static func parameters(_ options: [String: String]) throws -> TumblrThemeParameters {
        var parent: TumblrParentSite?
        switch (options["--parent-url"], options["--parent-label"]) {
        case (let url?, let label?): parent = TumblrParentSite(url: url, label: label)
        case (nil, nil): parent = nil
        default: throw TumblrThemeError.invalid(parameter: "parent", reason: "--parent-url and --parent-label go together")
        }
        return try TumblrThemeParameters(wordmark: options["--wordmark"], wordmarkURL: options["--wordmark-url"] ?? "/",
                                         parentSite: parent, relMeURL: options["--rel-me"], analyticsID: options["--gtm"])
    }

    private static func write(_ theme: Theme, to directory: String, html: String?) -> CommandResult {
        do {
            let folder = URL(fileURLWithPath: directory, isDirectory: true).appendingPathComponent("themes", isDirectory: true)
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            let file = folder.appendingPathComponent("\(theme.id).tumblr.css")
            try TumblrEmitter.emit(theme).write(to: file, atomically: true, encoding: .utf8)
            var out = "wrote \(file.path) (\(try TumblrEmitter.stamp(for: theme).text))\n"
            if let html {
                let page = folder.appendingPathComponent("\(theme.id).tumblr.html")
                try html.write(to: page, atomically: true, encoding: .utf8)
                out += "wrote \(page.path)\n"
            }
            return CommandResult(exitCode: 0, stdout: out)
        } catch {
            return CommandResult(exitCode: 1, stderr: "design-tokens: \(error)\n")
        }
    }

    private static func check(_ theme: Theme, _ options: [String: String], _ fetcher: any BlogFetching) -> CommandResult {
        let stamp: BlogStamp
        do {
            stamp = try TumblrEmitter.stamp(for: theme)
        } catch {
            return CommandResult(exitCode: 1, stderr: "design-tokens: \(error)\n")
        }
        let status: BlogStatus
        if let path = options["--html-file"] {
            guard let html = try? String(contentsOfFile: path, encoding: .utf8) else {
                return report(.unreadable("could not read \(path)"))
            }
            status = BlogChecker.compare(html: html, expected: stamp)
        } else {
            let address = options["--url"] ?? defaultURL
            guard let url = webURL(address) else { return usageError("\(address) is not an http or https URL") }
            status = BlogChecker.check(url: url, expected: stamp, fetcher: fetcher)
        }
        return report(status)
    }

    private static func report(_ status: BlogStatus) -> CommandResult {
        CommandResult(exitCode: status.exitCode, stdout: status.message + "\n")
    }

    private static func webURL(_ text: String) -> URL? {
        guard !text.contains(where: { $0.isWhitespace }), let url = URL(string: text),
              let scheme = url.scheme?.lowercased(), scheme == "http" || scheme == "https",
              let host = url.host, !host.isEmpty else { return nil }
        return url
    }

    private static func usageError(_ why: String) -> CommandResult {
        CommandResult(exitCode: 64, stderr: "design-tokens: \(why)\n\(usage)\n")
    }
}
