import Foundation

public extension Theme {
    /// Platinum, the Mac OS 8 and 9 look, as a theme (unreleased): a two-pixel-deep bevel on every control, flat greys, a lavender accent.
    /// Light only; the look has no dark appearance.
    ///
    /// **Source of record: a live Mac OS 8.0 at 24 bits** (Infinite Mac, 2026-11-19; `project/docs/technical/SkinMeasurements.md`), for every colour
    /// of the controls, title bar, scroll bar and menus. The geometry (and, in the first rounds, the colours) came from period screenshots, which
    /// were 256-colour: each colour there was the nearest 8-bit one, so the live values differ (`#E7E7E7` for the `#DDDDDD` the screenshots read).
    /// Measured: the button is 20 px high with a 1 px black outline and a corner that steps in 3 px; its bevel, outside in, is
    /// `#000000 #E7E7E7 #FFFFFF` on the top and left and `#000000 #969696 #C0C0C0` on the bottom and right, over a flat `#E7E7E7` body; the
    /// default button has a second three-pixel frame (`#000000 #E7E7E7 #C0C0C0` top and left, `#000000 #969696 #C0C0C0` bottom and right)
    /// outside that, its corner stepping in 4 to 5 px; a panel's body is `#E7E7E7`; the accent and highlight are the lavender `#5454B3`;
    /// a text field is a 1 px black outline on white. A window's frame area carries a fine dither of `#DADADA`, `#E7E7E7` and `#F3F3F3` that the
    /// theme draws flat.
    ///
    /// **Not measured, chosen here:** the focus ring, the disabled field and default button,
    /// the window frame (a plain 1 px outline; the title bar is measured, see `platinumTitleBar`) and the pressed state of the title bar's boxes,
    /// scroll bars, and the type (Charcoal is the system face on 8.x, Geneva for lists: general knowledge, named with the system sans as
    /// the fallback because neither is installed on most machines). The status roles carry no colour (black); status is a glyph.
    static var platinum: Theme {
        Theme(id: "platinum", name: "Platinum (Mac OS 8)", structure: classicMacStructure(family: platinumFamily, monospace: macMonospace),
              palette: platinumPalette, appearances: .lightOnly, conformance: platinumConformance, surfaces: platinumSurfaces,
              windowControls: WindowControls(leading: [.close], trailing: [.zoom, .minimize], titleBar: platinumTitleBar),
              scrollBar: platinumScrollBar, menus: platinumMenus)
    }

    /// Measured from the menu bar of the Mac OS 8.0 desktop capture: 20 rows (a white row, 17 of `#DDDDDD`, a `#999999` row, a black row), a white
    /// column at the left and a `#999999` one at the right; titles start 43 px in after the apple and are 15 px apart, so each carries 8 px.
    /// The highlighted title is the lavender `#5454B3` with white text, measured on a live Mac OS 8.0 (the captures had the highlight set to black and white).
    private static var platinumMenus: MenuMetrics {
        MenuMetrics(barHeight: 20, barInset: Insets(top: 1, leading: 1, bottom: 2, trailing: 1), itemHeight: 20, itemPadding: 8)
    }

    /// Measured from the Appearance window of the Mac OS 8.0 capture: the bar is 22 rows (black and white above, #999999 and black below),
    /// its parts start 2 px inside the frame, the boxes are 13 px, the stripes 12 px and the gap between parts 4 px. The right frame is
    /// three columns (`#000000 #000000 #999999`), so the right inset is one larger than the left. Two controls on one side sit 3 px apart (the
    /// About window of the capture: boxes at columns 445 and 461).
    private static var platinumTitleBar: TitleBarMetrics {
        TitleBarMetrics(height: 22, inset: Insets(top: 4, leading: 4, bottom: 2, trailing: 5), boxSize: 13, gap: 4, stripeHeight: 12, boxGap: 3)
    }

    /// Measured from the live horizontal scroll bar of the Mac OS 8.0 Appearance window: 16 px thick (a black line, 14 rows, a black line), with a
    /// 16 x 16 arrow button at each end and no gap. A vertical bar is the same drawing turned about its diagonal (assumed; no active vertical bar
    /// is in the captures).
    private static var platinumScrollBar: ScrollBarMetrics {
        ScrollBarMetrics(thickness: 16, arrowLength: 16, arrows: .bothEnds)
    }

    private static var platinumFamily: FontFamilyRef { .named("Charcoal", fallback: .named("Geneva", fallback: .sans)) }

    private static var platinumPalette: ThemePalette {
        typealias B = ThemeBuilders
        let black: UInt32 = 0x000000
        return ThemePalette(
            ink: B.adaptive(black), secondaryInk: B.adaptive(0x333333), background: B.adaptive(0xE7E7E7), surface: B.adaptive(0xFFFFFF),
            rule: B.adaptive(black), accent: B.adaptive(0x5454B3), onAccent: B.adaptive(0xFFFFFF), link: B.adaptive(0x5454B3),
            positive: B.adaptive(black), negative: B.adaptive(black), warning: B.adaptive(black), muted: B.adaptive(0x777777),
            series: [B.series("lavender", 0x6666CC)],
            // the progress bar's own rows, light to dark: #CCCCFF #9999FF #6666CC #333399 #000055
            sequential: B.ramp([0xCCCCFF, 0x9999FF, 0x6666CC, 0x333399, 0x000055]),
            diverging: B.ramp([0x333399, 0xE7E7E7, 0x333333]),
            // Every grey and lavender below is a 24-bit value read from a live Mac OS 8.0 (Infinite Mac, 2026-11-19). The names are the 8-bit
            // levels the first captures read (gray88 was #888888 there); the live value of each is the one the name now carries.
            extras: ["shade": B.adaptive(0xC0C0C0), "selection": B.adaptive(0xDADAFF), "desktop": B.adaptive(0xB3B3DA),
                     "bar": B.adaptive(0xDADADA), "gray22": B.adaptive(0x3F3F3F), "gray88": B.adaptive(0xA5A5A5),
                     "gray99": B.adaptive(0xB3B3B3), "grayBB": B.adaptive(0xCDCDCD), "grayEE": B.adaptive(0xF3F3F3), "gray96": B.adaptive(0x969696),
                     // the pressed button's ramp (black, #666666, #777777, then the #878787 fill), and the estimate for an inactive arrow's inner row
                     "gray66": B.adaptive(0x666666), "gray77": B.adaptive(0x777777), "gray87": B.adaptive(0x878787),
                     // the highlight of a menu title or row: the default Lavender highlight colour
                     "highlight": B.adaptive(0x5454B3),
                     // the scroll bar thumb's body and its shaded edge
                     "lavender": B.adaptive(0xB3B3FF), "lavenderShade": B.adaptive(0x8787DA)])
    }

    /// The control surfaces, in logical pixels.
    private static var platinumSurfaces: SurfaceSet {
        func ref(_ name: String) -> ColourReference { ColourReference(source: name) }
        func step(_ name: String, _ width: Double = 1) -> EdgeStep { EdgeStep(literal: ref(name), width) }
        // Outside in. ink = #000000, background = #E7E7E7, surface = #FFFFFF, gray96 = #969696, shade = #C0C0C0 (live Mac OS 8.0).
        let raisedTop = [step("ink"), step("background"), step("surface")]
        let raisedBottom = [step("ink"), step("gray96"), step("shade")]
        let raised = Edges(top: raisedTop, leading: raisedTop, bottom: raisedBottom, trailing: raisedBottom)
        // Pressed, measured on a live Mac OS 8.0: black, then #666666 and #777777 inside the top and left, #969696 and #A5A5A5 inside the bottom
        // and right, on a #878787 fill.
        let sunkenTop = [step("ink"), step("gray66"), step("gray77")]
        let sunkenBottom = [step("ink"), step("gray96"), step("gray88")]
        let pressed = Edges(top: sunkenTop, leading: sunkenTop, bottom: sunkenBottom, trailing: sunkenBottom)
        // The default button's extra frame, then the ordinary bevel inside it.
        let ringTop = [step("ink"), step("background"), step("shade")]
        let ringBottom = [step("ink"), step("gray96"), step("shade")]
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
        // are listed row by row from the capture (W = white, bar = #DADADA, bg = #E7E7E7, shade = #C0C0C0).
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
        // the zoom box: the same bevel with one line across it (row 5 of the 13); the windowshade box: two (rows 5 and 7)
        var zoomCells = boxCells
        for x in 1...11 { zoomCells[5 * 13 + x] = g22 }
        var shadeCells = boxCells
        for y in [5, 7] { for x in 1...11 { shadeCells[y * 13 + x] = g22 } }
        let barEdges = Edges(top: [step("ink"), step("surface")], leading: [step("ink"), step("surface")],
                             bottom: [step("ink"), step("gray99")], trailing: [step("ink"), step("ink"), step("gray99")])
        func tileOnly(_ layer: PatternSpec) -> SurfaceRecipe {
            SurfaceRecipe(layers: [.pattern(layer)], edges: nil, radius: .uniform(0), backdropBlur: nil, ink: ref("ink"), scale: .integer)
        }
        func tile(_ layer: PatternSpec) -> SurfaceRecipe {
            SurfaceRecipe(layers: [.fill(bar), .pattern(layer)], edges: nil, radius: .uniform(0), backdropBlur: nil, ink: ref("ink"), scale: .integer)
        }
        // Scroll bar (measured, see platinumScrollBar). The track's 14 rows, top to bottom: #777777 #888888 ten of #AAAAAA #BBBBBB #CCCCCC, between
        // black lines. The thumb is a 1 px bevel (#CCCCFF over #6666CC) on #9999FF with an 8 x 8 grip of grooves; the arrows are the button bevel
        // (white over #BBBBBB on #DDDDDD) with a 4 x 8 triangle, as whole 16 x 16 tiles. Corner pixels of the thumb differ by one pixel.
        let (lav, light, link) = (ref("lavender"), ref("selection"), ref("link"))
        let trackEdges = Edges(top: [step("ink"), step("gray96"), step("gray88")], leading: [step("gray96"), step("gray88")], bottom: [step("ink"), step("bar"), step("grayBB")], trailing: [])
        let thumbEdges = Edges(top: [step("ink"), step("selection")], leading: [step("ink"), step("selection")],
                               bottom: [step("ink"), step("lavenderShade")], trailing: [step("ink"), step("lavenderShade")])
        let gripKey: [Character: ColourReference] = ["e": gEE, "q": lav, "p": light, "s": link]
        let gripRows = ["eqeqeqeq", "pspspsps", "pspspsps", "pspspsps", "pspspsps", "pspspsps", "pspspsps", "qsqsqsqs"]
        let gripCells = gripRows.flatMap { $0.map { gripKey[$0] ?? lav } }
        // the track starts again just past the thumb: its sunken left edge (#777777 then #888888) is painted outside the thumb's right side, in the
        // rows between the thumb's black lines (a shadow shrunk by 1 px and moved right)
        let thumbBase = recipe(fill: "lavender", edges: thumbEdges, radius: 0)
        let thumb = SurfaceRecipe(
            layers: thumbBase.layers + [
                .shadow(ShadowLayer(shadow: ShadowSpec(colour: ref("gray96"), radius: 0, x: 2, y: 0), spread: -1)),
                .shadow(ShadowLayer(shadow: ShadowSpec(colour: ref("gray88"), radius: 0, x: 3, y: 0), spread: -1)),
            ], edges: thumbBase.edges, radius: thumbBase.radius, backdropBlur: nil, ink: thumbBase.ink, scale: .integer)
        // an arrow button: the bevel, then the triangle; the base column of the glyph and which way it grows
        func arrowCells(baseColumn: Int, growsRight: Bool, inactive: Bool = false) -> [ColourReference] {
            var cells: [ColourReference] = []
            let widths = [1, 2, 3, 4, 4, 3, 2, 1]
            for row in 0..<16 {
                for col in 0..<16 {
                    let k = ref("ink")
                    let glyphRow = row - 4
                    if (0..<8).contains(glyphRow) {
                        let w = widths[glyphRow]
                        let inGlyph = growsRight ? (baseColumn..<baseColumn + w).contains(col) : (baseColumn - w + 1...baseColumn).contains(col)
                        if inGlyph { cells.append(inactive ? ref("gray88") : k); continue }
                    }
                    // an inactive arrow's side toward the track is #555555 (the start arrow's right column, the end arrow's left), its two end pixels staying black
                    if inactive, col == (growsRight ? 0 : 15), row != 0, row != 15 { cells.append(ref("gray77")); continue }
                    if row == 0 || row == 15 || col == 0 || col == 15 { cells.append(k) }
                    else if inactive { cells.append(ref("grayEE")) }
                    else if row == 1 { cells.append(col == 14 ? bg : W) }
                    else if row == 14 { cells.append(col == 1 ? bg : ref("grayBB")) }
                    else if col == 1 { cells.append(W) }
                    else if col == 14 { cells.append(ref("grayBB")) }
                    else { cells.append(bg) }
                }
            }
            return cells
        }
        let menuBarEdges = Edges(top: [step("surface")], leading: [step("surface")], bottom: [step("ink"), step("gray99")], trailing: [step("gray99")],
                                 stacking: .bottomTrailingFirst)
        // Disabled and inactive (measured from the Open dialogs of the Mac OS 8.0 capture): a button is flat #DDDDDD with a one-pixel #888888 outline
        // and #888888 text; an inactive scroll bar is flat #EEEEEE inside its black outline, its arrows without a bevel and with #888888 triangles.
        // Assumed: a disabled default button loses its ring, and a disabled field dims only its text.
        let dimOutline = Edges(top: [step("gray88")], leading: [step("gray88")], bottom: [step("gray88")], trailing: [step("gray88")])
        let disabledButton = recipe(fill: "background", ink: "gray88", edges: dimOutline, radius: 3)
        let inactiveTrack = recipe(fill: "grayEE", edges: Edges(top: [step("ink")], leading: [], bottom: [step("ink")], trailing: []), radius: 0)
        let menuDim = SurfaceRecipe(layers: [], edges: nil, radius: .uniform(0), backdropBlur: nil, ink: ref("gray88"), scale: .integer)
        // The keyboard focus ring is chosen (the Mac OS draws none): two pixels of the accent outside the control.
        func focused(_ base: SurfaceRecipe) -> SurfaceRecipe {
            SurfaceRecipe(layers: base.layers + [.shadow(ShadowLayer(shadow: ShadowSpec(colour: ref("accent"), radius: 0, x: 0, y: 0), spread: 2))],
                          edges: base.edges, radius: base.radius, backdropBlur: nil, ink: base.ink, scale: .integer)
        }
        let buttonRest = recipe(fill: "background", edges: raised, radius: 3)
        let buttonDefaultRest = recipe(fill: "background", edges: ringed, radius: 5)
        let fieldRest = recipe(fill: "surface", edges: outline, radius: 0)
        return SurfaceSet(recipes: [
            .menuBar: [.rest: recipe(fill: "background", edges: menuBarEdges, radius: 0)],
            .menuItem: [.hover: recipe(fill: "highlight", ink: "surface", edges: nil, radius: 0), .disabled: menuDim],
            .scrollTrack: [.rest: recipe(fill: "shade", edges: trackEdges, radius: 0), .disabled: inactiveTrack],
            .scrollThumb: [.rest: thumb],
            .scrollGrip: [.rest: tileOnly(PatternSpec(literal: 8, 8, gripCells))],
            .scrollArrowStart: [.rest: tileOnly(PatternSpec(literal: 16, 16, arrowCells(baseColumn: 9, growsRight: false))),
                                .disabled: tileOnly(PatternSpec(literal: 16, 16, arrowCells(baseColumn: 9, growsRight: false, inactive: true)))],
            .scrollArrowEnd: [.rest: tileOnly(PatternSpec(literal: 16, 16, arrowCells(baseColumn: 6, growsRight: true))),
                              .disabled: tileOnly(PatternSpec(literal: 16, 16, arrowCells(baseColumn: 6, growsRight: true, inactive: true)))],
            .titleBar: [.rest: recipe(fill: "bar", edges: barEdges, radius: 0)],
            .titleStripes: [.rest: tile(PatternSpec(literal: 1, 2, [W, ref("gray96")]))],
            .windowBox: [.rest: tile(PatternSpec(literal: 13, 13, boxCells))],
            .windowBoxZoom: [.rest: tile(PatternSpec(literal: 13, 13, zoomCells))],
            .windowBoxMinimize: [.rest: tile(PatternSpec(literal: 13, 13, shadeCells))],
            .desktop: [.rest: recipe(fill: "desktop", edges: nil, radius: 0)],
            .window: [.rest: recipe(fill: "background", edges: outline, radius: 0)],
            .panel: [.rest: recipe(fill: "surface", edges: outline, radius: 0)],
            .button: [.rest: buttonRest, .active: recipe(fill: "gray87", ink: "surface", edges: pressed, radius: 3), .disabled: disabledButton, .focus: focused(buttonRest)],
            .buttonDefault: [.rest: buttonDefaultRest, .active: recipe(fill: "gray87", ink: "surface", edges: ringedPressed, radius: 5), .disabled: disabledButton,
                             .focus: focused(buttonDefaultRest)],
            .field: [.rest: fieldRest, .disabled: recipe(fill: "surface", ink: "gray88", edges: outline, radius: 0), .focus: focused(fieldRest)],
            .selection: [.rest: recipe(fill: "selection", edges: nil, radius: 0)],
        ])
    }

    /// What the validator finds in this palette, recorded exactly.
    static var platinumConformance: Conformance {
        Conformance(kind: .ledger, entries: [
            // the progress bar's lightest row (#CCCCFF) against the #E7E7E7 window body
            ledgerFail(.rampLightEnd, .light, "sequential", 1.24, 2.0),
        ])
    }
}
