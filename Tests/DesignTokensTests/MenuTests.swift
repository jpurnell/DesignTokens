import Foundation
import Testing
@testable import DesignTokens

/// Menus of System 7, Platinum and OPENSTEP: the menu bar of the first two (Mac OS 8.0 and System 7.0 captures) and OPENSTEP 4.2's vertical
/// menu, whose title and rows are the button's raised bevel drawn at 22 and 20 px.
@Suite("Menus")
struct MenuTests {
    private func lastRule(_ css: String, _ selector: String) throws -> String {
        let start = try #require(css.range(of: selector + " {", options: .backwards), Comment(rawValue: selector))
        return String(css[start.upperBound...].prefix(while: { $0 != "}" }))
    }

    private func lines(_ rule: String) -> [String] {
        rule.split(whereSeparator: \.isNewline).map { $0.trimmingCharacters(in: .whitespaces) }
    }

    @Test("OPENSTEP's menu rows are 20 px raised buttons, the title 22 px black, the highlighted row white")
    func openstepMenu() throws {
        let css = try ThemeCSSEmitter.emit(.openstep)
        let raised = "box-shadow: inset 0 -1px 0 0 var(--ink), inset -1px 0 0 0 var(--ink), inset 0 1px 0 0 var(--surface), inset 1px 0 0 0 var(--surface), inset 0 -2px 0 0 var(--muted), inset -2px 0 0 0 var(--muted);"
        let item = lines(try lastRule(css, "[data-theme-name=\"openstep\"] .dt-menu__item"))
        #expect(item.contains("background-color: var(--background);"))
        #expect(item.contains(raised))
        let title = lines(try lastRule(css, "[data-theme-name=\"openstep\"] .dt-menu__title"))
        #expect(title.contains("background-color: var(--ink);") && title.contains("color: var(--surface);"))
        let lit = lines(try lastRule(css, "[data-theme-name=\"openstep\"] .dt-menu__item[aria-selected=\"true\"]"))
        #expect(lit.contains("background-color: var(--surface);"))
    }

    @Test("OPENSTEP's menu is laid out as a 93 px column of a 22 px title and 20 px rows")
    func openstepLayout() throws {
        let css = try ThemeCSSEmitter.emit(.openstep)
        let column = lines(try lastRule(css, "[data-theme-name=\"openstep\"] .dt-menu"))
        #expect(column.contains("display: flex;") && column.contains("flex-direction: column;") && column.contains("inline-size: 93px;"))
        let title = lines(try lastRule(css, "[data-theme-name=\"openstep\"] .dt-menu__title"))
        #expect(title.contains("block-size: 22px;"))
        let item = lines(try lastRule(css, "[data-theme-name=\"openstep\"] .dt-menu__item"))
        #expect(item.contains("block-size: 20px;") && item.contains("padding: 0 6px;"))
    }

    @Test("Platinum's menu bar is 20 px: white on top and leading, #999999 then black under it, #999999 at the trailing edge")
    func platinumBar() throws {
        let css = try ThemeCSSEmitter.emit(.platinum)
        let bar = lines(try lastRule(css, "[data-theme-name=\"platinum\"] .dt-menubar"))
        #expect(bar.contains("background-color: var(--background);"))
        #expect(bar.contains("box-shadow: inset 0 -1px 0 0 var(--ink), inset -1px 0 0 0 var(--extra-gray99), inset 0 1px 0 0 var(--surface), inset 1px 0 0 0 var(--surface), inset 0 -2px 0 0 var(--extra-gray99);"))
        let layout = lines(try lastRule(css, "[data-theme-name=\"platinum\"] .dt-menubar"))
        #expect(layout.contains("block-size: 20px;"))
        let lit = lines(try lastRule(css, "[data-theme-name=\"platinum\"] .dt-menubar__item[aria-selected=\"true\"]"))
        #expect(lit.contains("background-color: var(--ink);") && lit.contains("color: var(--surface);"))
    }

    @Test("System 7's menu bar is white with a one-pixel black line under it, and a highlighted title is inverted")
    func system7Bar() throws {
        let css = try ThemeCSSEmitter.emit(.system7)
        let bar = lines(try lastRule(css, "[data-theme-name=\"system7\"] .dt-menubar"))
        #expect(bar.contains("block-size: 20px;"))
        #expect(bar.contains("background-color: var(--background);"))
        #expect(bar.contains("box-shadow: inset 0 -1px 0 0 var(--ink);"))
        let lit = lines(try lastRule(css, "[data-theme-name=\"system7\"] .dt-menubar__item[aria-selected=\"true\"]"))
        #expect(lit.contains("background-color: var(--ink);") && lit.contains("color: var(--background);"))
    }

    @Test("a theme without menus writes none, and the metrics survive the JSON round trip")
    func absentAndRoundTrip() throws {
        #expect(Theme.swiss.menus == nil)
        let swiss = try ThemeCSSEmitter.emit(.swiss)
        #expect(!swiss.contains("dt-menu"))
        let heights: [(Theme, Double?, Double)] = [(.system7, 20, 20), (.platinum, 20, 20), (.openstep, nil, 20)]
        for (theme, bar, row) in heights {
            #expect(theme.menus?.barHeight == bar && theme.menus?.itemHeight == row, "\(theme.id)")
            let decoded = try ThemeCodec.decode(try ThemeCodec.encode(theme))
            #expect(decoded.menus == theme.menus, "\(theme.id)")
            #expect(decoded.surfaces?.recipes[.menuItem] == theme.surfaces?.recipes[.menuItem], "\(theme.id)")
        }
    }

    @Test("GTK leaves the menu roles to GTK's own menus")
    func gtk() throws {
        let slot = try #require(ThemeSlot.slots(for: .openstep).first)
        let css = try GTKEmitter.emit(.openstep, slot: slot)
        #expect(!css.contains("dt-menu"))
    }

    // MARK: OPENSTEP's submenu arrow, disabled rows and dock tile

    private func cells(_ theme: Theme, _ role: SurfaceRole, _ state: ComponentState) throws -> PatternSpec {
        let recipe = try #require(theme.surfaces?.recipes[role]?[state], Comment(rawValue: "\(role) \(state)"))
        guard case .pattern(let spec)? = recipe.layers.last else { throw SurfaceError.cellSize(0) }
        return spec
    }

    @Test("the submenu arrow is a 7 x 7 triangle: black down the left, #555555 above, white below; on the lit row white and grey swap")
    func submenuArrow() throws {
        let (K, m, bg, W) = (ColourReference(source: "ink"), ColourReference(source: "muted"), ColourReference(source: "background"),
                             ColourReference(source: "surface"))
        let key: [Character: ColourReference] = ["K": K, "m": m, ".": bg, "W": W]
        let rows = ["Km.....", "K.mm...", "K...mm.", "K.....W", "K...WW.", "K.WW...", "KW....."]
        let expected = rows.flatMap { $0.map { key[$0] ?? bg } }
        let rest = try cells(.openstep, .menuArrow, .rest)
        #expect(rest.width == 7 && rest.height == 7)
        #expect(rest.cells == expected)
        // on a white row the interior is white and the lower edge takes the grey the row has elsewhere
        let swap: [Character: ColourReference] = ["K": K, "m": m, ".": W, "W": bg]
        #expect(try cells(.openstep, .menuArrow, .hover).cells == rows.flatMap { $0.map { swap[$0] ?? W } })
    }

    @Test("the arrow sits at the end of its row, 6 px from the edge and 6 px down, and takes the lit tile on the lit row")
    func arrowCSS() throws {
        let css = try ThemeCSSEmitter.emit(.openstep)
        let arrow = lines(try lastRule(css, "[data-theme-name=\"openstep\"] .dt-menu__arrow"))
        #expect(arrow.contains("inline-size: 7px;") && arrow.contains("block-size: 7px;"))
        #expect(arrow.contains("margin-inline-start: auto;") && arrow.contains("margin-block-start: 6px;") && arrow.contains("align-self: flex-start;"))
        let lit = try lastRule(css, "[data-theme-name=\"openstep\"] .dt-menu__item[aria-selected=\"true\"] .dt-menu__arrow")
        #expect(lit.contains("background-image"))
    }

    @Test("a disabled row or button has #555555 text on the same raised bevel")
    func disabled() throws {
        let css = try ThemeCSSEmitter.emit(.openstep)
        let row = lines(try lastRule(css, "[data-theme-name=\"openstep\"] .dt-menu__item[aria-disabled=\"true\"]"))
        #expect(row.contains("color: var(--muted);") && row.contains("background-color: var(--background);"))
        let button = lines(try lastRule(css, "[data-theme-name=\"openstep\"] .dt-button:disabled"))
        #expect(button.contains("color: var(--muted);") && button.contains("background-color: var(--background);"))
    }

    @Test("a dock tile is 64 px: two white rows on top and leading, a black line and a flat dark shade under and after, a slate diagonal gradient")
    func dockTile() throws {
        let theme = Theme.openstep
        #expect(theme.dock?.tileSize == 64)
        let recipe = try #require(theme.surfaces?.recipes[.dockTile]?[.rest])
        guard case .gradient(let gradient)? = recipe.layers.first else { throw SurfaceError.cellSize(0) }
        #expect(gradient.angleDegrees == 135 && gradient.stops.map(\.colour.source) == ["dockLight", "dockDark"])
        #expect(recipe.edges?.top.map(\.colour.source) == ["surface", "surface"])
        #expect(recipe.edges?.leading.map(\.colour.source) == ["surface", "surface"])
        #expect(recipe.edges?.bottom.map(\.colour.source) == ["ink", "dockShade"])
        let css = try ThemeCSSEmitter.emit(theme)
        let tile = lines(try lastRule(css, "[data-theme-name=\"openstep\"] .dt-dock__tile"))
        #expect(tile.contains("inline-size: 64px;") && tile.contains("block-size: 64px;"))
        #expect(tile.contains { $0.hasPrefix("background-image: linear-gradient(135deg") })
        #expect(Theme.swiss.dock == nil)
    }
}
