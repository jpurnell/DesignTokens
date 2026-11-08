import Testing
@testable import DesignTokens

@Suite("ColorToken")
struct ColorTokenTests {
    @Test("the role list is the nine SwiftGUIKit roles plus link, in a fixed order")
    func roles() {
        #expect(ColorToken.allCases.map(\.rawValue) == [
            "label", "secondaryLabel", "background", "secondaryBackground", "separator",
            "accent", "link", "success", "warning", "destructive",
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

    @Test("dark values not yet measured on the snapshot release are listed, not guessed")
    func unmeasured() {
        #expect(ColorToken.unmeasuredDark == [.success, .destructive])
        #expect(ColorToken.success.dark == nil)
    }

    @Test("every measured pair has text contrast of at least 4.5 to 1 for label on background")
    func labelContrast() {
        for appearance in Appearance.allCases {
            let ratio = Contrast.ratio(ColorToken.label.value(in: appearance), ColorToken.background.value(in: appearance))
            #expect(ratio >= 4.5)
        }
    }
}
