import Foundation
import Testing
@testable import DesignTokens

@Suite("Browser support and breakpoints (0.12.0)")
struct BrowserSupportTests {
    private static let root = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()

    private static func emitted(_ scope: BrowserSupport.Scope) throws -> String {
        switch scope {
        case .themes: try ([CSSEmitter.emit()] + Theme.all.map { try ThemeCSSEmitter.emit($0) }).joined(separator: "\n")
        case .components: ComponentsCSSEmitter.emit()
        case .tumblr: try TumblrEmitter.emit(.swiss)
        }
    }

    private static func matches(_ pattern: String, in text: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        return regex.matches(in: text, range: NSRange(text.startIndex..., in: text)).compactMap {
            Range($0.range(at: 1 <= $0.numberOfRanges - 1 ? 1 : 0), in: text).map { String(text[$0]) }
        }
    }

    private static var readme: String {
        (try? String(contentsOf: root.appendingPathComponent("README.md"), encoding: .utf8)) ?? ""
    }

    // MARK: The feature table is true of the CSS

    @Test("every listed feature appears in each file group it is listed for, and in no group it is not")
    func featuresMatchTheCSS() throws {
        for scope in BrowserSupport.Scope.allCases {
            let css = try Self.emitted(scope)
            for feature in BrowserSupport.features {
                let regex = try NSRegularExpression(pattern: feature.pattern)
                let found = regex.firstMatch(in: css, range: NSRange(css.startIndex..., in: css)) != nil
                #expect(found == feature.scopes.contains(scope), Comment(rawValue: "\(feature.name) in \(scope): found \(found), listed \(feature.scopes.contains(scope))"))
            }
        }
    }

    @Test("no feature outside the table is used")
    func nothingUnlisted() throws {
        for scope in BrowserSupport.Scope.allCases {
            let css = try Self.emitted(scope)
            for pattern in BrowserSupport.notUsed {
                let regex = try NSRegularExpression(pattern: pattern)
                #expect(regex.firstMatch(in: css, range: NSRange(css.startIndex..., in: css)) == nil, Comment(rawValue: "\(pattern) in \(scope)"))
            }
        }
    }

    @Test("the floor of the CSS a page links is Chrome and Edge 111, Safari 16.2, Firefox 113, set by color-mix() and container queries")
    func pageFloor() {
        let floor = BrowserSupport.pageFloor
        #expect(floor == BrowserSupport.Versions(chrome: 111, edge: 111, safari: 16.2, firefox: 113))
        #expect(BrowserSupport.floorText(floor) == "Chrome 111, Edge 111, Safari 16.2, Firefox 113")
        // the theme files alone ask for much less; the Tumblr block has its own floor, set by :has()
        #expect(BrowserSupport.floor(for: [.themes]) == BrowserSupport.Versions(chrome: 96, edge: 96, safari: 14.1, firefox: 101))
        #expect(BrowserSupport.floor(for: [.tumblr]).firefox == 121)
    }

    @Test("every feature has plausible versions: not zero, Edge no earlier than 12")
    func versionsPlausible() {
        for feature in BrowserSupport.features {
            let v = feature.versions
            #expect(v.chrome >= 1 && v.edge >= 12 && v.safari >= 1 && v.firefox >= 1, Comment(rawValue: feature.name))
            #expect(!feature.scopes.isEmpty, Comment(rawValue: feature.name))
        }
    }

    // MARK: Breakpoints are the CSS's

    @Test("the documented breakpoints are the ones in the emitted CSS")
    func breakpointsEqualTheCSS() throws {
        let components = ComponentsCSSEmitter.emit()
        let media = Self.matches(#"@media \(max-width: (\d+)px\)"#, in: components).compactMap(Int.init)
        #expect(!media.isEmpty && Set(media) == [BrowserSupport.Breakpoints.tableStackBelowPixels])
        #expect(Self.matches(#"@container \(max-width: (\d+)rem\)"#, in: components).compactMap(Int.init) == [BrowserSupport.Breakpoints.keyValueStackBelowRem])
        let console = try ThemeCSSEmitter.emit(try #require(Theme.named("console")))
        let console352 = Self.matches(#"--card-min: (\d+)px;"#, in: console).compactMap(Int.init)
        #expect(console352 == [BrowserSupport.Breakpoints.cardMinimumWidthInBaseUnits * 4])
        let tumblr = try TumblrEmitter.emit(.swiss)
        #expect(Self.matches(#"@media \(max-width: (\d+)px\)"#, in: tumblr).compactMap(Int.init) == BrowserSupport.Breakpoints.tumblrPixels)
        // and the two numbers the SwiftUI table uses are the same threshold
        #expect(BrowserSupport.Breakpoints.tableStackBelowPixels == 600)
    }

    @Test("the generated header of components.css states the floor, the features and the breakpoints")
    func headerStatesThem() {
        let css = ComponentsCSSEmitter.emit()
        let header = String(css.prefix(upTo: css.range(of: "\n/* ---- Page")?.lowerBound ?? css.endIndex))
        #expect(header.contains(BrowserSupport.floorText(BrowserSupport.pageFloor)))
        #expect(header.contains("No fallbacks are provided"))
        for feature in BrowserSupport.features where feature.scopes.contains(.components) {
            #expect(header.contains(feature.name), Comment(rawValue: feature.name))
        }
        #expect(header.contains("below a viewport of \(BrowserSupport.Breakpoints.tableStackBelowPixels)px"))
        #expect(header.contains("under \(BrowserSupport.Breakpoints.keyValueStackBelowRem)rem"))
        #expect(header.contains("\(BrowserSupport.Breakpoints.cardMinimumWidthInBaseUnits) base units"))
    }

    // MARK: The README holds the table

    @Test("the README has a Browser support section with every feature row as generated, the floor, the breakpoints and 'no fallbacks'")
    func readmeDocumentsIt() {
        let readme = Self.readme
        #expect(readme.contains("## Browser support"))
        for feature in BrowserSupport.features {
            #expect(readme.contains(BrowserSupport.markdownRow(feature)), Comment(rawValue: feature.name))
        }
        #expect(readme.contains(BrowserSupport.floorText(BrowserSupport.pageFloor)))
        #expect(readme.contains("no fallbacks are provided"))
        #expect(readme.contains("\(BrowserSupport.Breakpoints.tableStackBelowPixels) px"))
        #expect(readme.contains("\(BrowserSupport.Breakpoints.keyValueStackBelowRem) rem"))
        #expect(readme.contains("\(BrowserSupport.Breakpoints.cardMinimumWidthInBaseUnits) base units = \(BrowserSupport.Breakpoints.cardMinimumWidthInBaseUnits * 4) px"))
        for pixels in BrowserSupport.Breakpoints.tumblrPixels { #expect(readme.contains("\(pixels) px")) }
    }
}
