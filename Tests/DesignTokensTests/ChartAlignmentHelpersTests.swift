import Foundation
import Testing
@testable import DesignTokens

/// The data-level helpers a renderer needs to apply the chart alignment: which mark the theme emphasises, and how
/// many decimals a number format shows. Pure functions of the theme; the SwiftUI projection wraps them.
@Suite("Chart alignment: helpers")
struct ChartAlignmentHelpersTests {
    // MARK: Default emphasis

    @Test("Swiss emphasises the latest column of a vertical chart: the last index of n")
    func latestOfVertical() {
        let marks = Theme.swiss.structure.marks
        #expect(marks.defaultEmphasisIndex(count: 8, isVertical: true) == 7)
        #expect(marks.defaultEmphasisIndex(count: 1, isVertical: true) == 0)
    }

    @Test("there is nothing to emphasise in an empty chart, and no default emphasis on a horizontal ranked bar")
    func noEmphasis() {
        let marks = Theme.swiss.structure.marks
        #expect(marks.defaultEmphasisIndex(count: 0, isVertical: true) == nil)
        #expect(marks.defaultEmphasisIndex(count: 8, isVertical: false) == nil)
    }

    @Test("a theme whose default emphasis is none never emphasises by default")
    func noneEmphasisesNothing() {
        for theme in Theme.all where theme.structure.marks.defaultEmphasis == .none {
            #expect(theme.structure.marks.defaultEmphasisIndex(count: 8, isVertical: true) == nil, "\(theme.id)")
        }
        #expect(Theme.all.filter { $0.structure.marks.defaultEmphasis == .latest }.map(\.id) == ["swiss", "princeton", "console"])
    }

    // MARK: Number formats

    @Test("a fixed format shows exactly its decimals, a minimal one shows up to its cap, and a format with neither has no range")
    func fractionDigits() {
        #expect(NumberFormatSpec(decimals: 2).fractionDigits == 2...2)
        #expect(NumberFormatSpec(decimals: 0).fractionDigits == 0...0)
        #expect(NumberFormatSpec(maxDecimals: 2).fractionDigits == 0...2)
        #expect(NumberFormatSpec().fractionDigits == nil)
        // a fixed count wins over a cap
        #expect(NumberFormatSpec(decimals: 1, maxDecimals: 3).fractionDigits == 1...1)
        #expect(Theme.swiss.structure.numbers.plain.fractionDigits == 0...2)
        #expect(Theme.house.structure.numbers.plain.fractionDigits == 2...2)
    }

    @Test("Swiss's plain format prints the values of the approved chart as the drawing does: 41.2, 80, 52.6, 49.9")
    func swissPlainPrintsMinimally() throws {
        let digits = try #require(Theme.swiss.structure.numbers.plain.fractionDigits)
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = false
        formatter.minimumFractionDigits = digits.lowerBound
        formatter.maximumFractionDigits = digits.upperBound
        let printed = [41.2, 80, 52.6, 49.9, 63.4, 12.3456].map { formatter.string(from: NSNumber(value: $0)) }
        #expect(printed == ["41.2", "80", "52.6", "49.9", "63.4", "12.35"])
    }
}
