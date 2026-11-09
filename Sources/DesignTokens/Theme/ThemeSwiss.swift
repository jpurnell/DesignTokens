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
    /// `muted` token, and none is invented); `positive` and `negative` are ``ColorToken/success`` and
    /// ``ColorToken/destructive``, which are lighter than the darker green and red BusinessMath-UI uses for
    /// text; chart text line height is 1.3, the label role's, because the editorial theme has none.
    ///
    /// The palette's lightness band and contrast are not met by Apple's system colours for some slots. See
    /// the conformance ledger in the project documentation; those slots need direct labels.
    static var swiss: Theme {
        Theme(id: "swiss", name: "Swiss", structure: swissStructure, palette: swissPalette, appearances: .both)
    }

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
            onAccent: role(.onAccent), link: role(.link), positive: role(.success, system: .green),
            negative: role(.destructive, system: .red), warning: role(.warning), muted: role(.secondaryLabel),
            series: series,
            sequential: Ramp(light: Palette.sequential.map { ColorValue($0) },
                             dark: Palette.sequentialDark.map { ColorValue($0) }),
            diverging: Ramp(light: Palette.diverging.map { ColorValue($0) }, dark: nil))
    }

    private static var swissStructure: Structure {
        let hairline = Double(Rule.hairline.points)
        let rules = RuleSpec(
            title: TitleRule(weight: Double(Rule.section.points), position: .belowTitle, colour: .ink, inset: 0),
            section: Double(Rule.section.points), hairline: hairline, gridline: hairline, baseline: hairline,
            page: Double(Rule.page.points), reference: LineSpec(weight: 1, dash: [3, 3]), plotBorder: 0)
        let layout = LayoutSpec(
            margins: Insets(top: 16, leading: 8, bottom: 14, trailing: 16),
            gaps: Gaps(title: 4, subtitle: 12, plot: 8, source: 10),
            gutter: Double(Grid.gutter), columns: Grid.columns, baseUnit: Double(Grid.baseUnit),
            containerRadius: Double(Radius.container), controlRadius: Double(Radius.control),
            gridlines: .horizontalFaint)
        let labels = LabelSpec(values: .aboveOrEnd, series: .direct, axisSide: .leading,
                               axisLabelPlacement: .besideAxis, sourceLine: true)
        let marks = MarkSpec(lineWidth: 2, pointSize: 24, bandOpacity: 0.14, selectedLineWidth: 3,
                             barFill: .flat, barWidthRatio: 0.6, barCornerRadius: Double(Radius.container),
                             lineEnd: .none)
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
            plain: NumberFormatSpec(style: .decimal, decimals: 2))
    }
}
