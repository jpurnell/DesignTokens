import DesignTokens
import Foundation

/// `tumblr` and `check-blog` are handled by ``TumblrCommand``; the rest of this file is unchanged.
let arguments = Array(CommandLine.arguments.dropFirst())
if let name = arguments.first, TumblrCommand.names.contains(name) {
    let result = TumblrCommand.run(arguments, fetcher: ChromeBlogFetcher())
    FileHandle.standardOutput.write(Data(result.stdout.utf8))
    FileHandle.standardError.write(Data(result.stderr.utf8))
    exit(result.exitCode)
}

/// Writes `tokens.css` and `tokens.json` into a directory (default `Generated`).
let directory = CommandLine.arguments.dropFirst().first ?? "Generated"
let base = URL(fileURLWithPath: directory, isDirectory: true)
do {
    try FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
    try CSSEmitter.emit().write(to: base.appendingPathComponent("tokens.css"), atomically: true, encoding: .utf8)
    try JSONEmitter.emit().write(to: base.appendingPathComponent("tokens.json"), atomically: true, encoding: .utf8)
} catch {
    FileHandle.standardError.write(Data("design-tokens: \(error)\n".utf8))
    exit(1)
}
