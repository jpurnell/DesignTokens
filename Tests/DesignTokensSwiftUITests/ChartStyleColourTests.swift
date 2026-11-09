#if canImport(SwiftUI) && os(macOS)
import DesignTokens
import SwiftUI
import Testing
@testable import DesignTokensSwiftUI

/// Colour resolution. `Color.resolve(in:)` never returns off the main thread, and the dynamic colours it
/// resolves are main-actor state, so every test here is `@MainActor`.
@MainActor
@Suite("ChartStyle colours")
struct ChartStyleColourTests {
    private static let modes: [(dark: Bool, increased: Bool)] = [(false, false), (true, false), (false, true), (true, true)]

    /// Resolves in a light or dark environment. `EnvironmentValues.colorSchemeContrast` is read-only in SwiftUI,
    /// so Increase Contrast cannot be set here: `increased` is accepted so call sites read the same, and it does
    /// not reach the environment. It does not matter for stored colours, which are fixed by the style's own
    /// `increasedContrast`; it is why the system-colour test below covers the two standard modes only.
    private func resolve(_ color: Color, dark: Bool, increased _: Bool) -> Color.Resolved {
        var environment = EnvironmentValues()
        environment.colorScheme = dark ? .dark : .light
        return color.resolve(in: environment)
    }

    /// Whether a resolved colour is a stored value, to within half a byte on each channel and on alpha.
    private func matches(_ resolved: Color.Resolved, _ value: ColorValue) -> Bool {
        let half = 0.5 / 255.0
        return abs(Double(resolved.red) - Double(value.rgb.red) / 255) <= half
            && abs(Double(resolved.green) - Double(value.rgb.green) / 255) <= half
            && abs(Double(resolved.blue) - Double(value.rgb.blue) / 255) <= half
            && abs(Double(resolved.opacity) - value.alpha) <= half
    }

    @Test("a stored colour resolves to its own channels: #FF8D28 is 1.0, 141/255, 40/255")
    func channelsAreSRGBEncoded() {
        let resolved = resolve(ColorValue(hex: "#FF8D28")?.color ?? .black, dark: false, increased: false)
        #expect(abs(Double(resolved.red) - 1.0) < 1e-3)
        #expect(abs(Double(resolved.green) - 141.0 / 255) < 1e-3)
        #expect(abs(Double(resolved.blue) - 40.0 / 255) < 1e-3)
        #expect(abs(Double(resolved.opacity) - 1.0) < 1e-3)
    }

    @Test("every role, series colour and extra of every theme resolves to its Adaptive value in all four modes")
    func resolvesToAdaptiveValues() throws {
        for theme in Theme.all {
            for mode in Self.modes {
                let style = ChartStyle(theme: theme, appearance: mode.dark ? .dark : .light,
                                       increasedContrast: mode.increased, defersToSystemColors: false)
                for role in ColorRole.allCases {
                    let expected = theme.palette[role].value(in: mode.dark ? .dark : .light, increasedContrast: mode.increased)
                    // Resolved in the matching environment, and in the opposite one: a stored colour must not move.
                    #expect(matches(resolve(style.color(role), dark: mode.dark, increased: mode.increased), expected),
                            "\(theme.id) \(role.rawValue) dark=\(mode.dark) hc=\(mode.increased)")
                    #expect(matches(resolve(style.color(role), dark: !mode.dark, increased: !mode.increased), expected),
                            "\(theme.id) \(role.rawValue) is fixed, not dynamic")
                }
                for (index, entry) in theme.palette.series.enumerated() {
                    let expected = entry.color.value(in: mode.dark ? .dark : .light, increasedContrast: mode.increased)
                    #expect(matches(resolve(style.series(index), dark: mode.dark, increased: mode.increased), expected),
                            "\(theme.id) series \(entry.name) dark=\(mode.dark) hc=\(mode.increased)")
                    #expect(style.seriesValue(index) == expected)
                }
                for (name, adaptive) in theme.palette.extras {
                    let expected = adaptive.value(in: mode.dark ? .dark : .light, increasedContrast: mode.increased)
                    let color = try #require(style.extra(name), "\(theme.id) extra \(name)")
                    #expect(matches(resolve(color, dark: mode.dark, increased: mode.increased), expected), "\(theme.id) extra \(name)")
                }
            }
        }
    }

    @Test("Swiss accent resolves to the measured values: light, dark, and each with Increase Contrast")
    func swissAccentMeasuredValues() {
        let expected: [(dark: Bool, increased: Bool, hex: String)] = [
            (false, false, "#FF8D28"), (true, false, "#FF9230"), (false, true, "#C55300"), (true, true, "#FFA056"),
        ]
        for item in expected {
            let style = ChartStyle(theme: .swiss, appearance: item.dark ? .dark : .light,
                                   increasedContrast: item.increased, defersToSystemColors: false)
            let value = ColorValue(hex: item.hex) ?? ColorValue(RGB(red: 0, green: 0, blue: 0))
            #expect(matches(resolve(style.accent, dark: item.dark, increased: item.increased), value), "\(item.hex)")
            #expect(style.hex(.accent) == item.hex)
        }
    }

    @Test("a system-deferring Swiss style resolves to the same values the package measured on macOS 27.2 (light and dark; Increase Contrast cannot be set on an EnvironmentValues)")
    func systemColoursMatchTheSnapshot() {
        for mode in Self.modes where !mode.increased {
            let style = ChartStyle(theme: .swiss, appearance: mode.dark ? .dark : .light, increasedContrast: mode.increased)
            for role in [ColorRole.accent, .positive, .negative] {
                let expected = Theme.swiss.palette[role].value(in: mode.dark ? .dark : .light, increasedContrast: mode.increased)
                #expect(matches(resolve(style.color(role), dark: mode.dark, increased: mode.increased), expected),
                        "\(role.rawValue) dark=\(mode.dark) hc=\(mode.increased)")
            }
            for (index, entry) in Theme.swiss.palette.series.enumerated() {
                let expected = entry.color.value(in: mode.dark ? .dark : .light, increasedContrast: mode.increased)
                #expect(matches(resolve(style.series(index), dark: mode.dark, increased: mode.increased), expected),
                        "series \(entry.name) dark=\(mode.dark) hc=\(mode.increased)")
            }
        }
    }

    @Test("deferral is real: a deferring style's system colour moves with the environment, a stored one does not")
    func deferralIsDynamic() {
        let deferring = ChartStyle(theme: .swiss, appearance: .light)
        let light = resolve(deferring.accent, dark: false, increased: false)
        let dark = resolve(deferring.accent, dark: true, increased: false)
        #expect(abs(Double(light.green) - Double(dark.green)) > 1e-3)
        let stored = ChartStyle(theme: .swiss, appearance: .light, defersToSystemColors: false)
        #expect(resolve(stored.accent, dark: false, increased: false) == resolve(stored.accent, dark: true, increased: false))
    }

    @Test("a light-only theme keeps its light values in a dark context, even where a role names a system colour")
    func lightOnlyDoesNotDefer() {
        #expect(Theme.princeton.appearances == .lightOnly)
        let style = ChartStyle(theme: .princeton, appearance: .dark)
        for role in ColorRole.allCases {
            let expected = Theme.princeton.palette[role].light
            #expect(matches(resolve(style.color(role), dark: true, increased: false), expected), "princeton \(role.rawValue)")
        }
        // Princeton composes on Swiss, so some roles do name a system colour: the guard is what is under test.
        #expect(Theme.princeton.palette.positive.system == .green)
    }

    @Test("a fixed-dark theme resolves its single set of values in a light context too")
    func fixedDarkTheme() {
        let style = ChartStyle(theme: .legacyDark, appearance: .light)
        let expected = Theme.legacyDark.palette.background.light
        #expect(matches(resolve(style.background, dark: false, increased: false), expected))
    }

    @Test("a colour with alpha keeps it: legacy Dark's ink is white at 0xD8")
    func alphaSurvives() {
        let style = ChartStyle(theme: .legacyDark, appearance: .dark)
        let resolved = resolve(style.ink, dark: true, increased: false)
        #expect(abs(Double(resolved.opacity) - 216.0 / 255) < 1e-3)
    }

    @Test("series wrap, a negative index wraps, and an empty series falls back to the accent")
    func seriesWrap() {
        let style = ChartStyle(theme: .swiss, appearance: .light, defersToSystemColors: false)
        let count = style.seriesCount
        #expect(count == 8)
        #expect(style.seriesValue(count) == style.seriesValue(0))
        #expect(style.seriesValue(-1) == style.seriesValue(count - 1))
        var bare = Theme.swiss
        bare.palette.series = []
        let empty = ChartStyle(theme: bare, appearance: .light, defersToSystemColors: false)
        #expect(empty.seriesValue(3) == empty.value(.accent))
        #expect(empty.seriesCount == 0)
    }

    @Test("sequential and diverging sample the ramps, with the dark ramp in dark and neutral for no ramp")
    func rampSamples() throws {
        let light = ChartStyle(theme: .swiss, appearance: .light, defersToSystemColors: false)
        let first = Theme.swiss.palette.sequential.light[0]
        let last = Theme.swiss.palette.sequential.light[4]
        #expect(matches(resolve(light.sequential(0), dark: false, increased: false), first))
        #expect(matches(resolve(light.sequential(1), dark: false, increased: false), last))
        let dark = ChartStyle(theme: .swiss, appearance: .dark, defersToSystemColors: false)
        let darkRamp = Theme.swiss.palette.sequential.dark ?? []
        #expect(darkRamp.count == 5)
        #expect(matches(resolve(dark.sequential(0), dark: true, increased: false), darkRamp[0]))
        // Swiss has no dark diverging ramp: the light one is used as it is.
        #expect(matches(resolve(dark.diverging(1), dark: true, increased: false), Theme.swiss.palette.diverging.light[4]))
        #expect(light.ramp(named: "nonexistent", 0.5) == nil)
        #expect(light.rampStops(named: "nonexistent") == nil)
        let sharpe = try #require(Theme.legacyDefault.palette.extraRamps["sharpe"]).light
        #expect(sharpe.count == 4)
        let legacy = ChartStyle(theme: .legacyDefault, appearance: .light, defersToSystemColors: false)
        #expect(legacy.rampStops(named: "sharpe")?.count == 4)
        let middle = try #require(legacy.ramp(named: "sharpe", 0.5))
        #expect(matches(resolve(middle, dark: false, increased: false), sharpe[1].interpolated(to: sharpe[2], fraction: 0.5)))
    }

    @Test("a colour reference resolves a role or an extra at its opacity, and an unknown name is nil")
    func references() throws {
        let style = ChartStyle(theme: .legacyDefault, appearance: .light, defersToSystemColors: false)
        let positive = try #require(style.color(ColourReference(source: "positive", opacity: 0.7)))
        let resolved = resolve(positive, dark: false, increased: false)
        #expect(abs(Double(resolved.opacity) - 0.7) < 1e-3)
        let primary = try #require(style.color(ColourReference(source: "primary")))
        let expectedPrimary = try #require(Theme.legacyDefault.palette.extras["primary"]).light
        #expect(matches(resolve(primary, dark: false, increased: false), expectedPrimary))
        #expect(style.color(ColourReference(source: "nonexistent")) == nil)
        // The theme's own override mapping is exposed by key.
        let key = try #require(Theme.legacyDefault.palette.colourOverrides.keys.sorted().first)
        let reference = try #require(Theme.legacyDefault.palette.colourOverrides[key])
        let base = try #require(ColorRole(rawValue: reference.source).map { Theme.legacyDefault.palette[$0].light }
                                ?? Theme.legacyDefault.palette.extras[reference.source]?.light)
        let override = try #require(style.override(forKey: key))
        #expect(matches(resolve(override, dark: false, increased: false), ColorValue(base.rgb, alpha: base.alpha * reference.opacity)))
        #expect(style.override(forKey: "no.such.key") == nil)
    }

    @Test("neutral is the theme's neutral extra, and the muted role when the theme has none")
    func neutral() {
        let withExtra = ChartStyle(theme: .legacyDefault, appearance: .light, defersToSystemColors: false)
        let expected = Theme.legacyDefault.palette.extras["neutral"]?.light ?? ColorValue(RGB(red: 1, green: 2, blue: 3))
        #expect(matches(resolve(withExtra.neutral, dark: false, increased: false), expected))
        let without = ChartStyle(theme: .swiss, appearance: .light, defersToSystemColors: false)
        #expect(Theme.swiss.palette.extras["neutral"] == nil)
        #expect(matches(resolve(without.neutral, dark: false, increased: false), Theme.swiss.palette.muted.light))
    }

    @Test("Color(theme:role:appearance:) is the style's colour")
    func colorInit() {
        let color = Color(theme: .ft, role: .background, appearance: .dark, defersToSystemColors: false)
        let expected = Theme.ft.palette.background.value(in: .dark, increasedContrast: false)
        #expect(matches(resolve(color, dark: true, increased: false), expected))
    }
}
#endif
