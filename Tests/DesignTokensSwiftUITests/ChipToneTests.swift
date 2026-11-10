#if canImport(SwiftUI) && os(macOS)
import DesignTokens
import SwiftUI
import Testing
@testable import DesignTokensSwiftUI

@Suite("Outlined chip")
struct ChipToneTests {
    private let style = ChartStyle(theme: .swiss, appearance: .light)

    @Test("tones map to theme roles: neutral secondary ink, emphasis the accent, status the text-safe roles")
    func outlines() {
        #expect(ChipTone.neutral.outline(in: style) == style.secondaryInk)
        #expect(ChipTone.emphasis.outline(in: style) == style.accent)
        #expect(ChipTone.positive.outline(in: style) == style.positive)
        #expect(ChipTone.negative.outline(in: style) == style.negative)
        #expect(ChipTone.warning.outline(in: style) == style.warning)
        #expect(ChipTone.custom(.purple).outline(in: style) == .purple)
    }
}
#endif
