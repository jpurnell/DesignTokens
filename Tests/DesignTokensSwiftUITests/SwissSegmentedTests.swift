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
        @State private var selection: String
        init(selected: String = "Summary") { _selection = State(initialValue: selected) }
        var body: some View {
            SwissSegmentedControl(title: "View", options: ["Summary", "Checkers", "Inbox"], name: { $0 }, selection: $selection)
                .environment(\.swissTableProbe, true)
        }
    }

    private func frames(width: CGFloat, size: DynamicTypeSize = .large, selected: String = "Summary") -> [String: CGRect] {
        renderProbedTable(Demo(selected: selected).environment(\.dynamicTypeSize, size), width: width)
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

    @Test("the selected segment sits inside the border by the same inset on top and bottom for every position, and on the left for the first and the right for the last")
    func equalInsets() throws {
        let metrics = SwissMetrics(theme: .swiss)
        let inset = metrics.segmentInset + metrics.hairline
        for (selected, isFirst, isLast) in [("Summary", true, false), ("Checkers", false, false), ("Inbox", false, true)] {
            let f = frames(width: 420, selected: selected)
            let control = try #require(f["segmented/segments"]), fill = try #require(f["segmented/selected"])
            #expect(near(fill.minY - control.minY, inset, tolerance: 0.5), "\(selected) top")
            #expect(near(control.maxY - fill.maxY, inset, tolerance: 0.5), "\(selected) bottom")
            if isFirst { #expect(near(fill.minX - control.minX, inset, tolerance: 0.5), "first, left") } else { #expect(fill.minX - control.minX > inset + 1, "\(selected) is clear of the left edge") }
            if isLast { #expect(near(control.maxX - fill.maxX, inset, tolerance: 0.5), "last, right") } else { #expect(control.maxX - fill.maxX > inset + 1, "\(selected) is clear of the right edge") }
        }
    }

    @Test("the inset is one base unit and the selected fill's radius is the border's less the inset and the line, never below 0")
    func concentricRadius() {
        let swiss = SwissMetrics(theme: .swiss)
        #expect(swiss.segmentInset.isEqual(to: 4))
        #expect(swiss.segmentRadius.isZero, "4 pt control radius less 5 pt is square")
        var round = Theme.swiss
        round.structure.layout.controlRadius = 12
        let m = SwissMetrics(theme: round)
        #expect(m.segmentRadius.isEqual(to: 12 - m.segmentInset - m.hairline))
        #expect(m.segmentRadius < m.controlRadius)
    }

    @Test("the whole segment stays tappable: each is at least as tall as the control's inner height, which is the 44 pt target on a touch platform")
    func segmentsStayTall() throws {
        let f = frames(width: 420)
        let control = try #require(f["segmented/segments"]), fill = try #require(f["segmented/selected"])
        #expect(fill.height >= control.height - 2 * (SwissMetrics(theme: .swiss).segmentInset + 1) - 0.5)
    }
}
#endif
