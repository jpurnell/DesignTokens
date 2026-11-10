#if canImport(SwiftUI) && os(macOS)
import DesignTokens
import SwiftUI
import Testing
@testable import DesignTokensSwiftUI

@Suite("Key/value geometry")
struct KeyValueGeometryTests {
    private let grid = SwissMetrics(theme: .swiss).grid

    @Test("wide: the label takes columns 1 to 3 and the value starts at column 4 and spans 4 to 10")
    func wide() throws {
        let columns = try #require(KeyValueGeometry.columns(totalWidth: 1_000, grid: grid, minimumLabelWidth: 96))
        #expect(near(columns.labelWidth, grid.width(of: 1...3, in: 1_000)))
        #expect(near(columns.valueX, grid.x(ofColumn: 4, in: 1_000)))
        #expect(near(columns.valueWidth, grid.width(of: 4...10, in: 1_000)))
    }

    @Test("proportions: label to reading is (3c+2g) to (7c+6g)")
    func proportions() throws {
        let columns = try #require(KeyValueGeometry.columns(totalWidth: 1_200, grid: grid, minimumLabelWidth: 96))
        let c = (1_200.0 - 11 * 16) / 12
        #expect(near(columns.labelWidth / columns.valueWidth, (3 * c + 32) / (7 * c + 96)))
    }

    @Test("narrow: when the label column would be under the minimum the row stacks (nil), and at the boundary it does not")
    func stacking() throws {
        #expect(KeyValueGeometry.columns(totalWidth: 300, grid: grid, minimumLabelWidth: 96) == nil)
        // label width w(total) = 3 * (total - 176) / 12 + 32; w = 96 at total = 432
        #expect(try #require(KeyValueGeometry.columns(totalWidth: 432, grid: grid, minimumLabelWidth: 96)).labelWidth >= 96 - 1e-9)
        #expect(KeyValueGeometry.columns(totalWidth: 431, grid: grid, minimumLabelWidth: 96) == nil)
    }

    @Test("a larger minimum (large Dynamic Type) stacks sooner")
    func dynamicType() throws {
        let columns = try #require(KeyValueGeometry.columns(totalWidth: 600, grid: grid, minimumLabelWidth: 96))
        #expect(columns.labelWidth >= 96)
        #expect(KeyValueGeometry.columns(totalWidth: 600, grid: grid, minimumLabelWidth: 200) == nil)
    }
}
#endif
