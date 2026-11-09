import Foundation

public extension Theme {
    /// Economist: our interpretation of The Economist's chart style, in light and in an authored dark.
    ///
    /// Light values (colours, type, margins, gaps, marks) are `EditorialTheme.economist`'s current values in
    /// BusinessMath-UI, exactly, including the condensed named face `Econ Sans Cnd`, which now carries the
    /// sans fallback the model requires (BusinessMath-UI falls back to the system face silently). The dark
    /// variant is authored here, not taken from The Economist: near-black blue-grey surfaces, the paper
    /// grey as ink, series hues kept near the light ones with lightness moved into the dark band by a search
    /// that also kept adjacent pairs above the separation floors. `sequential.dark` is the light ramp reversed with each step's lightness reset to 0.46, 0.58, 0.69, 0.80, 0.91 at its own hue and chroma (a plain reversal leaves the darkest step under the 2:1 end-contrast floor).
    ///
    /// The vocabulary the model gains for it (gaps G2, G4, G6): a red rule above the title (1 pt) and a red
    /// tag block (28 by 6 pt) in the top-left corner, value labels above their gridline with the axis on
    /// the trailing edge, and slim bars (0.45 of the slot). Those are claims about The Economist drawn from
    /// general knowledge, not confirmed against a rendering. `link`, `warning` and `onAccent` are authored. `warning` is the yellow series (#EBB434) in light only: in dark it is #F0C04A, while the dark yellow series is #865D00, so the two differ there.
    static var economist: Theme {
        typealias B = ThemeBuilders
        let face = FontFamilyRef.named("Econ Sans Cnd", fallback: .sans)
        let type = B.typeRoles(
            title: B.text(face, 18, B.bold), subtitle: B.text(face, 13, B.regular),
            axisTitle: B.text(face, 11, B.medium), axisLabel: B.text(face, 11, B.regular),
            seriesLabel: B.text(face, 12, B.semibold), annotation: B.text(face, 11, B.regular),
            source: B.text(face, 10, B.regular), note: B.text(face, 10, B.regular), tag: B.text(face, 11, B.bold))
        let structure = Structure(
            rules: B.rules(title: TitleRule(weight: 1, position: .aboveTitle, colour: .negative, inset: 0),
                           reference: LineSpec(weight: 1, dash: [3, 3])),
            type: type,
            labels: LabelSpec(values: .off, series: .legend, axisSide: .trailing, axisLabelPlacement: .aboveGridline, sourceLine: true),
            layout: B.layout(top: 16, leading: 8, bottom: 14, trailing: 16, title: 3, subtitle: 14, plot: 8, source: 10,
                             gridlines: .horizontalFaint),
            marks: MarkSpec(lineWidth: 2.5, pointSize: 26, bandOpacity: 0.16, selectedLineWidth: 3.5, barFill: .flat,
                            barWidthRatio: 0.45, barCornerRadius: 0, lineEnd: .none,
                            tagMark: TagMark(width: 28, height: 6, colour: .negative)),
            numbers: B.standardNumbers)
        let palette = ThemePalette(
            ink: B.adaptive(0x121212, dark: 0xF3F2F0), secondaryInk: B.adaptive(0x758D99, dark: 0x9FB0B8),
            background: B.adaptive(0xFFFFFF, dark: 0x14181B), surface: B.adaptive(0xF3F2F0, dark: 0x1B2125),
            rule: B.adaptive(0xD9D9D6, dark: 0x38434A), accent: B.adaptive(0x006BA2, dark: 0x4DA3DB),
            onAccent: B.adaptive(0xFFFFFF, dark: 0x14181B), link: B.adaptive(0x006BA2, dark: 0x5CB0E4),
            positive: B.adaptive(0x379A8B, dark: 0x2DBBA3), negative: B.adaptive(0xE3120B, dark: 0xFF6B5E),
            warning: B.adaptive(0xEBB434, dark: 0xF0C04A), muted: B.adaptive(0xC5D0D6, dark: 0x4A565C),
            series: [B.series("blue", 0x006BA2, dark: 0x0769A8), B.series("cyan", 0x3EBCD2, dark: 0x10A4B2),
                     B.series("red", 0xE3120B, dark: 0xE35C42), B.series("green", 0x379A8B, dark: 0x089C85),
                     B.series("yellow", 0xEBB434, dark: 0x865D00), B.series("plum", 0x9A607F, dark: 0xAA3B7D)],
            sequential: B.ramp([0xCFE0E8, 0x7FB0C6, 0x3B8BB0, 0x00588D, 0x003D5C],
                               dark: [0x295E7E, 0x3880B8, 0x57A6CC, 0x95C6DD, 0xD3E4ED]),
            diverging: B.ramp([0x006BA2, 0x7FB0C6, 0xF3F2F0, 0xF1A9A5, 0xE3120B]),
            extras: ["neutral": B.adaptive(0x758D99, dark: 0x8FA3AD)])
        return Theme(id: "economist", name: "Economist", structure: structure, palette: palette, appearances: .both,
                     conformance: economistConformance)
    }
}
