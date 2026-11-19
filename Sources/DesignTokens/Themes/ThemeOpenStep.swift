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
    /// **Not measured, chosen here:** the pressed state (the bevel inverted), the disabled and focus states, scroll bars, menus (the
    /// menu's own drawing is in the captures), and the type (Helvetica 12 is general knowledge for the NeXT system face, named with the
    /// system sans as the fallback). A default button has no ring in OPENSTEP (it carries a return arrow), so its recipe is the button's.
    static var openstep: Theme {
        Theme(id: "openstep", name: "OPENSTEP 4.2", structure: classicMacStructure(family: openstepFamily, controlHeight: 27),
              palette: openstepPalette, appearances: .lightOnly, conformance: openstepConformance, surfaces: openstepSurfaces,
              windowControls: WindowControls(leading: [.minimize], trailing: [.close], titleBar: openstepTitleBar))
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
            extras: ["desktop": B.adaptive(0x555577)])
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
        return SurfaceSet(recipes: [
            .desktop: [.rest: recipe(fill: "desktop", edges: nil)],
            .window: [.rest: recipe(fill: "background", edges: outline)],
            .panel: [.rest: recipe(fill: "surface", edges: outline)],
            .button: [.rest: recipe(fill: "background", edges: raised), .active: recipe(fill: "background", edges: pressed)],
            .buttonDefault: [.rest: recipe(fill: "background", edges: raised), .active: recipe(fill: "background", edges: pressed)],
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
