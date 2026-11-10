#if canImport(SwiftUI) && os(macOS)
import DesignTokens
import SwiftUI
import Testing
@testable import DesignTokensSwiftUI

@Suite("Segmented control presentation")
struct SwissSegmentedRuleTests {
    @Test("automatic: segments when they fit at a normal size; a menu when they do not fit, or at an accessibility size even if they would")
    func automatic() {
        #expect(SwissSegmentedPresentation.automatic.resolved(isAccessibilitySize: false, segmentsFit: true) == .segments)
        #expect(SwissSegmentedPresentation.automatic.resolved(isAccessibilitySize: false, segmentsFit: false) == .menu)
        #expect(SwissSegmentedPresentation.automatic.resolved(isAccessibilitySize: true, segmentsFit: true) == .menu)
        #expect(SwissSegmentedPresentation.automatic.resolved(isAccessibilitySize: true, segmentsFit: false) == .menu)
    }

    @Test("a forced presentation ignores size and fit")
    func forced() {
        for size in [false, true] {
            for fit in [false, true] {
                #expect(SwissSegmentedPresentation.segments.resolved(isAccessibilitySize: size, segmentsFit: fit) == .segments)
                #expect(SwissSegmentedPresentation.menu.resolved(isAccessibilitySize: size, segmentsFit: fit) == .menu)
            }
        }
    }

    @Test("a finger's target is 44 points: eleven base units")
    func touchTarget() {
        #expect(SwissMetrics(theme: .swiss).minimumTouchTarget.isEqual(to: 44))
    }
}

@MainActor
@Suite("Segmented control in a real window")
struct SwissSegmentedLayoutTests {
    private struct Demo: View {
        @State private var selection = "Summary"
        var body: some View {
            SwissSegmentedControl(title: "View", options: ["Summary", "Checkers", "Inbox"], name: { $0 }, selection: $selection)
                .environment(\.swissTableProbe, true)
        }
    }

    private func frames(width: CGFloat, size: DynamicTypeSize = .large) -> [String: CGRect] {
        renderProbedTable(Demo().environment(\.dynamicTypeSize, size), width: width)
    }

    @Test("where the three words fit, they are segments on one line")
    func fits() throws {
        let f = frames(width: 420)
        let segments = try #require(f["segmented/segments"])
        #expect(f["segmented/menu"] == nil, "no menu is drawn beside them")
        #expect(segments.height < 40, "one line: \(segments.height)")
        #expect(near(segments.width, 420), "the segments fill the width")
    }

    @Test("where the words do not fit on one line each, the control is a menu, not broken words")
    func narrowBecomesMenu() throws {
        let f = frames(width: 150)
        let menu = try #require(f["segmented/menu"])
        #expect(f["segmented/segments"] == nil)
        #expect(menu.height < 60)
    }

    @Test("at an accessibility text size it is a menu even in a wide window")
    func accessibilitySize() throws {
        let f = frames(width: 900, size: .accessibility3)
        _ = try #require(f["segmented/menu"])
        #expect(f["segmented/segments"] == nil)
    }
}
#endif
