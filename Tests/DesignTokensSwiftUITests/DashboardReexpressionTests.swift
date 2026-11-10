#if canImport(SwiftUI) && os(macOS)
import DesignTokens
import SwiftUI
import Testing
@testable import DesignTokensSwiftUI

private struct Checker: Identifiable {
    let id: Int
    let name: String
    let failures: Int
}

/// A screen of the quality-gate dashboard (a project's Summary: status banner, view switch, orientation rows, a gap card, a
/// checker table), written only from the package's components on a theme composed from a dashboard-shaped palette. It is the
/// proof that what `IJSDashboardUI` hand-rolled is now one import: each piece names the dashboard file it replaces (the full
/// mapping is `project/docs/technical/SwissComponents.md`).
@MainActor
@Suite("Dashboard re-expression")
struct DashboardReexpressionTests {
    private struct Screen: View {
        @State private var tab = "Summary"
        @State private var sort: SwissTableSort? = SwissTableSort(column: "failures", ascending: false)
        let checkers = [Checker(id: 1, name: "safety", failures: 4), Checker(id: 2, name: "docs", failures: 0)]

        var body: some View {
            VStack(alignment: .leading, spacing: 24) {
                // PortfolioBannerView.swift
                StatusBanner(.warning, text: "Passing, not all confirmed")
                // DashboardSegmented (DashboardType.swift)
                SwissSegmentedControl(title: "View", options: ["Summary", "Checkers"], name: { $0 }, selection: $tab)
                // DashboardSection + HairlineRule (DashboardType.swift), KeyValueRow (AdaptiveViews.swift)
                SwissSection("Orientation") {
                    KeyValueList {
                        KeyValueRow("Version", text: "0.10.0")
                        KeyValueRow("Gate") { OutlinedChip("Failing", tone: .negative, glyph: "xmark.octagon.fill") }
                    }
                }
                // the gap card and StatusChip (StackMapView.swift, DashboardShape.swift)
                SwissCard(label: "#13", title: "Design tokens", description: "Shared tokens.",
                          chip: { OutlinedChip("Open", tone: .emphasis) },
                          footer: { SwissCardFooter("Builds on", names: "SwiftCLIKit") })
                // the native Tables the dashboard left (ProjectDetailView, ProjectsTableView, AnalyticsTables)
                SwissTable(checkers, columns: [
                    SwissTableColumn("Checker", id: "name", span: 8, isSortable: true, text: { $0.name }),
                    SwissTableColumn("Failures", id: "failures", span: 4, isFigure: true, isSortable: true, text: { String($0.failures) }),
                ], sort: $sort)
            }
            .frame(width: 720)
        }
    }

    private static let palette = AppPalette(
        id: "ijs-dashboard-window",
        background: Adaptive(light: ColorValue(RGB(rgb: 0xECECEC), alpha: 0), dark: ColorValue(RGB(rgb: 0x323232), alpha: 0)),
        textRoles: [NamedAdaptive("secondaryInk", light: 0x5C5C61, dark: 0xAEAEB2)],
        textSurfaces: TextSurfaces(light: [0xFFFFFF, 0xF2F2F7, 0xECECEC], dark: [0x000000, 0x1C1C1E, 0x323232]))

    @Test("the palette validates and the screen renders at the size its width and content decide, in light and dark")
    func rendersOnTheDashboardsTheme() throws {
        let result = Self.palette.validate()
        #expect(result.isConformant, "\(result.report)")
        let theme = Self.palette.theme()
        for scheme in [ColorScheme.light, .dark] {
            let renderer = ImageRenderer(content: Screen().chartTheme(theme).environment(\.colorScheme, scheme))
            renderer.scale = 1
            let image = try #require(renderer.cgImage, "\(scheme)")
            #expect(image.width == 720, "\(scheme)")
            #expect(image.height > 300 && image.height < 1_200, "\(scheme): \(image.height)")
        }
    }

    @Test("the theme the screen draws in is Swiss with the dashboard's surfaces, the one the validator measured")
    func themeIsTheValidatedOne() {
        let theme = Self.palette.theme()
        #expect(theme.id == "swiss+ijs-dashboard-window")
        #expect(theme.structure == Theme.swiss.structure)
    }
}
#endif
