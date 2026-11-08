import Testing
@testable import DesignTokens

@Suite("RGB")
struct RGBTests {
    @Test("parses six-digit hex with or without the hash, any case")
    func parses() {
        #expect(RGB(hex: "#FF8D28") == RGB(red: 255, green: 141, blue: 40))
        #expect(RGB(hex: "ff8d28") == RGB(red: 255, green: 141, blue: 40))
    }

    @Test("rejects malformed hex")
    func rejects() {
        #expect(RGB(hex: "#FFF") == nil)
        #expect(RGB(hex: "#GG0000") == nil)
        #expect(RGB(hex: "") == nil)
        #expect(RGB(hex: "#FF8D2800") == nil)
    }

    @Test("formats as uppercase #RRGGBB")
    func formats() {
        #expect(RGB(red: 0, green: 10, blue: 255).hex == "#000AFF")
    }
}
