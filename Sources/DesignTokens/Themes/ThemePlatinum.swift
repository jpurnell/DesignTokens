import Foundation

public extension Theme {
    /// Platinum, the Mac OS 8 and 9 look, as a theme (unreleased): a two-pixel-deep bevel on every control, flat greys, a lavender accent.
    /// Light only; the look has no dark appearance.
    ///
    /// **Source of record: pixels read from period screenshots of Mac OS 8.0** (`project/docs/technical/SkinMeasurements.md`, Platinum
    /// section). Measured: the button is 20 px high with a 1 px black outline and a corner that steps in 3 px; its bevel, outside in, is
    /// `#000000 #DDDDDD #FFFFFF` on the top and left and `#000000 #777777 #AAAAAA` on the bottom and right, over a flat `#DDDDDD` body; the
    /// default button has a second three-pixel frame (`#000000 #DDDDDD #AAAAAA` top and left, `#000000 #777777 #AAAAAA` bottom and right)
    /// outside that, its corner stepping in 4 to 5 px; a window's body is `#DDDDDD`; the progress bar is `#6666CC` (outline `#333399`);
    /// a selected row is `#CCCCFF`; the empty desktop reads `#9C9CCE`; a text field in the colour picker is a 1 px black outline on white.
    ///
    /// **Not measured, chosen here:** the pressed state (the bevel inverted over an `#AAAAAA` body), the disabled state, the focus ring,
    /// the window frame and title bar (a plain 1 px outline here; the real one is striped with close, zoom and windowshade boxes),
    /// scroll bars, and the type (Charcoal is the system face on 8.x, Geneva for lists: general knowledge, named with the system sans as
    /// the fallback because neither is installed on most machines). The status roles carry no colour (black); status is a glyph.
    static var platinum: Theme {
        Theme(id: "platinum", name: "Platinum (Mac OS 8)", structure: classicMacStructure(family: platinumFamily),
              palette: platinumPalette, appearances: .lightOnly, conformance: platinumConformance, surfaces: platinumSurfaces,
              windowControls: WindowControls(leading: [.close], trailing: [.zoom, .minimize], titleBar: platinumTitleBar))
    }

    /// Measured from the Appearance window of the Mac OS 8.0 capture: the bar is 22 rows (black and white above, #999999 and black below),
    /// its parts start 2 px inside the frame, the boxes are 13 px, the stripes 12 px and the gap between parts 4 px. The right frame is
    /// three columns (`#000000 #000000 #999999`), so the right inset is one larger than the left. The gap between a zoom and a windowshade
    /// box is not measured (the window sampled has one box at the right) and is taken as the same 4 px.
    private static var platinumTitleBar: TitleBarMetrics {
        TitleBarMetrics(height: 22, inset: Insets(top: 4, leading: 4, bottom: 2, trailing: 5), boxSize: 13, gap: 4, stripeHeight: 12)
    }

    private static var platinumFamily: FontFamilyRef { .named("Charcoal", fallback: .named("Geneva", fallback: .sans)) }

    private static var platinumPalette: ThemePalette {
        typealias B = ThemeBuilders
        let black: UInt32 = 0x000000
        return ThemePalette(
            ink: B.adaptive(black), secondaryInk: B.adaptive(0x333333), background: B.adaptive(0xDDDDDD), surface: B.adaptive(0xFFFFFF),
            rule: B.adaptive(black), accent: B.adaptive(0x6666CC), onAccent: B.adaptive(0xFFFFFF), link: B.adaptive(0x333399),
            positive: B.adaptive(black), negative: B.adaptive(black), warning: B.adaptive(black), muted: B.adaptive(0x777777),
            series: [B.series("lavender", 0x6666CC)],
            // the progress bar's own rows, light to dark: #CCCCFF #9999FF #6666CC #333399 #000055
            sequential: B.ramp([0xCCCCFF, 0x9999FF, 0x6666CC, 0x333399, 0x000055]),
            diverging: B.ramp([0x333399, 0xDDDDDD, 0x333333]),
            extras: ["shade": B.adaptive(0xAAAAAA), "selection": B.adaptive(0xCCCCFF), "desktop": B.adaptive(0x9C9CCE),
                     // the title bar's greys, read off the Mac OS 8.0 capture
                     "bar": B.adaptive(0xCCCCCC), "gray22": B.adaptive(0x222222), "gray88": B.adaptive(0x888888),
                     "gray99": B.adaptive(0x999999), "grayBB": B.adaptive(0xBBBBBB), "grayEE": B.adaptive(0xEEEEEE)])
    }

    /// The control surfaces, in logical pixels.
    private static var platinumSurfaces: SurfaceSet {
        func ref(_ name: String) -> ColourReference { ColourReference(source: name) }
        func step(_ name: String, _ width: Double = 1) -> EdgeStep { EdgeStep(literal: ref(name), width) }
        // Outside in. ink = #000000, background = #DDDDDD, surface = #FFFFFF, muted = #777777, shade = #AAAAAA.
        let raisedTop = [step("ink"), step("background"), step("surface")]
        let raisedBottom = [step("ink"), step("muted"), step("shade")]
        let raised = Edges(top: raisedTop, leading: raisedTop, bottom: raisedBottom, trailing: raisedBottom)
        let sunkenTop = [step("ink"), step("muted"), step("shade")]
        let sunkenBottom = [step("ink"), step("background"), step("surface")]
        let pressed = Edges(top: sunkenTop, leading: sunkenTop, bottom: sunkenBottom, trailing: sunkenBottom)
        // The default button's extra frame, then the ordinary bevel inside it.
        let ringTop = [step("ink"), step("background"), step("shade")]
        let ringBottom = [step("ink"), step("muted"), step("shade")]
        let ringed = Edges(top: ringTop + raisedTop, leading: ringTop + raisedTop,
                           bottom: ringBottom + raisedBottom, trailing: ringBottom + raisedBottom)
        let ringedPressed = Edges(top: ringTop + sunkenTop, leading: ringTop + sunkenTop,
                                  bottom: ringBottom + sunkenBottom, trailing: ringBottom + sunkenBottom)
        let outline = Edges(top: [step("ink")], leading: [step("ink")], bottom: [step("ink")], trailing: [step("ink")])
        func recipe(fill: String, ink: String = "ink", edges: Edges?, radius: Double) -> SurfaceRecipe {
            SurfaceRecipe(layers: [.fill(ref(fill))], edges: edges, radius: .uniform(radius), backdropBlur: nil,
                          ink: ref(ink), scale: .integer)
        }
        // Title bar (measured, see platinumTitleBar): the bar, the stripes (a 1 x 2 tile, white first) and the 13 x 13 close box, whose pixels
        // are listed row by row from the capture (W = white, bar = #CCCCCC, bg = #DDDDDD, shade = #AAAAAA).
        let (W, bar, bg, sh, g88, g22, g99, gBB, gEE) = (ref("surface"), ref("bar"), ref("background"), ref("shade"), ref("gray88"),
                                                          ref("gray22"), ref("gray99"), ref("grayBB"), ref("grayEE"))
        let boxCells: [ColourReference] = [
            g88, g88, g88, g88, g88, g88, g88, g88, g88, g88, g88, g88, bar,
            g88, g22, g22, g22, g22, g22, g22, g22, g22, g22, g22, g22, W,
            g88, g22, W, bar, bar, bar, bar, bar, bar, bar, bar, g22, W,
            g88, g22, bar, g99, g99, sh, sh, gBB, gBB, bar, g88, g22, W,
            g88, g22, bar, g99, sh, sh, gBB, gBB, bar, bar, g88, g22, W,
            g88, g22, bar, sh, sh, gBB, gBB, bar, bar, bg, g88, g22, W,
            g88, g22, bar, sh, gBB, gBB, bar, bar, bg, bg, g88, g22, W,
            g88, g22, bar, gBB, gBB, bar, bar, bg, bg, gEE, g88, g22, W,
            g88, g22, bar, gBB, bar, bar, bg, bg, gEE, gEE, g88, g22, W,
            g88, g22, bar, bar, bar, bg, bg, gEE, gEE, W, g88, g22, W,
            g88, g22, bar, g88, g88, g88, g88, g88, g88, g88, g88, g22, W,
            g88, g22, g22, g22, g22, g22, g22, g22, g22, g22, g22, g22, W,
            bar, W, W, W, W, W, W, W, W, W, W, W, W,
        ]
        // the windowshade box: the same bevel with two lines across it (rows 5 and 7 of the 13)
        var shadeCells = boxCells
        for y in [5, 7] { for x in 1...11 { shadeCells[y * 13 + x] = g22 } }
        let barEdges = Edges(top: [step("ink"), step("surface")], leading: [step("ink"), step("surface")],
                             bottom: [step("ink"), step("gray99")], trailing: [step("ink"), step("ink"), step("gray99")])
        func tile(_ layer: PatternSpec) -> SurfaceRecipe {
            SurfaceRecipe(layers: [.fill(bar), .pattern(layer)], edges: nil, radius: .uniform(0), backdropBlur: nil, ink: ref("ink"), scale: .integer)
        }
        return SurfaceSet(recipes: [
            .titleBar: [.rest: recipe(fill: "bar", edges: barEdges, radius: 0)],
            .titleStripes: [.rest: tile(PatternSpec(literal: 1, 2, [W, ref("muted")]))],
            .windowBox: [.rest: tile(PatternSpec(literal: 13, 13, boxCells))],
            .windowBoxMinimize: [.rest: tile(PatternSpec(literal: 13, 13, shadeCells))],
            .desktop: [.rest: recipe(fill: "desktop", edges: nil, radius: 0)],
            .window: [.rest: recipe(fill: "background", edges: outline, radius: 0)],
            .panel: [.rest: recipe(fill: "surface", edges: outline, radius: 0)],
            .button: [.rest: recipe(fill: "background", edges: raised, radius: 3),
                      .active: recipe(fill: "shade", edges: pressed, radius: 3)],
            .buttonDefault: [.rest: recipe(fill: "background", edges: ringed, radius: 5),
                             .active: recipe(fill: "shade", edges: ringedPressed, radius: 5)],
            .field: [.rest: recipe(fill: "surface", edges: outline, radius: 0)],
            .selection: [.rest: recipe(fill: "selection", edges: nil, radius: 0)],
        ])
    }

    /// What the validator finds in this palette, recorded exactly.
    static var platinumConformance: Conformance {
        Conformance(kind: .ledger, entries: [
            // the progress bar's lightest row (#CCCCFF) against the #DDDDDD window body
            ledgerFail(.rampLightEnd, .light, "sequential", 1.13, 2.0),
        ])
    }
}
