import Foundation

public extension Theme {
    /// OPENSTEP 4.2 (the NeXT look), as a theme (unreleased): flat `#AAAAAA` grey, a one-pixel white highlight on the top and left of a
    /// control and a two-pixel `#555555`/`#000000` shadow on the bottom and right, square corners, a black title bar, a slate-blue desktop.
    /// Light only; the look has no dark appearance.
    ///
    /// **Source of record: pixels read from OPENSTEP 4.2 captures** (`project/docs/technical/SkinMeasurements.md`, OPENSTEP section).
    /// Measured: the button's bevel and its 27 x 72 px size (the Open panel's Cancel); the text field (white, sunken: `#555555` twice at
    /// the top and left, `#FFFFFF` then `#AAAAAA` at the bottom and right); the title bar (23 rows, black, framed `#000000 #AAAAAA` top and
    /// left and `#000000 #555555` right and bottom) with a 15 x 15 miniaturize button at the left and a 14 x 14 close button at the right,
    /// each pixel for pixel in its tile (the Font Panel); the `#555577` desktop; the white selection.
    ///
    /// **Not measured, chosen here:** the pressed state (the bevel inverted), the disabled and focus states, scroll bars' pressed state, a menu's disabled rows and its submenu arrows, and the type (Helvetica 12 is general knowledge for the NeXT system face, named with the
    /// system sans as the fallback). A default button has no ring in OPENSTEP (it carries a return arrow), so its recipe is the button's.
    static var openstep: Theme {
        Theme(id: "openstep", name: "OPENSTEP 4.2", structure: classicMacStructure(family: openstepFamily, controlHeight: 27, monospace: openstepMonospace),
              palette: openstepPalette, appearances: .lightOnly, conformance: openstepConformance, surfaces: openstepSurfaces,
              windowControls: WindowControls(leading: [.minimize], trailing: [.close], titleBar: openstepTitleBar),
              scrollBar: openstepScrollBar, menus: openstepMenus, dock: DockMetrics(tileSize: 64))
    }

    /// Measured from the Workspace and Tools menus of the OPENSTEP 4.2 desktop capture: a menu is 93 px wide; its title is 22 rows (a white row,
    /// 19 of black, `#555555`, black) and each row 20 (a white row, 17 of `#AAAAAA`, `#555555`, black), the button's raised bevel; the highlighted
    /// row is white all through. Text starts 6 px in. The arrow of a row that opens a submenu is a 7 x 7 triangle 6 px from the row's end and 6 down.
    /// A disabled button's text is `#555555` on the same bevel (the Revert button of the Application Inspector); a disabled menu row is assumed to
    /// match. The dock's tiles are 64 px with a two-row white highlight, a black line and a dark shade at the bottom and right, and a diagonal gradient
    /// (fitted: `#ACACB9` to `#555565` corner to corner); the shade row is one flat `#47474F`, the middle of the capture's `#56575E` to `#3B3C44`, which vary with the ground (a translucent black would need `color-mix()` and raise the theme files' browser floor).
    /// The labels above a tile (a black strip with white text) are not drawn.
    private static var openstepMenus: MenuMetrics {
        MenuMetrics(itemHeight: 20, titleHeight: 22, itemPadding: 6, menuWidth: 93, arrowInset: 6)
    }

    /// Measured from the vertical scroller of the OPENSTEP 4.2 file viewer: 20 px wide (a black line, 1 px of grey, a 16 px column, 1 px of grey, a
    /// black line), the two 16 x 16 arrow buttons together at the bottom with 1 px between them, and 2 px (line and grey) at each end.
    private static var openstepScrollBar: ScrollBarMetrics {
        ScrollBarMetrics(thickness: 20, arrowLength: 16, arrows: .together, inset: 2, gap: 1)
    }

    /// NeXT's fixed-pitch face is Ohlfs (the Terminal and Edit), with Courier as the PostScript standby: general knowledge, named first, not
    /// measured from a capture; 12 px is chosen. Ohlfs is rarely installed, so Courier is what most machines show.
    private static var openstepMonospace: TextSpec {
        TextSpec(family: .named("Ohlfs", fallback: .named("Courier", fallback: .mono)), size: 12, weight: 400, tracking: 0,
                 italic: false, uppercase: false, lineHeight: 1.2)
    }

    private static var openstepFamily: FontFamilyRef { .named("Helvetica", fallback: .sans) }

    /// The Font Panel's title bar: 23 rows; the frame is two rows (top: `#000000 #AAAAAA`) and two columns at either side, with the
    /// buttons 2 px inside the frame at the left (columns 4 to 18), 3 px at the right (columns 280 to 293 of 299), 2 px below the frame's
    /// top. The buttons take their tiles' sizes.
    private static var openstepTitleBar: TitleBarMetrics {
        TitleBarMetrics(height: 23, inset: Insets(top: 4, leading: 4, bottom: 2, trailing: 5), boxSize: 14, gap: 4, stripeHeight: 0)
    }

    private static var openstepPalette: ThemePalette {
        typealias B = ThemeBuilders
        let black: UInt32 = 0x000000
        return ThemePalette(
            ink: B.adaptive(black), secondaryInk: B.adaptive(0x555555), background: B.adaptive(0xAAAAAA), surface: B.adaptive(0xFFFFFF),
            rule: B.adaptive(black), accent: B.adaptive(0x555577), onAccent: B.adaptive(0xFFFFFF), link: B.adaptive(black),
            positive: B.adaptive(black), negative: B.adaptive(black), warning: B.adaptive(black), muted: B.adaptive(0x555555),
            series: [B.series("slate", 0x555577)],
            sequential: B.ramp([0xFFFFFF, 0xAAAAAA, 0x555555, black]),
            diverging: B.ramp([0x555577, 0xAAAAAA, 0x555555]),
            extras: ["desktop": B.adaptive(0x555577),
                     // the dock tile's slate ground, corner to corner, fitted to the empty tile of the 4.2 capture
                     "dockLight": B.adaptive(0xACACB9), "dockDark": B.adaptive(0x555565), "dockShade": B.adaptive(0x47474F)])
    }

    private static var openstepSurfaces: SurfaceSet {
        func ref(_ name: String) -> ColourReference { ColourReference(source: name) }
        func step(_ name: String, _ width: Double = 1) -> EdgeStep { EdgeStep(literal: ref(name), width) }
        // ink = #000000, background = #AAAAAA, surface = #FFFFFF, muted = #555555. Outside in.
        let light = [step("surface")]
        let shadow = [step("ink"), step("muted")]
        let raised = Edges(top: light, leading: light, bottom: shadow, trailing: shadow, stacking: .bottomTrailingFirst)
        // chosen, not measured: the bevel inverted
        let pressed = Edges(top: shadow, leading: shadow, bottom: light, trailing: light, stacking: .topLeadingFirst)
        let sunkenTop = [step("muted"), step("muted")]
        let sunkenBottom = [step("surface"), step("background")]
        let sunken = Edges(top: sunkenTop, leading: sunkenTop, bottom: sunkenBottom, trailing: sunkenBottom)
        let outline = Edges(top: [step("ink")], leading: [step("ink")], bottom: [step("ink")], trailing: [step("ink")])
        func recipe(fill: String, ink: String = "ink", edges: Edges?) -> SurfaceRecipe {
            SurfaceRecipe(layers: [.fill(ref(fill))], edges: edges, radius: .uniform(0), backdropBlur: nil, ink: ref(ink), scale: .integer)
        }
        // the two title-bar buttons, row by row from the Font Panel (W = #FFFFFF, bg = #AAAAAA, g55 = #555555, ink = #000000)
        let (W, bg, g55, ink) = (ref("surface"), ref("background"), ref("muted"), ref("ink"))
        let miniaturize: [ColourReference] = [
            W, W, W, W, W, W, W, W, W, W, W, W, W, W, g55,
            W, bg, bg, bg, bg, bg, bg, bg, bg, bg, bg, bg, bg, g55, ink,
            W, bg, ink, ink, ink, ink, ink, ink, ink, ink, ink, ink, bg, g55, ink,
            W, bg, ink, ink, ink, ink, ink, ink, ink, ink, ink, ink, bg, g55, ink,
            W, bg, ink, ink, ink, ink, ink, ink, ink, ink, ink, ink, bg, g55, ink,
            W, bg, ink, bg, bg, bg, bg, bg, bg, bg, bg, ink, bg, g55, ink,
            W, bg, ink, bg, bg, bg, bg, bg, bg, bg, bg, ink, bg, g55, ink,
            W, bg, ink, bg, bg, bg, bg, bg, bg, bg, bg, ink, bg, g55, ink,
            W, bg, ink, bg, bg, bg, bg, bg, bg, bg, bg, ink, bg, g55, ink,
            W, bg, ink, bg, bg, bg, bg, bg, bg, bg, bg, ink, bg, g55, ink,
            W, bg, ink, bg, bg, bg, bg, bg, bg, bg, bg, ink, bg, g55, ink,
            W, bg, ink, ink, ink, ink, ink, ink, ink, ink, ink, ink, bg, g55, ink,
            W, bg, bg, bg, bg, bg, bg, bg, bg, bg, bg, bg, bg, g55, ink,
            W, g55, g55, g55, g55, g55, g55, g55, g55, g55, g55, g55, g55, g55, ink,
            g55, ink, ink, ink, ink, ink, ink, ink, ink, ink, ink, ink, ink, ink, ink,
        ]
        let closeX: [ColourReference] = [
            W, W, W, W, W, W, W, W, W, W, W, W, W, W,
            W, bg, bg, bg, bg, bg, bg, bg, bg, bg, bg, bg, bg, g55,
            W, bg, ink, g55, bg, bg, bg, bg, bg, bg, g55, ink, bg, g55,
            W, bg, g55, ink, g55, bg, bg, bg, bg, g55, ink, g55, bg, g55,
            W, bg, bg, g55, ink, g55, bg, bg, g55, ink, g55, bg, bg, g55,
            W, bg, bg, bg, g55, ink, g55, g55, ink, g55, bg, bg, bg, g55,
            W, bg, bg, bg, bg, g55, ink, ink, g55, bg, bg, bg, bg, g55,
            W, bg, bg, bg, bg, g55, ink, ink, g55, bg, bg, bg, bg, g55,
            W, bg, bg, bg, g55, ink, g55, g55, ink, g55, bg, bg, bg, g55,
            W, bg, bg, g55, ink, g55, bg, bg, g55, ink, g55, bg, bg, g55,
            W, bg, g55, ink, g55, bg, bg, bg, bg, g55, ink, g55, bg, g55,
            W, bg, ink, g55, bg, bg, bg, bg, bg, bg, g55, ink, bg, g55,
            W, bg, bg, bg, bg, bg, bg, bg, bg, bg, bg, bg, bg, g55,
            W, g55, g55, g55, g55, g55, g55, g55, g55, g55, g55, g55, g55, g55,
        ]
        func tile(_ width: Int, _ height: Int, _ cells: [ColourReference]) -> SurfaceRecipe {
            SurfaceRecipe(layers: [.fill(ink), .pattern(PatternSpec(literal: width, height, cells))], edges: nil, radius: .uniform(0),
                          backdropBlur: nil, ink: ink, scale: .integer)
        }
        let barEdges = Edges(top: [step("ink"), step("background")], leading: [step("ink"), step("background")],
                             bottom: [step("ink"), step("muted")], trailing: [step("ink"), step("muted")])
        // Scroll bar (measured, see openstepScrollBar): the track is a one-pixel checkerboard of #AAAAAA and #555555 in the 16 px column (#555555 first on the track's first row), the thumb
        // the button's raised bevel, and each arrow a 16 x 16 button with a triangle of black (its edge pixels #555555). Authored for a horizontal bar,
        // so the measured vertical tiles are turned about the diagonal. The knob on the thumb's middle (8 x 6) is drawn whole.
        let upGlyph = [
            ".......m........", ".......K........", "......mKm.......", "......KKK.......", ".....mKKKm......",
            ".....KKKKK......", "....mKKKKKm.....", "....KKKKKKK.....", "...mKKKKKKKm....",
        ]
        func arrow(glyph: [String]) -> PatternSpec {
            var cells: [ColourReference] = []
            for row in 0..<16 {
                for col in 0..<16 {
                    let g = (3..<12).contains(row) ? Array(glyph[row - 3])[col] : "."
                    if g == "K" { cells.append(ink); continue }
                    if g == "m" { cells.append(g55); continue }
                    if row == 15 || col == 15 { cells.append(ink) }
                    else if row == 14 { cells.append(col == 0 ? W : g55) }
                    else if row == 0 || col == 0 { cells.append(W) }
                    else if col == 14 { cells.append(g55) }
                    else { cells.append(bg) }
                }
            }
            return PatternSpec(literal: 16, 16, cells)
        }
        let down = arrow(glyph: Array(upGlyph.reversed()))
        let up = arrow(glyph: upGlyph)
        func wholeTile(_ spec: PatternSpec) -> SurfaceRecipe {
            SurfaceRecipe(layers: [.pattern(spec)], edges: nil, radius: .uniform(0), backdropBlur: nil, ink: ink, scale: .integer)
        }
        let knobKey: [Character: ColourReference] = ["m": g55, "K": ink, "W": W, ".": bg]
        let knobRows = [".mKKK...", "mKmmmm..", "Kmm.....", "Km..WW..", "Km.WWW..", ".m.WW..."]
        let knob = PatternSpec(literal: 8, 6, knobRows.flatMap { $0.map { knobKey[$0] ?? bg } })
        let dither = SurfaceRecipe(layers: [.fill(bg), .pattern(PatternSpec(literal: 2, 2, [g55, bg, bg, g55]))], edges: nil,
                                   radius: .uniform(0), backdropBlur: nil, ink: ink, scale: .integer)
        let arrowKey: [Character: ColourReference] = ["K": ink, "m": g55]
        func submenuArrow(ground: ColourReference, lit: ColourReference) -> SurfaceRecipe {
            let rows = ["Km.....", "K.mm...", "K...mm.", "K.....W", "K...WW.", "K.WW...", "KW....."]
            let cells = rows.flatMap { $0.map { c in arrowKey[c] ?? (c == "W" ? lit : ground) } }
            return wholeTile(PatternSpec(literal: 7, 7, cells))
        }
        let shade = step("dockShade")
        let dockEdges = Edges(top: [step("surface"), step("surface")], leading: [step("surface"), step("surface")], bottom: [step("ink"), shade],
                              trailing: [step("ink"), shade], stacking: .bottomTrailingFirst)
        let dockGround = GradientSpec(literalAngle: 135, [GradientStop(colour: ref("dockLight"), position: 0), GradientStop(colour: ref("dockDark"), position: 1)])
        let disabled = SurfaceRecipe(layers: [.fill(bg)], edges: raised, radius: .uniform(0), backdropBlur: nil, ink: g55, scale: .integer)
        return SurfaceSet(recipes: [
            .menuArrow: [.rest: submenuArrow(ground: bg, lit: W), .hover: submenuArrow(ground: W, lit: bg)],
            .dockTile: [.rest: SurfaceRecipe(layers: [.gradient(dockGround)], edges: dockEdges, radius: .uniform(0), backdropBlur: nil, ink: ink, scale: .integer)],
            .scrollBar: [.rest: recipe(fill: "background", edges: outline)],
            .scrollTrack: [.rest: dither],
            .scrollGrip: [.rest: wholeTile(knob.transposed)],
            .scrollThumb: [.rest: recipe(fill: "background", edges: raised)],
            .scrollArrowStart: [.rest: wholeTile(up.transposed)],
            .scrollArrowEnd: [.rest: wholeTile(down.transposed)],
            .menu: [.rest: recipe(fill: "desktop", edges: nil)],
            .menuTitle: [.rest: recipe(fill: "ink", ink: "surface", edges: raised)],
            .menuItem: [.rest: recipe(fill: "background", edges: raised), .hover: recipe(fill: "surface", edges: raised), .disabled: disabled],
            .desktop: [.rest: recipe(fill: "desktop", edges: nil)],
            .window: [.rest: recipe(fill: "background", edges: outline)],
            .panel: [.rest: recipe(fill: "surface", edges: outline)],
            .button: [.rest: recipe(fill: "background", edges: raised), .active: recipe(fill: "background", edges: pressed), .disabled: disabled],
            .buttonDefault: [.rest: recipe(fill: "background", edges: raised), .active: recipe(fill: "background", edges: pressed), .disabled: disabled],
            .field: [.rest: recipe(fill: "surface", edges: sunken)],
            .selection: [.rest: recipe(fill: "surface", edges: nil)],
            .titleBar: [.rest: recipe(fill: "ink", ink: "surface", edges: barEdges)],
            .windowBox: [.rest: tile(14, 14, closeX)],
            .windowBoxMinimize: [.rest: tile(15, 15, miniaturize)],
        ])
    }

    /// What the validator finds in this palette, recorded exactly. The one series, the desktop's slate blue, has almost no chroma
    /// (0.055 against the 0.1 floor), and the secondary ink is the look's `#555555` on its `#AAAAAA` grey (3.21:1, under 4.5:1); that
    /// pairing is how OPENSTEP draws disabled text and a field's inactive label, so it is recorded, not changed. Links are black.
    static var openstepConformance: Conformance {
        Conformance(kind: .ledger, entries: [
            ledgerFail(.chromaFloor, .light, "slate", 0.055, 0.1),
            ledgerFail(.textContrast, .light, "secondaryInk on background", 3.21, 4.5),
        ])
    }
}
