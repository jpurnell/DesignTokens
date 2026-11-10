import Foundation
import Testing
@testable import DesignTokens

@Suite("0.6.0 additions to the model")
struct ThemeAdditionsTests {
    @Test("the package version is 0.8.0")
    func versionConstant() {
        #expect(DesignTokens.version == "0.9.0")
    }

    @Test("TypeRole lists the nine chart roles and the six UI roles, and subscripts each field")
    func typeRoleSubscript() {
        #expect(TypeRole.allCases.count == 15)
        let roles = Theme.swiss.structure.type
        #expect(roles[.title] == roles.title)
        #expect(roles[.subtitle] == roles.subtitle)
        #expect(roles[.axisTitle] == roles.axisTitle)
        #expect(roles[.axisLabel] == roles.axisLabel)
        #expect(roles[.seriesLabel] == roles.seriesLabel)
        #expect(roles[.annotation] == roles.annotation)
        #expect(roles[.source] == roles.source)
        #expect(roles[.note] == roles.note)
        #expect(roles[.tag] == roles.tag)
        #expect(roles[.label] == roles.label)
        #expect(roles[.caption] == roles.caption)
        #expect(roles[.body] == roles.body)
        #expect(roles[.heading] == roles.heading)
        #expect(roles[.uiTitle] == roles.uiTitle)
        #expect(roles[.display] == roles.display)
        // The nine chart roles are distinct specs in Swiss, so a subscript that returned the wrong field would fail.
        #expect(roles[.title] != roles[.subtitle])
    }

    @Test("NumberKind subscripts each of the seven number formats")
    func numberKindSubscript() {
        #expect(NumberKind.allCases.count == 7)
        let numbers = Theme.swiss.structure.numbers
        #expect(numbers[.currency].style == .currency)
        #expect(numbers[.percent].style == .percent)
        #expect(numbers[.count].decimals == 0)
        #expect(numbers[.index].decimals == 1)
        #expect(numbers[.ratio].suffix == "×")
        #expect(numbers[.temperature].suffix == "°")
        // minimal decimals up to two, not a fixed two (chart alignment, 2026-11-09)
        #expect(numbers[.plain].decimals == nil)
        #expect(numbers[.plain].maxDecimals == 2)
    }

    @Test("ColorValue interpolates channel by channel, with alpha")
    func colourInterpolation() {
        let a = ColorValue(RGB(red: 0, green: 0, blue: 0), alpha: 0)
        let b = ColorValue(RGB(red: 200, green: 100, blue: 50), alpha: 1)
        let mid = a.interpolated(to: b, fraction: 0.5)
        #expect(mid.rgb == RGB(red: 100, green: 50, blue: 25))
        #expect(abs(mid.alpha - 0.5) <= 1.0 / 255)
        #expect(a.interpolated(to: b, fraction: 0) == a)
        #expect(a.interpolated(to: b, fraction: 1) == b)
        #expect(a.interpolated(to: b, fraction: -3) == a)
        #expect(a.interpolated(to: b, fraction: 9) == b)
        #expect(a.interpolated(to: b, fraction: .nan) == a)
    }

    @Test("Ramp.sample walks the steps: endpoints, an interior step, and the dark ramp")
    func rampSampling() throws {
        let black = ColorValue(RGB(red: 0, green: 0, blue: 0))
        let mid = ColorValue(RGB(red: 100, green: 50, blue: 20))
        let top = ColorValue(RGB(red: 200, green: 100, blue: 40))
        let ramp = Ramp(light: [black, mid, top], dark: [top, mid, black])
        #expect(ramp.sample(0) == black)
        #expect(ramp.sample(1) == top)
        #expect(ramp.sample(0.5) == mid)
        #expect(ramp.sample(0.25) == ColorValue(RGB(red: 50, green: 25, blue: 10)))
        #expect(ramp.sample(0.75) == ColorValue(RGB(red: 150, green: 75, blue: 30)))
        #expect(ramp.sample(0, dark: true) == top)
        #expect(ramp.sample(1, dark: true) == black)
        #expect(ramp.sample(-1) == black)
        #expect(ramp.sample(2) == top)
        // Without a dark ramp, the light ramp is used as it is.
        #expect(Ramp(light: [black, top], dark: nil).sample(1, dark: true) == top)
        // Degenerate ramps do not trap.
        #expect(Ramp(light: [], dark: nil).sample(0.5) == nil)
        #expect(Ramp(light: [mid], dark: nil).sample(0.5) == mid)
    }

    @Test("the new mark and layout fields have the values the BusinessMath-UI views use today")
    func newFieldValues() {
        for theme in Theme.all {
            #expect(theme.structure.marks.areaOpacity.isEqual(to: 0.22), "\(theme.id)")
            #expect(theme.structure.marks.fillOpacity.isEqual(to: 0.35), "\(theme.id)")
            #expect(theme.structure.marks.detailLineWidth.isEqual(to: 1.5), "\(theme.id)")
        }
        let legacy = Theme.all.filter { $0.id.hasPrefix("legacy-") }
        #expect(legacy.count == 4)
        for theme in legacy { #expect(theme.structure.layout.annotationRadius == 8, "\(theme.id)") }
        for theme in Theme.all where !theme.id.hasPrefix("legacy-") {
            #expect(theme.structure.layout.annotationRadius == 0, "\(theme.id)")
        }
    }

    @Test("0.5.0 JSON, written before these fields existed, still decodes, with the defaults")
    func oldJSONStillDecodes() throws {
        let data = try ThemeCodec.encode(Theme.swiss)
        var object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        var structure = try #require(object["structure"] as? [String: Any])
        var marks = try #require(structure["marks"] as? [String: Any])
        var layout = try #require(structure["layout"] as? [String: Any])
        #expect(try #require(marks["areaOpacity"] as? Double).isEqual(to: 0.22))
        #expect(try #require(layout["annotationRadius"] as? Double).isEqual(to: 0))
        for key in ["areaOpacity", "fillOpacity", "detailLineWidth"] { marks.removeValue(forKey: key) }
        layout.removeValue(forKey: "annotationRadius")
        structure["marks"] = marks
        structure["layout"] = layout
        object["structure"] = structure
        let old = try JSONSerialization.data(withJSONObject: object)
        let decoded = try ThemeCodec.decode(old)
        #expect(decoded == Theme.swiss)
    }
}
