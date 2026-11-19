import Foundation
import Testing
@testable import DesignTokens

/// The skins' fixed-pitch face: the original named first (Monaco on the Macintosh, Ohlfs then Courier on NeXT), then a face a machine has,
/// then the system monospace. The sizes are the systems' own, chosen and not measured.
@Suite("Skin monospace")
struct SkinMonospaceTests {
    private let skins: [(Theme, [String])] = [
        (.system7, ["Monaco", "Menlo"]),
        (.platinum, ["Monaco", "Menlo"]),
        (.openstep, ["Ohlfs", "Courier"]),
    ]

    private func names(_ family: FontFamilyRef) -> [String] {
        guard case .named(let name, let fallback) = family else { return [] }
        return [name] + names(fallback)
    }

    private func line(_ css: String, containing key: String) throws -> String {
        String(try #require(css.split(whereSeparator: \.isNewline).first { $0.contains(key) }))
    }

    @Test("each skin names its fixed-pitch faces in order and ends on the system monospace")
    func chain() throws {
        for (theme, expected) in skins {
            let spec = try #require(theme.structure.monospace, "\(theme.id)")
            #expect(names(spec.family) == expected, "\(theme.id)")
            #expect(!spec.uppercase && abs(spec.tracking) < 1e-12, "\(theme.id) is plain")
        }
    }

    @Test("a theme without one writes nothing, and its JSON is unchanged")
    func absent() throws {
        let json = String(decoding: try ThemeCodec.encode(.swiss), as: UTF8.self)
        #expect(Theme.swiss.structure.monospace == nil)
        #expect(!json.contains("monospace"))
        #expect(try !ThemeCSSEmitter.emit(.swiss).contains("--type-mono-"))
    }

    @Test("the role survives the JSON round trip")
    func roundTrip() throws {
        for (theme, _) in skins {
            let decoded = try ThemeCodec.decode(try ThemeCodec.encode(theme))
            #expect(decoded.structure.monospace == theme.structure.monospace, "\(theme.id)")
        }
    }

    @Test("the web CSS puts the named face first in --font-mono and writes the role's size and line")
    func webCSS() throws {
        for (theme, expected) in skins {
            let css = try ThemeCSSEmitter.emit(theme)
            let family = try line(css, containing: "--font-mono:")
            let spec = try #require(theme.structure.monospace)
            #expect(family.contains("\"\(expected[0])\", \"\(expected[1])\", ui-monospace"), "\(theme.id): \(family)")
            #expect(try line(css, containing: "--type-mono-size:").contains("\(Int(spec.size))px"), "\(theme.id)")
            #expect(try line(css, containing: "--type-mono-line:").contains("\(spec.lineHeight)"), "\(theme.id)")
        }
    }

    @Test("GTK gets a .monospace rule with the same face")
    func gtk() throws {
        for (theme, expected) in skins {
            let slot = try #require(ThemeSlot.slots(for: theme).first)
            let css = try GTKEmitter.emit(theme, slot: slot)
            let start = try #require(css.range(of: ".monospace {"))
            let block = String(css[start.lowerBound...].prefix(while: { $0 != "}" }))
            #expect(block.contains("font-family: \"\(expected[0])\", \"\(expected[1])\""), "\(theme.id): \(block)")
            #expect(block.contains("font-size:"), "\(theme.id)")
        }
    }
}
