#if canImport(SwiftUI) && os(macOS)
import DesignTokens
import SwiftUI
import Testing
@testable import DesignTokensSwiftUI
@testable import DesignTokens

@Suite("Outlined chip")
struct ChipToneTests {
    private let style = ChartStyle(theme: .swiss, appearance: .light)

    @Test("tones map to theme roles: neutral secondary ink, emphasis the accent, status the text-safe roles, warning the alert extra")
    func outlines() {
        #expect(ChipTone.neutral.outline(in: style) == style.secondaryInk)
        #expect(ChipTone.emphasis.outline(in: style) == style.accent)
        #expect(ChipTone.positive.outline(in: style) == style.positive)
        #expect(ChipTone.negative.outline(in: style) == style.negative)
        #expect(ChipTone.caution.outline(in: style) == style.warning)
        #expect(ChipTone.warning.outline(in: style) == style.alert)
        #expect(ChipTone.custom(.purple).outline(in: style) == .purple)
    }

    @Test("a status kind and its chip tone are the same colour as the banner fill of that kind")
    func toneMatchesKind() {
        for kind in StatusKind.allCases {
            for (appearance, increased) in [(Appearance.light, false), (.dark, false), (.light, true), (.dark, true)] {
                let s = ChartStyle(theme: .swiss, appearance: appearance, increasedContrast: increased, defersToSystemColors: false)
                let fill = StatusBannerStyle.resolve(kind, style: s).fill
                #expect(ChipTone.status(kind).outline(in: s) == fill.color, "\(kind) \(appearance) \(increased)")
            }
        }
    }

    @Test("caution and warning are two colours in every appearance, apart by at least 8 in OKLab (observed worst case 8.2, light)")
    func cautionAndWarningApart() {
        for (appearance, increased) in [(Appearance.light, false), (.dark, false), (.light, true), (.dark, true)] {
            let s = ChartStyle(theme: .swiss, appearance: appearance, increasedContrast: increased, defersToSystemColors: false)
            let caution = s.value(StatusKind.caution.adaptive(in: .swiss)).rgb
            let warning = s.value(StatusKind.warning.adaptive(in: .swiss)).rgb
            let distance = ColorAnalysis.deltaE(caution, warning, nil)
            #expect(distance >= 8, "\(appearance) increased=\(increased): \(distance)")
        }
    }

    @Test("a theme with no alert colour shows a warning in its warning role")
    func fallbackWithoutAlert() {
        var theme = Theme.swiss
        theme.palette.extras[ThemePalette.alertName] = nil
        #expect(StatusKind.warning.adaptive(in: theme) == theme.palette.warning)
        #expect(StatusKind.warning.adaptive(in: .swiss) != Theme.swiss.palette.warning)
    }

    @Test("every status tone's outline reaches 3:1 (WCAG 1.4.11) on the background and the card surface in light, dark and both increased-contrast appearances")
    func outlineContrast() {
        let tones: [(String, StatusKind)] = [("neutral", .neutral), ("positive", .positive), ("caution", .caution),
                                             ("warning", .warning), ("negative", .negative)]
        for (name, kind) in tones {
            for (appearance, increased) in [(Appearance.light, false), (.dark, false), (.light, true), (.dark, true)] {
                let s = ChartStyle(theme: .swiss, appearance: appearance, increasedContrast: increased, defersToSystemColors: false)
                let outline = s.value(kind.adaptive(in: .swiss)).rgb
                for surface in [ColorRole.background, .surface] {
                    let ratio = outline.contrastRatio(with: s.value(surface).rgb)
                    #expect(ratio >= 3, "\(name) \(appearance) increased=\(increased) on \(surface): \(ratio)")
                }
            }
        }
    }

    @Test("the chip's corner is the theme's container radius by default (square in Swiss) and the control radius on request")
    func shapes() {
        let metrics = SwissMetrics(theme: .swiss)
        #expect(ChipShape.container.shape(metrics).cornerSize == metrics.containerShape.cornerSize)
        #expect(ChipShape.control.shape(metrics).cornerSize == metrics.controlShape.cornerSize)
        #expect(metrics.containerRadius.isZero)
        #expect(metrics.controlRadius > 0)
        var rounded = Theme.swiss
        rounded.structure.layout.containerRadius = 6
        #expect(ChipShape.container.shape(SwissMetrics(theme: rounded)).cornerSize.width.isEqual(to: 6), "the default follows the theme, it is not a literal")
    }
}
#endif
