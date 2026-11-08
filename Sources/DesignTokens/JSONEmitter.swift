/// Emits the tokens as JSON for tools that cannot import Swift.
///
/// The text is built by hand, with sorted keys and fixed spacing, so the output is identical on every
/// platform and can be compared byte for byte with the checked-in copy.
public enum JSONEmitter {
    /// The complete document, ending in a newline.
    public static func emit() -> String {
        let colors = ColorToken.allCases.sorted { $0.rawValue < $1.rawValue }.map { token -> String in
            var fields = ["      \"light\": \"\(token.light.hex)\""]
            if let dark = token.dark { fields.insert("      \"dark\": \"\(dark.hex)\"", at: 0) }
            return "    \"\(token.rawValue)\": {\n" + fields.joined(separator: ",\n") + "\n    }"
        }
        let series = zip(Palette.seriesNames, Palette.series).map { "      { \"name\": \"\($0)\", \"hex\": \"\($1.hex)\" }" }
        let rules = Rule.allCases.sorted { $0.name < $1.name }.map { "    \"\($0.name)\": \($0.points)" }
        let lines = [
            "{",
            "  \"colors\": {",
            colors.joined(separator: ",\n"),
            "  },",
            "  \"grid\": { \"baseUnit\": \(Grid.baseUnit), \"columns\": \(Grid.columns), \"gutter\": \(Grid.gutter) },",
            "  \"palette\": {",
            "    \"diverging\": [\(list(Palette.diverging))],",
            "    \"princetonAccent\": \"\(Palette.princetonAccent.hex)\",",
            "    \"sequential\": [\(list(Palette.sequential))],",
            "    \"series\": [",
            series.joined(separator: ",\n"),
            "    ]",
            "  },",
            "  \"radius\": { \"container\": \(Radius.container), \"control\": \(Radius.control) },",
            "  \"rules\": {",
            rules.joined(separator: ",\n"),
            "  },",
            "  \"systemRelease\": \"\(Snapshot.systemRelease)\"",
            "}",
        ]
        return lines.joined(separator: "\n") + "\n"
    }

    private static func list(_ colors: [RGB]) -> String {
        colors.map { "\"\($0.hex)\"" }.joined(separator: ", ")
    }
}
