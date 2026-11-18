import Foundation

public extension Theme {
    /// System 7, the one-bit Macintosh look, as a theme (unreleased): black on white, one-pixel outlines, no bevel, no shadow, and a
    /// 50% checkerboard desktop. Light only; there is no dark appearance because the look has no third colour to make one from.
    ///
    /// **Source of record: pixels read from period screenshots** (`project/docs/technical/SkinMeasurements.md`, System 7.0 section).
    /// What was measured: the only two colours are `#000000` and `#FFFFFF`; a button is a 1 px black outline on white with no bevel; the
    /// desktop is a 2 x 2 checkerboard. What was **not** measured and is chosen here: the button corner radius (4), the default-button ring
    /// (outline, one pixel of white, one of black), the pressed state (inverted), and the typeface (Chicago for the system face is general
    /// knowledge, named with the system sans as its fallback because the face is not installed on most machines).
    ///
    /// Every surface is `ScalePolicy.integer`: drawn at 1x, 2x or 3x and never in between, so the outlines stay one logical pixel wide.
    /// The ledger records what a two-colour palette cannot do (a chart's series are not distinguishable by colour; use direct labels and
    /// the pattern layers of ``SurfaceRecipe``).
    static var system7: Theme {
        Theme(id: "system7", name: "System 7 (1-bit)", structure: system7Structure, palette: system7Palette,
              appearances: .lightOnly, conformance: system7Conformance, surfaces: system7Surfaces)
    }

    private static var system7Family: FontFamilyRef { .named("Chicago", fallback: .named("Geneva", fallback: .sans)) }

    private static var system7Palette: ThemePalette {
        typealias B = ThemeBuilders
        let black: UInt32 = 0x000000, white: UInt32 = 0xFFFFFF
        return ThemePalette(
            ink: B.adaptive(black), secondaryInk: B.adaptive(black), background: B.adaptive(white), surface: B.adaptive(white),
            rule: B.adaptive(black), accent: B.adaptive(black), onAccent: B.adaptive(white), link: B.adaptive(black),
            positive: B.adaptive(black), negative: B.adaptive(black), warning: B.adaptive(black), muted: B.adaptive(black),
            series: [B.series("black", black)],
            sequential: B.ramp([black, white]), diverging: B.ramp([black, white, black]),
            extras: [:])
    }

    private static var system7Structure: Structure {
        typealias B = ThemeBuilders
        func role(_ style: TypeStyle) -> TextSpec {
            var spec = B.uiRole(style)
            spec.family = system7Family
            return spec
        }
        func chart(_ size: Double, _ weight: Int) -> TextSpec { B.text(system7Family, size, weight) }
        let type = TypeRoles(
            title: chart(17, B.bold), subtitle: chart(13, B.regular), axisTitle: chart(11, B.regular),
            axisLabel: chart(11, B.regular), seriesLabel: chart(12, B.regular), annotation: chart(11, B.regular),
            source: chart(11, B.regular), note: chart(11, B.regular), tag: chart(11, B.regular),
            label: role(.label), caption: role(.caption), body: role(.body), heading: role(.heading),
            uiTitle: role(.title), display: role(.display))
        let layout = LayoutSpec(
            margins: Insets(top: 6, leading: 8, bottom: 12, trailing: 8),
            gaps: Gaps(title: 4, subtitle: 12, plot: 8, source: 10, referenceLabel: 5),
            gutter: Double(Grid.gutter), columns: Grid.columns, baseUnit: Double(Grid.baseUnit),
            containerRadius: 0, controlRadius: 4, gridlines: .baselineOnly,
            annotationRadius: 0, cardBorder: 1, cardPadding: 16, cardChrome: .bordered)
        let labels = LabelSpec(values: .aboveOrEnd, series: .direct, axisSide: .leading,
                               axisLabelPlacement: .besideAxis, sourceLine: true, valueHalo: 0)
        let marks = MarkSpec(lineWidth: 1, pointSize: 16, bandOpacity: 0, selectedLineWidth: 2,
                             barFill: .flat, barWidthRatio: 0.7, barCornerRadius: 0,
                             lineEnd: .none, defaultFill: .muted, defaultEmphasis: .latest, emphasisFill: .accent)
        return Structure(rules: B.rules(reference: LineSpec(weight: 1, dash: [])), type: type,
                         labels: labels, layout: layout, marks: marks, numbers: B.standardNumbers)
    }

    /// The control surfaces, in logical pixels on the one-bit grid.
    private static var system7Surfaces: SurfaceSet {
        func ref(_ name: String) -> ColourReference { ColourReference(source: name) }
        func step(_ name: String, _ width: Double) -> EdgeStep { EdgeStep(literal: ref(name), width) }
        func around(_ steps: [EdgeStep]) -> Edges { Edges(top: steps, leading: steps, bottom: steps, trailing: steps) }
        let outline = around([step("ink", 1)])
        func recipe(fill: String, ink: String, edges: Edges?, radius: Double, layers: [SurfaceLayer]? = nil) -> SurfaceRecipe {
            SurfaceRecipe(layers: layers ?? [.fill(ref(fill))], edges: edges, radius: .uniform(radius), backdropBlur: nil,
                          ink: ref(ink), scale: .integer)
        }
        let checkerboard = PatternSpec(literal: 2, 2, [ref("ink"), ref("background"), ref("background"), ref("ink")])
        return SurfaceSet(recipes: [
            .desktop: [.rest: recipe(fill: "background", ink: "ink", edges: nil, radius: 0, layers: [.fill(ref("background")), .pattern(checkerboard)])],
            .window: [.rest: recipe(fill: "background", ink: "ink", edges: outline, radius: 0)],
            .panel: [.rest: recipe(fill: "surface", ink: "ink", edges: outline, radius: 0)],
            .button: [.rest: recipe(fill: "background", ink: "ink", edges: outline, radius: 4),
                      .active: recipe(fill: "ink", ink: "background", edges: outline, radius: 4)],
            .buttonDefault: [.rest: recipe(fill: "background", ink: "ink", edges: around([step("ink", 1), step("background", 1), step("ink", 1)]), radius: 4),
                             .active: recipe(fill: "ink", ink: "background", edges: around([step("ink", 1), step("background", 1), step("ink", 1)]), radius: 4)],
            .field: [.rest: recipe(fill: "background", ink: "ink", edges: outline, radius: 0)],
        ])
    }

    /// What the validator finds in a two-colour palette, recorded exactly. The one series is black, so it is below the lightness band
    /// (0.0 against 0.43) and has no chroma (0.0 against 0.1); there is nothing to separate it from, so the pairwise checks do not run.
    /// The sequential ramp runs black to white and its light end fails the ramp check (1.0 against 2.0). A chart in this theme labels
    /// series directly and tells them apart by pattern, not by colour.
    static var system7Conformance: Conformance {
        Conformance(kind: .ledger, entries: [
            ledgerFail(.lightnessBand, .light, "black", 0.0, 0.43),
            ledgerFail(.chromaFloor, .light, "black", 0.0, 0.1),
            ledgerFail(.rampLightEnd, .light, "sequential", 1.0, 2.0),
        ])
    }
}
