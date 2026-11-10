#if canImport(SwiftUI)
import DesignTokens
import DesignTokensSwiftUI
import SwiftUI

/// One thing to render: a name, a caption, a width and the view.
@available(macOS 14.0, iOS 17.0, visionOS 1.0, tvOS 17.0, watchOS 10.0, *)
public struct GalleryScene {
    /// The file name stem.
    public let id: String
    /// The heading in the index.
    public let title: String
    /// The caption in the index.
    public let note: String
    /// The width the scene is drawn at on a Mac; the simulator runs draw it at the device's width.
    public let width: CGFloat
    /// The scene.
    public let view: AnyView
}

@available(macOS 14.0, iOS 17.0, visionOS 1.0, tvOS 17.0, watchOS 10.0, *)
struct Row: Identifiable {
    let id: Int
    let name: String
    let status: String
    let count: Int
}

@available(macOS 14.0, iOS 17.0, visionOS 1.0, tvOS 17.0, watchOS 10.0, *)
struct Node: Identifiable {
    let id: Int
    let name: String
    let health: Int?
    let tests: Int
    var children: [Node]?
}

@available(macOS 14.0, iOS 17.0, visionOS 1.0, tvOS 17.0, watchOS 10.0, *)
private enum Sample {
    static var rows: [Row] { [Row(id: 1, name: "swift-oauth", status: "Passing", count: 460),
                    Row(id: 2, name: "SwiftMCPClient", status: "Failing", count: 474),
                    Row(id: 3, name: "DesignTokens", status: "Passing", count: 440),
                    Row(id: 4, name: "BusinessMath-UI", status: "Stale", count: 1_212)] }

    static var portfolio: [Node] { [
    Node(id: 1, name: "Tools", health: nil, tests: 2_100, children: [
        Node(id: 11, name: "DesignTokens", health: 100, tests: 440, children: nil),
        Node(id: 12, name: "swift-oauth", health: 96, tests: 460, children: nil),
        Node(id: 13, name: "SwiftMCPClient", health: 71, tests: 474, children: nil),
    ]),
    Node(id: 2, name: "Playgrounds", health: nil, tests: 1_212, children: [
        Node(id: 21, name: "BusinessMath-UI", health: 88, tests: 1_212, children: nil),
    ]),
    Node(id: 3, name: "justinpurnell.com", health: 100, tests: 36, children: nil),
    ] }
}

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
        SwissTable(Sample.rows, columns: [
            SwissTableColumn("Project", id: "name", span: 5, sortBy: \.name, text: { $0.name }),
            SwissTableColumn("Status", id: "status", span: 3, isSortable: true) { row in
                OutlinedChip(row.status, tone: row.status == "Failing" ? .negative : row.status == "Stale" ? .warning : .neutral)
            },
            SwissTableColumn("Tests", id: "count", span: 4, isFigure: true, sortBy: \.count, text: { String($0.count) }),
        ], sort: $sort)
    }
}

/// A tree of projects with multiple selection, a sort, and a column that draws nothing on the group rows.
@available(macOS 14.0, iOS 17.0, visionOS 1.0, tvOS 17.0, watchOS 10.0, *)
private struct TreeDemo: View {
    @State private var sort: SwissTableSort? = SwissTableSort(column: "tests", ascending: false)
    @State private var selection: Set<Int> = [12, 21]
    @State private var expanded: Set<Int> = [1, 2]
    var body: some View {
        SwissTable(Sample.portfolio, columns: [
            SwissTableColumn("Project", id: "name", span: 5, sortBy: \.name, text: { $0.name }),
            SwissTableColumn("Health", id: "health", span: 4, isSortable: true, copy: { $0.health.map { "\($0)%" } ?? "" },
                             isEmpty: { $0.health == nil }) { node in
                if let health = node.health {
                    OutlinedChip("\(health)%", tone: health >= 95 ? .positive : health >= 80 ? .caution : .warning)
                }
            },
            SwissTableColumn("Tests", id: "tests", span: 3, isFigure: true, sortBy: \.tests, text: { String($0.tests) }),
        ], selection: $selection, sort: $sort, children: \.children, expanded: $expanded)
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
        Table(Sample.rows) {
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
            KeyValueRow("Version", text: "0.11.0")
            KeyValueRow("Last commit", text: "Nov 10, 2026")
        }
    }
}

/// The type roles, each with the size the platform resolves it to.
@available(macOS 14.0, iOS 17.0, visionOS 1.0, tvOS 17.0, watchOS 10.0, *)
private struct HierarchyDemo: View {
    private let roles: [(String, UIRole, String)] = [
        ("Display", .display, "display"), ("Page title", .title, "title"), ("Section heading", .section, "section"),
        ("Card title", .cardTitle, "cardTitle"), ("Row heading", .heading, "heading"),
        ("A value runs in the body role", .body, "body"), ("A caption in secondary ink", .caption, "caption"), ("Row label", .label, "label"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(roles, id: \.2) { text, role, name in
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text(text).uiText(role)
                    Spacer(minLength: 8)
                    Text("\(name) \(UITextSpec(role, theme: .swiss).pointSize.map { String(Int($0)) } ?? "?") pt").uiText(.caption).uiFigure()
                }
            }
        }
    }
}

/// A section, a card, a row of values: the hierarchy as a page uses it.
@available(macOS 14.0, iOS 17.0, visionOS 1.0, tvOS 17.0, watchOS 10.0, *)
private struct PageDemo: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Portfolio").uiText(.title)
            SwissSection("Summary") {
                KeyValueList {
                    KeyValueRow("Projects", text: "47")
                    KeyValueRow("Passing", text: "38")
                }
            }
            SwissEqualGrid(minimumColumnWidth: 220) {
                SwissCard(label: "#13", title: "Design tokens", description: "Shared colour, type and spacing.",
                          chip: { OutlinedChip("Open", tone: .emphasis) },
                          footer: { SwissCardFooter("Builds on", names: "SwiftCLIKit") })
            }
            .swissCardChrome(.borderless)
        }
    }
}

@available(macOS 14.0, iOS 17.0, visionOS 1.0, tvOS 17.0, watchOS 10.0, *)
private struct GapCards: View {
    private let names = ["SwiftCLIKit", "SwiftGUIKit", "SwiftOAuth", "SwiftMCPServer", "BusinessMath", "DesignTokens"]
    var body: some View {
        SwissEqualGrid(minimumColumnWidth: 230) {
            card("#1", "Design tokens & theming", "Shared colour, type and spacing tokens for every app.", "Open", .emphasis, ["SwiftCLIKit", "SwiftGUIKit"])
            card("#2", "Quality gate dashboard", "Portfolio health in one window, with a long description that wraps onto several lines to make this card the tallest in its row.", "In progress", .caution, names)
            card("#3", "OAuth", "Full OAuth 2.1.", "Closed", .neutral, ["SwiftMCPServer"])
            card("#4", "Terminal kit", "A shorter one.", "Planned", .neutral, ["SwiftCLIKit"])
            card("#5", "The lone last card", "Keeps the width of the others.", "Open", .emphasis, ["DesignTokens", "BusinessMath"])
        }
        .swissCardChrome(.borderless)
    }

    private func card(_ label: String, _ title: String, _ text: String, _ state: String, _ tone: ChipTone, _ builds: [String]) -> some View {
        SwissCard(label: label, title: title, description: text,
                  chip: { OutlinedChip(state, tone: tone) },
                  footer: {
                      SwissCardFooter("Builds on") {
                          ForEach(builds, id: \.self) { Text($0).uiText(.caption, ink: .ink).fontWeight(.bold) }
                      }
                  })
    }
}

@available(macOS 14.0, iOS 17.0, visionOS 1.0, tvOS 17.0, watchOS 10.0, *)
private struct FlowDemo: View {
    private let tags = ["macOS", "iOS", "iPadOS", "visionOS", "watchOS", "tvOS", "Linux", "Windows", "Mac Catalyst"]
    var body: some View {
        SwissFlow { ForEach(tags, id: \.self) { OutlinedChip($0) } }
    }
}

@available(macOS 14.0, iOS 17.0, visionOS 1.0, tvOS 17.0, watchOS 10.0, *)
private struct DynamicColourDemo: View {
    var body: some View {
        HStack(spacing: 16) {
            Text("Warning (the alert extra)").uiText(.heading, ink: .custom(Theme.textSafeAlert.dynamicColor))
            Text("Caution (the warning role)").uiText(.heading, ink: .custom(Theme.swiss.palette.warning.dynamicColor))
            Text("Positive").uiText(.heading, ink: .custom(Theme.swiss.palette.positive.dynamicColor))
            Text("Negative").uiText(.heading, ink: .custom(Theme.swiss.palette.negative.dynamicColor))
        }
    }
}

/// Every scene the gallery draws.
@MainActor
@available(macOS 14.0, iOS 17.0, visionOS 1.0, tvOS 17.0, watchOS 10.0, *)
public enum GalleryScenes {
    /// The scenes in order.
    public static var all: [GalleryScene] {
        [
            GalleryScene(id: "type-hierarchy", title: "Type hierarchy (this platform)", note: "Every UI role at the size this platform resolves it to, measured: the page title is the largest of the hierarchy, a section heading is clearly above a value, the card title is no larger than a section heading.", width: 720,
                         view: AnyView(HierarchyDemo())),
            GalleryScene(id: "type-page", title: "Type hierarchy in a page", note: "The roles as a page uses them: title, section heading over a rule, key/value rows (label and value), a borderless card with its title and caption.", width: 720,
                         view: AnyView(PageDemo())),
            GalleryScene(id: "type-compact", title: "Type hierarchy at a compact width", note: "The same roles in a 390 pt column (the Mac's sizes; the phone's measured sizes are in the simulator renders and the iOS test).", width: 390,
                         view: AnyView(HierarchyDemo())),
            GalleryScene(id: "type-roles", title: "Type roles", note: "The eight UI roles in Dynamic Type styles, the label role (capitals, tracked, secondary ink) and figures in monospaced digits.", width: 720,
                         view: AnyView(VStack(alignment: .leading, spacing: 12) {
                             Text("Label role").uiText(.label)
                             Text("Display").uiText(.display)
                             Text("Page title").uiText(.title)
                             Text("Section heading").uiText(.section)
                             Text("Card title").uiText(.cardTitle)
                             Text("Row heading").uiText(.heading)
                             Text("Body text runs in the reading column and carries the values.").uiText(.body)
                             Text("Caption: metadata and notes in secondary ink.").uiText(.caption)
                             HStack(spacing: 24) {
                                 Text("1,111").uiText(.body).uiFigure()
                                 Text("8,888").uiText(.body).uiFigure()
                             }
                         })),
            GalleryScene(id: "chips", title: "Outlined chips", note: "Square by default (the theme's container radius). Words always present; neutral, emphasis (accent), caution (yellow-brown) and warning (orange) apart, positive, negative, an app colour; an optional glyph. The last row is the 0.10.0 control radius.", width: 720,
                         view: AnyView(VStack(alignment: .leading, spacing: 12) {
                             HStack(spacing: 12) {
                                 OutlinedChip("Planned")
                                 OutlinedChip("Open", tone: .emphasis)
                                 OutlinedChip("Passing", tone: .positive, glyph: "checkmark.circle.fill")
                                 OutlinedChip("Failing", tone: .negative, glyph: "xmark.octagon.fill")
                                 OutlinedChip("In progress", tone: .custom(.purple))
                             }
                             HStack(spacing: 12) {
                                 OutlinedChip("Caution", tone: .caution, glyph: StatusKind.caution.glyph)
                                 OutlinedChip("Warning", tone: .warning, glyph: StatusKind.warning.glyph)
                                 OutlinedChip("Stale", tone: .status(.warning))
                             }
                             HStack(spacing: 12) {
                                 OutlinedChip("Control radius", shape: .control)
                                 OutlinedChip("Warning", tone: .warning, shape: .control)
                             }
                         })),
            GalleryScene(id: "dynamic-colour", title: "Dynamic colour from an Adaptive", note: "Adaptive.dynamicColor: a real Color that follows light and dark. The status colours as words, each a plain Color with no environment read; the same view in light and dark.", width: 720,
                         view: AnyView(DynamicColourDemo())),
            GalleryScene(id: "cards", title: "Swiss card (the Hybrid)", note: "3 pt rule, label and chip, card title, secondary description, ink hairline, footer. Square, hairline border, no fill.", width: 760,
                         view: AnyView(HStack(alignment: .top, spacing: 16) {
                             SwissCard(label: "#13", title: "Design tokens & theming",
                                       description: "Shared colour, type and spacing tokens for every app.",
                                       chip: { OutlinedChip("Open", tone: .emphasis) },
                                       footer: { SwissCardFooter("Builds on", names: "SwiftCLIKit + SwiftGUIKit") })
                             SwissCard(label: "#14", title: "Quality gate dashboard",
                                       description: "Portfolio health in one window.",
                                       chip: { OutlinedChip("Planned") })
                         })),
            GalleryScene(id: "cards-equal", title: "Borderless equal-height card rows", note: "SwissEqualGrid with borderless cards: rows as tall as their tallest card, footers pinned to the bottom so they line up across a row, a footer that wraps onto a second line (card 2), and a lone last card that keeps the column width.", width: 760,
                         view: AnyView(GapCards())),
            GalleryScene(id: "cards-equal-compact", title: "Equal-height cards at a phone width", note: "One column at 390 pt: each card as tall as its content.", width: 390,
                         view: AnyView(GapCards())),
            GalleryScene(id: "flow", title: "Flow layout", note: "SwissFlow wraps chips and tags onto new lines at the width.", width: 420,
                         view: AnyView(FlowDemo())),
            GalleryScene(id: "keyvalue", title: "Section and key/value rows", note: "A 3 pt rule and heading; label in columns 1-3, value in 4-10, hairline above each row. Below: the same rows in a narrow container, stacked.", width: 760,
                         view: AnyView(VStack(alignment: .leading, spacing: 24) {
                             SwissSection("Orientation") {
                                 KeyValueList {
                                     KeyValueRow("Version", text: "0.11.0")
                                     KeyValueRow("Last commit", text: "Nov 10, 2026")
                                     KeyValueRow("Platforms", text: "macOS 14, iOS 17, visionOS 1")
                                     KeyValueRow("Gate") { OutlinedChip("Passing", tone: .positive, glyph: "checkmark.circle.fill") }
                                 }
                             }
                             StackedRow().frame(width: 300)
                         })),
            GalleryScene(id: "segmented", title: "Segmented control", note: "Control radius, ink border, label role, one line per segment; the selected segment is ink with text measured to read on it.", width: 520,
                         view: AnyView(SegmentedDemo())),
            GalleryScene(id: "segmented-menu", title: "Segmented control at an accessibility size", note: "At an accessibility text size, or where the words would not fit on one line each, the control becomes a bordered menu button with the same title and value: no broken words. Top: accessibility3 at 520 pt (a Mac does not scale its text; the phone renders do). Bottom: a normal size in 150 pt, where the title drops before a word would break.", width: 520,
                         view: AnyView(VStack(alignment: .leading, spacing: 16) {
                             SegmentedDemo().environment(\.dynamicTypeSize, .accessibility3)
                             SegmentedDemo().frame(width: 150)
                         })),
            GalleryScene(id: "banner", title: "Status banners", note: "A status fill, a glyph and words; text chosen by measured contrast against the fill in this appearance. Caution and warning are two colours.", width: 640,
                         view: AnyView(VStack(spacing: 8) {
                             StatusBanner(.positive, text: "Healthy · 100% passing")
                             StatusBanner(.caution, text: "Passing, not all confirmed")
                             StatusBanner(.warning, text: "Refresh failed, showing data from 2 days ago")
                             StatusBanner(.negative, text: "Failing · 38% passing")
                             StatusBanner(.neutral, text: "No projects")
                         })),
            GalleryScene(id: "table", title: "Swiss table", note: "Header in the label role over an ink hairline; neutral hairline rows; sortable headers that sort the rows themselves (sortBy); figures in monospaced digits.", width: 760,
                         view: AnyView(TableDemo())),
            GalleryScene(id: "table-tree", title: "Table: selection, tree rows, empty cells", note: "Multiple selection (the rule colour fill and an accent bar; command-click toggles, command-C copies), disclosure rows with indent, and a Health cell that draws nothing on the group rows without moving the Tests column.", width: 760,
                         view: AnyView(TreeDemo())),
            GalleryScene(id: "table-compact", title: "Table at a phone width", note: "Under 600 pt the rows stack: the first column is the row's title and the others are label and value pairs, with the sort in a menu above. Selection and disclosure still work.", width: 390,
                         view: AnyView(TreeDemo())),
            GalleryScene(id: "table-accessibility", title: "Table at an accessibility size", note: "At accessibility3 the rows stack even in a wide window, and each label sits above its value.", width: 760,
                         view: AnyView(TreeDemo().environment(\.dynamicTypeSize, .accessibility3))),
            GalleryScene(id: "native-table", title: "Native Table with swissTableStyle()", note: "What a native Table can take: no zebra, no scroll background, our cells. Its header stays the system's.", width: 520,
                         view: AnyView(NativeTableDemo())),
            GalleryScene(id: "form", title: "Form controls", note: "SwissFormStyle, SwissLabeledContentStyle, SwissToggleStyle and SwissTextField; SwissSection in place of a Section header.", width: 520,
                         view: AnyView(FormDemo())),
        ]
    }
}
#endif

#if canImport(SwiftUI)
/// Paints the active theme's background behind a scene.
@available(macOS 14.0, iOS 17.0, visionOS 1.0, tvOS 17.0, watchOS 10.0, *)
public struct GalleryBackground: View {
    /// Creates the background.
    public init() {}

    /// The background.
    public var body: some View {
        ChartStyleReader { style in style.background }
    }
}
#endif
