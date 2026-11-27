#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// The scenes the skins gallery shows under a theme: one shared components scene, and for a skin a scene of its window, menus,
/// scroll bars and dock, built from what the theme defines.
///
/// A skin scene is generated from the model, not written by hand: a part appears only when the theme has it (a title bar when it places
/// window controls and has a title-bar recipe, scroll bars when it has ``ScrollBarMetrics``, menus when it has ``MenuMetrics``, a dock
/// when it has ``DockMetrics``). A theme that lacks a part simply does not show it, so a gap is visible rather than papered over. The
/// markup uses only classes the theme's stylesheet writes, which a test checks per theme.
enum GalleryScenes {
    /// The components scene: one of each shared component, built only from classes `components.css` documents.
/// The components scene: one of each shared component, built only from classes `components.css` documents.
static let sharedScene = """
    <div class="dt-page">
      <header class="dt-header">
        <div class="dt-header__title"><h2 class="dt-title">Components</h2></div>
        <div class="dt-header__aside"><span class="dt-caption">the same markup in every theme</span></div>
      </header>
      <section class="dt-section">
        <h3 class="dt-section__heading">Buttons and form</h3>
        <div class="dt-actions">
          <button type="button" class="dt-button dt-button--primary">Primary</button>
          <button type="button" class="dt-button">Default</button>
          <button type="button" class="dt-button dt-button--destructive">Destructive</button>
          <button type="button" class="dt-button" disabled>Disabled</button>
        </div>
        <div class="dt-form">
          <div class="dt-field">
            <label class="dt-field__label" for="g-name">Name</label>
            <input class="dt-input" id="g-name" type="text" value="Ada Lovelace">
          </div>
          <div class="dt-field">
            <label class="dt-field__label" for="g-kind">Kind</label>
            <select class="dt-select" id="g-kind"><option>Window</option><option>Menu</option></select>
          </div>
          <div class="dt-field">
            <label class="dt-field__label" for="g-note">Note</label>
            <textarea class="dt-textarea" id="g-note" rows="2">Text that wraps.</textarea>
          </div>
          <label class="dt-checkline"><input class="dt-check" type="checkbox" checked> Keep me signed in</label>
          <div class="dt-segmented" role="radiogroup" aria-label="View">
            <button type="button" class="dt-segmented__option" role="radio" aria-checked="true">List</button>
            <button type="button" class="dt-segmented__option" role="radio" aria-checked="false">Grid</button>
          </div>
        </div>
      </section>
      <section class="dt-section">
        <h3 class="dt-section__heading">Status</h3>
        <p>
          <span class="dt-chip dt-chip--success">Success</span>
          <span class="dt-chip dt-chip--caution">Caution</span>
          <span class="dt-chip dt-chip--warning">Warning</span>
          <span class="dt-chip dt-chip--destructive">Destructive</span>
          <span class="dt-chip dt-chip--neutral">Neutral</span>
        </p>
        <div class="dt-banner dt-banner--caution"><div class="dt-banner__head">A banner holds text and a <a class="dt-link" href="#">link</a>.</div></div>
        <div class="dt-meter dt-meter--success">
          <div class="dt-meter__track" role="meter" aria-valuenow="72" aria-valuemin="0" aria-valuemax="100" aria-label="Capacity">
            <div class="dt-meter__fill" style="inline-size: 72%"></div>
          </div>
          <span class="dt-meter__figure">72%</span>
        </div>
      </section>
      <section class="dt-section">
        <h3 class="dt-section__heading">Table and cards</h3>
        <table class="dt-table">
          <thead><tr><th>Item</th><th class="dt-num">Count</th></tr></thead>
          <tbody>
            <tr><td data-label="Item">Windows</td><td class="dt-num" data-label="Count">12</td></tr>
            <tr><td data-label="Item">Menus</td><td class="dt-num" data-label="Count">4</td></tr>
          </tbody>
        </table>
        <div class="dt-cards">
          <article class="dt-card">
            <div class="dt-card__header"><span class="dt-card__name">First card</span></div>
            <div class="dt-stats"><div class="dt-stat"><span class="dt-stat__label">Open</span><span class="dt-stat__figure">12</span></div></div>
            <div class="dt-card__footer">Footer</div>
          </article>
          <article class="dt-card">
            <div class="dt-card__header"><span class="dt-card__name">Second card</span></div>
            <div class="dt-stats"><div class="dt-stat"><span class="dt-stat__label">Closed</span><span class="dt-stat__figure">4</span></div></div>
            <div class="dt-card__footer">Footer</div>
          </article>
        </div>
      </section>
    </div>
    """

    /// A skin's scene, or `nil` for a theme without surfaces (it gets only the shared scene).
    ///
    /// A major part (window, menus, dock) is shown when the theme defines it; a sub-part (one window control, the separator, a scroll
    /// bar grip, a dock label) is shown only when the theme's own stylesheet styles its class, so a skin is never shown a part it does
    /// not draw.
    ///
    /// - Throws: ``ThemeEmitError`` when the theme's stylesheet cannot be emitted.
    static func skinScene(for theme: Theme) throws -> String? {
        guard theme.surfaces != nil else { return nil }
        let css = try ThemeCSSEmitter.emit(theme)
        let styled = Styled(css: css)
        var parts: [String] = []
        if let controls = theme.windowControls, controls.titleBar != nil, theme.surfaces?.recipes[.titleBar] != nil {
            parts.append(windows(theme, controls: controls, styled: styled))
        }
        if theme.menus != nil, styled.has("dt-menubar") || styled.hasBlock("dt-menu") { parts.append(menus(styled)) }
        if theme.dock != nil, styled.has("dt-dock__tile") { parts.append(dock(styled)) }
        if parts.isEmpty { parts.append("<p class=\"skin-scene__caption\">This theme defines no window, menu or dock parts to show.</p>") }
        return parts.joined(separator: "\n")
    }

    /// What a theme's stylesheet styles.
    private struct Styled {
        let css: String
        func has(_ name: String) -> Bool { css.contains(".\(name)") }
        /// The block itself (`.dt-menu {`), not just a part inside it (`.dt-menu__item`).
        func hasBlock(_ name: String) -> Bool { css.contains(".\(name) {") || css.contains(".\(name),") }
    }

    private static func titleBar(controls: WindowControls, title: String, active: Bool, styled: Styled) -> String {
        let boxes = (controls.leading + controls.trailing).filter { styled.has("dt-titlebar__box--\($0.rawValue)") }.map {
            "<button type=\"button\" class=\"dt-titlebar__box dt-titlebar__box--\($0.rawValue)\" aria-label=\"\($0.rawValue)\"></button>"
        }.joined()
        let disabled = active ? "" : " aria-disabled=\"true\""
        return "<div class=\"dt-titlebar\"\(disabled)>\(boxes)<span class=\"dt-titlebar__stripes\"></span><span class=\"dt-titlebar__title\">\(title)</span><span class=\"dt-titlebar__stripes\"></span></div>"
    }

    private static func scrollBars(_ theme: Theme, active: Bool, styled: Styled) -> (vertical: String, horizontal: String) {
        guard theme.scrollBar != nil, styled.has("dt-scrollbar") else { return ("", "") }
        let disabled = active ? "" : " aria-disabled=\"true\""
        func arrow(_ end: String, _ label: String) -> String {
            styled.has("dt-scrollbar__arrow--\(end)")
                ? "<button type=\"button\" class=\"dt-scrollbar__arrow dt-scrollbar__arrow--\(end)\" aria-label=\"\(label)\"></button>" : ""
        }
        let grip = styled.has("dt-scrollbar__grip") ? "<span class=\"dt-scrollbar__grip\"></span>" : ""
        func bar(_ orientation: String, thumb: String) -> String {
            "<div class=\"dt-scrollbar\" data-orientation=\"\(orientation)\"\(disabled)>\(arrow("start", "Scroll back"))<div class=\"dt-scrollbar__track\"><div class=\"dt-scrollbar__thumb\" style=\"\(thumb)\">\(grip)</div></div>\(arrow("end", "Scroll forward"))</div>"
        }
        return (bar("vertical", thumb: "block-size: 40%; margin-block-start: 10%"), bar("horizontal", thumb: "inline-size: 45%; margin-inline-start: 15%"))
    }

    private static func window(_ theme: Theme, controls: WindowControls, title: String, active: Bool, styled: Styled) -> String {
        let bars = scrollBars(theme, active: active, styled: styled)
        let corner = bars.vertical.isEmpty ? "" : "<span class=\"skin-window__corner\"></span>"
        return """
            <div class="skin-window dt-page">
              \(titleBar(controls: controls, title: title, active: active, styled: styled))
              <div class="skin-window__body">
                <div class="skin-window__content"><p class="dt-body">Text in a window. The title bar is \(active ? "active" : "inactive").</p></div>\(bars.vertical)
                \(bars.horizontal)\(corner)
              </div>
            </div>
            """
    }

    private static func windows(_ theme: Theme, controls: WindowControls, styled: Styled) -> String {
        """
        <div class="skin-scene__row">
          <div><p class="skin-scene__caption">Window, active</p>
        \(window(theme, controls: controls, title: "Active", active: true, styled: styled))</div>
          <div><p class="skin-scene__caption">Window, inactive</p>
        \(window(theme, controls: controls, title: "Inactive", active: false, styled: styled))</div>
        </div>
        """
    }

    private static func menus(_ styled: Styled) -> String {
        let bar = styled.has("dt-menubar")
            ? "<div class=\"dt-menubar\" role=\"menubar\"><span class=\"dt-menubar__item\">File</span><span class=\"dt-menubar__item\" aria-selected=\"true\">Edit</span><span class=\"dt-menubar__item\" aria-disabled=\"true\">View</span></div>" : ""
        let separator = styled.has("dt-menu__separator") ? "\n      <div class=\"dt-menu__separator\"></div>" : ""
        let menu = styled.hasBlock("dt-menu") ? """
            <div class="dt-menu" role="menu">
              <div class="dt-menu__item">Undo</div>
              <div class="dt-menu__item" aria-selected="true">Cut</div>
              <div class="dt-menu__item" aria-disabled="true">Copy</div>\(separator)
              <div class="dt-menu__item">Select All</div>
            </div>
            """ : ""
        return """
        <div><p class="skin-scene__caption">Menus</p>
          <div class="skin-menus">
            \(bar)
            \(menu)
          </div>
        </div>
        """
    }

    private static func dock(_ styled: Styled) -> String {
        func tile(_ name: String) -> String {
            let label = styled.has("dt-dock__label") ? "<span class=\"dt-dock__label\">\(name)</span>" : ""
            return "<button type=\"button\" class=\"dt-dock__tile\">\(label)</button>"
        }
        return """
        <div><p class="skin-scene__caption">Dock</p>
          <div class="skin-dock">\(tile("Files"))\(tile("Mail"))\(tile("Notes"))</div>
        </div>
        """
    }
}
