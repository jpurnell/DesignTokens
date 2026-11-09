import Foundation

/// A decoded JSON tree: only its shape (which keys an object carries), not its values.
///
/// ``Theme``'s decoder reads the input twice, once into the model and once into this, to find keys the model
/// does not have. Synthesised `Codable` ignores them, so a misspelt `darkIncreasd` would otherwise be a
/// silently missing value.
indirect enum RawJSON: Decodable {
    case null
    case scalar
    case array([RawJSON])
    case object([String: RawJSON])

    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
            return
        }
        // a value that is not an array or an object is a scalar, whose value this type does not keep
        do {
            self = .array(try container.decode([RawJSON].self))
            return
        } catch let error as DecodingError {
            guard case .typeMismatch = error else { throw error }
        }
        do {
            self = .object(try container.decode([String: RawJSON].self))
            return
        } catch let error as DecodingError {
            guard case .typeMismatch = error else { throw error }
        }
        self = .scalar
    }

    /// The paths of keys in `self` that `known` (the same document as the model writes it) does not have.
    /// An explicit `null` is not a key: the model leaves an absent optional out.
    func unknownKeys(comparedWith known: RawJSON, path: String = "") -> [String] {
        switch (self, known) {
        case (.object(let given), .object(let expected)):
            var found: [String] = []
            for key in given.keys.sorted() {
                guard let value = given[key] else { continue }
                if case .null = value { continue }
                let here = path.isEmpty ? key : "\(path).\(key)"
                guard let counterpart = expected[key] else { found.append(here); continue }
                found += value.unknownKeys(comparedWith: counterpart, path: here)
            }
            return found
        case (.array(let given), .array(let expected)):
            return given.indices.filter { expected.indices.contains($0) }.flatMap {
                given[$0].unknownKeys(comparedWith: expected[$0], path: "\(path)[\($0)]")
            }
        default:
            return []
        }
    }
}

extension Theme {
    /// What is wrong with the theme besides its appearance support (see ``appearanceIssues``), as sentences.
    /// Empty means consistent. The same list gates decoding and encoding, so the codec writes nothing it
    /// would refuse to read.
    ///
    /// - A per-chart colour override, or the shadow colour, names something that is neither a ``ColorRole`` nor
    ///   a key of ``ThemePalette/extras``, or has an opacity outside 0 to 1.
    /// - A ramp override names something that is neither `sequential`, `diverging` nor a key of
    ///   ``ThemePalette/extraRamps``.
    /// - A rule weight is negative or not a number.
    /// - A ramp has a dark version with a different number of steps from its light one.
    /// - The conformance is ``Conformance/strict`` and still carries ledger entries.
    var consistencyProblems: [String] {
        var problems: [String] = []
        let roles = Set(ColorRole.allCases.map(\.rawValue))
        let colourNames = roles.union(palette.extras.keys)
        func check(_ reference: ColourReference, _ subject: String) {
            if !colourNames.contains(reference.source) {
                problems.append("\(subject) names \"\(reference.source)\", which is neither a colour role nor a key of palette.extras")
            }
            if !(0...1).contains(reference.opacity) {
                problems.append("\(subject) has opacity \(reference.opacity), outside 0 to 1")
            }
        }
        for key in palette.colourOverrides.keys.sorted() {
            if let reference = palette.colourOverrides[key] { check(reference, "palette.colourOverrides[\"\(key)\"]") }
        }
        if let shadow = structure.layout.shadow { check(shadow.colour, "structure.layout.shadow.colour") }
        let rampNames = Set(["sequential", "diverging"]).union(palette.extraRamps.keys)
        for key in palette.rampOverrides.keys.sorted() {
            if let target = palette.rampOverrides[key], !rampNames.contains(target) {
                problems.append("palette.rampOverrides[\"\(key)\"] names \"\(target)\", which is no ramp (sequential, diverging or a key of palette.extraRamps)")
            }
        }
        let rules = structure.rules
        let weights: [(String, Double)] = [
            ("structure.rules.title.weight", rules.title.weight), ("structure.rules.section", rules.section),
            ("structure.rules.hairline", rules.hairline), ("structure.rules.gridline", rules.gridline),
            ("structure.rules.baseline", rules.baseline), ("structure.rules.page", rules.page),
            ("structure.rules.reference.weight", rules.reference.weight), ("structure.rules.plotBorder", rules.plotBorder),
        ]
        for (subject, weight) in weights where !(weight.isFinite && weight >= 0) {
            problems.append("\(subject) is negative or not a number (\(weight))")
        }
        func parity(_ ramp: Ramp, _ subject: String) {
            if let dark = ramp.dark, dark.count != ramp.light.count {
                problems.append("\(subject) has \(ramp.light.count) light steps and \(dark.count) dark steps; a dark ramp has as many steps as the light one")
            }
        }
        parity(palette.sequential, "palette.sequential")
        parity(palette.diverging, "palette.diverging")
        for key in palette.extraRamps.keys.sorted() {
            if let ramp = palette.extraRamps[key] { parity(ramp, "palette.extraRamps.\(key)") }
        }
        if conformance.kind == .strict, !conformance.entries.isEmpty {
            problems.append("conformance is strict but carries \(conformance.entries.count) ledger entries; a strict theme has none")
        }
        return problems
    }
}
