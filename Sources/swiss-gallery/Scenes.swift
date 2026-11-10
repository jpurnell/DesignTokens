#if canImport(SwiftUI) && canImport(AppKit)
import AppKit
import DesignTokens
import DesignTokensSwiftUI
import SwiftUI

@available(macOS 14.0, iOS 17.0, visionOS 1.0, tvOS 17.0, watchOS 10.0, *)
struct Row: Identifiable {
    let id: Int
    let name: String
    let status: String
    let count: Int
}

@available(macOS 14.0, *)
private let rows = [Row(id: 1, name: "swift-oauth", status: "Passing", count: 460),
                    Row(id: 2, name: "SwiftMCPClient", status: "Failing", count: 474),
                    Row(id: 3, name: "DesignTokens", status: "Passing", count: 440),
                    Row(id: 4, name: "BusinessMath-UI", status: "Stale", count: 1_212)]

@available(macOS 14.0, iOS 17.0, visionOS 1.0, tvOS 17.0, watchOS 10.0, *)
private struct SegmentedDemo: View {
    @State private var selection = "Summary"
    var body: some View {
        SwissSegmentedControl(title: "View", options: ["Summary", "Checkers", "Inbox"], name: { $0 }, selection: $selection)
    }
}

@available(macOS 14.0, iOS 17.0, visionOS 1.0, tvOS 17.0, watchOS 10.0, *)
private struct TableDemo: View {
    @State private var sort: SwissTableSort? = SwissTableSort(column: "count", ascending: false)
    var body: some View {
        SwissTable(rows, columns: [
            SwissTableColumn("Project", id: "name", span: 5, isSortable: true, text: { $0.name }),
            SwissTableColumn("Status", id: "status", span: 3, isSortable: true) { row in
                OutlinedChip(row.status, tone: row.status == "Failing" ? .negative : row.status == "Stale" ? .warning : .neutral)
            },
            SwissTableColumn("Tests", id: "count", span: 4, isFigure: true, isSortable: true, text: { String($0.count) }),
        ], sort: $sort)
    }
}

@available(macOS 14.0, iOS 17.0, visionOS 1.0, tvOS 17.0, watchOS 10.0, *)
private struct FormDemo: View {
    @State private var enabled = true
    @State private var other = false
    @State private var name = "swift-oauth"
    var body: some View {
        Form {
            SwissSection("Server") {
                LabeledContent("Host") { Text("roseclub.org") }
                LabeledContent("Port") { Text("9086").uiFigure() }
            }
            Toggle("Run the gate on commit", isOn: $enabled)
            Toggle("Fail on warnings", isOn: $other)
            SwissTextField("Project", prompt: "Name", text: $name)
        }
        .formStyle(.swiss)
        .toggleStyle(.swiss)
        .labeledContentStyle(.swiss)
    }
}

@available(macOS 14.0, iOS 17.0, visionOS 1.0, tvOS 17.0, watchOS 10.0, *)
private struct NativeTableDemo: View {
    var body: some View {
        Table(rows) {
            TableColumn("Project", value: \.name)
            TableColumn("Tests") { Text(String($0.count)).uiText(.body).uiFigure() }
        }
        .swissTableStyle()
        .frame(height: 190)
    }
}

@available(macOS 14.0, iOS 17.0, visionOS 1.0, tvOS 17.0, watchOS 10.0, *)
private struct StackedRow: View {
    var body: some View {
        KeyValueList {
            KeyValueRow("Version", text: "0.10.0")
            KeyValueRow("Last commit", text: "Nov 10, 2026")
        }
    }
}

@available(macOS 14.0, iOS 17.0, visionOS 1.0, tvOS 17.0, watchOS 10.0, *)
@MainActor
enum Scenes {
    static var all: [Scene] {
        [
            Scene(id: "type-roles", title: "Type roles", note: "The six UI roles in Dynamic Type styles, the label role (capitals, tracked, secondary ink) and figures in monospaced digits.", width: 720,
                  view: AnyView(VStack(alignment: .leading, spacing: 12) {
                      Text("Label role").uiText(.label)
                      Text("Display").uiText(.display)
                      Text("Page title").uiText(.title)
                      Text("Section heading").uiText(.heading)
                      Text("Body text runs in the reading column and carries the values.").uiText(.body)
                      Text("Caption: metadata and notes in secondary ink.").uiText(.caption)
                      HStack(spacing: 24) {
                          Text("1,111").uiText(.body).uiFigure()
                          Text("8,888").uiText(.body).uiFigure()
                      }
                  })),
            Scene(id: "chips", title: "Outlined chips", note: "Words always present; neutral, emphasis (accent), the status roles and an app colour; an optional glyph.", width: 720,
                  view: AnyView(HStack(spacing: 12) {
                      OutlinedChip("Planned")
                      OutlinedChip("Open", tone: .emphasis)
                      OutlinedChip("Passing", tone: .positive, glyph: "checkmark.circle.fill")
                      OutlinedChip("Failing", tone: .negative, glyph: "xmark.octagon.fill")
                      OutlinedChip("Stale", tone: .warning, glyph: "exclamationmark.triangle.fill")
                      OutlinedChip("In progress", tone: .custom(.purple))
                  })),
            Scene(id: "cards", title: "Swiss card (the Hybrid)", note: "3 pt rule, label and chip, large title, secondary description, ink hairline, footer. Square, hairline border, no fill.", width: 760,
                  view: AnyView(HStack(alignment: .top, spacing: 16) {
                      SwissCard(label: "#13", title: "Design tokens & theming",
                                description: "Shared colour, type and spacing tokens for every app.",
                                chip: { OutlinedChip("Open", tone: .emphasis) },
                                footer: { SwissCardFooter("Builds on", names: "SwiftCLIKit + SwiftGUIKit") })
                      SwissCard(label: "#14", title: "Quality gate dashboard",
                                description: "Portfolio health in one window.",
                                chip: { OutlinedChip("Planned") })
                  })),
            Scene(id: "keyvalue", title: "Section and key/value rows", note: "A 3 pt rule and heading; label in columns 1-3, value in 4-10, hairline above each row. Below: the same rows in a narrow container, stacked.", width: 760,
                  view: AnyView(VStack(alignment: .leading, spacing: 24) {
                      SwissSection("Orientation") {
                          KeyValueList {
                              KeyValueRow("Version", text: "0.10.0")
                              KeyValueRow("Last commit", text: "Nov 10, 2026")
                              KeyValueRow("Platforms", text: "macOS 14, iOS 17, visionOS 1")
                              KeyValueRow("Gate") { OutlinedChip("Passing", tone: .positive, glyph: "checkmark.circle.fill") }
                          }
                      }
                      StackedRow().frame(width: 300)
                  })),
            Scene(id: "segmented", title: "Segmented control", note: "Control radius, ink border, label role; the selected segment is ink with text measured to read on it.", width: 520,
                  view: AnyView(SegmentedDemo())),
            Scene(id: "banner", title: "Status banners", note: "A status fill, a glyph and words; text chosen by measured contrast against the fill in this appearance.", width: 640,
                  view: AnyView(VStack(spacing: 8) {
                      StatusBanner(.positive, text: "Healthy · 100% passing")
                      StatusBanner(.warning, text: "Passing, not all confirmed")
                      StatusBanner(.negative, text: "Failing · 38% passing")
                      StatusBanner(.neutral, text: "No projects")
                  })),
            Scene(id: "table", title: "Swiss table", note: "Header in the label role over an ink hairline; neutral hairline rows; a sortable header; figures in monospaced digits.", width: 760,
                  view: AnyView(TableDemo())),
            Scene(id: "native-table", title: "Native Table with swissTableStyle()", note: "What a native Table can take: no zebra, no scroll background, our cells. Its header stays the system's.", width: 520,
                  view: AnyView(NativeTableDemo())),
            Scene(id: "form", title: "Form controls", note: "SwissFormStyle, SwissLabeledContentStyle, SwissToggleStyle and SwissTextField; SwissSection in place of a Section header.", width: 520,
                  view: AnyView(FormDemo())),
        ]
    }
}
#endif
