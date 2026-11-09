import Foundation
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

    @Test("a sign is not a hex digit: UInt32(_, radix: 16) would accept '+' and '-', the parser must not")
    func rejectsSigns() {
        for text in ["#+12345", "+12345", "#-00000", "-00000", "#1+2+3+", "#12345-", "#-1234a"] {
            #expect(RGB(hex: text) == nil, "\(text)")
            #expect(ColorValue(hex: text) == nil, "\(text)")
        }
    }

    @Test("the alpha byte of an eight-digit colour is strict hex too")
    func rejectsSignedAlpha() {
        for text in ["#112233+F", "#112233-0", "#112233+0", "112233-F", "#112233 F", "#112233 "] {
            #expect(ColorValue(hex: text) == nil, "\(text)")
        }
        #expect(ColorValue(hex: "#1122330F")?.hex == "#1122330F")
        #expect(ColorValue(hex: "#112233ff")?.hex == "#112233")
    }

    @Test("full-width and other non-ASCII digits are not hex digits")
    func rejectsNonASCII() {
        #expect(RGB(hex: "#１１２２３３") == nil)
        #expect(ColorValue(hex: "#１１２２３３") == nil)
        #expect(RGB(hex: "#11 233") == nil)
    }

    @Test("a signed colour string does not decode from JSON")
    func signedHexDoesNotDecode() {
        #expect(throws: (any Error).self) { try JSONDecoder().decode(ColorValue.self, from: Data("\"#+12345\"".utf8)) }
        #expect(throws: (any Error).self) { try JSONDecoder().decode(ColorValue.self, from: Data("\"#112233+F\"".utf8)) }
        #expect(throws: Never.self) { try JSONDecoder().decode(ColorValue.self, from: Data("\"#112233\"".utf8)) }
    }

    @Test("formats as uppercase #RRGGBB")
    func formats() {
        #expect(RGB(red: 0, green: 10, blue: 255).hex == "#000AFF")
    }
}
