import Foundation
import Testing
@testable import DesignTokens

/// WCAG contrast from the published formula, written independently of the package's.
private func published(_ a: UInt32, _ b: UInt32) -> Double {
    func lum(_ v: UInt32) -> Double {
        func lin(_ c: UInt32) -> Double {
            let s = Double(c) / 255
            return s <= 0.04045 ? s / 12.92 : pow((s + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * lin((v >> 16) & 0xFF) + 0.7152 * lin((v >> 8) & 0xFF) + 0.0722 * lin(v & 0xFF)
    }
    let (hi, lo) = (max(lum(a), lum(b)), min(lum(a), lum(b)))
    return (hi + 0.05) / (lo + 0.05)
}

private func twoPlaces(_ x: Double) -> Double { (x * 100).rounded() / 100 }

private enum StatusRole: String, AppTextRole {
    case failure, success
}

private enum StatusPalette: AppPaletteSource {
    typealias TextRoles = StatusRole
    static let palette = AppPalette(
        id: "status",
        textRoles: [NamedAdaptive("failure", light: 0xC4161C, dark: 0xFF6961),
                    NamedAdaptive("success", light: 0x1B7030, dark: 0x30D158)])
}

private enum WrongRolesPalette: AppPaletteSource {
    typealias TextRoles = StatusRole
    static let palette = AppPalette(
        id: "wrong",
        textRoles: [NamedAdaptive("failure", light: 0xC4161C, dark: 0xFF6961),
                    NamedAdaptive("stray", light: 0x1B7030, dark: 0x30D158)])
}

@Suite("App palette: text roles")
struct AppPaletteTextRoleTests {
    private let swissLightNegative: UInt32 = 0xDB2C2C
    private let swissDarkNegative: UInt32 = 0xFF4245

    @Test("a palette may have text roles and nothing else: no series, no accent, defaults for the rest")
    func textOnlyPalette() {
        let palette = AppPalette(id: "t", textRoles: [NamedAdaptive("ok", light: 0x1B7030, dark: 0x30D158)])
        #expect(palette.series == nil && palette.accent == nil)
        #expect(palette.textRoles.map(\.name) == ["ok"])
        let result = palette.validate()
        #expect(result.isConformant, "\(result.report)")
        #expect(result.appearances == [.light, .dark])
        #expect(result.labelRequirements.isEmpty)
    }

    @Test("a role under 4.5:1 is a failing textContrast finding with the WCAG value, and no chart check ever applies to it")
    func measuredAsTextOnly() throws {
        let palette = AppPalette(id: "weak", textRoles: [NamedAdaptive("faint", light: 0xBBBBBB, dark: 0x333333)])
        let findings = palette.validate().findings
        #expect(findings.allSatisfy { $0.check == .textContrast }, "no lightness band, separation or mark finding for text")
        let light = try #require(findings.first { $0.appearance == .light && $0.subject == "faint on background" })
        let bg = Theme.swiss.palette.background.light.rgb
        let swissBackground = UInt32(bg.red) << 16 | UInt32(bg.green) << 8 | UInt32(bg.blue)
        #expect(light.severity == .fail)
        #expect(abs(light.measured - twoPlaces(published(0xBBBBBB, swissBackground))) < 1e-9)
        #expect(abs(light.threshold - 4.5) < 1e-12)
        #expect(findings.contains { $0.appearance == .dark && $0.subject == "faint on background" })
        #expect(findings.contains { $0.subject == "faint on surface" })
        #expect(!palette.validate().isConformant)
    }

    @Test("Swiss's negative passes on Swiss's surfaces, so with no declared surfaces it has no finding")
    func swissSurfacesByDefault() {
        let palette = AppPalette(id: "s", textRoles: [NamedAdaptive("negative", light: swissLightNegative, dark: swissDarkNegative)])
        #expect(palette.validate().findings.isEmpty)
    }

    @Test("declared host surfaces: the same colours fail on the host's greys, at the measured values, by hex")
    func hostSurfaces() throws {
        let palette = AppPalette(
            id: "host",
            textRoles: [NamedAdaptive("negative", light: swissLightNegative, dark: swissDarkNegative)],
            textSurfaces: TextSurfaces(light: [0xFFFFFF, 0xECECEC], dark: [0x000000, 0x323232]))
        let findings = palette.validate().findings
        let light = try #require(findings.first { $0.appearance == .light })
        #expect(light.subject == "negative on #ECECEC")
        #expect(abs(light.measured - 4.03) < 1e-9, "the 4.03 on #ECECEC measured for the dashboard")
        let dark = try #require(findings.first { $0.appearance == .dark })
        #expect(dark.subject == "negative on #323232")
        #expect(abs(dark.measured - 3.73) < 1e-9)
        #expect(findings.count == 2, "white and black are fine, so exactly one finding per appearance")
        #expect(findings.allSatisfy { $0.check == .textContrast && $0.severity == .fail })
    }

    @Test("a declared list replaces the theme's surfaces: a role that fails only on Swiss's own surface is not measured there")
    func declaredReplacesDefault() {
        let palette = AppPalette(id: "r", textRoles: [NamedAdaptive("grey", light: 0x767676, dark: 0xAAAAAA)],
                                 textSurfaces: TextSurfaces(light: [0xFFFFFF], dark: [0x000000]))
        #expect(palette.validate().findings.isEmpty, "#767676 is 4.54:1 on white, and Swiss's #FAFAFA card is not on the list")
    }

    @Test("an increased-contrast list defaults to the standard one, and a role without the slot is not measured in it")
    func increasedAppearances() {
        let with = AppPalette(id: "i", textRoles: [NamedAdaptive("a", light: 0x595959, dark: 0xCCCCCC, lightIncreased: 0xBBBBBB)],
                              textSurfaces: TextSurfaces(light: [0xFFFFFF], dark: [0x000000]))
        let result = with.validate()
        #expect(result.appearances == [.light, .dark, .lightIncreased])
        #expect(result.findings.map(\.appearance) == [.lightIncreased], "the increased value is the weak one, on the light list")
        let without = AppPalette(id: "i2", textRoles: [NamedAdaptive("a", light: 0x595959, dark: 0xCCCCCC)],
                                 textSurfaces: TextSurfaces(light: [0xFFFFFF], dark: [0x000000]))
        #expect(without.validate().appearances == [.light, .dark])
        let host = AppPalette(id: "i3", textRoles: [NamedAdaptive("a", light: 0x595959, dark: 0xCCCCCC, lightIncreased: 0x333333)],
                              textSurfaces: TextSurfaces(light: [0xFFFFFF], dark: [0x000000], lightIncreased: [0x444444]))
        #expect(host.validate().findings.map(\.subject) == ["a on #444444"], "an explicit increased list is used")
    }

    @Test("a role without a dark value makes the palette light only; no dark value is invented")
    func noDarkIsLightOnly() {
        let palette = AppPalette(id: "l", textRoles: [NamedAdaptive("a", light: 0x1B7030)])
        #expect(palette.validate().appearances == [.light])
        #expect(palette.theme().appearances == .lightOnly)
    }

    @Test("structure: a duplicate role name and an empty declared surface list are findings")
    func structure() {
        let duplicate = AppPalette(id: "d", textRoles: [NamedAdaptive("a", light: 0x000000, dark: 0xFFFFFF), NamedAdaptive("a", light: 0x111111, dark: 0xEEEEEE)])
        #expect(duplicate.validate().findings.contains { $0.check == .structure && $0.subject == "text role a (duplicate name)" })
        let empty = AppPalette(id: "e", textRoles: [NamedAdaptive("a", light: 0x000000, dark: 0xFFFFFF)], textSurfaces: TextSurfaces(light: [ColorValue]()))
        #expect(empty.validate().findings.contains { $0.check == .structure && $0.subject == "textSurfaces light (empty)" })
    }

    @Test("composition: a role named like Swiss's overrides it; any other name is an extra, so web and terminal output carry it")
    func composition() throws {
        let palette = AppPalette(id: "c", textRoles: [NamedAdaptive("secondaryInk", light: 0x5C5C61, dark: 0xAEAEB2),
                                                      NamedAdaptive("negative", light: 0xC4161C, dark: 0xFF6961),
                                                      NamedAdaptive("caution", light: 0x7A5C00, dark: 0xFFD60A)])
        let theme = palette.theme()
        #expect(theme.palette.secondaryInk.light.hex == "#5C5C61")
        #expect(theme.palette.negative.dark?.hex == "#FF6961")
        #expect(theme.palette.positive == Theme.swiss.palette.positive, "a role the app does not name is Swiss's")
        #expect(theme.palette.extras["caution"]?.light.hex == "#7A5C00")
        #expect(theme.palette.ink == Theme.swiss.palette.ink)
        let css = try ThemeCSSEmitter.emit(theme)
        #expect(css.uppercased().contains("#7A5C00"), "the app's own extra reaches the CSS")
    }

    @Test("0.8.0-shaped JSON (no text keys) decodes with defaults, and the new fields round-trip")
    func codec() throws {
        let old = AppPalette(id: "old")
        let data = try ThemeCodec.encode(old)
        let object = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        var legacy = object
        legacy["textRoles"] = nil
        legacy["textSurfaces"] = nil
        let decoded = try ThemeCodec.decodeAppPalette(try JSONSerialization.data(withJSONObject: legacy))
        #expect(decoded == old)
        #expect(decoded.textRoles.isEmpty && decoded.textSurfaces == nil)
        let full = AppPalette(id: "full", textRoles: [NamedAdaptive("a", light: 0x5C5C61, dark: 0xAEAEB2, lightIncreased: 0x333333)],
                              textSurfaces: TextSurfaces(light: [0xFFFFFF, 0xECECEC], dark: [0x000000], lightIncreased: [0xFFFFFF]))
        #expect(try ThemeCodec.decodeAppPalette(ThemeCodec.encode(full)) == full)
    }

    @Test("typed roles: text(_:) reads the declared colour, and the declared roles are exactly the enum's cases")
    func typedRoles() throws {
        #expect(StatusPalette.text(.failure).light.hex == "#C4161C")
        #expect(StatusPalette.text(.success).dark?.hex == "#30D158")
        #expect(StatusPalette.palette.text(named: "failure")?.light.hex == "#C4161C")
        #expect(StatusPalette.palette.text(named: "nope") == nil)
        let ok = StatusPalette.validate()
        #expect(ok.isConformant, "\(ok.report)")
        let bad = WrongRolesPalette.validate()
        let subjects = bad.findings.filter { $0.check == .structure }.map(\.subject)
        #expect(subjects.contains("text role success (not declared)"))
        #expect(subjects.contains("text role stray (no case in TextRoles)"))
        #expect(!bad.isConformant)
        #expect(WrongRolesPalette.text(.success) == Theme.swiss.palette.ink, "an undeclared role reads as ink, already a failing finding")
    }

    @Test("a source that names no TextRoles is not cross-checked")
    func noEnumNoCrossCheck() {
        let result = WineLikePalette.validate()
        #expect(!result.findings.contains { $0.check == .structure })
    }
}

private enum WineLikePalette: AppPaletteSource {
    static let palette = AppPalette(id: "plain", textRoles: [NamedAdaptive("a", light: 0x1B7030, dark: 0x30D158)])
}
