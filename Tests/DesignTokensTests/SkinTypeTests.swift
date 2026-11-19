import Foundation
import Testing
@testable import DesignTokens

/// The original systems set their interface text in one face at one size, in sentence case with no added tracking; none of them
/// capitalised labels. The faces are named first and fall back to what a machine has (project/docs/technical/SkinMeasurements.md).
@Suite("Skin type")
struct SkinTypeTests {
    private let skins: [(Theme, [String])] = [
        (.system7, ["Chicago", "Geneva"]),
        (.platinum, ["Charcoal", "Geneva"]),
        (.openstep, ["Helvetica"]),
    ]

    private func names(_ family: FontFamilyRef) -> [String] {
        guard case .named(let name, let fallback) = family else { return [] }
        return [name] + names(fallback)
    }

    @Test("every interface role is sentence case with no added letter-spacing")
    func plainText() {
        for (theme, _) in skins {
            let type = theme.structure.type
            for (name, spec) in [("label", type.label), ("caption", type.caption), ("body", type.body), ("heading", type.heading),
                                 ("uiTitle", type.uiTitle), ("display", type.display)] {
                #expect(!spec.uppercase, "\(theme.id) \(name) is not uppercase")
                #expect(abs(spec.tracking) < 1e-12, "\(theme.id) \(name) has no tracking")
            }
        }
    }

    @Test("each skin names its original faces first, in order, then falls back to the system sans")
    func faceChains() {
        for (theme, expected) in skins {
            for spec in [theme.structure.type.body, theme.structure.type.label, theme.structure.type.uiTitle] {
                let chain = names(spec.family)
                #expect(chain == expected, "\(theme.id)")
            }
        }
    }

    @Test("the generated CSS lists the original face before any modern one, so a machine that has it uses it")
    func cssOrder() throws {
        for (theme, expected) in skins {
            let css = try ThemeCSSEmitter.emit(theme)
            let line = try #require(css.split(whereSeparator: \.isNewline).first { $0.contains("--type-body-family:") })
            let firstQuoted = try #require(line.range(of: "\"\(expected[0])\""))
            if let sf = line.range(of: "SF Pro") { #expect(firstQuoted.lowerBound < sf.lowerBound, "\(theme.id)") }
            #expect(line.contains(".sans") == false)
        }
    }
}
