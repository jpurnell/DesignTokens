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

    @Test("every dt- class the page uses is one components.css writes")
    func sceneClassesExist() throws {
        let html = try file(Self.page, in: try GalleryEmitter.emit())
        let components = ComponentsCSSEmitter.emit()
        var used = Set<String>()
        for value in values(of: "class", in: html) {
            for token in value.split(whereSeparator: { $0 == " " }) where token.hasPrefix("dt-") { used.insert(String(token)) }
        }
        #expect(used.count >= 10, "the components scene should exercise the components; found \(used.count)")
        for name in used.sorted() {
            #expect(components.contains(".\(name)"), "\(name) is not written by components.css")
        }
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

    @Test("the chosen theme is kept in the URL hash: the script reads and writes location.hash")
    func hashState() throws {
        let script = try file("gallery/gallery.js", in: try GalleryEmitter.emit())
        #expect(script.contains("location.hash"))
        #expect(script.contains("data-theme-name"))
    }
}
