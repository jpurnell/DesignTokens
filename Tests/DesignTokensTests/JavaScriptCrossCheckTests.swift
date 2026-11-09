import Foundation
import Testing
@testable import DesignTokens

/// Runs the vendored copy of the dataviz skill's `validate_palette.js` (`Vendored/`, hash-pinned by
/// `VendoredScriptTests`) under Node on the same palettes and compares numbers. Needs Node; where it is absent
/// the tests are SKIPPED and the skip is visible in the test report with the reason (it is never a silent pass).
@Suite("JavaScript cross-check")
struct JavaScriptCrossCheckTests {
    static let node: String? = JavaScriptValidator.nodePath()
    static let script: String? = JavaScriptValidator.scriptPath()
    static let reason = "needs Node (found: \(node ?? "none"); set NODE to its path) and the vendored validate_palette.js (found: \(script ?? "none"))"

    @Test("validatorMatchesJavaScriptOnAllPalettes", .enabled(if: node != nil && script != nil, Comment(rawValue: reason)))
    func validatorMatchesJavaScriptOnAllPalettes() throws {
        let node = try #require(Self.node)
        let script = try #require(Self.script)
        var cases: [JavaScriptValidator.Case] = []
        for theme in Theme.all {
            for dark in (theme.appearances == .both ? [false, true] : [theme.appearances == .fixedDark]) {
                let background = ThemeValidator.surface(of: theme, role: .background, appearance: dark ? .dark : .light)
                let colours = theme.palette.series.map { ThemeValidator.resolved(ThemeValidator.value($0.color, theme: theme, appearance: dark ? .dark : .light), over: background).rgb.hex }
                cases.append(.init(name: "\(theme.id) \(dark ? "dark" : "light") adjacent", palette: colours, dark: dark, surface: background.rgb.hex, pairs: "adjacent"))
                if colours.count <= 8 {
                    cases.append(.init(name: "\(theme.id) \(dark ? "dark" : "light") all", palette: colours, dark: dark, surface: background.rgb.hex, pairs: "all"))
                }
            }
        }
        // a deliberately bad palette: the comparison must see failures, not agree on silence
        cases.append(.init(name: "bad", palette: ["#808080", "#808080", "#FFFFFF", "#7F7F80"], dark: false, surface: "#FAFAFA", pairs: "all"))
        let results = try JavaScriptValidator.run(node: node, script: script, cases: cases)
        #expect(results.count == cases.count)
        var failuresSeen = 0
        for (c, js) in zip(cases, results) {
            let m = try ThemeValidator.measure(hexes: c.palette, surface: c.surface, dark: c.dark, pairs: c.pairs == "all" ? .all : .adjacent)
            #expect(js.bandOffenders == m.outOfBand.map { JavaScriptValidator.Offender(hex: m.hexes[$0.index], value: Rounding.places($0.value, 3)) }, "\(c.name) band")
            #expect(js.chromaOffenders == m.chromaBelowFloor.map { JavaScriptValidator.Offender(hex: m.hexes[$0.index], value: Rounding.places($0.value, 3)) }, "\(c.name) chroma")
            let cvd = try #require(m.worstCVD, "\(c.name) has a compared pair")
            let normal = try #require(m.worstNormal, "\(c.name) has a compared pair")
            #expect(same([js.cvdWorst], [Rounding.places(cvd.value, 1)]), "\(c.name) CVD \(js.cvdWorst) vs \(cvd.value)")
            #expect(js.cvdKind == cvd.kind?.rawValue, "\(c.name) CVD kind")
            #expect(js.cvdState == m.cvdState.rawValue, "\(c.name) CVD state")
            #expect(same([js.normalWorst], [Rounding.places(normal.value, 1)]), "\(c.name) normal")
            #expect(js.contrastOffenders == m.contrast.enumerated().filter { $0.element < 3 }.map { JavaScriptValidator.Offender(hex: m.hexes[$0.offset], value: Rounding.places($0.element, 2)) }, "\(c.name) contrast")
            if js.cvdState == "fail" || js.normalWorst < 15 || !js.bandOffenders.isEmpty { failuresSeen += 1 }
        }
        #expect(failuresSeen >= 3, "the comparison saw real failures, so agreement is not agreement on silence")
    }

    @Test("ordinal ramps agree with validateOrdinal (monotone, step gap, light end)", .enabled(if: node != nil && script != nil, Comment(rawValue: reason)))
    func ordinalRampsMatchJavaScript() throws {
        let node = try #require(Self.node)
        let script = try #require(Self.script)
        let ramps: [(String, [String], Bool, String)] = [
            ("swiss sequential light", Palette.sequential.map(\.hex), false, "#FAFAFA"),
            ("swiss sequential dark", Palette.sequentialDark.map(\.hex), true, "#101112"),
            ("swiss blue sequential light", Theme.swiss.palette.sequential.light.map(\.hex), false, "#FAFAFA"),
            ("swiss blue sequential dark", (Theme.swiss.palette.sequential.dark ?? []).map(\.hex), true, "#101112"),
            ("economist sequential", Theme.economist.palette.sequential.light.map(\.hex), false, "#FFFFFF"),
            ("ft sequential dark", (Theme.ft.palette.sequential.dark ?? []).map(\.hex), true, "#1F1B18"),
            ("shuffled", ["#FF9134", "#6E3700", "#B85F01", "#DF7502", "#924A01"], false, "#FAFAFA"),
        ]
        let results = try JavaScriptValidator.runOrdinal(node: node, script: script, ramps: ramps)
        for ((name, hexes, dark, surface), js) in zip(ramps, results) {
            let m = try ThemeValidator.measureRamp(hexes: hexes, surface: surface, dark: dark)
            #expect(js.monotone == m.monotone, "\(name) monotone")
            #expect(js.thinSteps == m.thinSteps.count, "\(name) thin steps")
            #expect(same([js.lightEnd], [Rounding.places(m.lightEndContrast, 2)]), "\(name) light end")
            #expect(same([js.hueSpread], [Rounding.places(m.hueSpread, 0)]), "\(name) hue spread")
        }
        #expect(results.last?.monotone == false)
    }
}
