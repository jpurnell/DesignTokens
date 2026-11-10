#if canImport(SwiftUI) && os(macOS)
import Foundation
import Testing

/// The drift-checker standard applied to this package's own components: every colour, radius and font comes from the tokens.
@Suite("Swiss components read tokens, not literals")
struct SwissSourceDisciplineTests {
    private func sources() throws -> [(String, String)] {
        let directory = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("Sources/DesignTokensSwiftUI/Swiss")
        let files = try FileManager.default.contentsOfDirectory(atPath: directory.path).filter { $0.hasSuffix(".swift") }
        return try files.map { ($0, try String(contentsOf: directory.appendingPathComponent($0), encoding: .utf8)) }
    }

    @Test("no literal colour, corner radius or fixed-size font in any Swiss component file")
    func noLiterals() throws {
        let forbidden: [(String, String)] = [
            ("a hex colour", "#[0-9A-Fa-f]{6}\\b"),
            ("Color(red/white/hue)", "Color\\((red|white|hue|\\.sRGB)"),
            ("a named system colour", "Color\\.(white|black|red|green|blue|orange|yellow|purple|gray|primary|secondary)\\b"),
            ("a numeric corner radius", "cornerRadius: *[0-9]"),
            ("a fixed font size", "\\.system\\(size:"),
            ("a numeric line width", "lineWidth: *[0-9]"),
        ]
        let found = try sources()
        #expect(!found.isEmpty)
        for (name, text) in found {
            for line in text.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline) where !line.trimmingCharacters(in: .whitespaces).hasPrefix("//") {
                for (what, pattern) in forbidden where line.range(of: pattern, options: .regularExpression) != nil {
                    Issue.record("\(name): \(what): \(line)")
                }
            }
        }
    }

    @Test("the core target imports no UI framework, so it stays Foundation-only and Linux-buildable")
    func coreIsFoundationOnly() throws {
        let core = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("Sources/DesignTokens")
        let enumerator = try #require(FileManager.default.enumerator(atPath: core.path))
        var checked = 0
        for case let path as String in enumerator where path.hasSuffix(".swift") {
            let text = try String(contentsOf: core.appendingPathComponent(path), encoding: .utf8)
            checked += 1
            for framework in ["SwiftUI", "AppKit", "UIKit", "Combine", "CoreGraphics"] {
                #expect(!text.contains("import \(framework)"), "\(path) imports \(framework)")
            }
        }
        #expect(checked > 20)
    }
}
#endif
