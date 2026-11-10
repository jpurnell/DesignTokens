import Foundation
import Testing
@testable import DesignTokens

@Suite("Theme slots")
struct ThemeSlotTests {
    @Test("a theme that declares both appearances has four slots, in a fixed order")
    func both() {
        #expect(ThemeSlot.slots(for: Theme.swiss).map(\.name) == ["light", "light-increased", "dark", "dark-increased"])
    }

    @Test("a light-only theme has two, a fixed-dark theme has two named dark")
    func single() {
        #expect(Theme.princeton.appearances == .lightOnly)
        #expect(ThemeSlot.slots(for: Theme.princeton).map(\.name) == ["light", "light-increased"])
        #expect(Theme.legacyDark.appearances == .fixedDark)
        #expect(ThemeSlot.slots(for: Theme.legacyDark).map(\.name) == ["dark", "dark-increased"])
    }

    @Test("Swiss: the slots resolve to the measured values (accent light #FF8D28, dark #FF9230)")
    func swissValues() throws {
        let slots = ThemeSlot.slots(for: Theme.swiss)
        let accent = Theme.swiss.palette.accent
        #expect(slots[0].rgb(accent, in: Theme.swiss).hex == "#FF8D28")
        #expect(slots[2].rgb(accent, in: Theme.swiss).hex == "#FF9230")
    }

    @Test("a fixed-dark theme reads its single (light) slot for the dark name")
    func fixedDarkReadsStoredValue() {
        let theme = Theme.legacyDark
        let slot = ThemeSlot.slots(for: theme)[0]
        #expect(slot.rgb(theme.palette.background, in: theme) == theme.palette.background.light.rgb)
    }

    @Test("a translucent colour is composited over the slot background: 200,100,0 at 128/255 over white is 227,177,127")
    func composite() {
        var theme = Theme.swiss
        theme.palette.background.light = ColorValue(RGB(rgb: 0xFFFFFF))
        let translucent = Adaptive(light: ColorValue(RGB(red: 200, green: 100, blue: 0), alpha: 128.0 / 255.0))
        let out = ThemeSlot.slots(for: theme)[0].rgb(translucent, in: theme)
        // 255 - 55a, 255 - 155a, 255 - 255a with a = 128/255: 227.4, 177.2, 127
        #expect(out == RGB(red: 227, green: 177, blue: 127))
    }

    @Test("an opaque colour is returned unchanged")
    func opaque() {
        let slot = ThemeSlot.slots(for: Theme.swiss)[0]
        #expect(slot.rgb(Adaptive(light: ColorValue(RGB(rgb: 0x123456))), in: Theme.swiss) == RGB(rgb: 0x123456))
    }
}
