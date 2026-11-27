import Testing
#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif
@testable import DesignTokens

@Suite("Skins gallery: the page, its script and its own stylesheet")
struct GalleryEmitterTests {
    private static let page = "gallery/index.html"

    private func file(_ path: String, in files: [GeneratedFile]) throws -> String {
        try #require(files.first { $0.path == path }, "\(path) was not emitted").contents
    }

    /// Every value of `attribute="..."` in `html`, in order.
    private func values(of attribute: String, in html: String) -> [String] {
        var found: [String] = []
        var rest = Substring(html)
        let opening = " \(attribute)=\""
        while let start = rest.firstRange(of: opening, in: rest.startIndex..<rest.endIndex) {
            let tail = rest[start.upperBound...]
            guard let end = tail.firstIndex(of: "\"") else { break }
            found.append(String(tail[..<end]))
            rest = tail[end...]
        }
        return found
    }

    // MARK: The file set

    @Test("the gallery is exactly three files: the page, its stylesheet and its script")
    func fileSet() throws {
        let files = try GalleryEmitter.emit()
        #expect(files.map(\.path) == ["gallery/index.html", "gallery/gallery.css", "gallery/gallery.js"])
    }

    @Test("--format gallery keeps only the gallery files, and the default set includes them")
    func generatorIntegration() throws {
        let only = try Generator.files(formats: [.gallery]).map(\.path)
        #expect(only == ["gallery/index.html", "gallery/gallery.css", "gallery/gallery.js"])
        let everything = try Generator.files().map(\.path)
        #expect(Set(only).isSubset(of: Set(everything)))
        #expect(GeneratedFormat(rawValue: "gallery") == .gallery)
        let single = try Generator.files(for: [Theme.swiss], includeDefaults: false).map(\.path)
        #expect(!single.contains { $0.hasPrefix("gallery/") }, "one theme's files do not carry the whole-set viewer")
    }

    @Test("two emits are byte-identical: nothing in the page depends on the date or on chance")
    func deterministic() throws {
        #expect(try GalleryEmitter.emit() == GalleryEmitter.emit())
    }

    // MARK: Links

    @Test("every relative href and src in the page names a file the generator writes")
    func linksResolve() throws {
        let written = Set(try Generator.files().map(\.path))
        let html = try file(Self.page, in: try GalleryEmitter.emit())
        let targets = values(of: "href", in: html) + values(of: "src", in: html)
        #expect(!targets.isEmpty)
        for target in targets where !target.hasPrefix("#") {
            #expect(!target.hasPrefix("http") && !target.hasPrefix("/"), "\(target) must be relative so the page works from file:// and any path")
            let resolved = target.hasPrefix("../") ? String(target.dropFirst(3)) : "gallery/" + target
            #expect(written.contains(resolved), "\(target) is not a generated file (looked for \(resolved))")
        }
    }

    @Test("every theme's stylesheet and components.css are linked, once each")
    func linksEveryTheme() throws {
        let html = try file(Self.page, in: try GalleryEmitter.emit())
        let hrefs = values(of: "href", in: html)
        for theme in Theme.all {
            #expect(hrefs.filter { $0 == "../themes/\(theme.id).css" }.count == 1, "\(theme.id)")
        }
        #expect(hrefs.filter { $0 == "../components.css" }.count == 1)
        #expect(hrefs.filter { $0 == "gallery.css" }.count == 1)
        #expect(values(of: "src", in: html) == ["gallery.js"])
    }

    // MARK: The switcher

    @Test("the switcher has one entry per theme: the skins first, then the rest in registry order")
    func switcherOrder() throws {
        let html = try file(Self.page, in: try GalleryEmitter.emit())
        let listed = values(of: "data-theme", in: html)
        let skins = Theme.all.filter { $0.surfaces != nil }.map(\.id)
        let others = Theme.all.filter { $0.surfaces == nil }.map(\.id)
        #expect(!skins.isEmpty)
        #expect(listed == skins + others)
    }

    @Test("the stage starts on the first theme in the switcher, and is the only element carrying data-theme-name")
    func stage() throws {
        let html = try file(Self.page, in: try GalleryEmitter.emit())
        let scoped = values(of: "data-theme-name", in: html)
        let first = try #require((Theme.all.filter { $0.surfaces != nil } + Theme.all.filter { $0.surfaces == nil }).first)
        #expect(scoped == [first.id])
    }

    @Test("a theme name is escaped where the page writes it")
    func nameEscaped() throws {
        var hostile = Theme.swiss
        hostile.name = "<script>alert(1)</script> & \"q\""
        let html = try file(Self.page, in: try GalleryEmitter.emit(themes: [hostile]))
        #expect(!html.contains("<script>alert"), "the name must not become markup")
        #expect(html.contains("&lt;script&gt;alert(1)&lt;/script&gt; &amp; &quot;q&quot;"))
    }

    @Test("a theme whose id is not a slug is refused, as every other emitter refuses it")
    func badIDRefused() {
        var bad = Theme.swiss
        bad.id = "Not A Slug"
        #expect(throws: ThemeEmitError.self) { _ = try GalleryEmitter.emit(themes: [bad]) }
    }

    // MARK: The scene

    @Test("every dt- class the shared scene uses is one components.css writes")
    func sceneClassesExist() throws {
        let html = try file(Self.page, in: try GalleryEmitter.emit())
        let components = ComponentsCSSEmitter.emit()
        let used = classes(in: GalleryScenes.sharedScene)
        #expect(used.count >= 10, "the components scene should exercise the components; found \(used.count)")
        for name in used.sorted() {
            #expect(components.contains(".\(name)"), "\(name) is not written by components.css")
        }
        #expect(html.contains(GalleryScenes.sharedScene), "the page carries the shared scene as given")
    }

    // MARK: Skin scenes

    private func classes(in markup: String) -> Set<String> {
        var used = Set<String>()
        for value in values(of: "class", in: markup) {
            for token in value.split(whereSeparator: { $0 == " " }) where token.hasPrefix("dt-") { used.insert(String(token)) }
        }
        return used
    }

    @Test("a skin scene exists for each theme with surfaces and for no other, once each")
    func skinScenePerSkin() throws {
        let html = try file(Self.page, in: try GalleryEmitter.emit())
        let scenes = values(of: "data-skin-scene", in: html)
        let skins = Theme.all.filter { $0.surfaces != nil }.map(\.id)
        #expect(!skins.isEmpty)
        #expect(scenes == skins)
        for theme in Theme.all where theme.surfaces == nil {
            #expect(try GalleryScenes.skinScene(for: theme) == nil, "\(theme.id) has no surfaces, so no skin scene")
        }
    }

    @Test("every dt- class in a skin's scene is written by that skin's stylesheet or components.css, so a class the emitter stops writing fails here")
    func skinSceneClassesWritten() throws {
        for theme in Theme.all where theme.surfaces != nil {
            let scene = try #require(try GalleryScenes.skinScene(for: theme), "\(theme.id)")
            let css = try ThemeCSSEmitter.emit(theme) + ComponentsCSSEmitter.emit()
            let used = classes(in: scene)
            #expect(!used.isEmpty, "\(theme.id)")
            for name in used.sorted() {
                #expect(css.contains(".\(name)"), "\(theme.id): \(name) is written by neither \(theme.id).css nor components.css")
            }
        }
    }

    @Test("a skin scene shows exactly the parts the theme defines, and says so where it has none")
    func skinScenePartsFollowTheModel() throws {
        for theme in Theme.all where theme.surfaces != nil {
            let scene = try #require(try GalleryScenes.skinScene(for: theme), "\(theme.id)")
            let used = classes(in: scene)
            let hasBar = theme.windowControls?.titleBar != nil && theme.surfaces?.recipes[.titleBar] != nil
            #expect(used.contains("dt-titlebar") == hasBar, "\(theme.id) title bar")
            #expect(used.contains("dt-scrollbar") == (theme.scrollBar != nil), "\(theme.id) scroll bars")
            let css = try ThemeCSSEmitter.emit(theme)
            // menus follow what the stylesheet draws: a theme can have a menu bar and no menu column (System 7) or the reverse (OPENSTEP)
            #expect(used.contains("dt-menubar") == (theme.menus != nil && css.contains(".dt-menubar")), "\(theme.id) menu bar")
            #expect(used.contains("dt-menu") == (theme.menus != nil && (css.contains(".dt-menu {") || css.contains(".dt-menu,"))), "\(theme.id) menu")
            #expect(used.contains("dt-dock__tile") == (theme.dock != nil && theme.surfaces?.recipes[.dockTile]?[.rest] != nil), "\(theme.id) dock")
        }
    }

    @Test("a title bar carries one box per control the theme places, and an inactive window is the same bar marked aria-disabled")
    func titleBarControls() throws {
        for theme in Theme.all {
            guard let controls = theme.windowControls, controls.titleBar != nil, theme.surfaces?.recipes[.titleBar] != nil else { continue }
            let scene = try #require(try GalleryScenes.skinScene(for: theme), "\(theme.id)")
            let css = try ThemeCSSEmitter.emit(theme)
            for control in controls.leading + controls.trailing {
                // a control appears when the stylesheet styles it, and only then
                #expect(scene.contains("dt-titlebar__box--\(control.rawValue)") == css.contains(".dt-titlebar__box--\(control.rawValue)"), "\(theme.id) \(control.rawValue)")
            }
            #expect(scene.components(separatedBy: "class=\"dt-titlebar\">").count - 1 == 1, "\(theme.id): the active bar")
            #expect(scene.components(separatedBy: "class=\"dt-titlebar\" aria-disabled=\"true\"").count - 1 == 1, "\(theme.id): the inactive bar")
        }
    }

    @Test("a menu shows a selected row, a disabled row and a separator, so every state the recipes draw is on screen")
    func menuStates() throws {
        for theme in Theme.all where theme.menus != nil && theme.surfaces != nil {
            let scene = try #require(try GalleryScenes.skinScene(for: theme), "\(theme.id)")
            guard classes(in: scene).contains("dt-menu") else { continue }
            #expect(scene.contains("class=\"dt-menu__item\" aria-selected=\"true\""), "\(theme.id)")
            #expect(scene.contains("class=\"dt-menu__item\" aria-disabled=\"true\""), "\(theme.id)")
            #expect(scene.contains("dt-menu__separator") == (try ThemeCSSEmitter.emit(theme)).contains(".dt-menu__separator"), "\(theme.id)")
        }
    }

    @Test("the script shows the scene of the selected theme and hides the others")
    func scriptTogglesScenes() throws {
        let script = try file("gallery/gallery.js", in: try GalleryEmitter.emit())
        #expect(script.contains("data-skin-scene"))
        #expect(script.contains("hidden"))
    }

    @Test("the page and its script load nothing from the network and the script is plain ES2020 with no modules")
    func selfContained() throws {
        let files = try GalleryEmitter.emit()
        for path in ["gallery/index.html", "gallery/gallery.css", "gallery/gallery.js"] {
            let text = try file(path, in: files)
            #expect(!text.contains("http://") && !text.contains("https://"), "\(path) must not reference the network")
        }
        let script = try file("gallery/gallery.js", in: files)
        #expect(!script.contains("import ") && !script.contains("export "), "no modules: the page must open from file://")
        #expect(!(try file(Self.page, in: files)).contains("type=\"module\""))
    }

    @Test("the page's own stylesheet never names a theme: the chrome is neutral and the stage is the only themed part")
    func chromeIsNeutral() throws {
        let css = try file("gallery/gallery.css", in: try GalleryEmitter.emit())
        #expect(!css.contains("data-theme-name"))
        for theme in Theme.all { #expect(!css.contains("[data-theme-name=\"\(theme.id)\"]")) }
    }

    @Test("the table and the cards below it are separated by the theme's own card gap, not by a fixed length")
    func tableAndCardsSpaced() throws {
        let css = try file("gallery/gallery.css", in: try GalleryEmitter.emit())
        #expect(css.contains(".stage .dt-table + .dt-cards"))
        #expect(css.contains("margin-block-start: var(--card-gap"))
        for theme in Theme.all {
            let themed = try ThemeCSSEmitter.emit(theme)
            #expect(themed.contains("--card-gap:"), "\(theme.id) defines --card-gap, which the gallery spacing reads")
        }
    }

    @Test("a scene caption sits on the page's own neutral colours, so it reads over any skin's desktop")
    func captionLegible() throws {
        let css = try file("gallery/gallery.css", in: try GalleryEmitter.emit())
        let rule = try #require(css.split(whereSeparator: \.isNewline).first { $0.contains(".skin-scene__caption") }, "a caption rule")
        #expect(rule.contains("background: Canvas") && rule.contains("color: CanvasText"))
    }

    @Test("the chosen theme is kept in the URL hash: the script reads and writes location.hash")
    func hashState() throws {
        let script = try file("gallery/gallery.js", in: try GalleryEmitter.emit())
        #expect(script.contains("location.hash"))
        #expect(script.contains("data-theme-name"))
    }
}
