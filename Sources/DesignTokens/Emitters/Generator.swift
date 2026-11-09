import Foundation

/// A file the generator writes, as a path relative to the output directory and its text.
public struct GeneratedFile: Sendable, Hashable {
    /// The path relative to the output directory: `themes/swiss.css`.
    public var path: String
    /// The file's text.
    public var contents: String

    /// Creates a generated file.
    public init(path: String, contents: String) {
        self.path = path
        self.contents = contents
    }
}

/// Why the generator refused its arguments.
public enum GeneratorError: Error, Sendable, Equatable {
    /// No registered theme has this id.
    case unknownTheme(String)
    /// An argument the generator does not know.
    case unknownArgument(String)
    /// A flag that needs a value has none.
    case missingValue(String)
}

/// The generator behind `design-tokens`: plans the files, writes them, and answers `list`.
///
/// The set is `tokens.css` and `tokens.json` (the default look, unchanged since 0.3.0) and, for each theme in
/// ``Theme/all``, `themes/<id>.css` and `themes/<id>.json`. Every file is committed and golden-tested.
public enum Generator {
    /// Every generated file, in a stable order: the two default files, then each theme's CSS and JSON.
    ///
    /// - Parameters:
    ///   - themes: The themes to emit.
    ///   - includeDefaults: Whether to include `tokens.css` and `tokens.json`.
    public static func files(for themes: [Theme] = Theme.all, includeDefaults: Bool = true) throws -> [GeneratedFile] {
        var files: [GeneratedFile] = []
        if includeDefaults {
            files.append(GeneratedFile(path: "tokens.css", contents: CSSEmitter.emit()))
            files.append(GeneratedFile(path: "tokens.json", contents: JSONEmitter.emit()))
        }
        for theme in themes {
            files.append(GeneratedFile(path: "themes/\(theme.id).css", contents: try ThemeCSSEmitter.emit(theme)))
            files.append(GeneratedFile(path: "themes/\(theme.id).json", contents: try ThemeJSONEmitter.emit(theme)))
        }
        return files
    }

    /// Runs the command line: `[emit] [--all | --theme <id>] [directory]`, or `list`.
    ///
    /// With no arguments, or only a directory (the form `design-tokens Generated` has always had), every file is
    /// written. `--theme <id>` writes that theme's pair only. `list` returns the theme ids and writes nothing.
    /// Arguments are checked before anything is written, so a refusal leaves the directory alone.
    ///
    /// - Returns: The paths written (relative to the directory), or the theme ids for `list`.
    /// - Throws: ``GeneratorError`` for an unknown theme, flag or missing value; a file error from writing.
    @discardableResult
    public static func run(arguments: [String], defaultDirectory: String = "Generated") throws -> [String] {
        var arguments = arguments
        if arguments.first == "list" { return Theme.all.map(\.id) }
        if arguments.first == "emit" { arguments.removeFirst() }
        var themeID: String?
        var directory: String?
        var index = 0
        while index < arguments.count {
            let argument = arguments[index]
            switch argument {
            case "--all":
                themeID = nil
            case "--theme":
                guard index + 1 < arguments.count else { throw GeneratorError.missingValue("--theme") }
                index += 1
                themeID = arguments[index]
            default:
                guard !argument.hasPrefix("--"), directory == nil else { throw GeneratorError.unknownArgument(argument) }
                directory = argument
            }
            index += 1
        }
        let files: [GeneratedFile]
        if let themeID {
            guard let theme = Theme.named(themeID) else { throw GeneratorError.unknownTheme(themeID) }
            files = try Self.files(for: [theme], includeDefaults: false)
        } else {
            files = try Self.files()
        }
        let base = URL(fileURLWithPath: directory ?? defaultDirectory, isDirectory: true)
        for file in files {
            let url = base.appendingPathComponent(file.path)
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try file.contents.write(to: url, atomically: true, encoding: .utf8)
        }
        return files.map(\.path)
    }
}
