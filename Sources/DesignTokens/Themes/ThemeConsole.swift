import Foundation

public extension Theme {
    /// Console: the look of the FleetWatch web page before it moved onto the design system (added in 0.12.0), as a theme of its own.
    ///
    /// A fixed-dark navy theme, bordered cards in an auto-fit grid (``CardChrome/bordered``), the status colours of a terminal
    /// dashboard, and a monospaced face for every text role. The id is `console`; the palette is navy, not the green-on-black the
    /// name may suggest.
    ///
    /// **Source of record: the page's own stylesheet** (`app.css`, 2026-11-10). Surfaces `#1A1A2E` (page) and `#16213E` (card),
    /// `#0F3460` (border and rule), `#0A0A1A` (the inset behind inputs and bars, the `inset` extra), text `#E0E0E0`, dim text
    /// `#8888AA`, status `#4ADE80` (ok), `#FACC15` (late), `#F87171` (down), and `#60A5FA` (links). Radii 8 (container), 4
    /// (control) and 3 (the bars and tags, here ``MarkSpec/barCornerRadius``); a 1 px card border; the font stack
    /// `'SF Mono', 'Menlo', 'Consolas', monospace`.
    ///
    /// These colours are the theme's own values. They are not mapped onto the Swiss tokens, and nothing here tunes them to the
    /// validation method: the ledger records what the package's validator measures, as the legacy themes' do.
    ///
    /// **Not in the source, and chosen here (each is marked):**
    /// - `accent` and `link` are the page's blue; `onAccent` is the inset `#0A0A1A`, the darkest of the page's own colours.
    /// - `muted` is the dim text colour, the page's colour for an idle or retired thing.
    /// - The `alert` extra, the stronger warning beside the caution yellow, is `#FB923C`. The page has no orange; its four hues
    ///   are the 400 shades of the Tailwind palette (`green-400`, `yellow-400`, `red-400`, `blue-400`), so the orange is Tailwind's
    ///   `orange-400`, the same family.
    /// - The series: the four page hues then four more 400 shades (`orange-400` `#FB923C`, `purple-400` `#C084FC`, `cyan-400`
    ///   `#22D3EE`, `pink-400` `#F472B6`), eight in all, so the eight series stay in one family.
    /// - The sequential ramp is one hue, blue, from `blue-700` `#1D4ED8` to `blue-200` `#BFDBFE` in five Tailwind steps, light
    ///   toward the high end, as a ramp reads on a dark surface. The diverging ramp runs the page's blue to its red through a
    ///   dark neutral `#4C4C66` (the dim text at about half its lightness), so the middle sits near the surface.
    /// - Layout: gutter and base unit are the package's. The page's gaps and padding are `1.2rem` (19.2 px), which is not on the
    ///   4 px grid, so ``LayoutSpec/cardPadding`` is 20 and the gutter stays 16. Margins and gaps are Swiss's: the page has no
    ///   charts. Rules are the package's hairline weights.
    /// - The UI and chart text roles take the sizes, weights and tracking of the package's roles (the same as Swiss); only the
    ///   family is the page's. The page's font sizes are in `rem` and off the type scale; they are not carried.
    static let console = Theme(id: "console", name: "Console", structure: consoleStructure, palette: consolePalette,
                               appearances: .fixedDark, conformance: consoleConformance)

    /// The page's font stack as a family: `SF Mono`, then `Menlo`, then `Consolas`, then the system monospace.
    ///
    /// Each name falls back to the next, so the CSS reads `"SF Mono", "Menlo", "Consolas", ui-monospace, ..., monospace`.
    private static var consoleFamily: FontFamilyRef {
        .named("SF Mono", fallback: .named("Menlo", fallback: .named("Consolas", fallback: .mono)))
    }

    private static var consolePalette: ThemePalette {
        typealias B = ThemeBuilders
        func blue(_ values: [UInt32]) -> Ramp { B.ramp(values) }
        return ThemePalette(
            ink: B.adaptive(0xE0E0E0), secondaryInk: B.adaptive(0x8888AA), background: B.adaptive(0x1A1A2E),
            surface: B.adaptive(0x16213E), rule: B.adaptive(0x0F3460), accent: B.adaptive(0x60A5FA),
            onAccent: B.adaptive(0x0A0A1A), link: B.adaptive(0x60A5FA), positive: B.adaptive(0x4ADE80),
            negative: B.adaptive(0xF87171), warning: B.adaptive(0xFACC15), muted: B.adaptive(0x8888AA),
            series: [B.series("blue", 0x60A5FA), B.series("green", 0x4ADE80), B.series("orange", 0xFB923C),
                     B.series("purple", 0xC084FC), B.series("red", 0xF87171), B.series("cyan", 0x22D3EE),
                     B.series("yellow", 0xFACC15), B.series("pink", 0xF472B6)],
            sequential: blue([0x1D4ED8, 0x3B82F6, 0x60A5FA, 0x93C5FD, 0xBFDBFE]),
            diverging: B.ramp([0x60A5FA, 0x4C4C66, 0xF87171]),
            extras: ["inset": B.adaptive(0x0A0A1A), ThemePalette.alertName: B.adaptive(0xFB923C)])
    }

    private static var consoleStructure: Structure {
        typealias B = ThemeBuilders
        func role(_ style: TypeStyle) -> TextSpec {
            var spec = B.uiRole(style)
            spec.family = consoleFamily
            return spec
        }
        func chart(_ size: Double, _ weight: Int) -> TextSpec { B.text(consoleFamily, size, weight) }
        let type = TypeRoles(
            title: chart(17, B.bold), subtitle: chart(13, B.regular), axisTitle: chart(11, B.medium),
            axisLabel: chart(11, B.regular), seriesLabel: chart(12, B.semibold), annotation: chart(11, B.bold),
            source: chart(11, B.regular), note: chart(11, B.regular), tag: chart(11, B.bold),
            label: role(.label), caption: role(.caption), body: role(.body), heading: role(.heading),
            uiTitle: role(.title), display: role(.display))
        let layout = LayoutSpec(
            margins: Insets(top: 6, leading: 8, bottom: 12, trailing: 8),
            gaps: Gaps(title: 4, subtitle: 12, plot: 8, source: 10, referenceLabel: 5),
            gutter: Double(Grid.gutter), columns: Grid.columns, baseUnit: Double(Grid.baseUnit),
            containerRadius: 8, controlRadius: 4, gridlines: .horizontalFaint,
            annotationRadius: 8, cardBorder: 1, cardPadding: 20, cardChrome: .bordered)
        let labels = LabelSpec(values: .aboveOrEnd, series: .direct, axisSide: .leading,
                               axisLabelPlacement: .besideAxis, sourceLine: true, valueHalo: 3)
        let marks = MarkSpec(lineWidth: 2, pointSize: 24, bandOpacity: 0.14, selectedLineWidth: 3,
                             barFill: .flat, barWidthRatio: 0.7, barCornerRadius: 3,
                             lineEnd: .none, defaultFill: .muted, defaultEmphasis: .latest, emphasisFill: .accent)
        return Structure(rules: B.rules(reference: LineSpec(weight: Double(Rule.hairline.points), dash: [])), type: type,
                         labels: labels, layout: layout, marks: marks, numbers: B.standardNumbers)
    }
}
