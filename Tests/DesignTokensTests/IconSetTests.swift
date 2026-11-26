import Foundation
#if canImport(FoundationXML)
import FoundationXML
#endif
import Testing
@testable import DesignTokens

/// OPENSTEP's dock icons: original drawings in the look of the 4.2 icons, as vectors on a 56-unit grid so they scale to any screen.
@Suite("Icon sets")
struct IconSetTests {
    private static let names = ["application", "calendar", "clock", "console", "disk", "document", "edit", "folder", "home", "library",
                                "mail", "preferences", "recycler"]

    private func parses(_ svg: String) -> Bool {
        let parser = XMLParser(data: Data(svg.utf8))
        return parser.parse()
    }

    @Test("OPENSTEP carries thirteen icons, each a 56 x 56 drawing with a unique kebab-case name")
    func theSet() throws {
        let set = try #require(Theme.openstep.icons)
        #expect(set.icons.map(\.name).sorted() == Self.names)
        #expect(Set(set.icons.map(\.name)).count == set.icons.count)
        #expect(set.icons.allSatisfy { $0.viewBox == "0 0 56 56" })
        #expect(Theme.swiss.icons == nil)
    }

    @Test("every icon is well-formed SVG with the 56-unit view box, and uses only drawing elements")
    func wellFormed() throws {
        let set = try #require(Theme.openstep.icons)
        for icon in set.icons {
            let svg = IconEmitter.emit(icon)
            #expect(svg.hasPrefix("<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 56 56\""), "\(icon.name)")
            #expect(parses(svg), "\(icon.name) is not well-formed")
            for tag in ["script", "foreignObject", "image", "style", "a "] { #expect(!svg.contains("<" + tag), "\(icon.name) uses <\(tag)") }
        }
    }

    @Test("every drawing is shaded and outlined: it defines a gradient and draws black")
    func shaded() throws {
        let set = try #require(Theme.openstep.icons)
        for icon in set.icons {
            #expect(icon.body.contains("Gradient id="), "\(icon.name) has no gradient")
            #expect(icon.body.contains("#000"), "\(icon.name) has no black outline")
        }
    }

    @Test("a drawing needs a name of lower-case letters, digits and hyphens and some content")
    func validation() {
        #expect(throws: IconError.self) { _ = try Icon(name: "Bad Name", body: "<rect/>") }
        #expect(throws: IconError.self) { _ = try Icon(name: "ok", body: "") }
        #expect(throws: IconError.self) { _ = try Icon(name: "ok", viewBox: "0 0 48", body: "<rect/>") }
    }

    @Test("the generator writes one file per icon under themes/<id>.icons, and none for a theme without icons")
    func generated() throws {
        let files = try Generator.files(for: [.openstep, .swiss], includeDefaults: false, formats: [.icons])
        #expect(files.map(\.path).sorted() == Self.names.map { "themes/openstep.icons/\($0).svg" })
    }

    @Test("the icon set survives the JSON round trip")
    func roundTrip() throws {
        let decoded = try ThemeCodec.decode(try ThemeCodec.encode(.openstep))
        #expect(decoded.icons == Theme.openstep.icons)
    }
}
