import Foundation
import Testing
@testable import DesignTokens

/// The dashboard's roles, as its app declares them: what each is for, never a series.
enum DashboardRole: String, AppTextRole {
    case secondary, failure, warning, success, caution, progress, planned
}

private let dashboardLightSurfaces: [UInt32] = [0xFFFFFF, 0xF2F2F7, 0xECECEC, 0xF9F9F9]
private let dashboardDarkSurfaces: [UInt32] = [0x000000, 0x1C1C1E, 0x2C2C2E, 0x323232]

private let dashboardColours: [(DashboardRole, light: UInt32, dark: UInt32)] = [
    (.secondary, 0x5C5C61, 0xAEAEB2), (.failure, 0xC4161C, 0xFF6961), (.warning, 0xA04D00, 0xFF9F0A),
    (.success, 0x1B7030, 0x30D158), (.caution, 0x7A5C00, 0xFFD60A), (.progress, 0x0A5FC2, 0x64B5FF),
    (.planned, 0xA02BB5, 0xEA8DFF),
]

/// A palette shaped like the quality-gate dashboard's (its 0.8.0 declaration is quoted in `legacyStatusSeries`), written
/// for these tests: the seven text roles on the app's own backgrounds. It is not the dashboard's file and ships nowhere.
private enum DashboardShapedPalette: AppPaletteSource {
    typealias TextRoles = DashboardRole
    static let palette = AppPalette(
        id: "ijs-dashboard",
        textRoles: dashboardColours.map { NamedAdaptive($0.0.rawValue, light: $0.light, dark: $0.dark) },
        textSurfaces: TextSurfaces(light: dashboardLightSurfaces, dark: dashboardDarkSurfaces))
}

/// The same colours as the 0.8.0 adoption had to declare them: six of them as chart series, with the seven
/// `labelRequired` pairs and the 22 reviewed ledger rows (all of them about charts).
private let legacyStatusSeries = AppPalette(
    id: "ijs-dashboard",
    series: dashboardColours.filter { $0.0 != .secondary }.map { NamedAdaptive($0.0.rawValue, light: $0.light, dark: $0.dark) },
    seriesOrder: .entityOrder(labelRequired: [
        SeriesPair("failure", "warning"), SeriesPair("failure", "success"), SeriesPair("failure", "caution"),
        SeriesPair("warning", "success"), SeriesPair("warning", "caution"), SeriesPair("success", "caution"),
        SeriesPair("progress", "planned"),
    ]),
    conformance: Conformance(kind: .ledger, entries: [
        Finding(severity: .fail, check: .cvdSeparation, appearance: .light, subject: "failure / warning", measured: 1.4, threshold: 6.0),
        Finding(severity: .warn, check: .cvdSeparation, appearance: .light, subject: "failure / success", measured: 7.5, threshold: 8.0),
        Finding(severity: .fail, check: .cvdSeparation, appearance: .light, subject: "failure / caution", measured: 4.2, threshold: 6.0),
        Finding(severity: .fail, check: .cvdSeparation, appearance: .light, subject: "warning / success", measured: 4.9, threshold: 6.0),
        Finding(severity: .fail, check: .cvdSeparation, appearance: .light, subject: "warning / caution", measured: 1.2, threshold: 6.0),
        Finding(severity: .fail, check: .cvdSeparation, appearance: .light, subject: "success / caution", measured: 3.8, threshold: 6.0),
        Finding(severity: .fail, check: .cvdSeparation, appearance: .light, subject: "progress / planned", measured: 4.6, threshold: 6.0),
        Finding(severity: .fail, check: .normalSeparation, appearance: .light, subject: "failure / warning", measured: 10.2, threshold: 15.0),
        Finding(severity: .fail, check: .normalSeparation, appearance: .light, subject: "warning / caution", measured: 7.8, threshold: 15.0),
        Finding(severity: .fail, check: .normalSeparation, appearance: .light, subject: "success / caution", measured: 11.8, threshold: 15.0),
        Finding(severity: .fail, check: .lightnessBand, appearance: .dark, subject: "failure", measured: 0.707, threshold: 0.67),
        Finding(severity: .fail, check: .lightnessBand, appearance: .dark, subject: "warning", measured: 0.782, threshold: 0.67),
        Finding(severity: .fail, check: .lightnessBand, appearance: .dark, subject: "success", measured: 0.756, threshold: 0.67),
        Finding(severity: .fail, check: .lightnessBand, appearance: .dark, subject: "caution", measured: 0.885, threshold: 0.67),
        Finding(severity: .fail, check: .lightnessBand, appearance: .dark, subject: "progress", measured: 0.753, threshold: 0.67),
        Finding(severity: .fail, check: .lightnessBand, appearance: .dark, subject: "planned", measured: 0.781, threshold: 0.67),
        Finding(severity: .fail, check: .cvdSeparation, appearance: .dark, subject: "failure / success", measured: 3.7, threshold: 6.0),
        Finding(severity: .warn, check: .cvdSeparation, appearance: .dark, subject: "warning / success", measured: 7.1, threshold: 8.0),
        Finding(severity: .warn, check: .cvdSeparation, appearance: .dark, subject: "success / caution", measured: 7.7, threshold: 8.0),
        Finding(severity: .fail, check: .cvdSeparation, appearance: .dark, subject: "progress / planned", measured: 4.3, threshold: 6.0),
        Finding(severity: .fail, check: .normalSeparation, appearance: .dark, subject: "failure / warning", measured: 14.7, threshold: 15.0),
        Finding(severity: .fail, check: .normalSeparation, appearance: .dark, subject: "warning / caution", measured: 13.3, threshold: 15.0),
    ]))

/// The dashboard's adoption re-expressed on 0.9.0: the proof that the three things its report asked for hold.
@Suite("App palette adoption: the dashboard-shaped example")
struct DashboardShapedExampleTests {
    @Test("before: as six chart series the same colours carried 7 label-required pairs and 22 ledger rows about charts")
    func beforeIsChartNoise() {
        let before = legacyStatusSeries.validate()
        #expect(before.isConformant, "the reviewed 0.8.0 ledger still reproduces exactly: \(before.report)")
        #expect(before.findings.count == 22)
        #expect(before.labelRequirements.count == 7)
        #expect(before.findings.allSatisfy { $0.check != .textContrast }, "and not one row was about text")
    }

    @Test("(b) after: declared as text roles the chart rows and label pairs do not exist, and there is no ledger")
    func afterHasNoChartChecks() {
        let after = DashboardShapedPalette.validate()
        #expect(after.isConformant, "\(after.report)")
        #expect(after.findings.isEmpty)
        #expect(after.labelRequirements.isEmpty)
        #expect(DashboardShapedPalette.palette.conformance == .strict, "no reviewed ledger is needed")
        #expect(DashboardShapedPalette.palette.series == nil)
        #expect(after.appearances == [.light, .dark], "the dark values are really measured")
    }

    @Test("(a) every role, all seven including secondary, is validated as text on every one of the app's own surfaces",
          arguments: DashboardRole.allCases)
    func textOnOwnSurfaces(_ role: DashboardRole) throws {
        let colour = DashboardShapedPalette.text(role)
        let dark = try #require(colour.dark)
        for hex in dashboardLightSurfaces {
            #expect(colour.light.rgb.meetsAA(on: RGB(rgb: hex)), "\(role) light on \(RGB(rgb: hex).hex)")
        }
        for hex in dashboardDarkSurfaces {
            #expect(dark.rgb.meetsAA(on: RGB(rgb: hex)), "\(role) dark on \(RGB(rgb: hex).hex)")
        }
        // and the package says the same, so the AA guarantee is the validator's, not only the test's
        #expect(!DashboardShapedPalette.validate().findings.contains { $0.subject.hasPrefix(role.rawValue + " on") })
    }

    @Test("(a) the guarantee asserts: one role nudged to a failing value on the host's grey is a textContrast finding naming that grey")
    func theGuaranteeFails() throws {
        var weak = DashboardShapedPalette.palette
        let index = try #require(weak.textRoles.firstIndex { $0.name == "failure" })
        weak.textRoles[index] = NamedAdaptive("failure", light: 0xDB2C2C, dark: 0xFF4245)  // Swiss's own negative
        let findings = weak.validate().findings
        let light = try #require(findings.first { $0.appearance == .light && $0.subject == "failure on #ECECEC" })
        #expect(abs(light.measured - 4.03) < 1e-9)
        let dark = try #require(findings.first { $0.appearance == .dark && $0.subject == "failure on #323232" })
        #expect(abs(dark.measured - 3.73) < 1e-9)
        #expect(findings.allSatisfy { $0.check == .textContrast && $0.subject.hasPrefix("failure on ") })
        // exactly the surfaces where the independently computed ratio is under 4.5 are findings, no more and no fewer
        let failing = dashboardLightSurfaces.filter { !RGB(rgb: 0xDB2C2C).meetsAA(on: RGB(rgb: $0)) }.map { "failure on " + RGB(rgb: $0).hex }
            + dashboardDarkSurfaces.filter { !RGB(rgb: 0xFF4245).meetsAA(on: RGB(rgb: $0)) }.map { "failure on " + RGB(rgb: $0).hex }
        #expect(Set(findings.map(\.subject)) == Set(failing))
        #expect(findings.count == failing.count)
        #expect(!weak.validate().isConformant)
    }

    @Test("(a) the host-surface measurements the report quoted: Swiss's text-safe roles on the system grey")
    func swissOnTheHostGrey() throws {
        let host = TextSurfaces(light: [0xECECEC], dark: [0x323232])
        func measure(_ role: ColorRole) -> [Finding] {
            let palette = AppPalette(id: "swiss-on-host", textRoles: [NamedAdaptive(name: role.rawValue, color: Theme.swiss.palette[role])],
                                     textSurfaces: host)
            return palette.validate().findings
        }
        let figures: [(ColorRole, Double)] = [(.negative, 4.03), (.positive, 4.14), (.warning, 4.01), (.secondaryInk, 4.40)]
        for (role, expected) in figures {
            let found = try #require(measure(role).first { $0.appearance == .light && $0.subject == "\(role.rawValue) on #ECECEC" },
                                     "\(role) light is under 4.5 on #ECECEC")
            #expect(abs(found.measured - expected) < 1e-9, "\(role)")
        }
        let darkNegative = try #require(measure(.negative).first { $0.appearance == .dark })
        #expect(abs(darkNegative.measured - 3.73) < 1e-9)
    }

    @Test("(c) Swiss's own roles still validate on Swiss's own surfaces, by Swiss's own ledger, unchanged by the new slots")
    func swissIsUnchanged() {
        let findings = ThemeValidator.validate(Theme.swiss)
        #expect(ThemeValidator.deviations(found: findings, against: Theme.swiss.conformance).isEmpty)
        let bg = Theme.swiss.palette.background.light.rgb
        for role in [ColorRole.positive, .negative] {
            #expect(Theme.swiss.palette[role].light.rgb.meetsAA(on: bg), "\(role) is text-safe on Swiss's own background")
        }
        // an app that declares nothing about text is measured against exactly this and finds nothing
        #expect(AppPalette(id: "empty").validate().findings.isEmpty)
    }

    @Test("composition: a role named like one of Swiss's overrides it, any other name becomes an extra")
    func composition() {
        let theme = DashboardShapedPalette.palette.theme()
        #expect(theme.id == "swiss+ijs-dashboard")
        #expect(theme.palette.secondaryInk == Theme.swiss.palette.secondaryInk, "named secondary, not secondaryInk: it is an extra")
        #expect(theme.palette.extras["secondary"]?.light.hex == "#5C5C61")
        #expect(theme.palette.warning.light.hex == "#A04D00", "warning is a name Swiss has, so the app's overrides it")
        #expect(theme.palette.extras["failure"]?.dark?.hex == "#FF6961")
    }
}
