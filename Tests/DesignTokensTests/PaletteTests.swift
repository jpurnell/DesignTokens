import Testing
@testable import DesignTokens

@Suite("Palette")
struct PaletteTests {
    @Test("series colours are the eight system colours in the fixed order (validated for adjacency and colour-vision separation; fails the lightness band for yellow, and in dark for orange, green, yellow and cyan)")
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

    @Test("dark series are the system colours measured in the dark appearance, in the same order")
    func seriesDark() {
        #expect(Palette.seriesDark.map(\.hex) == [
            "#FF9230", "#6D7CFF", "#30D158", "#DB34F2", "#FFD600", "#0091FF", "#FF4245", "#3CD3FE",
        ])
        #expect(Palette.seriesDark.count == Palette.series.count)
        #expect(Palette.seriesDark[0] == ColorToken.accent.dark)
    }

    @Test("adjacent dark series colours also differ by at least 15 in OKLab x100")
    func adjacentDistanceDark() {
        for (a, b) in zip(Palette.seriesDark, Palette.seriesDark.dropFirst()) {
            #expect(OKLab.distance(a, b) >= 15)
        }
    }

    @Test("every dark series colour reads against the dark background at 3 to 1 or better")
    func seriesDarkContrast() {
        let background = ColorToken.background.value(in: .dark)
        for color in Palette.seriesDark {
            #expect(Contrast.ratio(color, background) >= 3)
        }
    }

    @Test("increased-contrast series are the system colours measured with Increase Contrast on, same order")
    func seriesIncreasedContrast() {
        #expect(Palette.seriesIncreasedContrast.map(\.hex) == [
            "#C55300", "#564ADE", "#008932", "#B02FC2", "#A16A00", "#1E6EF4", "#E9152D", "#007EAE",
        ])
        #expect(Palette.seriesIncreasedContrastDark.map(\.hex) == [
            "#FFA056", "#A7AAFF", "#4AD968", "#EA8DFF", "#FEDF43", "#5CB8FF", "#FF6165", "#6DD9FF",
        ])
        #expect(Palette.seriesIncreasedContrast[0] == ColorToken.accent.increasedContrastLight)
        #expect(Palette.seriesIncreasedContrastDark[2] == ColorToken.success.increasedContrastDark)
    }

    @Test("each increased-contrast series colour contrasts with its surface at least as much as the standard one")
    func seriesIncreasedContrastNotWorse() {
        let pairs: [(hc: [RGB], standard: [RGB], appearance: Appearance)] = [
            (Palette.seriesIncreasedContrast, Palette.series, .light),
            (Palette.seriesIncreasedContrastDark, Palette.seriesDark, .dark),
        ]
        for pair in pairs {
            let surface = ColorToken.background.value(in: pair.appearance)
            for (hc, standard) in zip(pair.hc, pair.standard) {
                #expect(Contrast.ratio(hc, surface) >= Contrast.ratio(standard, surface))
            }
        }
    }

    @Test("adjacent increased-contrast series colours differ by at least 15 in OKLab x100")
    func adjacentDistanceIncreasedContrast() {
        for series in [Palette.seriesIncreasedContrast, Palette.seriesIncreasedContrastDark] {
            for (a, b) in zip(series, series.dropFirst()) {
                #expect(OKLab.distance(a, b) >= 15)
            }
        }
    }

    @Test("the dark sequential ramp is the light ramp reversed, so more is lighter on a dark surface")
    func sequentialDark() {
        #expect(Palette.sequentialDark == Palette.sequential.reversed())
        let luminance = Palette.sequentialDark.map(Contrast.luminance)
        #expect(luminance == luminance.sorted())
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
