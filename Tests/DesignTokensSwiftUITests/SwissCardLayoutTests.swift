#if canImport(SwiftUI) && os(macOS)
import DesignTokens
import SwiftUI
import Testing
@testable import DesignTokensSwiftUI

/// Measured in a real window: where the footers and the bottoms of cards end up.
@MainActor
@Suite("Swiss card in a row")
struct SwissCardLayoutTests {
    private func card(_ name: String, long: Bool) -> some View {
        SwissCard(label: "#1", title: "Title \(name)",
                  description: long ? String(repeating: "A long description that wraps onto several lines. ", count: 5) : "Short.",
                  footer: { Text("footer \(name)").probe("footer\(name)") })
            .probe("card\(name)")
    }

    @Test("in a SwissEqualGrid the cards of a row are one height and their footers sit on the same line")
    func footersAlign() throws {
        let frames = renderFrames(SwissEqualGrid(minimumColumnWidth: 200, spacing: 16) {
            card("A", long: false)
            card("B", long: true)
        }.swissCardChrome(.borderless), width: 440)
        let a = try #require(frames["cardA"]), b = try #require(frames["cardB"])
        let fa = try #require(frames["footerA"]), fb = try #require(frames["footerB"])
        #expect(near(a.height, b.height), "equal height: \(a.height) against \(b.height)")
        #expect(near(a.minY, b.minY))
        #expect(near(fa.maxY, fb.maxY), "footers aligned: \(fa.maxY) against \(fb.maxY)")
        #expect(near(fa.maxY, a.maxY - 12), "the footer is pinned to the bottom edge, inside the card's vertical padding")
    }

    @Test("outside a grid a card is as tall as its content: the footer follows the content, it is not stretched")
    func notStretched() throws {
        let frames = renderFrames(HStack(alignment: .top, spacing: 16) {
            card("A", long: false)
            card("B", long: true)
        }, width: 440)
        let a = try #require(frames["cardA"]), b = try #require(frames["cardB"])
        #expect(a.height < b.height, "a short card stays short: \(a.height) against \(b.height)")
    }

    @Test("a lone last card keeps the width of the others, and rows are as tall as their tallest card")
    func loneLastCard() throws {
        let frames = renderFrames(SwissEqualGrid(minimumColumnWidth: 200, spacing: 16) {
            card("A", long: false)
            card("B", long: false)
            card("C", long: true)
        }, width: 440)
        let a = try #require(frames["cardA"]), b = try #require(frames["cardB"]), c = try #require(frames["cardC"])
        #expect(near(a.width, 212) && near(b.width, 212) && near(c.width, 212), "two columns of 212 in 440 with a 16 gutter")
        #expect(near(c.minX, a.minX), "the third card starts a new row")
        #expect(c.minY > a.maxY, "below the first row")
        #expect(near(a.height, b.height))
    }

    @Test("below the minimum column width the grid is one column")
    func oneColumn() throws {
        let frames = renderFrames(SwissEqualGrid(minimumColumnWidth: 300, spacing: 16) {
            card("A", long: false)
            card("B", long: false)
        }, width: 400)
        let a = try #require(frames["cardA"]), b = try #require(frames["cardB"])
        #expect(near(a.width, 400) && near(b.width, 400))
        #expect(b.minY > a.maxY)
    }

    @Test("borderless: the footer text is flush with the card's edge; bordered: it is inset by three base units")
    func chrome() throws {
        func footerX(_ chrome: SwissCardChrome) throws -> CGFloat {
            let frames = renderFrames(SwissCard(title: "T", footer: { Text("F").probe("footer") })
                .swissCardChrome(chrome).probe("card"), width: 300)
            return try #require(frames["footer"]).minX - #require(frames["card"]).minX
        }
        #expect(try near(footerX(.borderless), 0))
        #expect(try near(footerX(.bordered), 12))
    }
}
#endif
