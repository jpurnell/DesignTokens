import Foundation

public extension Theme {
    /// Princeton's colours as an ``AppPalette``: Princeton orange as the accent, an eight-colour categorical
    /// palette, and orange sequential and diverging ramps, from `EditorialTheme.swissPrinceton` in
    /// BusinessMath-UI exactly (the accent from ``Palette/princetonAccent``). No dark values: the dark
    /// reference values in that file's comments were never measured and stay out.
    static var princetonPalette: AppPalette {
        typealias B = ThemeBuilders
        return AppPalette(
            id: "princeton",
            accent: B.adaptive(0xE77500),
            series: [B.series("orange", 0xE77500), B.series("sky", 0x03B9FC), B.series("crimson", 0xAD274F),
                     B.series("teal", 0x03C4BB), B.series("violet", 0xA34AAC), B.series("green", 0x007912),
                     B.series("periwinkle", 0x98A1FF), B.series("olive", 0x867500)],
            sequential: B.ramp([0xFE913F, 0xE17204, 0xBA5D01, 0x944900, 0x703500]),
            diverging: B.ramp([0x0791C7, 0x8DBDD9, 0xE8E8E8, 0xECB18B, 0xE77500]),
            seriesOrder: .validatedOrder)
    }

    /// Princeton: Swiss structure and surfaces with ``princetonPalette`` composed on, light only.
    ///
    /// Composing keeps Swiss's structure and surfaces. The result is declared light only and Swiss's dark
    /// values are stripped, because Princeton has no measured dark series and none is invented; a dark context
    /// shows Princeton on Swiss's light background. The theme's id is `princeton`.
    static var princeton: Theme {
        var theme = Theme.swiss.composed(with: princetonPalette)
        theme.id = "princeton"
        theme.name = "Princeton"
        theme.appearances = .lightOnly
        theme.palette = theme.palette.strippingDark()
        theme.conformance = princetonConformance
        return theme
    }
}
