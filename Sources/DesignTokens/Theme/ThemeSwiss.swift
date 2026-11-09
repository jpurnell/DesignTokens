import Foundation

public extension Theme {
    /// Swiss: the house style, San Francisco throughout, Apple system colours, flat surfaces, a heavy rule
    /// under the title, faint horizontal gridlines, value labels on the data.
    ///
    /// Swiss is built from the package's own constants (``ColorToken``, ``Palette``, ``Rule``, ``Grid``,
    /// ``Radius``, ``TypeStyle``), so it is defined once and the generated `tokens.css` does not change.
    /// Where a field has no constant, the value is the one BusinessMath-UI's Swiss editorial theme uses
    /// today, and the source is noted below.
    ///
    /// Not held by the package, so chosen here and marked: `muted` is the secondary ink (there is no
    /// `muted` token, and none is invented); chart text line height is 1.3, the label role's, because the
    /// editorial theme has none.
    ///
    /// After the chart alignment (owner decisions 2026-11-09): `muted` is the neutral mark grey (``neutralMark``), the
    /// magnitude ramp is one-hue blue (``blueSequential``) and the diverging ramp has a dark version
    /// (``darkDiverging``). The structure draws the heavy rule above the title, marks neutral with the latest column in
    /// the accent, and a muted solid hairline for a target line.
    ///
    /// `positive` and `negative` are **deliberately not the system colours** (owner decision 2026-11-09).
    /// They are gain and loss, printed as text and used as marks in charts, so they are the darker text-safe
    /// pair, `textSafePositive` and `textSafeNegative`, at 4.5:1 or more on the Swiss background and the
    /// card surface in every appearance. ``ColorToken/success`` and ``ColorToken/destructive`` stay the system
    /// colours (2.13:1 and 3.42:1 as text in light), and the series keep the system green and red for marks.
    /// Neither role names a system colour, so a ``ColorRole`` deferral cannot replace the values with Apple's.
    ///
    /// The palette's lightness band and contrast are not met by Apple's system colours for some slots. See
    /// the conformance ledger in the project documentation; those slots need direct labels.
    ///
    /// Built once and stored (it was a computed property before 0.6.0; a use site does not change).
    static let swiss = Theme(id: "swiss", name: "Swiss", structure: swissStructure, palette: swissPalette,
                             appearances: .both, conformance: swissConformance)

    /// Swiss's `positive`: a green that reads as text. Light #268053 (4.68:1 on the background, 4.89 on the card
    /// surface), dark the system dark green #30D158 (9.35 and 8.79), Increase Contrast light #0E6B3A (6.32) and
    /// dark #4AD968 (10.28). It names no system colour, on purpose: see `swiss`.
    ///
    /// The light value keeps the green hue of BusinessMath-UI's #1F9D55 (which is 3.35:1 on #FAFAFA, 3.49 on
    /// white) and is a touch bluer and darker. The bluer step is what keeps it apart from the red under
    /// deutan and protan simulation (9.7 against 5.6 had it stayed at the same hue, below the method's floor of 6).
    static var textSafePositive: Adaptive {
        Adaptive(light: ColorValue(RGB(rgb: 0x268053)), dark: ColorValue(RGB(rgb: 0x30D158)),
                 lightIncreased: ColorValue(RGB(rgb: 0x0E6B3A)), darkIncreased: ColorValue(RGB(rgb: 0x4AD968)))
    }

    /// Swiss's `negative`: a red that reads as text. Light #DB2C2C (4.56:1 on the background, 4.76 on the card
    /// surface), dark the system dark red #FF4245 (5.51 and 5.18), Increase Contrast light #B81D1D (6.23) and
    /// dark #FF6165 (6.44). It names no system colour, on purpose: see `swiss`.
    ///
    /// BusinessMath-UI's #D64545 is 4.19:1 on #FAFAFA, under 4.5, so this is a little deeper and more saturated.
    /// The 0.3.0 increased-contrast values (#008932 and #E9152D, 4.35 and 4.36) do not reach 4.5 either, so the
    /// light increased slots are darker still.
    static var textSafeNegative: Adaptive {
        Adaptive(light: ColorValue(RGB(rgb: 0xDB2C2C)), dark: ColorValue(RGB(rgb: 0xFF4245)),
                 lightIncreased: ColorValue(RGB(rgb: 0xB81D1D)), darkIncreased: ColorValue(RGB(rgb: 0xFF6165)))
    }

    /// The system green and red, as Swiss's `positive` and `negative` were before 2026-11-09. Princeton is
    /// composed on Swiss and keeps these: its palette and ledger did not change.
    static var systemPositive: Adaptive { Adaptive(token: .success, system: .green) }
    /// See `systemPositive`.
    static var systemNegative: Adaptive { Adaptive(token: .destructive, system: .red) }

    private static var swissPalette: ThemePalette {
        func role(_ token: ColorToken, system: SystemColorName? = nil) -> Adaptive {
            Adaptive(token: token, system: system)
        }
        let series = zip(Palette.seriesNames, Palette.series.indices).map { name, index -> NamedAdaptive in
            NamedAdaptive(name: name, color: Adaptive(
                light: ColorValue(Palette.series[index]),
                dark: ColorValue(Palette.seriesDark[index]),
                lightIncreased: ColorValue(Palette.seriesIncreasedContrast[index]),
                darkIncreased: ColorValue(Palette.seriesIncreasedContrastDark[index]),
                system: SystemColorName(rawValue: name)))
        }
        return ThemePalette(
            ink: role(.label), secondaryInk: role(.secondaryLabel), background: role(.background),
            surface: role(.secondaryBackground), rule: role(.separator), accent: role(.accent, system: .orange),
            onAccent: role(.onAccent), link: role(.link), positive: textSafePositive,
            negative: textSafeNegative, warning: role(.warning), muted: neutralMark,
            series: series, sequential: blueSequential,
            diverging: Ramp(light: Palette.diverging.map { ColorValue($0) }, dark: darkDiverging))
    }

    /// Swiss's `muted`: the neutral grey of a mark that is not emphasised. Light #B9BBBD and dark #4E5053 are the
    /// approved drawing's history-bar greys, `color-mix(muted 45%, background)` of the secondary ink over the
    /// background (45% of #6A6D72 over #FAFAFA, 45% of #9A9DA2 over #101112). They stay the default although they
    /// are 1.84:1 and 2.34:1 on the background (1.93 and 2.20 on the card surface), under the method's 3:1: the
    /// grey must stay lighter than the accent, and the relief is the printed value (owner decision 2026-11-09;
    /// ledgered). Increase Contrast uses 3:1 greys, light #8E9196 (3.03:1, 3.16 on the card) and dark #6F7176
    /// (3.87:1, 3.64). It names no system colour, so it is never deferred to Apple's.
    static var neutralMark: Adaptive {
        Adaptive(light: ColorValue(RGB(rgb: 0xB9BBBD)), dark: ColorValue(RGB(rgb: 0x4E5053)),
                 lightIncreased: ColorValue(RGB(rgb: 0x8E9196)), darkIncreased: ColorValue(RGB(rgb: 0x6F7176)))
    }

    /// Swiss's magnitude ramp: one hue, blue, because orange is emphasis only (owner decision 2026-11-09).
    /// Light "blue C", light to dark: #6AB0FF #2E92F5 #0A74D6 #0757A6 #053C73 (monotone, no thin step, 2.17:1 at the
    /// light end, hue spread 2.2 degrees). Dark, authored and not the light ramp reversed (reversed it is 1.7:1 at
    /// its darkest step): dark to light, #064E8B #0167B8 #1382E1 #449FFA #7FBCFE, the light ramp's hue (OKLCH 251.5,
    /// the system dark blue's) at OKLCH L 0.42 to 0.78 in even 0.09 steps, the darkest step 2.22:1 on #101112.
    /// `Palette.sequential` (orange) and `tokens.css` are unchanged.
    static var blueSequential: Ramp {
        func steps(_ values: [UInt32]) -> [ColorValue] { values.map { ColorValue(RGB(rgb: $0)) } }
        return Ramp(light: steps([0x6AB0FF, 0x2E92F5, 0x0A74D6, 0x0757A6, 0x053C73]),
                    dark: steps([0x064E8B, 0x0167B8, 0x1382E1, 0x449FFA, 0x7FBCFE]))
    }

    /// Swiss's dark diverging ramp, built like the series: the endpoints are the system dark blue #0091FF and
    /// orange #FF9230, the midpoint is a dark neutral #414344 (OKLCH L 0.38, 1.9:1 on #101112: it is meant to sit
    /// near the surface), and each arm's middle step is the endpoint's hue at L 0.52 (blue, #246BB1) and 0.57
    /// (orange, #AB6224). Lightness runs 0.65, 0.52, 0.38, 0.57, 0.76: no step under 0.13 apart.
    static var darkDiverging: [ColorValue] {
        [0x0091FF, 0x246BB1, 0x414344, 0xAB6224, 0xFF9230].map { ColorValue(RGB(rgb: $0)) }
    }

    private static var swissStructure: Structure {
        let hairline = Double(Rule.hairline.points)
        let rules = RuleSpec(
            title: TitleRule(weight: Double(Rule.section.points), position: .aboveTitle, colour: .ink, inset: 0, gapAfter: 8),
            section: Double(Rule.section.points), hairline: hairline, gridline: hairline, baseline: 1.5,
            page: Double(Rule.page.points), reference: LineSpec(weight: hairline, dash: []), plotBorder: 0,
            baselineColour: .ink, referenceColour: .secondaryInk, referenceLabelColour: .ink)
        let layout = LayoutSpec(
            margins: Insets(top: 6, leading: 8, bottom: 12, trailing: 8),
            gaps: Gaps(title: 4, subtitle: 12, plot: 8, source: 10, referenceLabel: 5),
            gutter: Double(Grid.gutter), columns: Grid.columns, baseUnit: Double(Grid.baseUnit),
            containerRadius: Double(Radius.container), controlRadius: Double(Radius.control),
            gridlines: .horizontalFaint)
        let labels = LabelSpec(values: .aboveOrEnd, series: .direct, axisSide: .leading,
                               axisLabelPlacement: .besideAxis, sourceLine: true, valueHalo: 3)
        let marks = MarkSpec(lineWidth: 2, pointSize: 24, bandOpacity: 0.14, selectedLineWidth: 3,
                             barFill: .flat, barWidthRatio: 0.7, barCornerRadius: Double(Radius.container),
                             lineEnd: .none, defaultFill: .muted, defaultEmphasis: .latest, emphasisFill: .accent)
        return Structure(rules: rules, type: swissType, labels: labels, layout: layout, marks: marks,
                         numbers: standardNumbers)
    }

    private static var swissType: TypeRoles {
        let chartLine = TypeStyle.label.lineHeight
        func chart(_ size: Double, _ weight: Int) -> TextSpec {
            TextSpec(family: .sans, size: size, weight: weight, tracking: 0, italic: false, uppercase: false,
                     lineHeight: chartLine)
        }
        func role(_ style: TypeStyle) -> TextSpec {
            TextSpec(family: .sans, size: style.points, weight: style.weight, tracking: style.trackingEm,
                     italic: false, uppercase: style.uppercase, lineHeight: style.lineHeight)
        }
        let regular = 400, medium = 500, semibold = 600, bold = 700
        return TypeRoles(
            title: chart(17, bold), subtitle: chart(13, regular), axisTitle: chart(11, medium),
            axisLabel: chart(11, regular), seriesLabel: chart(12, semibold), annotation: chart(11, bold),
            source: chart(11, regular), note: chart(11, regular), tag: chart(11, bold),
            label: role(.label), caption: role(.caption), body: role(.body), heading: role(.heading),
            uiTitle: role(.title), display: role(.display))
    }

    private static var standardNumbers: NumberFormats {
        NumberFormats(
            currency: NumberFormatSpec(style: .currency, abbreviate: true, prefix: "$"),
            percent: NumberFormatSpec(style: .percent, decimals: 1),
            count: NumberFormatSpec(style: .decimal, decimals: 0, abbreviate: true),
            index: NumberFormatSpec(style: .decimal, decimals: 1),
            ratio: NumberFormatSpec(style: .decimal, decimals: 2, suffix: "×"),
            temperature: NumberFormatSpec(style: .decimal, decimals: 1, suffix: "°"),
            plain: NumberFormatSpec(style: .decimal, maxDecimals: 2))
    }
}
