import Testing
@testable import DesignTokens

@Suite("Metrics")
struct MetricsTests {
    @Test("rule weights are 1, 3 and 8 points")
    func rules() {
        #expect(Rule.hairline.points == 1)
        #expect(Rule.section.points == 3)
        #expect(Rule.page.points == 8)
    }

    @Test("grid is 12 columns with a 16 point gutter and a 4 point base")
    func grid() {
        #expect(Grid.columns == 12)
        #expect(Grid.gutter == 16)
        #expect(Grid.baseUnit == 4)
        #expect(Grid.gutter.isMultiple(of: Grid.baseUnit))
    }

    @Test("label column is 1 to 3, reading column 4 to 10, wide media 4 to 12")
    func spans() {
        #expect(Grid.label == 1...3)
        #expect(Grid.reading == 4...10)
        #expect(Grid.wide == 4...12)
    }

    @Test("container radius is 0 and control radius is 4")
    func radius() {
        #expect(Radius.container == 0)
        #expect(Radius.control == 4)
    }
}
