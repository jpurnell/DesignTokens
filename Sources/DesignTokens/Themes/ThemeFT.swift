import Foundation

public extension Theme {
    /// FT: our interpretation of the Financial Times chart style, with the salmon paper, in light and in an
    /// authored dark.
    ///
    /// Light values (colours, type sizes, margins, gaps, marks) are `EditorialTheme.ft`'s current values in
    /// BusinessMath-UI, exactly: the paper `#FFF1E5`, the serif title (the system serif, New York; the real
    /// FT faces are licensed and not shipped), sans for data. The dark variant is authored here, not taken
    /// from the FT, which has no published dark chart palette that was consulted: warm charcoal surfaces,
    /// the paper colour as ink, and series hues kept near the light ones with lightness moved into the dark
    /// band by a search that also kept every adjacent pair above the separation floors (the authored dark
    /// series, and `sequential.dark`, which is the light ramp reversed as `Palette.sequentialDark` is).
    ///
    /// Roles editorial themes do not have are authored: `link` is the accent, `warning` is the orange series,
    /// `onAccent` is white in light and the dark background in dark. The vocabulary the model gains for the
    /// FT (gaps G1, G8, G9): direct series labels, a dot at the end of a line, the axis on the trailing
    /// edge. Those are claims about the FT drawn from general knowledge and not confirmed against a rendering.
    static var ft: Theme {
        typealias B = ThemeBuilders
        let type = B.typeRoles(
            title: B.text(.serifNewYork, 19, B.bold), subtitle: B.text(.sans, 13, B.regular),
            axisTitle: B.text(.sans, 11, B.medium), axisLabel: B.text(.sans, 11, B.regular),
            seriesLabel: B.text(.sans, 12, B.semibold), annotation: B.text(.sans, 11, B.regular),
            source: B.text(.sans, 10, B.regular), note: B.text(.sans, 10, B.regular),
            tag: B.text(.serifNewYork, 11, B.bold))
        let structure = Structure(
            rules: B.rules(reference: LineSpec(weight: 1, dash: [4, 4])), type: type,
            labels: LabelSpec(values: .off, series: .direct, axisSide: .trailing, axisLabelPlacement: .besideAxis, sourceLine: true),
            layout: B.layout(top: 16, leading: 12, bottom: 14, trailing: 16, title: 4, subtitle: 13, plot: 8, source: 10,
                             gridlines: .horizontalFaint),
            marks: MarkSpec(lineWidth: 2.5, pointSize: 28, bandOpacity: 0.18, selectedLineWidth: 3.5, barFill: .flat,
                            barWidthRatio: 0.6, barCornerRadius: 0, lineEnd: .dot),
            numbers: B.standardNumbers)
        let palette = ThemePalette(
            ink: B.adaptive(0x33302E, dark: 0xF2E5DA), secondaryInk: B.adaptive(0x66605C, dark: 0xB8ABA0),
            background: B.adaptive(0xFFF1E5, dark: 0x1F1B18), surface: B.adaptive(0xF2E5DA, dark: 0x252019),
            rule: B.adaptive(0xE6D9CE, dark: 0x4A413A), accent: B.adaptive(0x0F5499, dark: 0x498AED),
            onAccent: B.adaptive(0xFFFFFF, dark: 0x1F1B18), link: B.adaptive(0x0F5499, dark: 0x6FA3F0),
            positive: B.adaptive(0x0D7680, dark: 0x049EA8), negative: B.adaptive(0x990F3D, dark: 0xF06A8C),
            warning: B.adaptive(0xFF8833, dark: 0xFF9A52), muted: B.adaptive(0xCCC1B7, dark: 0x5E544C),
            series: [B.series("blue", 0x0F5499, dark: 0x498AED), B.series("claret", 0x990F3D, dark: 0xB83955),
                     B.series("teal", 0x0D7680, dark: 0x049EA8), B.series("orange", 0xFF8833, dark: 0xB65E02),
                     B.series("purple", 0x593380, dark: 0x7E4BC6), B.series("crimson", 0x9E2F50, dark: 0xED446D)],
            sequential: B.ramp([0xFCE6D6, 0xF4A582, 0xD6604D, 0xB2182B, 0x7F0A1F],
                               dark: [0x992A34, 0xD13D44, 0xEA725E, 0xF7A885, 0xF2DDCD]),
            diverging: B.ramp([0x0F5499, 0x92C5DE, 0xFFF1E5, 0xF4A582, 0x990F3D]),
            extras: ["neutral": B.adaptive(0x66605C, dark: 0xA39A92)])
        return Theme(id: "ft", name: "Financial Times", structure: structure, palette: palette, appearances: .both,
                     conformance: ftConformance)
    }
}
