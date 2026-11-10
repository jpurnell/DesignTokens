import Foundation
import Testing
@testable import DesignTokens

@Suite("Terminal colour quantisation")
struct TerminalColourTests {
    /// The xterm 256-colour table entries 16 to 255, built here from the published construction
    /// (6x6x6 cube with levels 0, 95, 135, 175, 215, 255; then 24 greys 8 + 10k), not from the package.
    private static let table: [(index: Int, rgb: RGB)] = {
        let levels: [UInt8] = [0, 95, 135, 175, 215, 255]
        var out: [(Int, RGB)] = []
        for r in 0..<6 { for g in 0..<6 { for b in 0..<6 {
            out.append((16 + 36 * r + 6 * g + b, RGB(red: levels[r], green: levels[g], blue: levels[b])))
        } } }
        for k in 0..<24 {
            let v = UInt8(8 + 10 * k)
            out.append((232 + k, RGB(red: v, green: v, blue: v)))
        }
        return out
    }()

    @Test("the table has 240 entries and every one maps to its own index")
    func everyEntryRoundTrips() {
        #expect(Self.table.count == 240)
        for entry in Self.table {
            #expect(TerminalColour.xterm256(entry.rgb) == entry.index, "index \(entry.index)")
        }
    }

    @Test("published anchors: orange, black, white, mid grey, cube blue-grey")
    func anchors256() {
        #expect(TerminalColour.xterm256(RGB(rgb: 0xFF8D28)) == 208)   // (255,135,0): distance 36 + 1600
        #expect(TerminalColour.xterm256(RGB(rgb: 0x000000)) == 16)
        #expect(TerminalColour.xterm256(RGB(rgb: 0xFFFFFF)) == 231)
        #expect(TerminalColour.xterm256(RGB(rgb: 0x808080)) == 244)   // 8 + 10 * 12 = 128
        #expect(TerminalColour.xterm256(RGB(rgb: 0x5F87AF)) == 67)    // 16 + 36 + 12 + 3
        #expect(TerminalColour.xterm256(RGB(rgb: 0xFF0000)) == 196)
    }

    @Test("an exact tie goes to the lower index: (115,0,0) is 20 from both 95 and 135")
    func tieGoesLow() {
        #expect(TerminalColour.xterm256(RGB(red: 115, green: 0, blue: 0)) == 52)
    }

    @Test("indices 0 to 15 are never chosen for the 256 column")
    func neverTheUsersSixteen() {
        for value in stride(from: 0, through: 255, by: 15) {
            let v = UInt8(value)
            #expect(TerminalColour.xterm256(RGB(red: v, green: 255 - v, blue: v / 2)) >= 16)
        }
    }

    @Test("sixteen-colour: anchors with hand-computed nearest (orange is 3: 8196 against 14596 for 11)")
    func anchors16() {
        #expect(TerminalColour.xterm16(RGB(rgb: 0xFF8D28)) == 3)
        #expect(TerminalColour.xterm16(RGB(rgb: 0x000000)) == 0)
        #expect(TerminalColour.xterm16(RGB(rgb: 0xFFFFFF)) == 15)
        #expect(TerminalColour.xterm16(RGB(rgb: 0xFF0000)) == 9)
        #expect(TerminalColour.xterm16(RGB(rgb: 0x00CD00)) == 2)
        #expect(TerminalColour.xterm16(RGB(rgb: 0xE5E5E5)) == 7)
        #expect(TerminalColour.xterm16(RGB(rgb: 0x7F7F7F)) == 8)
    }

    @Test("sixteen-colour SGR codes: 0 to 7 are 30 to 37 (40 to 47), 8 to 15 are 90 to 97 (100 to 107)")
    func sgrCodes() {
        #expect(TerminalColour.sgr16(0, background: false) == 30)
        #expect(TerminalColour.sgr16(3, background: false) == 33)
        #expect(TerminalColour.sgr16(7, background: false) == 37)
        #expect(TerminalColour.sgr16(8, background: false) == 90)
        #expect(TerminalColour.sgr16(15, background: false) == 97)
        #expect(TerminalColour.sgr16(0, background: true) == 40)
        #expect(TerminalColour.sgr16(7, background: true) == 47)
        #expect(TerminalColour.sgr16(8, background: true) == 100)
        #expect(TerminalColour.sgr16(15, background: true) == 107)
    }
}
