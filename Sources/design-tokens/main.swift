import DesignTokens
import Foundation

/// `tumblr` and `check-blog` are handled by ``TumblrCommand``; everything else goes to ``Generator``.
let arguments = Array(CommandLine.arguments.dropFirst())
if let name = arguments.first, TumblrCommand.names.contains(name) {
    let result = TumblrCommand.run(arguments, fetcher: ChromeBlogFetcher())
    FileHandle.standardOutput.write(Data(result.stdout.utf8))
    FileHandle.standardError.write(Data(result.stderr.utf8))
    exit(result.exitCode)
}

/// `design-tokens [emit] [--all | --theme <id>] [directory]` writes the generated files (default directory
/// `Generated`); `design-tokens list` prints the registered theme ids.
do {
    let isList = CommandLine.arguments.dropFirst().first == "list"
    let results = try Generator.run(arguments: Array(CommandLine.arguments.dropFirst()))
    for line in results { FileHandle.standardOutput.write(Data((isList ? line : "wrote \(line)").utf8 + [0x0A])) }
} catch {
    FileHandle.standardError.write(Data("design-tokens: \(error)\n".utf8))
    exit(1)
}
