import Foundation
import Testing
@testable import DesignTokens

/// The structure fields added to express the approved Swiss and Apple "Hybrid" chart (audit
/// `project/plans/proposals/2026-11-09_ChartAlignmentToApprovedDesign.md`, section 4). Every new field defaults to
/// today's behaviour; only Swiss (and Princeton, which is built on Swiss's structure) opt in.
@Suite("Chart alignment: structure")
struct ChartAlignmentStructureTests {
    /// The themes whose behaviour must not change. Enumerated, not derived from `Theme.all`.
    private static let unchangedIDs = ["house", "ft", "economist", "legacy-default", "legacy-dark", "legacy-financial", "legacy-accessible"]

    private static var unchanged: [Theme] { unchangedIDs.compactMap { Theme.named($0) } }

    // MARK: The new fields default to today's behaviour

    @Test("the seven unchanged themes carry every new field at its default")
    func unchangedThemesAreAtDefaults() {
        #expect(Self.unchanged.count == 7)
        for theme in Self.unchanged {
            let s = theme.structure
            #expect(s.marks.defaultFill == .series, "\(theme.id)")
            #expect(s.marks.defaultEmphasis == .none, "\(theme.id)")
            #expect(s.marks.emphasisFill == .accent, "\(theme.id)")
            #expect(s.rules.title.gapAfter == nil, "\(theme.id)")
            #expect(s.rules.baselineColour == .rule, "\(theme.id)")
            #expect(s.rules.referenceColour == .secondaryInk, "\(theme.id)")
            #expect(s.rules.referenceLabelColour == .secondaryInk, "\(theme.id)")
            #expect(s.layout.gaps.referenceLabel == 3, "\(theme.id)")
            #expect(s.layout.cardBorder == 0, "\(theme.id)")
            #expect(s.layout.cardPadding == 0, "\(theme.id)")
            #expect(s.labels.valueHalo == 0, "\(theme.id)")
            for kind in NumberKind.allCases { #expect(s.numbers[kind].maxDecimals == nil, "\(theme.id) \(kind)") }
        }
    }

    @Test("their old structure values are untouched: bar ratio, rule position, baseline, margins")
    func unchangedThemesKeepOldValues() {
        let expected: [String: (bar: Double, baseline: Double, top: Double, trailing: Double)] = [
            "house": (0.6, 1, 16, 16),
        ]
        let house = Theme.house.structure
        #expect(house.marks.barWidthRatio.isEqual(to: expected["house"]?.bar ?? .nan))
        #expect(house.rules.baseline == expected["house"]?.baseline)
        #expect(house.layout.margins.top == expected["house"]?.top)
        #expect(house.layout.margins.trailing == expected["house"]?.trailing)
        #expect(Theme.economist.structure.rules.title.position == .aboveTitle)
    }

    // MARK: Swiss expresses the approved design

    @Test("Swiss: neutral marks, the latest column in the accent, a 3 pt ink rule above the title, a 1.5 pt ink baseline")
    func swissStructureValues() {
        let s = Theme.swiss.structure
        #expect(s.marks.defaultFill == .muted)
        #expect(s.marks.defaultEmphasis == .latest)
        #expect(s.marks.emphasisFill == .accent)
        #expect(s.marks.barWidthRatio.isEqual(to: 0.7))
        #expect(s.rules.title.position == .aboveTitle)
        #expect(s.rules.title.weight == 3)
        #expect(s.rules.title.colour == .ink)
        #expect(s.rules.title.gapAfter == 8)
        #expect(s.rules.baseline.isEqual(to: 1.5))
        #expect(s.rules.baselineColour == .ink)
        #expect(s.rules.gridline == 1)
        // owner decision 2026-11-09: the target line is a muted solid hairline; its label is ink, on the line
        #expect(s.rules.referenceColour == .secondaryInk)
        #expect(s.rules.referenceLabelColour == .ink)
        #expect(s.rules.reference == LineSpec(weight: s.rules.hairline, dash: []))
        #expect(s.layout.gaps.referenceLabel == 5)
        // owner decision 2026-11-09: the card border is an option, off for Swiss
        #expect(s.layout.cardBorder == 0)
        #expect(s.layout.cardPadding == 0)
        #expect(s.layout.margins == Insets(top: 6, leading: 8, bottom: 12, trailing: 8))
        #expect(s.labels.valueHalo == 3)
        #expect(s.labels.values == .aboveOrEnd)
        #expect(s.labels.series == .direct)
    }

    @Test("Swiss's bars are square: barCornerRadius is 0 in the theme, which is the single source (BusinessMath-UI draws no radius of its own)")
    func swissBarsAreSquare() {
        #expect(Theme.swiss.structure.marks.barCornerRadius.isEqual(to: 0))
        #expect(Theme.princeton.structure.marks.barCornerRadius.isEqual(to: 0))
        #expect(Radius.container == 0, "the value was Radius.container; it is now a literal 0, equal to it today")
    }

    @Test("Swiss's plain number format prints the fewest decimals up to two: 41.2, 80, 52.6, not 41.20")
    func swissPlainIsMinimal() {
        let plain = Theme.swiss.structure.numbers.plain
        #expect(plain.decimals == nil)
        #expect(plain.maxDecimals == 2)
        #expect(plain.style == .decimal)
        // the other kinds keep their explicit decimals
        #expect(Theme.swiss.structure.numbers.count.decimals == 0)
        #expect(Theme.swiss.structure.numbers.index.decimals == 1)
        #expect(Theme.swiss.structure.numbers.percent.decimals == 1)
    }

    @Test("Princeton inherits Swiss's structure whole: it is a Swiss variant with its own accent and series")
    func princetonInheritsSwissStructure() {
        #expect(Theme.princeton.structure == Theme.swiss.structure)
        #expect(Theme.princeton.structure.marks.defaultFill == .muted)
        #expect(Theme.princeton.palette.series.first?.name == "orange")
        #expect(Theme.princeton.palette.accent.light != Theme.swiss.palette.accent.light)
    }

    // MARK: Codec

    private static func object(_ theme: Theme) throws -> [String: Any] {
        let data = try ThemeCodec.encode(theme)
        return try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
    }

    @Test("the canonical JSON writes the new fields, and a nil optional writes nothing")
    func jsonCarriesNewFields() throws {
        let swiss = try Self.object(.swiss)
        let structure = try #require(swiss["structure"] as? [String: Any])
        let marks = try #require(structure["marks"] as? [String: Any])
        #expect(marks["defaultFill"] as? String == "muted")
        #expect(marks["defaultEmphasis"] as? String == "latest")
        #expect(marks["emphasisFill"] as? String == "accent")
        let rules = try #require(structure["rules"] as? [String: Any])
        #expect(rules["baselineColour"] as? String == "ink")
        #expect(rules["referenceColour"] as? String == "secondaryInk")
        #expect(rules["referenceLabelColour"] as? String == "ink")
        let title = try #require(rules["title"] as? [String: Any])
        #expect(title["gapAfter"] as? Double == 8)
        let house = try Self.object(.house)
        let houseTitle = try #require(((house["structure"] as? [String: Any])?["rules"] as? [String: Any])?["title"] as? [String: Any])
        #expect(houseTitle["gapAfter"] == nil, "a nil gapAfter is left out, not written as null")
    }

    /// The canonical text of a theme with the keys 0.6.0 gained for the chart alignment removed, a line at a time
    /// (the canonical form puts one scalar key per line), and a comma left dangling before a closing brace repaired.
    private static func textRemovingNewKeys(of theme: Theme) throws -> String {
        let added: Set<String> = ["defaultFill", "defaultEmphasis", "emphasisFill", "baselineColour", "referenceColour",
                                  "referenceLabelColour", "cardBorder", "cardPadding", "referenceLabel", "valueHalo", "cardChrome"]
        var lines = String(decoding: try ThemeCodec.encode(theme), as: UTF8.self)
            .split(omittingEmptySubsequences: false, whereSeparator: \.isNewline).map(String.init)
        lines.removeAll { line in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard trimmed.hasPrefix("\""), let end = trimmed.dropFirst().firstIndex(of: "\"") else { return false }
            return added.contains(String(trimmed[trimmed.index(after: trimmed.startIndex)..<end])) && trimmed[end...].hasPrefix("\" :")
        }
        for index in lines.indices.dropFirst() {
            let closing = lines[index].trimmingCharacters(in: .whitespaces)
            if (closing.hasPrefix("}") || closing.hasPrefix("]")), lines[index - 1].hasSuffix(",") {
                lines[index - 1].removeLast()
            }
        }
        return lines.joined(separator: "\n")
    }

    /// The FNV-1a 64 of each unchanged theme's committed `Generated/themes/<id>.json` before the chart alignment
    /// (taken from `git show 8e29e5c:Generated/themes/<id>.json`).
    private static let preChangeFingerprints: [String: String] = [
        "house": "5ed67cf4b6639b87", "ft": "bb3c6a270b5ca4db", "economist": "e9330bbccd9810c7",
        "legacy-default": "b07a4bf0764d6dc9", "legacy-dark": "e76d0222d5425e75",
        "legacy-financial": "7a1c771435074a42", "legacy-accessible": "0898100354440b15",
    ]

    @Test("an unchanged theme's JSON, less the new defaulted keys, is byte-for-byte its pre-change JSON")
    func unchangedThemesDifferOnlyByNewKeys() throws {
        for theme in Self.unchanged {
            let data = Data(try Self.textRemovingNewKeys(of: theme).utf8)
            #expect(Fingerprint.fnv1a64(data) == Self.preChangeFingerprints[theme.id], "\(theme.id)")
        }
    }

    @Test("JSON written before the chart alignment decodes, with every new field at its default")
    func oldJSONDecodesToDefaults() throws {
        let data = Data(try Self.textRemovingNewKeys(of: .house).utf8)
        let decoded = try JSONDecoder().decode(Theme.self, from: data)
        #expect(decoded == Theme.house)
        #expect(decoded.structure.marks.defaultFill == .series)
    }

    @Test("every theme round-trips through the canonical codec, new fields included")
    func roundTrips() throws {
        for theme in Theme.all {
            let again = try ThemeCodec.decode(try ThemeCodec.encode(theme))
            #expect(again == theme, "\(theme.id)")
        }
    }

    @Test("the card border is an option: withCardBorder turns on the approved 1 pt border and 8 pt padding, and off again")
    func cardBorderOption() {
        let card = Theme.swiss.withCardBorder()
        #expect(card.structure.layout.cardBorder == 1)
        #expect(card.structure.layout.cardPadding == 8)
        #expect(card.id == "swiss+card" && Theme.named("swiss+card") == nil)
        #expect(card.palette == Theme.swiss.palette && card.conformance == Theme.swiss.conformance)
        var expected = Theme.swiss.structure
        expected.layout.cardBorder = 1
        expected.layout.cardPadding = 8
        #expect(card.structure == expected)
        #expect(Theme.swiss.structure.withCardBorder(2, padding: 12).layout.cardBorder == 2)
        #expect(card.structure.withCardBorder(0, padding: 0) == Theme.swiss.structure)
        #expect((try? ThemeCodec.decode(ThemeCodec.encode(card))) == card)
    }

    @Test("a misspelt new field is refused, not defaulted")
    func misspeltNewFieldIsRefused() throws {
        var object = try Self.object(.swiss)
        var structure = try #require(object["structure"] as? [String: Any])
        var marks = try #require(structure["marks"] as? [String: Any])
        marks["defaultFil"] = "muted"
        structure["marks"] = marks
        object["structure"] = structure
        let data = try JSONSerialization.data(withJSONObject: object)
        #expect(throws: DecodingError.self) { try JSONDecoder().decode(Theme.self, from: data) }
    }

    @Test("a negative or non-numeric card border, padding, halo, gap or decimals cap makes the theme invalid")
    func newFieldsAreChecked() {
        func problems(_ edit: (inout Theme) -> Void) -> [String] {
            var theme = Theme.swiss
            edit(&theme)
            return theme.consistencyProblems
        }
        #expect(problems { $0.structure.layout.cardBorder = -1 }.count == 1)
        #expect(problems { $0.structure.layout.cardPadding = .nan }.count == 1)
        #expect(problems { $0.structure.labels.valueHalo = -0.5 }.count == 1)
        #expect(problems { $0.structure.layout.gaps.referenceLabel = -2 }.count == 1)
        #expect(problems { $0.structure.rules.title.gapAfter = -1 }.count == 1)
        #expect(problems { $0.structure.numbers.plain.maxDecimals = -1 }.count == 1)
        #expect(problems { _ in }.isEmpty)
    }
}
