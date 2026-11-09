import Testing
@testable import DesignTokens

@Suite("ColorToken")
struct ColorTokenTests {
    @Test("the role list is the nine SwiftGUIKit roles plus onAccent and link, in a fixed order")
    func roles() {
        #expect(ColorToken.allCases.map(\.rawValue) == [
            "label", "secondaryLabel", "background", "secondaryBackground", "separator",
            "accent", "onAccent", "link", "success", "warning", "destructive",
        ])
    }

    @Test("accent is Apple's system orange, snapshot of macOS 27.2")
    func accent() {
        #expect(ColorToken.accent.light.hex == "#FF8D28")
        #expect(ColorToken.accent.dark?.hex == "#FF9230")
        #expect(Snapshot.systemRelease == "macOS 27.2")
    }

    @Test("ink and surfaces match the artifact's light and dark blocks")
    func inkAndSurfaces() {
        #expect(ColorToken.label.light.hex == "#111214")
        #expect(ColorToken.label.dark?.hex == "#F2F2EF")
        #expect(ColorToken.background.light.hex == "#FAFAFA")
        #expect(ColorToken.background.dark?.hex == "#101112")
        #expect(ColorToken.separator.light.hex == "#D6D8DB")
        #expect(ColorToken.separator.dark?.hex == "#2E3033")
    }

    @Test("onAccent is ink on the accent, at least 4.5 to 1 in both appearances")
    func onAccent() {
        for appearance in Appearance.allCases {
            let ratio = Contrast.ratio(ColorToken.onAccent.value(in: appearance), ColorToken.accent.value(in: appearance))
            #expect(ratio >= 4.5)
        }
        #expect(ColorToken.onAccent.light.hex == "#111214")
        #expect(ColorToken.onAccent.dark?.hex == "#111214")
    }

    @Test("success and destructive dark values are the system green and red, measured on macOS 27.2")
    func statusDark() {
        #expect(ColorToken.success.dark?.hex == "#30D158")
        #expect(ColorToken.destructive.dark?.hex == "#FF4245")
    }

    @Test("every role has a measured dark value, so nothing falls back to light silently")
    func noneUnmeasured() {
        #expect(ColorToken.unmeasuredDark.isEmpty)
    }

    @Test("every measured pair has text contrast of at least 4.5 to 1 for label on background")
    func labelContrast() {
        for appearance in Appearance.allCases {
            let ratio = Contrast.ratio(ColorToken.label.value(in: appearance), ColorToken.background.value(in: appearance))
            #expect(ratio >= 4.5)
        }
    }

    @Test("increased-contrast values are the system colours measured with Increase Contrast on, macOS 27.2")
    func increasedContrastMeasured() {
        #expect(ColorToken.accent.increasedContrastLight?.hex == "#C55300")
        #expect(ColorToken.accent.increasedContrastDark?.hex == "#FFA056")
        #expect(ColorToken.success.increasedContrastLight?.hex == "#008932")
        #expect(ColorToken.success.increasedContrastDark?.hex == "#4AD968")
        #expect(ColorToken.destructive.increasedContrastLight?.hex == "#E9152D")
        #expect(ColorToken.destructive.increasedContrastDark?.hex == "#FF6165")
    }

    @Test("roles that could not be measured have no increased-contrast value, never a guess")
    func increasedContrastUnmeasured() {
        let measured: Set<ColorToken> = [.accent, .success, .destructive]
        for token in ColorToken.allCases where !measured.contains(token) {
            #expect(token.increasedContrastLight == nil)
            #expect(token.increasedContrastDark == nil)
        }
        #expect(Set(ColorToken.unmeasuredIncreasedContrast) == Set(ColorToken.allCases).subtracting(measured))
    }

    @Test("increased-contrast accent and status colours read against the surface at least as well as the standard value")
    func increasedContrastNotWorse() {
        for token in [ColorToken.accent, .success, .destructive] {
            for appearance in Appearance.allCases {
                let surface = ColorToken.background.value(in: appearance)
                let hc = token.value(in: appearance, increasedContrast: true)
                #expect(Contrast.ratio(hc, surface) >= Contrast.ratio(token.value(in: appearance), surface))
            }
        }
    }

    @Test("link has no increased-contrast value: the measured system link has less contrast than the package's own link")
    func linkNotAdopted() {
        #expect(ColorToken.link.increasedContrastLight == nil)
        #expect(ColorToken.link.increasedContrastDark == nil)
        let measuredLight = RGB(rgb: 0x0068DA), measuredDark = RGB(rgb: 0x419CFF)
        #expect(Contrast.ratio(measuredLight, ColorToken.background.light) < Contrast.ratio(ColorToken.link.light, ColorToken.background.light))
        #expect(Contrast.ratio(measuredDark, ColorToken.background.value(in: .dark)) < Contrast.ratio(ColorToken.link.value(in: .dark), ColorToken.background.value(in: .dark)))
    }

    @Test("value(in:increasedContrast:) falls back to the standard value when unmeasured")
    func increasedContrastFallback() {
        #expect(ColorToken.label.value(in: .dark, increasedContrast: true) == ColorToken.label.value(in: .dark))
        #expect(ColorToken.accent.value(in: .light, increasedContrast: false) == ColorToken.accent.light)
    }
}
