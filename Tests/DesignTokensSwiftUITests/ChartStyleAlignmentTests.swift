#if canImport(SwiftUI) && os(macOS)
@testable import DesignTokens
import SwiftUI
import Testing
@testable import DesignTokensSwiftUI

/// What BusinessMath-UI reads to draw the approved Swiss chart: neutral and emphasis fills, the title rule's
/// geometry, the heavy baseline, the target line, the value halo and the card. Colours are resolved, so every test
/// is `@MainActor`.
@MainActor
@Suite("ChartStyle chart alignment")
struct ChartStyleAlignmentTests {
    private func style(_ theme: Theme = .swiss, dark: Bool = false, increased: Bool = false) -> ChartStyle {
        ChartStyle(theme: theme, appearance: dark ? .dark : .light, increasedContrast: increased, defersToSystemColors: false)
    }

    private func resolve(_ color: Color, dark: Bool = false) -> Color.Resolved {
        var environment = EnvironmentValues()
        environment.colorScheme = dark ? .dark : .light
        return color.resolve(in: environment)
    }

    private func matches(_ resolved: Color.Resolved, _ value: ColorValue) -> Bool {
        let half = 0.5 / 255.0
        return abs(Double(resolved.red) - Double(value.rgb.red) / 255) <= half
            && abs(Double(resolved.green) - Double(value.rgb.green) / 255) <= half
            && abs(Double(resolved.blue) - Double(value.rgb.blue) / 255) <= half
    }

    // MARK: Fills

    @Test("Swiss: an un-emphasised mark is the neutral grey and an emphasised one is the accent, in light and dark")
    func swissFills() {
        for dark in [false, true] {
            let s = style(dark: dark)
            #expect(matches(resolve(s.markFill(emphasised: false), dark: dark), s.value(.muted)), "neutral dark=\(dark)")
            #expect(matches(resolve(s.markFill(emphasised: true), dark: dark), s.value(.accent)), "emphasis dark=\(dark)")
            #expect(matches(resolve(s.emphasisColour, dark: dark), s.value(.accent)))
        }
        #expect(style().markFillValue(emphasised: false).hex == "#B9BBBD")
        #expect(style(dark: true).markFillValue(emphasised: false).hex == "#4E5053")
        #expect(style(increased: true).markFillValue(emphasised: false).hex == "#8E9196")
        #expect(style(dark: true, increased: true).markFillValue(emphasised: false).hex == "#6F7176")
        #expect(style().markFillValue(emphasised: true).hex == "#FF8D28")
    }

    @Test("a theme whose default fill is the series colours fills un-emphasised marks with the series, and greys them only when emphasis is named")
    func houseFills() {
        let s = style(.house)
        #expect(s.defaultMarkFill == .series)
        #expect(s.markFillValue(emphasised: false, series: 2) == s.seriesValue(2))
        #expect(s.markFillValue(emphasised: false, emphasisNamed: true, series: 2) == s.value(.muted))
        #expect(s.markFillValue(emphasised: true, emphasisNamed: true) == s.value(.accent))
    }

    @Test("the emphasis fill is the theme's role: Princeton's accent is its own orange")
    func emphasisIsTheThemesAccent() {
        let princeton = style(.princeton)
        #expect(princeton.markFillValue(emphasised: true) == princeton.value(.accent))
        #expect(princeton.markFillValue(emphasised: true) != style().markFillValue(emphasised: true))
        var recoloured = Theme.swiss
        recoloured.structure.marks.emphasisFill = .link
        #expect(style(recoloured).markFillValue(emphasised: true) == style(recoloured).value(.link))
    }

    @Test("the grey ladder for two or three series is the secondary ink, then the muted grey, then stays muted")
    func greyLadder() {
        let light = style()
        #expect(light.neutralLadderValue(0).hex == "#6A6D72")
        #expect(light.neutralLadderValue(1).hex == "#B9BBBD")
        #expect(light.neutralLadderValue(2).hex == "#B9BBBD")
        let dark = style(dark: true)
        #expect(dark.neutralLadderValue(0).hex == "#9A9DA2")
        #expect(dark.neutralLadderValue(1).hex == "#4E5053")
        #expect(matches(resolve(light.neutralLadder(0)), light.value(.secondaryInk)))
    }

    @Test("default emphasis: the index the theme emphasises when the author names none")
    func defaultEmphasisIndex() {
        #expect(style().defaultEmphasis == .latest)
        #expect(style().defaultEmphasisIndex(count: 8, isVertical: true) == 7)
        #expect(style().defaultEmphasisIndex(count: 8, isVertical: false) == nil)
        #expect(style(.house).defaultEmphasisIndex(count: 8, isVertical: true) == nil)
    }

    // MARK: Rules, labels, layout

    @Test("the title rule sits above the title with an 8 pt gap, and a theme with no gapAfter falls back to the title gap")
    func titleRuleGeometry() throws {
        let rule = try #require(style().titleRule)
        #expect(rule.position == .aboveTitle)
        #expect(near(rule.weight, 3))
        #expect(near(rule.gap, 8))
        #expect(near(style().titleRuleGap, 8))
        let house = style(.house)
        #expect(near(house.titleRuleGap, house.titleGap))
        let economist = try #require(style(.economist).titleRule)
        #expect(near(economist.gap, style(.economist).titleGap))
    }

    @Test("the baseline is a 1.5 pt ink rule in Swiss, and the rule colour elsewhere")
    func baseline() {
        #expect(near(style().baselineWeight, 1.5))
        #expect(matches(resolve(style().baselineColor), style().value(.ink)))
        #expect(matches(resolve(style(.house).baselineColor), style(.house).value(.rule)))
    }

    @Test("the target line is a muted solid hairline with an ink label 5 pt above it in Swiss; other themes keep their dashed secondary-ink line (House: 4 4), 3 pt")
    func referenceLine() {
        let s = style()
        #expect(near(s.referenceStroke.lineWidth, 1))
        #expect(s.referenceStroke.dash.isEmpty)
        #expect(matches(resolve(s.referenceColor), s.value(.secondaryInk)))
        #expect(matches(resolve(s.referenceLabelColor), s.value(.ink)))
        #expect(near(s.referenceLabelGap, 5))
        let house = style(.house)
        #expect(house.referenceStroke.dash == [4, 4])
        #expect(matches(resolve(house.referenceColor), house.value(.secondaryInk)))
        #expect(matches(resolve(house.referenceLabelColor), house.value(.secondaryInk)))
        #expect(near(house.referenceLabelGap, 3))
    }

    @Test("the value halo is 3 pt of the background colour in Swiss, none elsewhere")
    func halo() {
        #expect(near(style().valueHalo, 3))
        #expect(matches(resolve(style().valueHaloColor), style().value(.background)))
        #expect(matches(resolve(style(dark: true).valueHaloColor, dark: true), style(dark: true).value(.background)))
        #expect(near(style(.house).valueHalo, 0))
        #expect(!style(.house).hasValueHalo && style().hasValueHalo)
    }

    @Test("the halo is the surface the text sits on: a light-only theme in a dark context has its own light background as halo, and the ink paired with it")
    func haloMatchesTheSurfaceBehindTheText() {
        let princeton = style(.princeton, dark: true)
        // Princeton declares no dark values, so a dark context shows its light colours: halo, background and ink stay a pair
        #expect(princeton.valueHaloValue() == ChartStyle(theme: .princeton, appearance: .light, defersToSystemColors: false).value(.background))
        #expect(princeton.valueHaloValue().hex == "#FAFAFA")
        #expect(Contrast.ratio(princeton.value(.ink).rgb, princeton.valueHaloValue().rgb) >= 4.5)
        #expect(princeton.paintsOwnSurface, "dark context, light-only theme: the chart must paint its own background or the halo shows as a white shadow")
        #expect(!style(.princeton).paintsOwnSurface)
        #expect(!style(.swiss, dark: true).paintsOwnSurface, "Swiss has dark values, so its dark halo is the dark background")
        #expect(style(.swiss, dark: true).valueHaloValue().hex == "#101112")
        #expect(style(.swiss).valueHaloValue().hex == "#FAFAFA")
        // a caller that paints a different surface behind the text says so, and the halo follows it
        let surround = ColorValue(RGB(rgb: 0x101112))
        #expect(princeton.valueHaloValue(over: surround) == surround)
        #expect(matches(resolve(princeton.valueHaloColor(over: surround.color), dark: true), surround))
    }

    @Test("the card border is off in Swiss and on, in the rule colour, with its padding, for the opt-in variant")
    func cardBorder() {
        let off = style()
        #expect(!off.hasCardBorder)
        #expect(near(off.cardBorderWeight, 0))
        #expect(near(off.cardPadding, 0))
        let on = style(Theme.swiss.withCardBorder())
        #expect(on.hasCardBorder)
        #expect(near(on.cardBorderWeight, 1))
        #expect(near(on.cardPadding, 8))
        #expect(matches(resolve(on.cardBorderColor), on.value(.rule)))
    }

    @Test("the margins are symmetric 8 pt left and right with 6 above and 12 below, and bars take 0.7 of their slot")
    func marginsAndBars() {
        let s = style()
        #expect(near(s.margins.leading, 8) && near(s.margins.trailing, 8))
        #expect(near(s.margins.top, 6) && near(s.margins.bottom, 12))
        #expect(near(s.barWidthRatio, 0.7))
    }

    @Test("number format digits come through the style")
    func digits() {
        #expect(style().fractionDigits(.plain) == 0...2)
        #expect(style(.house).fractionDigits(.plain) == 2...2)
        #expect(style(.house).fractionDigits(.currency) == nil)
    }

    @Test("the dark diverging ramp is sampled in dark: its ends are the system dark blue and orange")
    func darkDiverging() {
        let dark = style(dark: true)
        #expect(matches(resolve(dark.diverging(0), dark: true), ColorValue(RGB(rgb: 0x0091FF))))
        #expect(matches(resolve(dark.diverging(1), dark: true), ColorValue(RGB(rgb: 0xFF9230))))
        #expect(matches(resolve(dark.sequential(1), dark: true), ColorValue(RGB(rgb: 0x7FBCFE))))
    }
}
#endif
