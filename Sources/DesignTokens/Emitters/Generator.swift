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

/// A kind of generated file, for `design-tokens emit --format`.
public enum GeneratedFormat: String, Sendable, Hashable, CaseIterable {
    /// `tokens.css` and `themes/<id>.css`.
    case css
    /// `tokens.json` and `themes/<id>.json`.
    case json
    /// The Tumblr paste-in block and the full theme document (Swiss only in the committed set).
    case tumblr
    /// `themes/<id>.ansi.txt`.
    case ansi
    /// `themes/<id>.slides.txt`, `.slides.fonts.xml` and `.slides.colors.<appearance>.xml`.
    case slides
    /// `components.css`, the web component stylesheet (``ComponentsCSSEmitter``).
    case components
}

/// Why the generator refused its arguments.
public enum GeneratorError: Error, Sendable, Equatable {
    /// No registered theme has this id.
    case unknownTheme(String)
    /// An argument the generator does not know.
    case unknownArgument(String)
    /// `--format` names no format (the known ones are css, json, tumblr, ansi, slides and components).
    case unknownFormat(String)
    /// A flag that needs a value has none.
    case missingValue(String)
}

/// The generator behind `design-tokens`: plans the files, writes them, and answers `list`.
///
/// The set is `tokens.css` and `tokens.json` (the default look, unchanged since 0.3.0), `components.css` (0.12.0) and, for each theme in
/// ``Theme/all``, `themes/<id>.css` and `themes/<id>.json`, plus `themes/swiss.tumblr.css` (the Tumblr paste-in block,
/// for the one theme the blog uses; `design-tokens tumblr --theme <id>` can write any other on request, uncommitted).
/// `themes/swiss.tumblr.html` is the complete Tumblr theme document, with placeholders for the blog's own values.
/// Each theme also has the terminal table `themes/<id>.ansi.txt` (``ANSIEmitter``) and the slide files
/// (``SlidesEmitter``): `themes/<id>.slides.txt`, `themes/<id>.slides.fonts.xml` and one
/// `themes/<id>.slides.colors.<appearance>.xml` per appearance (`light`, `dark`; the increased-contrast slots are in the list only). Every file is committed and golden-tested.
public enum Generator {
    /// The theme whose Tumblr paste-in block is part of the committed file set.
    public static let tumblrThemeID = "swiss"

    /// Every generated file, in a stable order: the two default files, then each theme's files (CSS, JSON, Tumblr block and full theme for
    /// Swiss, terminal, slides).
    ///
    /// - Parameters:
    ///   - themes: The themes to emit.
    ///   - includeDefaults: Whether to include `tokens.css` and `tokens.json`.
    ///   - formats: The kinds of file to keep, or `nil` for all of them.
    public static func files(for themes: [Theme] = Theme.all, includeDefaults: Bool = true,
                             formats: Set<GeneratedFormat>? = nil) throws -> [GeneratedFile] {
        var files: [(GeneratedFormat, GeneratedFile)] = []
        if includeDefaults {
            files.append((.css, GeneratedFile(path: "tokens.css", contents: CSSEmitter.emit())))
            files.append((.json, GeneratedFile(path: "tokens.json", contents: JSONEmitter.emit())))
            files.append((.components, GeneratedFile(path: "components.css", contents: ComponentsCSSEmitter.emit())))
        }
        for theme in themes {
            files.append((.css, GeneratedFile(path: "themes/\(theme.id).css", contents: try ThemeCSSEmitter.emit(theme))))
            files.append((.json, GeneratedFile(path: "themes/\(theme.id).json", contents: try ThemeJSONEmitter.emit(theme))))
            if theme.id == tumblrThemeID {
                files.append((.tumblr, GeneratedFile(path: "themes/\(theme.id).tumblr.css", contents: try TumblrEmitter.emit(theme))))
                files.append((.tumblr, GeneratedFile(path: "themes/\(theme.id).tumblr.html", contents: try TumblrThemeEmitter.emit(theme))))
            }
            files.append((.ansi, GeneratedFile(path: "themes/\(theme.id).ansi.txt", contents: try ANSIEmitter.emit(theme))))
            files.append((.slides, GeneratedFile(path: "themes/\(theme.id).slides.txt", contents: try SlidesEmitter.emitList(theme))))
            files.append((.slides, GeneratedFile(path: "themes/\(theme.id).slides.fonts.xml", contents: try SlidesEmitter.emitFontScheme(theme))))
            for slot in ThemeSlot.slots(for: theme) where !slot.increasedContrast {
                files.append((.slides, GeneratedFile(path: "themes/\(theme.id).slides.colors.\(slot.name).xml",
                                                     contents: try SlidesEmitter.emitColourScheme(theme, slot: slot))))
            }
        }
        return files.filter { formats?.contains($0.0) ?? true }.map(\.1)
    }

    /// Runs the command line: `[emit] [--all | --theme <id>] [--components] [--format <name>[,<name>]]... [directory]`, or `list`.
    ///
    /// `--components` keeps `components.css` (alone, or with the kinds `--format` names); `--all`, the default, includes it.
    ///
    /// With no arguments, or only a directory (the form `design-tokens Generated` has always had), every file is
    /// written. `--theme <id>` writes that theme's files only. `--format` (repeatable, or comma-separated) keeps only those kinds of file
/// (css, json, tumblr, ansi, slides, components); with no `--theme` the two default files count as css and json. `list` returns the theme ids and writes nothing.
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
        var formats: Set<GeneratedFormat>?
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
            case "--components":
                formats = (formats ?? []).union([.components])
            case "--format":
                guard index + 1 < arguments.count else { throw GeneratorError.missingValue("--format") }
                index += 1
                var chosen = formats ?? []
                for name in arguments[index].split(separator: ",").map(String.init) {
                    guard let format = GeneratedFormat(rawValue: name) else { throw GeneratorError.unknownFormat(name) }
                    chosen.insert(format)
                }
                guard !chosen.isEmpty else { throw GeneratorError.unknownFormat(arguments[index]) }
                formats = chosen
            default:
                guard !argument.hasPrefix("--"), directory == nil else { throw GeneratorError.unknownArgument(argument) }
                directory = argument
            }
            index += 1
        }
        let files: [GeneratedFile]
        if let themeID {
            guard let theme = Theme.named(themeID) else { throw GeneratorError.unknownTheme(themeID) }
            files = try Self.files(for: [theme], includeDefaults: false, formats: formats)
        } else {
            files = try Self.files(formats: formats)
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
