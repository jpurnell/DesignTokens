import Foundation

public extension Theme {
    /// House: the default editorial style, clean, neutral and restrained, light only.
    ///
    /// Colours, type sizes, margins, gaps and marks are `EditorialTheme.house`'s current values in
    /// BusinessMath-UI, exactly. The model needs three roles that editorial theme does not have, and they are
    /// authored here: `link` is the accent, `warning` is the second series (orange), and `onAccent` is white
    /// (5.2 to 1 on the accent). `neutral`, which editorial themes have and the roles do not, is
    /// `extras["neutral"]`. Where a field has no source (title rule, bar width, series labelling) it is neutral:
    /// no title rule, bar width 0.6, a legend, value labels off, flat bars.
    ///
    /// Light only: no dark values are authored; a dark context shows House on its own background.
    static var house: Theme {
        typealias B = ThemeBuilders
        let type = B.typeRoles(
            title: B.text(.sans, 18, B.bold), subtitle: B.text(.sans, 13, B.regular),
            axisTitle: B.text(.sans, 11, B.medium), axisLabel: B.text(.sans, 11, B.regular),
            seriesLabel: B.text(.sans, 12, B.semibold), annotation: B.text(.sans, 11, B.regular),
            source: B.text(.sans, 10, B.regular), note: B.text(.sans, 10, B.regular), tag: B.text(.sans, 11, B.bold))
        let structure = Structure(
            rules: B.rules(reference: LineSpec(weight: 1, dash: [4, 4])), type: type,
            labels: LabelSpec(values: .off, series: .legend, axisSide: .leading, axisLabelPlacement: .besideAxis, sourceLine: true),
            layout: B.layout(top: 16, leading: 16, bottom: 14, trailing: 16, title: 4, subtitle: 12, plot: 8, source: 10,
                             gridlines: .horizontalFaint),
            marks: MarkSpec(lineWidth: 2.5, pointSize: 30, bandOpacity: 0.18, selectedLineWidth: 3.5, barFill: .flat,
                            barWidthRatio: 0.6, barCornerRadius: 0, lineEnd: .none),
            numbers: B.standardNumbers)
        let palette = ThemePalette(
            ink: B.adaptive(0x1A202C), secondaryInk: B.adaptive(0x718096), background: B.adaptive(0xFFFFFF),
            surface: B.adaptive(0xF7FAFC), rule: B.adaptive(0xE2E8F0), accent: B.adaptive(0x2B6CB0),
            onAccent: B.adaptive(0xFFFFFF), link: B.adaptive(0x2B6CB0), positive: B.adaptive(0x1F9D55),
            negative: B.adaptive(0xD64545), warning: B.adaptive(0xDD6B20), muted: B.adaptive(0xA0AEC0),
            series: [B.series("blue", 0x2B6CB0), B.series("orange", 0xDD6B20), B.series("green", 0x38A169),
                     B.series("purple", 0x805AD5), B.series("pink", 0xD53F8C), B.series("cyan", 0x00A3C4)],
            sequential: B.ramp([0xEBF8FF, 0x90CDF4, 0x3182CE, 0x2C5282, 0x1A365D]),
            diverging: B.ramp([0x2C5282, 0x90CDF4, 0xF7FAFC, 0xFEB2B2, 0xC53030]),
            extras: ["neutral": B.adaptive(0x4A5568)])
        return Theme(id: "house", name: "House", structure: structure, palette: palette, appearances: .lightOnly,
                     conformance: houseConformance)
    }
}
