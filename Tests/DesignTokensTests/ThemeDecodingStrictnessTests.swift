import Foundation
import Testing
@testable import DesignTokens

/// `Theme`'s own `Decodable` validates, so a plain `JSONDecoder().decode(Theme.self)` is as strict as
/// `ThemeCodec.decode`. Each case below starts from a valid encoded theme and breaks exactly one thing.
@Suite("Theme decoding is strict")
struct ThemeDecodingStrictnessTests {
    // MARK: Editing a JSON tree

    private func tree(_ theme: Theme) throws -> Any {
        try JSONSerialization.jsonObject(with: ThemeCodec.encode(theme))
    }

    /// Replaces the value at `path` (dictionary keys, or array indices as numeric strings) with `transform(old)`;
    /// returning `nil` from `transform` removes a dictionary key.
    private func modify(_ node: Any, _ path: ArraySlice<String>, _ transform: (Any?) -> Any?) -> Any {
        guard let head = path.first else { return transform(node) ?? NSNull() }
        if var dictionary = node as? [String: Any] {
            if path.count == 1 {
                dictionary[head] = transform(dictionary[head])
            } else if let child = dictionary[head] {
                dictionary[head] = modify(child, path.dropFirst(), transform)
            }
            return dictionary
        }
        if var array = node as? [Any], let index = Int(head), array.indices.contains(index) {
            array[index] = modify(array[index], path.dropFirst(), transform)
            return array
        }
        return node
    }

    private func edited(_ theme: Theme, _ path: String, _ transform: (Any?) -> Any?) throws -> Data {
        let root = try tree(theme)
        let changed = modify(root, path.split(separator: ".").map(String.init)[...], transform)
        return try JSONSerialization.data(withJSONObject: changed)
    }

    /// The theme's JSON with one extra key (a string value) in the object at `path` ("" is the root).
    private func adding(_ key: String, at path: String, to theme: Theme) throws -> Data {
        let root = try tree(theme)
        let parts = path.split(separator: ".").map(String.init)[...]
        let changed = parts.isEmpty ? addKey(root, key) : modify(root, parts) { addKey($0 as Any, key) }
        return try JSONSerialization.data(withJSONObject: changed)
    }

    private func addKey(_ node: Any, _ key: String) -> Any {
        guard var dictionary = node as? [String: Any] else { return node }
        dictionary[key] = "#000000"
        return dictionary
    }

    private func message(_ error: any Error) -> String {
        switch error {
        case let decoding as DecodingError:
            switch decoding {
            case .dataCorrupted(let c), .keyNotFound(_, let c), .typeMismatch(_, let c), .valueNotFound(_, let c):
                return c.debugDescription + " @ " + c.codingPath.map(\.stringValue).joined(separator: ".")
            @unknown default: return "\(decoding)"
            }
        default: return String(describing: error)
        }
    }

    /// Both decoders must refuse `data`; returns the plain decoder's message.
    private func refusal(_ data: Data, _ label: String, sourceLocation: SourceLocation = #_sourceLocation) -> String {
        var text = ""
        do {
            _ = try JSONDecoder().decode(Theme.self, from: data)
            Issue.record("plain JSONDecoder accepted \(label)", sourceLocation: sourceLocation)
        } catch { text = message(error) }
        do {
            _ = try ThemeCodec.decode(data)
            Issue.record("ThemeCodec.decode accepted \(label)", sourceLocation: sourceLocation)
        } catch {}
        return text
    }

    // MARK: Unknown keys

    @Test("a misspelt top-level key is an error naming it, not a silent default")
    func misspeltConformance() throws {
        let data = try edited(.swiss, "conformance") { _ in nil }
        var object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        object["conformence"] = ["kind": "strict", "entries": []] as [String: Any]
        let text = refusal(try JSONSerialization.data(withJSONObject: object), "conformence")
        #expect(text.contains("conformence"), "\(text)")
    }

    @Test("an unknown key anywhere in the tree is refused with its path")
    func unknownKeysAtDepth() throws {
        let cases: [(path: String, key: String)] = [
            ("", "appearences"),
            ("palette.ink", "darkk"),
            ("palette.series.0.color", "darkIncreasd"),
            ("structure.rules.title", "wieght"),
            ("structure.layout", "annotationRadious"),
            ("structure.marks", "lineWidht"),
            ("palette.sequential", "darkk"),
            ("conformance", "entires"),
        ]
        for (path, key) in cases {
            let data = try adding(key, at: path, to: .swiss)
            let text = refusal(data, "\(path).\(key)")
            #expect(text.contains(key), "\(path): \(text)")
        }
    }

    @Test("an explicit null for an optional field is not an unknown key")
    func nullIsNotUnknown() throws {
        let data = try edited(.house, "palette.ink") { old in
            guard var dictionary = old as? [String: Any] else { return old }
            dictionary["dark"] = NSNull()
            dictionary["system"] = NSNull()
            return dictionary
        }
        #expect(try JSONDecoder().decode(Theme.self, from: data) == Theme.house)
    }

    // MARK: Dangling references

    @Test("a colour override that names no role and no extra is refused")
    func danglingColourOverride() throws {
        let changed = try edited(.legacyDefault, "palette.colourOverrides") { old in
            guard var dictionary = old as? [String: Any] else { return old }
            dictionary["tornado.low"] = ["source": "ghost", "opacity": 1]
            return dictionary
        }
        let text = refusal(changed, "dangling colourOverride")
        #expect(text.contains("ghost") && text.contains("tornado.low"), "\(text)")
    }

    @Test("a ramp override that names no ramp is refused; sequential, diverging and extraRamps are valid targets")
    func danglingRampOverride() throws {
        let changed = try edited(.legacyDefault, "palette.rampOverrides") { old in
            guard var dictionary = old as? [String: Any] else { return old }
            dictionary["efficientfrontier"] = "ghost"
            return dictionary
        }
        let text = refusal(changed, "dangling rampOverride")
        #expect(text.contains("ghost") && text.contains("efficientfrontier"), "\(text)")
        for target in ["sequential", "diverging", "sharpe"] {
            let fine = try edited(.legacyDefault, "palette.rampOverrides") { old in
                guard var dictionary = old as? [String: Any] else { return old }
                dictionary["efficientfrontier"] = target
                return dictionary
            }
            #expect(throws: Never.self, "\(target)") { try JSONDecoder().decode(Theme.self, from: fine) }
        }
    }

    @Test("a shadow colour that names no role and no extra is refused")
    func danglingShadowSource() throws {
        let changed = try edited(.legacyDefault, "structure.layout.shadow.colour.source") { _ in "ghost" }
        let text = refusal(changed, "dangling shadow")
        #expect(text.contains("ghost") && text.contains("shadow"), "\(text)")
    }

    @Test("an opacity outside 0 to 1 in a colour reference is refused")
    func opacityOutOfRange() throws {
        let changed = try edited(.legacyDefault, "structure.layout.shadow.colour.opacity") { _ in 1.5 }
        let text = refusal(changed, "opacity 1.5")
        #expect(text.contains("opacity"), "\(text)")
    }

    // MARK: Numbers and shapes

    @Test("a negative rule weight is refused, naming the weight")
    func negativeRuleWeight() throws {
        for path in ["structure.rules.gridline", "structure.rules.title.weight", "structure.rules.reference.weight"] {
            let text = refusal(try edited(.swiss, path) { _ in -1 }, path)
            #expect(text.contains("rules") && text.contains("negative"), "\(path): \(text)")
        }
    }

    @Test("a ramp whose dark and light steps differ in number is refused")
    func rampLengthParity() throws {
        let changed = try edited(.swiss, "palette.sequential.dark") { old in
            guard let array = old as? [Any] else { return old }
            return Array(array.dropLast())
        }
        let text = refusal(changed, "sequential dark one short")
        #expect(text.contains("sequential") && text.contains("dark"), "\(text)")
        let extra = try edited(.legacyDefault, "palette.extraRamps.sharpe") { old in
            guard var dictionary = old as? [String: Any], let light = dictionary["light"] as? [Any] else { return old }
            dictionary["dark"] = light + light
            return dictionary
        }
        #expect(refusal(extra, "extra ramp dark twice as long").contains("sharpe"))
    }

    @Test("a strict theme that carries ledger entries is refused")
    func strictWithEntries() throws {
        let data = try edited(.swiss, "conformance.kind") { _ in "strict" }
        let text = refusal(data, "strict with swiss's entries")
        #expect(text.contains("strict"), "\(text)")
    }

    @Test("a theme whose dark values contradict its appearances is refused by the plain decoder, as ThemeError.invalid")
    func plainDecoderChecksAppearances() throws {
        let data = try edited(.swiss, "palette.ink.dark") { _ in nil }
        #expect(throws: ThemeError.invalid([AppearanceIssue(kind: .missingDark, subject: "palette.ink")])) {
            try JSONDecoder().decode(Theme.self, from: data)
        }
        #expect(throws: ThemeError.invalid([AppearanceIssue(kind: .missingDark, subject: "palette.ink")])) {
            try ThemeCodec.decode(data)
        }
    }

    // MARK: Defaults only where the format has gained fields

    @Test("fields added in 0.5.0 are required: removing conformance, extras, colourOverrides or rampOverrides is an error")
    func since050FieldsAreRequired() throws {
        for path in ["conformance", "palette.extras", "palette.colourOverrides", "palette.rampOverrides"] {
            let data = try edited(.swiss, path) { _ in nil }
            let text = refusal(data, "missing \(path)")
            #expect(text.contains(path.split(separator: ".").last.map(String.init) ?? path), "\(path): \(text)")
        }
    }

    @Test("fields added in 0.6.0 may be absent and take their documented defaults")
    func since060FieldsDefault() throws {
        var data = try edited(.swiss, "structure.layout.annotationRadius") { _ in nil }
        for key in ["areaOpacity", "fillOpacity", "detailLineWidth"] {
            let object = try JSONSerialization.jsonObject(with: data)
            data = try JSONSerialization.data(withJSONObject: modify(object, ["structure", "marks", key]) { _ in nil })
        }
        let decoded = try JSONDecoder().decode(Theme.self, from: data)
        #expect(decoded.structure.layout.annotationRadius == 0)
        #expect(decoded.structure.marks.areaOpacity == MarkSpec.defaultAreaOpacity)
        #expect(decoded.structure.marks.fillOpacity == MarkSpec.defaultFillOpacity)
        #expect(decoded.structure.marks.detailLineWidth == MarkSpec.defaultDetailLineWidth)
        #expect(decoded == Theme.swiss)
    }

    @Test("required fields stay required: a missing structure or id is an error")
    func requiredFields() throws {
        for path in ["structure", "id", "palette.series", "palette.ink"] {
            #expect(!refusal(try edited(.swiss, path) { _ in nil }, "missing \(path)").isEmpty, "\(path)")
        }
    }

    // MARK: Everything we ship is still accepted

    @Test("every registered theme decodes with a plain JSONDecoder, and so does every committed theme file")
    func shippedThemesDecode() throws {
        for theme in Theme.all {
            let data = try ThemeCodec.encode(theme)
            #expect(try JSONDecoder().decode(Theme.self, from: data) == theme, "\(theme.id)")
            #expect(try ThemeCodec.decode(data) == theme, "\(theme.id)")
        }
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        for theme in Theme.all {
            let file = root.appendingPathComponent("Generated/themes/\(theme.id).json")
            #expect(try ThemeCodec.decode(Data(contentsOf: file)) == theme, "\(theme.id).json")
        }
    }
}
