#if canImport(SwiftUI)
import DesignTokens
import SwiftUI

/// The Hybrid card of the design system: a 3 pt ink rule across the top, a small label and an outlined-chip slot, the title large,
/// a secondary-ink description, and a footer set off by an ink hairline ("Builds on ...").
///
/// Square (the container radius), a hairline border in the neutral `rule` colour (or none: ``SwiftUI/View/swissCardChrome(_:)``),
/// no fill (the page is the surface), no shadow, no dashed edge. State is the chip and its words, never a tinted or dashed card.
/// VoiceOver reads it as a container whose children are still reachable, so a button in the footer is.
///
/// In a ``SwissEqualGrid`` the card is offered its row's height and pins the footer to the bottom edge, so footers line up across a
/// row. Anywhere else it is as tall as its content.
///
/// ```swift
/// SwissCard(label: "#13", title: "Design tokens", description: "Shared colour, type and spacing.",
///           chip: { OutlinedChip("Open", tone: .emphasis) },
///           footer: { SwissCardFooter("Builds on", names: "SwiftCLIKit + SwiftGUIKit") })
/// ```
@available(macOS 14.0, iOS 17.0, visionOS 1.0, tvOS 17.0, watchOS 10.0, *)
public struct SwissCard<Chip: View, Footer: View>: View {
    private let label: String?
    private let title: String
    private let description: String?
    private let chip: Chip
    private let footer: Footer
    private let hasChip: Bool
    private let hasFooter: Bool
    @Environment(\.swissCardChrome) private var chrome
    @Environment(\.swissFillsHeight) private var fillsHeight

    fileprivate init(label: String?, title: String, description: String?, chip: Chip, hasChip: Bool, footer: Footer, hasFooter: Bool) {
        self.label = label
        self.title = title
        self.description = description
        self.chip = chip
        self.footer = footer
        self.hasChip = hasChip
        self.hasFooter = hasFooter
    }

    /// Creates a card with a chip and a footer.
    public init(label: String? = nil, title: String, description: String? = nil,
                @ViewBuilder chip: () -> Chip, @ViewBuilder footer: () -> Footer) {
        self.init(label: label, title: title, description: description, chip: chip(), hasChip: true, footer: footer(), hasFooter: true)
    }

    /// The card.
    public var body: some View {
        ChartStyleReader { style in
            let metrics = SwissMetrics(theme: style.theme)
            let inset = chrome == .bordered ? metrics.step(3) : 0
            VStack(alignment: .leading, spacing: 0) {
                SwissRule(.section, tone: .ink)
                VStack(alignment: .leading, spacing: metrics.step(3)) {
                    if label != nil || hasChip {
                        HStack(alignment: .firstTextBaseline, spacing: metrics.step(2)) {
                            if let label { Text(label).uiText(.label) }
                            Spacer(minLength: metrics.step(2))
                            if hasChip { chip }
                        }
                    }
                    Text(title).uiText(.cardTitle).fixedSize(horizontal: false, vertical: true)
                    if let description {
                        Text(description).uiText(.body, ink: .secondaryInk)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    if hasFooter {
                        // The spacer is what pins the footer: it takes whatever height the row gives beyond the content's. Only in
                        // an equal grid: a spacer anywhere else would stretch the card to the tallest of its neighbours.
                        if fillsHeight { Spacer(minLength: 0) }
                        VStack(alignment: .leading, spacing: metrics.step(2)) {
                            SwissRule(.hairline, tone: .ink)
                            footer
                        }
                        .padding(.top, metrics.step(1))
                    }
                }
                .padding(.horizontal, inset)
                .padding(.vertical, metrics.step(3))
                .frame(maxHeight: fillsHeight ? .infinity : nil, alignment: .top)
            }
            .frame(maxWidth: .infinity, maxHeight: fillsHeight ? .infinity : nil, alignment: .topLeading)
            .modifier(CardBorder(bordered: chrome == .bordered))
            .accessibilityElement(children: .contain)
        }
    }
}

/// Whether a ``SwissCard`` draws its hairline border.
@available(macOS 14.0, iOS 17.0, visionOS 1.0, tvOS 17.0, watchOS 10.0, *)
public enum SwissCardChrome: Sendable, Hashable {
    /// A hairline border in the `rule` colour around the card, and padding inside it (0.10.0's card).
    case bordered
    /// No border: the 3 pt top rule is the card's edge, and the text sits flush with the column (the Stack Map's gap cards).
    case borderless
}

@available(macOS 14.0, iOS 17.0, visionOS 1.0, tvOS 17.0, watchOS 10.0, *)
private struct CardChromeKey: EnvironmentKey {
    static let defaultValue = SwissCardChrome.bordered
}

@available(macOS 14.0, iOS 17.0, visionOS 1.0, tvOS 17.0, watchOS 10.0, *)
extension EnvironmentValues {
    var swissCardChrome: SwissCardChrome {
        get { self[CardChromeKey.self] }
        set { self[CardChromeKey.self] = newValue }
    }
}

@available(macOS 14.0, iOS 17.0, visionOS 1.0, tvOS 17.0, watchOS 10.0, *)
public extension View {
    /// Sets whether the ``SwissCard``s inside draw their hairline border. ``SwissCardChrome/borderless`` keeps the 3 pt top rule.
    func swissCardChrome(_ chrome: SwissCardChrome) -> some View {
        environment(\.swissCardChrome, chrome)
    }
}

@available(macOS 14.0, iOS 17.0, visionOS 1.0, tvOS 17.0, watchOS 10.0, *)
private struct CardBorder: ViewModifier {
    let bordered: Bool
    func body(content: Content) -> some View {
        if bordered { content.swissContainer() } else { content }
    }
}

@available(macOS 14.0, iOS 17.0, visionOS 1.0, tvOS 17.0, watchOS 10.0, *)
private struct ContainerModifier: ViewModifier {
    @Environment(\.theme) private var theme
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.colorSchemeContrast) private var contrast

    func body(content: Content) -> some View {
        let style = ChartStyle(theme: theme, colorScheme: colorScheme, contrast: contrast)
        let metrics = SwissMetrics(theme: theme)
        return content.overlay(metrics.containerShape.strokeBorder(style.rule, lineWidth: metrics.hairline))
    }
}

@available(macOS 14.0, iOS 17.0, visionOS 1.0, tvOS 17.0, watchOS 10.0, *)
public extension View {
    /// A container as the design draws it: the container shape (square in Swiss) with a hairline border in the neutral `rule`
    /// colour, and nothing else: no fill (the page is the surface), no shadow, no dashed edge. For a panel or a row that is not a
    /// ``SwissCard``.
    func swissContainer() -> some View {
        modifier(ContainerModifier())
    }
}

@available(macOS 14.0, iOS 17.0, visionOS 1.0, tvOS 17.0, watchOS 10.0, *)
public extension SwissCard where Chip == EmptyView {
    /// A card with a footer and no chip.
    init(label: String? = nil, title: String, description: String? = nil, @ViewBuilder footer: () -> Footer) {
        self.init(label: label, title: title, description: description, chip: EmptyView(), hasChip: false,
                  footer: footer(), hasFooter: true)
    }
}

@available(macOS 14.0, iOS 17.0, visionOS 1.0, tvOS 17.0, watchOS 10.0, *)
public extension SwissCard where Footer == EmptyView {
    /// A card with a chip and no footer.
    init(label: String? = nil, title: String, description: String? = nil, @ViewBuilder chip: () -> Chip) {
        self.init(label: label, title: title, description: description, chip: chip(), hasChip: true,
                  footer: EmptyView(), hasFooter: false)
    }
}

@available(macOS 14.0, iOS 17.0, visionOS 1.0, tvOS 17.0, watchOS 10.0, *)
public extension SwissCard where Chip == EmptyView, Footer == EmptyView {
    /// A card with neither a chip nor a footer.
    init(label: String? = nil, title: String, description: String? = nil) {
        self.init(label: label, title: title, description: description, chip: EmptyView(), hasChip: false,
                  footer: EmptyView(), hasFooter: false)
    }
}

/// The card's footer row: a label in secondary ink and the names after it in bold ink ("Builds on" and the packages), wrapping onto
/// further lines when they do not fit. The names may be any views, so a name can be a button.
@available(macOS 14.0, iOS 17.0, visionOS 1.0, tvOS 17.0, watchOS 10.0, *)
public struct SwissCardFooter<Names: View>: View {
    private let label: String
    private let names: Names

    /// Creates a footer row whose names are views (each is placed in the flow; a button is a name that selects).
    public init(_ label: String, @ViewBuilder names: () -> Names) {
        self.label = label
        self.names = names()
    }

    /// The row.
    public var body: some View {
        ChartStyleReader { style in
            let metrics = SwissMetrics(theme: style.theme)
            SwissFlowLayout(spacing: metrics.step(2), lineSpacing: metrics.step(1)) {
                Text(label).uiText(.caption)
                names
            }
        }
    }
}

@available(macOS 14.0, iOS 17.0, visionOS 1.0, tvOS 17.0, watchOS 10.0, *)
public extension SwissCardFooter where Names == AnyView {
    /// A footer row whose names are one string in bold ink.
    init(_ label: String, names: String) {
        self.init(label) { AnyView(Text(names).uiText(.caption, ink: .ink).fontWeight(.bold)) }
    }
}

/// A section: the 3 pt ink rule across its top, the heading under it, then its content.
@available(macOS 14.0, iOS 17.0, visionOS 1.0, tvOS 17.0, watchOS 10.0, *)
public struct SwissSection<Content: View>: View {
    private let title: String
    private let content: Content

    /// Creates a section.
    public init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    /// The section.
    public var body: some View {
        ChartStyleReader { style in
            let metrics = SwissMetrics(theme: style.theme)
            VStack(alignment: .leading, spacing: metrics.step(2)) {
                SwissRule(.section, tone: .ink)
                Text(title).uiText(.section)
                VStack(alignment: .leading, spacing: 0) { content }
            }
            .accessibilityElement(children: .contain)
        }
    }
}
#endif
