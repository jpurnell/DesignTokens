import Foundation

/// A finding that fails the method, written into a ledger.
func ledgerFail(_ check: Check, _ appearance: ValidationAppearance, _ subject: String, _ measured: Double,
                _ threshold: Double) -> Finding {
    Finding(severity: .fail, check: check, appearance: appearance, subject: subject, measured: measured, threshold: threshold)
}

/// A finding that needs a secondary encoding, written into a ledger.
func ledgerWarn(_ check: Check, _ appearance: ValidationAppearance, _ subject: String, _ measured: Double,
                _ threshold: Double) -> Finding {
    Finding(severity: .warn, check: check, appearance: appearance, subject: subject, measured: measured, threshold: threshold)
}

/// Building blocks shared by the theme definitions. Where a number has no source of record it is the
/// value Swiss uses, and each theme file says which.
enum ThemeBuilders {
    static let regular = 400, medium = 500, semibold = 600, bold = 700

    /// Chart text line height: the package's label role. No editorial theme has one.
    static var chartLineHeight: Double { TypeStyle.label.lineHeight }

    /// A chart text role.
    static func text(_ family: FontFamilyRef, _ size: Double, _ weight: Int, platformStyle: PlatformTextStyle? = nil) -> TextSpec {
        TextSpec(family: family, size: size, weight: weight, tracking: 0, italic: false, uppercase: false,
                 lineHeight: chartLineHeight, platformStyle: platformStyle)
    }

    /// The package's six UI roles, as numbers. Editorial themes have no UI roles, so every theme takes these.
    static func uiRole(_ style: TypeStyle) -> TextSpec {
        TextSpec(family: .sans, size: style.points, weight: style.weight, tracking: style.trackingEm, italic: false,
                 uppercase: style.uppercase, lineHeight: style.lineHeight)
    }

    /// The type roles of an editorial theme: the nine chart roles, then the package's UI roles.
    static func typeRoles(title: TextSpec, subtitle: TextSpec, axisTitle: TextSpec, axisLabel: TextSpec,
                          seriesLabel: TextSpec, annotation: TextSpec, source: TextSpec, note: TextSpec,
                          tag: TextSpec) -> TypeRoles {
        TypeRoles(title: title, subtitle: subtitle, axisTitle: axisTitle, axisLabel: axisLabel, seriesLabel: seriesLabel,
                  annotation: annotation, source: source, note: note, tag: tag,
                  label: uiRole(.label), caption: uiRole(.caption), body: uiRole(.body), heading: uiRole(.heading),
                  uiTitle: uiRole(.title), display: uiRole(.display))
    }

    /// The seven number formats every theme has today (`FormatTokens.standard`).
    static var standardNumbers: NumberFormats {
        NumberFormats(
            currency: NumberFormatSpec(style: .currency, abbreviate: true, prefix: "$"),
            percent: NumberFormatSpec(style: .percent, decimals: 1),
            count: NumberFormatSpec(style: .decimal, decimals: 0, abbreviate: true),
            index: NumberFormatSpec(style: .decimal, decimals: 1),
            ratio: NumberFormatSpec(style: .decimal, decimals: 2, suffix: "×"),
            temperature: NumberFormatSpec(style: .decimal, decimals: 1, suffix: "°"),
            plain: NumberFormatSpec(style: .decimal, decimals: 2))
    }

    /// The rule weights of a theme with no title rule: hairline gridline and baseline, as the renderers draw today.
    static func rules(title: TitleRule? = nil, reference: LineSpec) -> RuleSpec {
        let hairline = Double(Rule.hairline.points)
        return RuleSpec(
            title: title ?? TitleRule(weight: 0, position: .none, colour: .ink, inset: 0),
            section: Double(Rule.section.points), hairline: hairline, gridline: hairline, baseline: hairline,
            page: Double(Rule.page.points), reference: reference, plotBorder: 0)
    }

    /// Margins, gaps and the grid. Gutter, columns, base unit and radii are the package's, not themed.
    static func layout(top: Double, leading: Double, bottom: Double, trailing: Double, title: Double, subtitle: Double,
                       plot: Double, source: Double, gridlines: GridlineStyle, shadow: ShadowSpec? = nil,
                       annotationRadius: Double = Double(Radius.container)) -> LayoutSpec {
        LayoutSpec(margins: Insets(top: top, leading: leading, bottom: bottom, trailing: trailing),
                   gaps: Gaps(title: title, subtitle: subtitle, plot: plot, source: source),
                   gutter: Double(Grid.gutter), columns: Grid.columns, baseUnit: Double(Grid.baseUnit),
                   containerRadius: Double(Radius.container), controlRadius: Double(Radius.control),
                   gridlines: gridlines, shadow: shadow, annotationRadius: annotationRadius)
    }

    /// A ramp from packed colours, light only.
    static func ramp(_ values: [UInt32], dark: [UInt32]? = nil) -> Ramp {
        Ramp(light: values.map { ColorValue.packed($0) }, dark: dark.map { $0.map { ColorValue.packed($0) } })
    }

    /// An adaptive colour from packed light and dark values.
    static func adaptive(_ light: UInt32, dark: UInt32? = nil) -> Adaptive {
        Adaptive(light: .packed(light), dark: dark.map { ColorValue.packed($0) })
    }

    /// A named series entry from packed light and dark values.
    static func series(_ name: String, _ light: UInt32, dark: UInt32? = nil) -> NamedAdaptive {
        NamedAdaptive(name: name, color: adaptive(light, dark: dark))
    }
}
