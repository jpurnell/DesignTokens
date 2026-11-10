#if canImport(SwiftUI) && os(macOS)
import DesignTokens
import SwiftUI
import Testing
@testable import DesignTokensSwiftUI

@Suite("Swiss metrics and grid")
struct SwissMetricsTests {
    private let metrics = SwissMetrics(theme: .swiss)

    @Test("rule weights and radii equal the tokens")
    func tokens() {
        #expect(near(metrics.hairline, CGFloat(Rule.hairline.points)))
        #expect(near(metrics.sectionRule, CGFloat(Rule.section.points)))
        #expect(near(metrics.pageRule, CGFloat(Rule.page.points)))
        #expect(near(metrics.containerRadius, CGFloat(Radius.container)))
        #expect(near(metrics.controlRadius, CGFloat(Radius.control)))
        #expect(near(metrics.unit, CGFloat(Grid.baseUnit)))
        #expect(near(metrics.gutter, CGFloat(Grid.gutter)))
        #expect(near(metrics.hairline, 1) && near(metrics.sectionRule, 3) && near(metrics.pageRule, 8))
        #expect(near(metrics.containerRadius, 0) && near(metrics.controlRadius, 4))
    }

    @Test("the chip outline is twice the hairline, and steps are multiples of the base unit")
    func derived() {
        #expect(near(metrics.chipOutline, 2 * metrics.hairline))
        for n in 0...10 { #expect(near(metrics.step(n), 4 * CGFloat(n))) }
    }

    @Test("the metrics follow the theme, not constants")
    func followsTheme() {
        var theme = Theme.swiss
        theme.structure.layout.controlRadius = 9
        theme.structure.layout.baseUnit = 8
        theme.structure.rules.hairline = 0.5
        let changed = SwissMetrics(theme: theme)
        #expect(near(changed.controlRadius, 9))
        #expect(near(changed.step(2), 16))
        #expect(near(changed.hairline, 0.5))
    }

    @Test("label spans columns 1 to 3 and reading 4 to 10")
    func spans() {
        #expect(metrics.grid.label == 1...3)
        #expect(metrics.grid.reading == 4...10)
    }

    @Test("column geometry: 12 columns and 11 gutters fill the width; spans are n columns and n-1 gutters")
    func geometry() {
        let grid = metrics.grid
        let total: CGFloat = 1_000
        let column = grid.columnWidth(in: total)
        #expect(near(column * 12 + 11 * 16, 1_000))
        #expect(near(column, 824.0 / 12.0))
        #expect(near(grid.x(ofColumn: 1, in: total), 0))
        #expect(near(grid.x(ofColumn: 4, in: total), 3 * (column + 16)))
        #expect(near(grid.width(of: 1...3, in: total), 3 * column + 2 * 16))
        #expect(near(grid.width(of: 4...10, in: total), 7 * column + 6 * 16))
        let labelWidth: CGFloat = grid.width(of: 1...3, in: total)
        #expect(near(grid.x(ofColumn: 4, in: total) - labelWidth, 16), "one gutter between label and reading")
        let readingEnd: CGFloat = grid.x(ofColumn: 4, in: total) + grid.width(of: 4...10, in: total)
        #expect(near(grid.x(ofColumn: 11, in: total) - readingEnd, 16))
        #expect(near(grid.width(of: 1...12, in: total), 1_000))
    }

    @Test("a width too narrow for the gutters gives zero-width columns, not a negative one")
    func narrow() {
        #expect(near(metrics.grid.columnWidth(in: 50), 0))
        #expect(metrics.grid.width(of: 1...3, in: 50) >= 0)
    }
}
#endif
