import Foundation

/// The four themes of BusinessMath-UI's `ChartThemeProviding` family, carried as they are.
///
/// They are not designed to the dataviz method and they are not tuned to it: their colours are the values in
/// `Theme/Themes/*.swift`, exactly, and the findings the validator makes about them are recorded in a legacy
/// conformance ledger that fails on any change. The 15 colours of the protocol are mapped onto the twelve
/// roles plus ``ThemePalette/extras``:
///
/// | Legacy | Role or extra |
/// |---|---|
/// | `accent` | `accent` |
/// | `gain`, `loss`, `warning` | `positive`, `negative`, `warning` |
/// | `secondary` | `secondaryInk` |
/// | `neutral` | `muted`, and `extras["neutral"]` |
/// | `border` | `rule` |
/// | `chartBackground`, `annotationBackground` | `background`, `surface` |
/// | `primary`, `info`, `highlight`, `subtle`, `emphasis`, `shadow` | `extras` of the same name |
///
/// Not part of any legacy theme, and authored here: `ink` is the system label colour (legacy views draw text
/// in the platform's primary colour), `link` is `primary`, and `onAccent` is black or white, whichever has more
/// contrast on the accent. The five 3D gradients: `correlation` is `diverging`, `heatmap` is `sequential`,
/// `volatility`, `sharpe` and `distribution` are `extraRamps`; stop positions are even (the legacy `0.33` and
/// `0.66` stops are thirds). Per-chart colour overrides are `colourOverrides`; keys a theme does not override
/// use the library's standard mapping, which is not data. `ChartGradient.gainLoss`, a library constant, is
/// not carried.
///
/// Legacy structure: platform-automatic gridlines, gradient bars, no title rule, no value labels (the
/// views disagree on that default today), a drop shadow, and the platform text styles. The numeric sizes under
/// them are Swiss's (no legacy source has numbers); margins and gaps are `LayoutTokens.standard`; marks are
/// `MarkTokens` defaults. Which text role maps to which platform style is assumed from how often the views
/// use each (`headline` 26 times, `subheadline` 20, `caption` 51, `caption2` 60) and not checked view by view.
enum LegacyThemes {
    typealias B = ThemeBuilders

    static var structure: Structure {
        func role(_ size: Double, _ weight: Int, _ style: PlatformTextStyle) -> TextSpec {
            B.text(.sans, size, weight, platformStyle: style)
        }
        let type = B.typeRoles(
            title: role(17, B.bold, .headline), subtitle: role(13, B.regular, .subheadline),
            axisTitle: role(11, B.medium, .caption), axisLabel: role(11, B.regular, .caption2),
            seriesLabel: role(12, B.semibold, .caption), annotation: role(11, B.bold, .caption),
            source: role(11, B.regular, .caption2), note: role(11, B.regular, .caption2), tag: role(11, B.bold, .caption2))
        return Structure(
            rules: B.rules(reference: LineSpec(weight: 1, dash: [4, 4])), type: type,
            labels: LabelSpec(values: .off, series: .legend, axisSide: .leading, axisLabelPlacement: .besideAxis, sourceLine: false),
            layout: B.layout(top: 16, leading: 16, bottom: 14, trailing: 16, title: 4, subtitle: 12, plot: 8, source: 10,
                             gridlines: .platformAutomatic,
                             shadow: ShadowSpec(colour: ColourReference(source: "shadow"), radius: 4, x: 0, y: 2),
                             annotationRadius: 8),
            marks: MarkSpec(lineWidth: 2.5, pointSize: 30, bandOpacity: 0.18, selectedLineWidth: 3.5, barFill: .autoGradient,
                            barWidthRatio: 0.6, barCornerRadius: 0, lineEnd: .none),
            numbers: B.standardNumbers)
    }
}

public extension Theme {
    /// Legacy Default: BusinessMath-UI's `DefaultTheme`, which uses SwiftUI system colours with no hex values.
    ///
    /// A labelled snapshot: each system colour resolved as an `NSColor` in the named light and dark appearances
    /// on macOS 27.2 (the measurer in the 0.2.0 and 0.3.0 releases), with Increase Contrast **off** on the
    /// measuring Mac (`NSWorkspace.accessibilityDisplayShouldIncreaseContrast` false). The named
    /// high-contrast appearances returned values identical to the standard ones in that process, so
    /// increased-contrast values were not distinguishable here; the eight colours measured in 0.3.0 from a
    /// real app with Increase Contrast on (`Palette.seriesIncreasedContrast` and its dark) are reused for the
    /// slots that are the same system colours, and the rest carry no increased value. `Adaptive.system`
    /// names the system colour wherever the model has a name for it, so Apple adapters still defer to it.
    ///
    /// `ink` is `labelColor` (`#000000D8`, `#FFFFFFD8`: alpha 0.85), `rule` is `separatorColor` (`#0000001A`,
    /// `#FFFFFF1F`), `background` is `textBackgroundColor` and `surface` is `controlBackgroundColor`, as
    /// `PlatformColors` uses them on macOS. Marked legacy.
    static var legacyDefault: Theme {
        typealias B = ThemeBuilders
        func sys(_ name: String, _ system: SystemColorName, _ light: UInt32, _ dark: UInt32,
                 increased: (UInt32, UInt32)? = nil) -> NamedAdaptive {
            NamedAdaptive(name: name, color: Adaptive(light: .packed(light), dark: .packed(dark),
                lightIncreased: increased.map { ColorValue.packed($0.0) }, darkIncreased: increased.map { ColorValue.packed($0.1) },
                system: system))
        }
        let blue = sys("blue", .blue, 0x0088FF, 0x0091FF, increased: (0x1E6EF4, 0x5CB8FF))
        let green = sys("green", .green, 0x34C759, 0x30D158, increased: (0x008932, 0x4AD968))
        let orange = sys("orange", .orange, 0xFF8D28, 0xFF9230, increased: (0xC55300, 0xFFA056))
        let purple = sys("purple", .purple, 0xCB30E0, 0xDB34F2, increased: (0xB02FC2, 0xEA8DFF))
        let red = sys("red", .red, 0xFF383C, 0xFF4245, increased: (0xE9152D, 0xFF6165))
        let cyan = sys("cyan", .cyan, 0x00C0E8, 0x3CD3FE, increased: (0x007EAE, 0x6DD9FF))
        let yellow = sys("yellow", .yellow, 0xFFCC00, 0xFFD600, increased: (0xA16A00, 0xFEDF43))
        let pink = sys("pink", .pink, 0xFF2D55, 0xFF375F)
        let mint = sys("mint", .mint, 0x00C8B3, 0x00DAC3)
        let indigo = sys("indigo", .indigo, 0x6155F5, 0x6D7CFF, increased: (0x564ADE, 0xA7AAFF))
        let gray = sys("gray", .gray, 0x8E8E93, 0x98989D)
        func translucent(_ base: NamedAdaptive, _ alpha: UInt8) -> Adaptive {
            Adaptive(light: ColorValue(base.color.light.rgb, alpha: Double(alpha) / 255),
                     dark: base.color.dark.map { ColorValue($0.rgb, alpha: Double(alpha) / 255) }, system: base.color.system)
        }
        let white = Adaptive(light: .packed(0xFFFFFF), dark: .packed(0xFFFFFF))
        let black = Adaptive(light: .packed(0x000000), dark: .packed(0x000000))
        let palette = ThemePalette(
            ink: Adaptive(light: .packed(0x000000, alpha: 0xD8), dark: .packed(0xFFFFFF, alpha: 0xD8)),
            secondaryInk: gray.color,
            background: Adaptive(light: .packed(0xFFFFFF), dark: .packed(0x1E1E1E)),
            surface: Adaptive(light: .packed(0xFFFFFF), dark: .packed(0x1E1E1E)),
            rule: Adaptive(light: .packed(0x000000, alpha: 0x1A), dark: .packed(0xFFFFFF, alpha: 0x1F)),
            accent: orange.color, onAccent: black, link: blue.color, positive: green.color, negative: red.color,
            warning: yellow.color, muted: gray.color,
            series: [blue, green, orange, purple, red, cyan, yellow, pink, mint, indigo],
            sequential: Ramp(light: [0x532EE6, 0x2EE6E6, 0x32E62E, 0xE6D32E, 0xE62E2E].map { ColorValue.packed($0) }, dark: nil),
            diverging: Ramp(light: [blue.color.light, ColorValue.packed(0xFFFFFF), red.color.light],
                            dark: [blue.color.dark ?? blue.color.light, ColorValue.packed(0xFFFFFF), red.color.dark ?? red.color.light]),
            extraRamps: [
                "volatility": B.ramp([0x532EE6, 0x2EE6E6, 0x32E62E, 0xE6D32E, 0xE62E2E]),
                "sharpe": Ramp(light: [red, orange, yellow, green].map(\.color.light),
                               dark: [red, orange, yellow, green].map { $0.color.dark ?? $0.color.light }),
                "distribution": Ramp(
                    light: [0.3, 0.6, 0.9].map { ColorValue(blue.color.light.rgb, alpha: $0) },
                    dark: [0.3, 0.6, 0.9].map { ColorValue((blue.color.dark ?? blue.color.light).rgb, alpha: $0) }),
            ],
            extras: [
                "primary": blue.color, "info": cyan.color, "highlight": translucent(yellow, 0x4D),
                "subtle": translucent(gray, 0x1A), "emphasis": purple.color, "neutral": gray.color,
                "shadow": Adaptive(light: .packed(0x000000, alpha: 0x1A), dark: .packed(0x000000, alpha: 0x1A)),
                "white": white,
            ],
            colourOverrides: [
                "montecarlo.optimistic": ColourReference(source: "positive", opacity: 0.7),
                "montecarlo.conservative": ColourReference(source: "negative", opacity: 0.7),
                "boxplot.secondary": ColourReference(source: "secondaryInk"),
                "correlation.positive": ColourReference(source: "negative"),
                "correlation.negative": ColourReference(source: "primary"),
                "correlation.neutral": ColourReference(source: "white"),
                "scatter.regression": ColourReference(source: "negative", opacity: 0.6),
                "scatter.residual.positive": ColourReference(source: "positive"),
                "scatter.residual.negative": ColourReference(source: "negative"),
                "timeseries.trend": ColourReference(source: "primary"),
                "timeseries.seasonal": ColourReference(source: "accent"),
                "timeseries.residual": ColourReference(source: "secondaryInk"),
            ],
            rampOverrides: ["efficientfrontier": "sharpe", "surfacemorph": "sequential", "probability": "distribution",
                            "riskreturn": "sharpe"])
        return Theme(id: "legacy-default", name: "Legacy Default", structure: LegacyThemes.structure, palette: palette,
                     appearances: .both, conformance: legacyDefaultConformance)
    }

    /// Legacy Dark: BusinessMath-UI's `DarkTheme`, for a dark surface only.
    ///
    /// Declared ``AppearanceSupport/fixedDark``: its colours are stored in the `light` slot and measured with
    /// the dark band on its own `#1A1A1F` chart background. `highlight` is SwiftUI's `Color.yellow` at 25%,
    /// which is a system colour in the source; it is recorded as the dark system yellow (`#FFD600`).
    /// `border` is white at 15%, `subtle` white at 5%, `shadow` black at 30%. Marked legacy; nothing tuned.
    static var legacyDark: Theme {
        typealias B = ThemeBuilders
        let palette = ThemePalette(
            ink: Adaptive(light: .packed(0xFFFFFF, alpha: 0xD8)), secondaryInk: B.adaptive(0x9999A6),
            background: B.adaptive(0x1A1A1F), surface: B.adaptive(0x26262E),
            rule: Adaptive(light: .packed(0xFFFFFF, alpha: 0x26)), accent: B.adaptive(0xFFB24C),
            onAccent: B.adaptive(0x000000), link: B.adaptive(0x66B2FF), positive: B.adaptive(0x4CE666),
            negative: B.adaptive(0xFF6666), warning: B.adaptive(0xFFD94C), muted: B.adaptive(0x80808C),
            series: [B.series("blue", 0x66B2FF), B.series("green", 0x4CE666), B.series("orange", 0xFFB24C),
                     B.series("purple", 0xB280FF), B.series("red", 0xFF6666), B.series("cyan", 0x66CCE6),
                     B.series("yellow", 0xFFD94C), B.series("pink", 0xFF80B2), B.series("mint", 0x80E6B2),
                     B.series("lavender", 0x9999FF)],
            sequential: B.ramp([0x66B2FF, 0x66CCE6, 0x4CE666, 0xFFD94C, 0xFF6666]),
            diverging: B.ramp([0x66B2FF, 0x4C4C59, 0xFF6666]),
            extraRamps: [
                "volatility": B.ramp([0x66B2FF, 0x66CCE6, 0x4CE666, 0xFFD94C, 0xFF6666]),
                "sharpe": B.ramp([0xFF6666, 0xFFB24C, 0xFFD94C, 0x4CE666]),
                "distribution": Ramp(light: [0.3, 0.6, 0.9].map { ColorValue(RGB(rgb: 0x66B2FF), alpha: $0) }, dark: nil),
            ],
            extras: [
                "primary": B.adaptive(0x66B2FF), "info": B.adaptive(0x66CCE6),
                "highlight": Adaptive(light: .packed(0xFFD600, alpha: 0x40)), "subtle": Adaptive(light: .packed(0xFFFFFF, alpha: 0x0D)),
                "emphasis": B.adaptive(0xB280FF), "neutral": B.adaptive(0x80808C),
                "shadow": Adaptive(light: .packed(0x000000, alpha: 0x4D)),
            ],
            colourOverrides: [
                "boxplot.secondary": ColourReference(source: "info"),
                "correlation.positive": ColourReference(source: "negative"),
                "correlation.negative": ColourReference(source: "primary"),
                "correlation.neutral": ColourReference(source: "neutral"),
            ],
            rampOverrides: [:])
        return Theme(id: "legacy-dark", name: "Legacy Dark", structure: LegacyThemes.structure, palette: palette,
                     appearances: .fixedDark, conformance: legacyDarkConformance)
    }

    /// Legacy Financial: BusinessMath-UI's `FinancialTheme`, light only, exactly as it is. Marked legacy.
    static var legacyFinancial: Theme {
        typealias B = ThemeBuilders
        let palette = ThemePalette(
            ink: Adaptive(light: .packed(0x000000, alpha: 0xD8)), secondaryInk: B.adaptive(0x666673),
            background: B.adaptive(0xFFFFFF), surface: B.adaptive(0xFAFAFC), rule: B.adaptive(0xCCCCD1),
            accent: B.adaptive(0xCC9933), onAccent: B.adaptive(0x000000), link: B.adaptive(0x004C99),
            positive: B.adaptive(0x008040), negative: B.adaptive(0xB21A1A), warning: B.adaptive(0xE6B200),
            muted: B.adaptive(0x808080),
            series: [B.series("blue", 0x004C99), B.series("green", 0x008040), B.series("gold", 0xCC9933),
                     B.series("purple", 0x663399), B.series("red", 0xB21A1A), B.series("teal", 0x3380B2),
                     B.series("bronze", 0x996633), B.series("slate", 0x4C4C80)],
            sequential: B.ramp([0x3380B2, 0xCC9933, 0xB21A1A]),
            diverging: B.ramp([0x004C99, 0xF2F2F5, 0xB21A1A]),
            extraRamps: [
                "volatility": B.ramp([0x3380B2, 0x008040, 0xE6B200, 0xB21A1A]),
                "sharpe": B.ramp([0xB21A1A, 0xE6B200, 0xCC9933, 0x008040]),
                "distribution": Ramp(light: [0.2, 0.5, 0.8].map { ColorValue(RGB(rgb: 0x004C99), alpha: $0) }, dark: nil),
            ],
            extras: [
                "primary": B.adaptive(0x004C99), "info": B.adaptive(0x3380B2), "highlight": B.adaptive(0xF2E6B2),
                "subtle": B.adaptive(0xF2F2F5), "emphasis": B.adaptive(0x663399), "neutral": B.adaptive(0x808080),
                "shadow": Adaptive(light: .packed(0x000000, alpha: 0x14)),
            ],
            colourOverrides: [
                "montecarlo.band": ColourReference(source: "primary", opacity: 0.25),
                "boxplot.secondary": ColourReference(source: "info"),
                "correlation.positive": ColourReference(source: "negative"),
                "correlation.negative": ColourReference(source: "primary"),
                "correlation.neutral": ColourReference(source: "subtle"),
            ],
            rampOverrides: [:])
        return Theme(id: "legacy-financial", name: "Legacy Financial", structure: LegacyThemes.structure, palette: palette,
                     appearances: .lightOnly, conformance: legacyFinancialConformance)
    }

    /// Legacy Accessible: BusinessMath-UI's `AccessibleTheme`, light only, exactly as it is. It advertises
    /// itself as colour-blind safe; the ledger records what the method measures. Marked legacy.
    static var legacyAccessible: Theme {
        typealias B = ThemeBuilders
        let palette = ThemePalette(
            ink: Adaptive(light: .packed(0x000000, alpha: 0xD8)), secondaryInk: B.adaptive(0x4C4C4C),
            background: B.adaptive(0xFFFFFF), surface: B.adaptive(0xF2F2F2), rule: B.adaptive(0x4C4C4C),
            accent: B.adaptive(0xCC6600), onAccent: B.adaptive(0x000000), link: B.adaptive(0x000099),
            positive: B.adaptive(0x00804C), negative: B.adaptive(0x990000), warning: B.adaptive(0xCC9900),
            muted: B.adaptive(0x666666),
            series: [B.series("blue", 0x000099), B.series("orange", 0xCC6600), B.series("grey", 0x666666),
                     B.series("purple", 0x990099), B.series("teal", 0x008080), B.series("olive", 0xB2B200)],
            sequential: B.ramp([0x000099, 0x008080, 0xB2B200, 0xCC6600]),
            diverging: B.ramp([0x000099, 0x808080, 0xCC6600]),
            extraRamps: [
                "volatility": B.ramp([0x000099, 0x008080, 0xB2B200, 0xCC6600]),
                "sharpe": B.ramp([0x990000, 0xCC6600, 0xB2B200, 0x00804C]),
                "distribution": B.ramp([0xB2B2E6, 0x6666B2, 0x000099]),
            ],
            extras: [
                "primary": B.adaptive(0x000099), "info": B.adaptive(0x008099), "highlight": B.adaptive(0xFFFFB2),
                "subtle": B.adaptive(0xEDEDED), "emphasis": B.adaptive(0x660080), "neutral": B.adaptive(0x666666),
                "shadow": Adaptive(light: .packed(0x000000, alpha: 0x26)),
            ],
            colourOverrides: [
                "tornado.low": ColourReference(source: "accent"),
                "tornado.high": ColourReference(source: "primary"),
                "boxplot.secondary": ColourReference(source: "accent"),
                "boxplot.median": ColourReference(source: "neutral"),
                "boxplot.outlier": ColourReference(source: "emphasis"),
                "correlation.positive": ColourReference(source: "accent"),
                "correlation.negative": ColourReference(source: "primary"),
                "correlation.neutral": ColourReference(source: "neutral"),
            ],
            rampOverrides: [:])
        return Theme(id: "legacy-accessible", name: "Legacy Accessible", structure: LegacyThemes.structure, palette: palette,
                     appearances: .lightOnly, conformance: legacyAccessibleConformance)
    }
}
