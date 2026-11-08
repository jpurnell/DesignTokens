import Testing
@testable import DesignTokens

@Suite("Palette")
struct PaletteTests {
    @Test("series colours are the eight system colours in the validated order")
    func series() {
        #expect(Palette.series.map(\.hex) == [
            "#FF8D28", "#6155F5", "#34C759", "#CB30E0", "#FFCC00", "#0088FF", "#FF383C", "#00C0E8",
        ])
        #expect(Palette.seriesNames == ["orange", "indigo", "green", "purple", "yellow", "blue", "red", "cyan"])
    }

    @Test("adjacent series colours differ by at least 15 in OKLab x100 (normal-vision floor)")
    func adjacentDistance() {
        for (a, b) in zip(Palette.series, Palette.series.dropFirst()) {
            #expect(OKLab.distance(a, b) >= 15)
        }
    }

    @Test("sequential and diverging ramps are the system-orange ramps")
    func ramps() {
        #expect(Palette.sequential.map(\.hex) == ["#FF9134", "#DF7502", "#B85F01", "#924A01", "#6E3700"])
        #expect(Palette.diverging.map(\.hex) == ["#0088FF", "#8ABBF8", "#E8E8E8", "#F7BD95", "#FF8D28"])
    }

    @Test("the Princeton accent is kept as a custom option, not the default")
    func princeton() {
        #expect(Palette.princetonAccent.hex == "#E77500")
        #expect(Palette.series.first != Palette.princetonAccent)
    }
}
