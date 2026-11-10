#if canImport(SwiftUI)
import DesignTokens
import SwiftUI
#if canImport(AppKit)
import AppKit
#endif

/// Places its subviews on the grid, one per span, tops aligned.
@available(macOS 14.0, iOS 17.0, visionOS 1.0, tvOS 17.0, watchOS 10.0, *)
private struct GridRowLayout: Layout {
    let spans: [Int]
    let grid: SwissGrid

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        let frames = SwissTableGeometry.frames(spans: spans, total: width, grid: grid)
        var height: CGFloat = 0
        for (index, subview) in subviews.enumerated() where index < frames.count {
            height = max(height, subview.sizeThatFits(ProposedViewSize(width: frames[index].width, height: nil)).height)
        }
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let frames = SwissTableGeometry.frames(spans: spans, total: bounds.width, grid: grid)
        for (index, subview) in subviews.enumerated() where index < frames.count {
            subview.place(at: CGPoint(x: bounds.minX + frames[index].x, y: bounds.minY), anchor: .topLeading,
                          proposal: ProposedViewSize(width: frames[index].width, height: bounds.height))
        }
    }
}

/// What a ``SwissTable`` does below its minimum width.
@available(macOS 14.0, iOS 17.0, visionOS 1.0, tvOS 17.0, watchOS 10.0, *)
public enum SwissTableNarrow: Sendable, Hashable {
    /// Stack each row: its first column as the title and the others as label and value pairs under it. The default.
    case stack
    /// Scroll horizontally at the minimum width (0.10.0's behaviour).
    case scroll
}

/// A table's selection, single or multiple, over the row ids.
@available(macOS 14.0, iOS 17.0, visionOS 1.0, tvOS 17.0, watchOS 10.0, *)
fileprivate enum SwissTableSelection<ID: Hashable> {
    case single(Binding<ID?>)
    case multiple(Binding<Set<ID>>)

    var ids: Set<ID> {
        switch self {
        case .single(let binding): binding.wrappedValue.map { [$0] } ?? []
        case .multiple(let binding): binding.wrappedValue
        }
    }

    var isMultiple: Bool {
        if case .multiple = self { return true }
        return false
    }

    func set(_ ids: Set<ID>) {
        switch self {
        case .single(let binding): binding.wrappedValue = ids.first
        case .multiple(let binding): binding.wrappedValue = ids
        }
    }
}

/// Reports where each cell lands, for a test: off unless a test turns it on.
struct SwissTableProbeKey: PreferenceKey {
    static let defaultValue: [String: CGRect] = [:]
    static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) {
        value.merge(nextValue()) { _, new in new }
    }
}

private struct SwissTableProbeFlag: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var swissTableProbe: Bool {
        get { self[SwissTableProbeFlag.self] }
        set { self[SwissTableProbeFlag.self] = newValue }
    }
}

@available(macOS 14.0, iOS 17.0, visionOS 1.0, tvOS 17.0, watchOS 10.0, *)
struct CellProbe: ViewModifier {
    let key: String
    @Environment(\.swissTableProbe) private var enabled

    func body(content: Content) -> some View {
        if enabled {
            content.background(GeometryReader { proxy in
                Color.clear.preference(key: SwissTableProbeKey.self, value: [key: proxy.frame(in: .global)])
            })
        } else {
            content
        }
    }
}

/// A table on the 12-column grid, with none of the system's header or row chrome: the header in the label role over an ink
/// hairline, rows separated by neutral hairlines, no zebra, number columns in monospaced digits, a sortable header, optional selection,
/// copy and disclosure rows. Lazy, and the same on every platform; below a width, or at an accessibility text size, its rows stack
/// (see ``SwissTableNarrow``) so a phone gets a list of small cards rather than twelve crushed columns.
///
/// A native `Table`'s header cannot be styled (see ``SwiftUI/View/swissTableStyle()``), which is why this exists.
///
/// ```swift
/// struct Project: Identifiable { let id: Int; let name: String; let tests: Int }
/// let projects = [Project(id: 1, name: "swift-oauth", tests: 460), Project(id: 2, name: "DesignTokens", tests: 440)]
/// let table = SwissTable(projects, columns: [
///     SwissTableColumn("Project", id: "name", span: 6, sortBy: \.name, text: { $0.name }),
///     SwissTableColumn("Tests", id: "tests", span: 3, isFigure: true, sortBy: \.tests, text: { String($0.tests) }),
/// ], selection: .constant(Set<Int>()), sort: .constant(nil))
/// ```
@available(macOS 14.0, iOS 17.0, visionOS 1.0, tvOS 17.0, watchOS 10.0, *)
public struct SwissTable<Row: Identifiable>: View {
    private let rows: [Row]
    private let columns: [SwissTableColumn<Row>]
    private let sort: Binding<SwissTableSort?>?
    private let children: KeyPath<Row, [Row]?>?
    private let expandedBinding: Binding<Set<Row.ID>>?
    private let selection: SwissTableSelection<Row.ID>?
    private let minimumWidth: CGFloat?
    private let narrow: SwissTableNarrow
    @State private var ownExpanded: Set<Row.ID> = []
    @Environment(\.dynamicTypeSize) private var typeSize

    private init(rows: [Row], columns: [SwissTableColumn<Row>], sort: Binding<SwissTableSort?>?, children: KeyPath<Row, [Row]?>?,
                 expanded: Binding<Set<Row.ID>>?, selection: SwissTableSelection<Row.ID>?, minimumWidth: CGFloat?,
                 narrow: SwissTableNarrow) {
        self.rows = rows
        self.columns = columns
        self.sort = sort
        self.children = children
        self.expandedBinding = expanded
        self.selection = selection
        self.minimumWidth = minimumWidth
        self.narrow = narrow
    }

    /// Creates a table without selection.
    ///
    /// - Parameters:
    ///   - rows: The rows. When a column has a `compare` and `sort` is set, the table orders them (the rows of each group in a tree);
    ///     otherwise they are shown in the order given.
    ///   - columns: The columns; their spans together fit in 12 (``SwissTableGeometry/isValid(spans:columns:)``).
    ///   - sort: The sort the header shows and changes, or `nil` for a table whose headers are not buttons.
    ///   - children: Where a row's children are, for disclosure rows; a row whose value is `nil` is a leaf. `nil` for a flat table.
    ///   - expanded: The ids of the open groups, or `nil` to let the table keep them.
    ///   - minimumWidth: The width under which the table stacks (or scrolls), or `nil` for ``SwissMetrics/tableStackedBelow``.
    ///   - narrow: What happens under that width.
    public init(_ rows: [Row], columns: [SwissTableColumn<Row>], sort: Binding<SwissTableSort?>? = nil,
                children: KeyPath<Row, [Row]?>? = nil, expanded: Binding<Set<Row.ID>>? = nil,
                minimumWidth: CGFloat? = nil, narrow: SwissTableNarrow = .stack) {
        self.init(rows: rows, columns: columns, sort: sort, children: children, expanded: expanded, selection: nil,
                  minimumWidth: minimumWidth, narrow: narrow)
    }

    /// Creates a table with single selection: a tap or the arrow keys choose a row; the row says it is selected to VoiceOver.
    public init(_ rows: [Row], columns: [SwissTableColumn<Row>], selection: Binding<Row.ID?>,
                sort: Binding<SwissTableSort?>? = nil, children: KeyPath<Row, [Row]?>? = nil,
                expanded: Binding<Set<Row.ID>>? = nil, minimumWidth: CGFloat? = nil, narrow: SwissTableNarrow = .stack) {
        self.init(rows: rows, columns: columns, sort: sort, children: children, expanded: expanded,
                  selection: .single(selection), minimumWidth: minimumWidth, narrow: narrow)
    }

    /// Creates a table with multiple selection: a click selects a row, command or shift toggles it (any tap toggles on a touch screen),
    /// and command-C or the context menu copies the selected rows as tab-separated text.
    public init(_ rows: [Row], columns: [SwissTableColumn<Row>], selection: Binding<Set<Row.ID>>,
                sort: Binding<SwissTableSort?>? = nil, children: KeyPath<Row, [Row]?>? = nil,
                expanded: Binding<Set<Row.ID>>? = nil, minimumWidth: CGFloat? = nil, narrow: SwissTableNarrow = .stack) {
        self.init(rows: rows, columns: columns, sort: sort, children: children, expanded: expanded,
                  selection: .multiple(selection), minimumWidth: minimumWidth, narrow: narrow)
    }

    // MARK: State

    private var expanded: Set<Row.ID> { expandedBinding?.wrappedValue ?? ownExpanded }

    private func setExpanded(_ ids: Set<Row.ID>) {
        if let expandedBinding { expandedBinding.wrappedValue = ids } else { ownExpanded = ids }
    }

    private func toggle(_ id: Row.ID) {
        var next = expanded
        if next.contains(id) { next.remove(id) } else { next.insert(id) }
        setExpanded(next)
    }

    private var entries: [SwissTableEntry<Row>] {
        SwissTableTree.flatten(rows, children: children, expanded: expanded) {
            SwissTableSorting.sorted($0, columns: columns, by: sort?.wrappedValue)
        }
    }

    /// The space inside a row's edges when rows can be selected, so the selection's accent bar and fill sit around the content, not on it.
    private func rowInset(_ metrics: SwissMetrics) -> CGFloat { selection != nil ? metrics.step(2) : 0 }

    private var stacksAtThisSize: Bool { narrow == .stack && typeSize.isAccessibilitySize }

    // MARK: Body

    /// The table.
    public var body: some View {
        ChartStyleReader { style in
            let metrics = SwissMetrics(theme: style.theme)
            let shown = entries
            container(metrics: metrics, style: style, entries: shown)
                .modifier(SelectionBehaviour(
                    isEnabled: selection != nil,
                    copyText: { selectedText(in: shown) },
                    move: { delta in move(delta, in: shown) },
                    open: { opens in openSelected(opens, in: shown) }))
        }
    }

    @ViewBuilder
    private func container(metrics: SwissMetrics, style: ChartStyle, entries: [SwissTableEntry<Row>]) -> some View {
        if stacksAtThisSize {
            stacked(style: style, metrics: metrics, entries: entries)
        } else if narrow == .stack {
            ViewThatFits(in: .horizontal) {
                wide(style: style, metrics: metrics, entries: entries).frame(minWidth: minimumWidth ?? metrics.tableStackedBelow)
                stacked(style: style, metrics: metrics, entries: entries)
            }
        } else if let minimumWidth {
            ViewThatFits(in: .horizontal) {
                wide(style: style, metrics: metrics, entries: entries).frame(minWidth: minimumWidth)
                ScrollView(.horizontal) { wide(style: style, metrics: metrics, entries: entries).frame(width: minimumWidth) }
            }
        } else {
            wide(style: style, metrics: metrics, entries: entries)
        }
    }

    // MARK: Wide

    private func wide(style: ChartStyle, metrics: SwissMetrics, entries: [SwissTableEntry<Row>]) -> some View {
        let spans = columns.map(\.span)
        return LazyVStack(alignment: .leading, spacing: 0, pinnedViews: []) {
            header(style: style, metrics: metrics, spans: spans)
            ForEach(entries) { entry in
                decorated(entry, style: style, metrics: metrics) {
                    VStack(spacing: 0) {
                        GridRowLayout(spans: spans, grid: metrics.grid) {
                            ForEach(columns) { column in
                                cell(column, entry: entry, metrics: metrics, style: style)
                            }
                        }
                        .padding(.vertical, metrics.step(2))
                        .padding(.horizontal, rowInset(metrics))
                        SwissRule(.hairline)
                    }
                }
            }
        }
        .accessibilityElement(children: .contain)
    }

    /// One cell. It is always a view, even when the app's cell draws nothing: the row places its subviews by position, and a cell that
    /// disappeared would move every column after it one place to the left.
    private func cell(_ column: SwissTableColumn<Row>, entry: SwissTableEntry<Row>, metrics: SwissMetrics, style: ChartStyle) -> some View {
        HStack(spacing: metrics.step(1)) {
            if column.id == columns.first?.id { leading(entry, metrics: metrics, style: style) }
            column.cell(entry.row)
                .uiText(.body)
                .modifier(FigureModifier(isFigure: column.isFigure))
                .modifier(CellProbe(key: "\(entry.id)/\(column.id)/content"))
        }
        .frame(maxWidth: .infinity, alignment: column.isFigure ? .trailing : .leading)
        .modifier(CellProbe(key: "\(entry.id)/\(column.id)"))
    }

    /// The indent and disclosure control that lead the first column of a tree.
    @ViewBuilder
    private func leading(_ entry: SwissTableEntry<Row>, metrics: SwissMetrics, style: ChartStyle) -> some View {
        if children != nil {
            HStack(spacing: 0) {
                Color.clear.frame(width: CGFloat(entry.depth) * metrics.step(4), height: metrics.hairline)
                if entry.isGroup {
                    Button { toggle(entry.id) } label: {
                        Image(systemName: entry.isExpanded ? "chevron.down" : "chevron.right")
                            .imageScale(.small).foregroundStyle(style.ink)
                            .frame(width: metrics.step(5), height: metrics.step(5))
                            .swissTouchTarget(metrics)
                    }
                    .buttonStyle(.plain)
                    .accessibilityHidden(true)
                } else {
                    Color.clear.frame(width: metrics.step(5), height: metrics.hairline)
                }
            }
        }
    }

    // MARK: Stacked

    private func stacked(style: ChartStyle, metrics: SwissMetrics, entries: [SwissTableEntry<Row>]) -> some View {
        LazyVStack(alignment: .leading, spacing: 0, pinnedViews: []) {
            sortMenu(style: style, metrics: metrics)
            SwissRule(.hairline, tone: .ink)
            ForEach(entries) { entry in
                decorated(entry, style: style, metrics: metrics) {
                    VStack(alignment: .leading, spacing: 0) {
                        VStack(alignment: .leading, spacing: metrics.step(1)) {
                            if let first = columns.first {
                                HStack(spacing: metrics.step(1)) {
                                    leading(entry, metrics: metrics, style: style)
                                    first.cell(entry.row).uiText(.heading).modifier(FigureModifier(isFigure: first.isFigure))
                                }
                                .modifier(CellProbe(key: "\(entry.id)/\(first.id)"))
                            }
                            ForEach(columns.dropFirst()) { column in
                                if !(column.isEmpty?(entry.row) ?? false) { pair(column, entry: entry, metrics: metrics) }
                            }
                        }
                        .padding(.vertical, metrics.step(3))
                        .padding(.horizontal, rowInset(metrics))
                        SwissRule(.hairline)
                    }
                }
            }
        }
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private func pair(_ column: SwissTableColumn<Row>, entry: SwissTableEntry<Row>, metrics: SwissMetrics) -> some View {
        let value = column.cell(entry.row).uiText(.body).modifier(FigureModifier(isFigure: column.isFigure))
            .modifier(CellProbe(key: "\(entry.id)/\(column.id)"))
        if typeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: metrics.step(1)) {
                Text(column.title).uiText(.label).fixedSize(horizontal: false, vertical: true)
                value
            }
        } else {
            HStack(alignment: .firstTextBaseline, spacing: metrics.step(2)) {
                Text(column.title).uiText(.label).fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: metrics.step(2))
                value
            }
        }
    }

    /// The header's sort buttons have no row of headers to sit in when rows are stacked, so the choice is a menu above them.
    @ViewBuilder
    private func sortMenu(style: ChartStyle, metrics: SwissMetrics) -> some View {
        let sortable = columns.filter(\.isSortable)
        if let sort, !sortable.isEmpty {
            let current = sort.wrappedValue
            Menu {
                ForEach(sortable) { column in
                    Button {
                        sort.wrappedValue = SwissTableSort.toggled(sort.wrappedValue, on: column.id)
                    } label: {
                        if current?.column == column.id {
                            Label(column.title, systemImage: current?.ascending == true ? "chevron.up" : "chevron.down")
                        } else {
                            Text(column.title)
                        }
                    }
                }
            } label: {
                HStack(spacing: metrics.step(1)) {
                    Text(sortLabel(current)).uiText(.label, ink: .ink)
                    Image(systemName: "chevron.up.chevron.down").imageScale(.small).foregroundStyle(style.ink)
                }
                .padding(.bottom, metrics.step(2))
                .swissTouchTarget(metrics)
            }
            .menuStyle(.button)
            .buttonStyle(.plain)
            .accessibilityLabel("Sort by")
            .accessibilityValue(sortLabel(current))
        }
    }

    private func sortLabel(_ current: SwissTableSort?) -> String {
        guard let current, let column = columns.first(where: { $0.id == current.column }) else { return "Sort by" }
        return "Sort by \(column.title)"
    }

    // MARK: Header

    private func header(style: ChartStyle, metrics: SwissMetrics, spans: [Int]) -> some View {
        VStack(spacing: 0) {
            GridRowLayout(spans: spans, grid: metrics.grid) {
                ForEach(columns) { column in
                    headerCell(column, style: style)
                }
            }
            .padding(.bottom, metrics.step(2))
            .padding(.horizontal, rowInset(metrics))
            SwissRule(.hairline, tone: .ink)
        }
    }

    @ViewBuilder
    private func headerCell(_ column: SwissTableColumn<Row>, style: ChartStyle) -> some View {
        let alignment: Alignment = column.isFigure ? .trailing : .leading
        let current = sort?.wrappedValue
        let words = SwissTableSort.description(title: column.title, column: column.id, sort: current)
        if column.isSortable, let sort {
            Button { sort.wrappedValue = SwissTableSort.toggled(sort.wrappedValue, on: column.id) } label: {
                HStack(spacing: SwissMetrics(theme: style.theme).step(1)) {
                    Text(column.title).uiText(.label)
                    if current?.column == column.id {
                        Image(systemName: current?.ascending == true ? "chevron.up" : "chevron.down")
                            .imageScale(.small).foregroundStyle(style.ink).accessibilityHidden(true)
                    }
                }
                .frame(maxWidth: .infinity, alignment: alignment)
                .swissTouchTarget(SwissMetrics(theme: style.theme))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(words)
            .accessibilityAddTraits(.isHeader)
        } else {
            Text(column.title).uiText(.label)
                .frame(maxWidth: .infinity, alignment: alignment)
                .accessibilityAddTraits(.isHeader)
        }
    }

    // MARK: Row chrome, selection and copy

    private func decorated<Inner: View>(_ entry: SwissTableEntry<Row>, style: ChartStyle, metrics: SwissMetrics,
                                        @ViewBuilder inner: () -> Inner) -> some View {
        let selected = selection?.ids.contains(entry.id) ?? false
        return inner()
            .background(selected ? style.rule : Color.clear)
            .overlay(alignment: .leading) {
                if selected { Rectangle().fill(style.accent).frame(width: metrics.sectionRule) }
            }
            .contentShape(Rectangle())
            .onTapGesture { tap(entry.id) }
            .contextMenu {
                if selection != nil {
                    Button("Copy") { SwissTableCopy.write(selectedText(in: entries, including: entry.id)) }
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(selected ? .isSelected : [])
            .accessibilityValue(entry.isGroup ? (entry.isExpanded ? "expanded" : "collapsed") : "")
            .accessibilityActions {
                if entry.isGroup { Button(entry.isExpanded ? "Collapse" : "Expand") { toggle(entry.id) } }
            }
    }

    private func tap(_ id: Row.ID) {
        guard let selection else { return }
        selection.set(SwissTableSelectionRule.tapped(id, current: selection.ids, multiple: selection.isMultiple, extend: extendsSelection))
    }

    private var extendsSelection: Bool {
        #if os(macOS)
        let flags = NSEvent.modifierFlags
        return flags.contains(.command) || flags.contains(.shift)
        #else
        return true
        #endif
    }

    private func selectedText(in entries: [SwissTableEntry<Row>], including extra: Row.ID? = nil) -> String {
        var ids = selection?.ids ?? []
        if let extra, !ids.contains(extra) { ids = [extra] }
        let chosen = entries.filter { ids.contains($0.id) }.map(\.row)
        return SwissTableCopy.text(rows: chosen, columns: columns)
    }

    private func move(_ delta: Int, in entries: [SwissTableEntry<Row>]) -> Bool {
        guard let selection, let target = SwissTableSelectionRule.moved(from: selection.ids, by: delta, order: entries.map(\.id)) else { return false }
        selection.set([target])
        return true
    }

    private func openSelected(_ opens: Bool, in entries: [SwissTableEntry<Row>]) -> Bool {
        guard let selection, let id = selection.ids.first, let entry = entries.first(where: { $0.id == id }),
              entry.isGroup, entry.isExpanded != opens else { return false }
        toggle(id)
        return true
    }
}

/// Focus, the arrow keys, command-C and Edit > Copy for a table with a selection.
@available(macOS 14.0, iOS 17.0, visionOS 1.0, tvOS 17.0, watchOS 10.0, *)
private struct SelectionBehaviour: ViewModifier {
    let isEnabled: Bool
    let copyText: () -> String
    let move: (Int) -> Bool
    let open: (Bool) -> Bool

    func body(content: Content) -> some View {
        if isEnabled {
            content
                .focusable()
                .focusEffectDisabled()
                .onKeyPress(.downArrow) { move(1) ? .handled : .ignored }
                .onKeyPress(.upArrow) { move(-1) ? .handled : .ignored }
                .onKeyPress(.rightArrow) { open(true) ? .handled : .ignored }
                .onKeyPress(.leftArrow) { open(false) ? .handled : .ignored }
                .onKeyPress(characters: CharacterSet(charactersIn: "c"), phases: .down) { press in
                    guard press.modifiers.contains(.command) else { return .ignored }
                    SwissTableCopy.write(copyText())
                    return .handled
                }
                .copyable([copyText()])
        } else {
            content
        }
    }
}

@available(macOS 14.0, iOS 17.0, visionOS 1.0, tvOS 17.0, watchOS 10.0, *)
private struct FigureModifier: ViewModifier {
    let isFigure: Bool
    func body(content: Content) -> some View {
        if isFigure { content.uiFigure() } else { content }
    }
}

@available(macOS 14.0, iOS 17.0, visionOS 1.0, tvOS 17.0, watchOS 10.0, *)
public extension View {
    /// What can be set on a native `Table`: no alternating row backgrounds (macOS) and no scroll-view background, so the page shows
    /// through. Cell content is the app's own views and takes ``uiText(_:)`` and ``uiFigure()``.
    ///
    /// What cannot: the header bar, its column dividers and its text. `TableColumn`'s title is a string, not a view (there is no
    /// `Text` overload), and the header is the system's own control, so it takes no type role. Where the design needs a Swiss
    /// header, use ``SwissTable``. On iPhone a native `Table` shows only its first column.
    func swissTableStyle() -> some View {
        #if os(macOS)
        tableStyle(.inset(alternatesRowBackgrounds: false)).scrollContentBackground(.hidden)
        #else
        scrollContentBackground(.hidden)
        #endif
    }
}
#endif
