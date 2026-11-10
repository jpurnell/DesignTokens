#if canImport(SwiftUI)
import DesignTokens
import SwiftUI

/// The Hybrid card of the design system: a 3 pt ink rule across the top, a small label and an outlined-chip slot, the title large,
/// a secondary-ink description, and a footer set off by an ink hairline ("Builds on ...").
///
/// Square (the container radius), a hairline border in the neutral `rule` colour, no fill (the page is the surface), no shadow, no
/// dashed edge. State is the chip and its words, never a tinted or dashed card. VoiceOver reads it as a container whose children
/// are still reachable, so a button in the footer is.
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
                    Text(title).uiText(.title).fixedSize(horizontal: false, vertical: true)
                    if let description {
                        Text(description).uiText(.body, ink: .secondaryInk)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    if hasFooter {
                        VStack(alignment: .leading, spacing: metrics.step(2)) {
                            SwissRule(.hairline, tone: .ink)
                            footer
                        }
                        .padding(.top, metrics.step(1))
                    }
                }
                .padding(metrics.step(3))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .swissContainer()
            .accessibilityElement(children: .contain)
        }
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

/// The card's footer row: a label in secondary ink and the names after it in bold ink ("Builds on" and the packages).
@available(macOS 14.0, iOS 17.0, visionOS 1.0, tvOS 17.0, watchOS 10.0, *)
public struct SwissCardFooter: View {
    private let label: String
    private let names: String

    /// Creates a footer row.
    public init(_ label: String, names: String) {
        self.label = label
        self.names = names
    }

    /// The row.
    public var body: some View {
        ChartStyleReader { style in
            HStack(alignment: .firstTextBaseline, spacing: SwissMetrics(theme: style.theme).step(2)) {
                Text(label).uiText(.caption)
                Text(names).uiText(.caption, ink: .ink).fontWeight(.bold)
            }
            .accessibilityElement(children: .combine)
        }
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
                Text(title).uiText(.heading)
                VStack(alignment: .leading, spacing: 0) { content }
            }
            .accessibilityElement(children: .contain)
        }
    }
}
#endif
