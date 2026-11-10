#if canImport(SwiftUI) && os(macOS)
import DesignTokens
import SwiftUI
import Testing
@testable import DesignTokensSwiftUI

/// WCAG contrast written out from the published formula, independent of the package's.
private func published(_ a: RGB, _ b: RGB) -> Double {
    func lin(_ c: UInt8) -> Double {
        let s = Double(c) / 255
        return s <= 0.04045 ? s / 12.92 : pow((s + 0.055) / 1.055, 2.4)
    }
    func lum(_ v: RGB) -> Double { 0.2126 * lin(v.red) + 0.7152 * lin(v.green) + 0.0722 * lin(v.blue) }
    let hi = max(lum(a), lum(b)), lo = min(lum(a), lum(b))
    return (hi + 0.05) / (lo + 0.05)
}

@Suite("Status banner: text on each status fill")
struct StatusBannerTests {
    private let appearances: [(Appearance, Bool)] = [(.light, false), (.dark, false), (.light, true), (.dark, true)]

    @Test("on every status fill, in light, dark and both increased-contrast appearances, the chosen text reads at 4.5:1")
    func textReadsOnEveryFill() {
        for kind in StatusKind.allCases {
            for (appearance, increased) in appearances {
                let style = ChartStyle(theme: .swiss, appearance: appearance, increasedContrast: increased, defersToSystemColors: false)
                let resolved = StatusBannerStyle.resolve(kind, style: style)
                let ratio = published(resolved.text.rgb, resolved.fill.rgb)
                #expect(ratio >= 4.5, "\(kind) \(appearance) increased=\(increased): \(ratio)")
                #expect(abs(resolved.contrast - ratio) < 1e-9, "the reported contrast is the measured one")
            }
        }
    }

    @Test("the chosen text is the better of ink and the background")
    func chosenIsBetter() {
        for kind in StatusKind.allCases {
            for (appearance, increased) in appearances {
                let style = ChartStyle(theme: .swiss, appearance: appearance, increasedContrast: increased, defersToSystemColors: false)
                let resolved = StatusBannerStyle.resolve(kind, style: style)
                let ink = published(style.value(.ink).rgb, resolved.fill.rgb)
                let background = published(style.value(.background).rgb, resolved.fill.rgb)
                #expect(abs(resolved.contrast - max(ink, background)) < 1e-9, "\(kind) \(appearance)")
            }
        }
    }

    @Test("the fill is the theme's role for the status")
    func fills() {
        let style = ChartStyle(theme: .swiss, appearance: .light, defersToSystemColors: false)
        #expect(StatusBannerStyle.resolve(.positive, style: style).fill == style.value(.positive))
        #expect(StatusBannerStyle.resolve(.negative, style: style).fill == style.value(.negative))
        #expect(StatusBannerStyle.resolve(.caution, style: style).fill == style.value(.warning))
        #expect(StatusBannerStyle.resolve(.warning, style: style).fill == style.value(StatusKind.warning.adaptive(in: .swiss)))
        #expect(StatusBannerStyle.resolve(.neutral, style: style).fill == style.value(.secondaryInk))
    }

    @Test("each status has its own glyph shape, so the state is not told by colour alone")
    func glyphsDistinct() {
        let glyphs = StatusKind.allCases.map(\.glyph)
        #expect(Set(glyphs).count == glyphs.count)
    }
}
#endif
