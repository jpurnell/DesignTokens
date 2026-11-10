#if canImport(SwiftUI)
import DesignTokens
import SwiftUI

@available(macOS 14.0, iOS 17.0, visionOS 1.0, tvOS 17.0, watchOS 10.0, *)
extension SwissMetrics {
    /// The least size of a tappable target on a touch platform: 44 pt, the platform guideline (eleven base units), not a design token.
    public var minimumTouchTarget: CGFloat { step(11) }
}

@available(macOS 14.0, iOS 17.0, visionOS 1.0, tvOS 17.0, watchOS 10.0, *)
@available(macOS 14.0, iOS 17.0, visionOS 1.0, tvOS 17.0, watchOS 10.0, *)
private struct TouchTargetModifier: ViewModifier {
    @Environment(\.theme) private var theme

    func body(content: Content) -> some View {
        content.swissTouchTarget(SwissMetrics(theme: theme))
    }
}

@available(macOS 14.0, iOS 17.0, visionOS 1.0, tvOS 17.0, watchOS 10.0, *)
public extension View {
    /// At least 44 pt square (``SwissMetrics/minimumTouchTarget``) where a finger or a gaze taps; nothing on a Mac. Put it on every
    /// control a person taps that is not already one of the package's.
    func swissTouchTarget() -> some View {
        modifier(TouchTargetModifier())
    }
}

@available(macOS 14.0, iOS 17.0, visionOS 1.0, tvOS 17.0, watchOS 10.0, *)
extension View {
    /// The same, with metrics already in hand.
    func swissTouchTarget(_ metrics: SwissMetrics) -> some View {
        #if os(iOS) || os(visionOS)
        frame(minWidth: metrics.minimumTouchTarget, minHeight: metrics.minimumTouchTarget).contentShape(Rectangle())
        #else
        self
        #endif
    }
}

/// How a ``SwissSegmentedControl`` presents its choices.
@available(macOS 14.0, iOS 17.0, visionOS 1.0, tvOS 17.0, watchOS 10.0, *)
public enum SwissSegmentedPresentation: Sendable, Hashable {
    /// Segments when they fit on one line each and the text size is not an accessibility size, a menu otherwise. The default.
    case automatic
    /// Always segments (each on one line; the control scrolls nothing and may be wider than its container).
    case segments
    /// Always a menu.
    case menu

    /// What is drawn: pure, so a test holds the rule.
    ///
    /// - Parameters:
    ///   - isAccessibilitySize: Whether Dynamic Type is at an accessibility size, where segments would break words ("SUM-MARY").
    ///   - segmentsFit: Whether every segment fits on one line in the width on offer.
    public func resolved(isAccessibilitySize: Bool, segmentsFit: Bool) -> Resolved {
        switch self {
        case .segments: .segments
        case .menu: .menu
        case .automatic: (isAccessibilitySize || !segmentsFit) ? .menu : .segments
        }
    }

    /// What is drawn.
    public enum Resolved: Sendable, Hashable {
        /// A row of segments.
        case segments
        /// A button that opens a menu of the choices.
        case menu
    }
}

/// A segmented control as the design draws a control: the control radius, an ink hairline border, the label role, the selected
/// segment filled with ink and set in the colour measured to read on it (``ReadableText``). Selection is said to VoiceOver, and
/// each segment is at least 44 pt tall where a finger taps.
///
/// Each segment is one line: a word is never broken. When the segments do not fit the width, or at an accessibility text size, the
/// control becomes a menu (a bordered button naming the current choice) with the same 44 pt target, with no code at the call site
/// (``SwissSegmentedPresentation``).
@available(macOS 14.0, iOS 17.0, visionOS 1.0, tvOS 17.0, watchOS 10.0, *)
public struct SwissSegmentedControl<Value: Hashable>: View {
    private let title: String
    private let options: [Value]
    private let name: (Value) -> String
    private let presentation: SwissSegmentedPresentation
    @Binding private var selection: Value
    @Environment(\.dynamicTypeSize) private var typeSize

    /// Creates a control.
    ///
    /// - Parameters:
    ///   - title: What the control chooses, read by VoiceOver ("View") and shown on the menu.
    ///   - options: The choices, in order.
    ///   - name: Each choice's words.
    ///   - presentation: Segments, a menu, or (the default) whichever fits.
    ///   - selection: The chosen value.
    public init(title: String, options: [Value], name: @escaping (Value) -> String,
                presentation: SwissSegmentedPresentation = .automatic, selection: Binding<Value>) {
        self.title = title
        self.options = options
        self.name = name
        self.presentation = presentation
        self._selection = selection
    }

    /// The control.
    public var body: some View {
        ChartStyleReader { style in
            let metrics = SwissMetrics(theme: style.theme)
            switch presentation {
            case .segments: segments(style: style, metrics: metrics)
            case .menu: menu(style: style, metrics: metrics)
            case .automatic:
                if typeSize.isAccessibilitySize {
                    menu(style: style, metrics: metrics)
                } else {
                    ViewThatFits(in: .horizontal) {
                        segments(style: style, metrics: metrics)
                        menu(style: style, metrics: metrics)
                    }
                }
            }
        }
    }

    private func segments(style: ChartStyle, metrics: SwissMetrics) -> some View {
        let onInk = ReadableText.on(style.value(.ink), style: style).colour.color
        let fill = RoundedRectangle(cornerRadius: metrics.segmentRadius)
        return HStack(spacing: 0) {
            ForEach(options, id: \.self) { option in
                let selected = option == selection
                Button { selection = option } label: {
                    Text(name(option))
                        .uiText(.label, ink: .custom(selected ? onInk : style.ink))
                        .lineLimit(1)
                        .padding(.horizontal, metrics.step(3))
                        .padding(.vertical, metrics.step(2))
                        .frame(maxWidth: .infinity)
                        .background { if selected { fill.fill(style.ink).modifier(CellProbe(key: "segmented/selected")) } }
                        .swissTouchTarget(metrics)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
        // The selected segment sits inside the border by the same inset on every side; the border's line is on top of it.
        .padding(metrics.segmentInset + metrics.hairline)
        .overlay(metrics.controlShape.strokeBorder(style.ink, lineWidth: metrics.hairline))
        .accessibilityElement(children: .contain)
        .accessibilityLabel(title)
        .modifier(CellProbe(key: "segmented/segments"))
    }

    private func menuLabel(style: ChartStyle, metrics: SwissMetrics, showsTitle: Bool) -> some View {
        HStack(spacing: metrics.step(2)) {
            if showsTitle { Text(title).uiText(.label).lineLimit(1) }
            Text(name(selection)).uiText(.label, ink: .ink).fontWeight(.bold).lineLimit(1)
            Spacer(minLength: metrics.step(2))
            Image(systemName: "chevron.up.chevron.down").imageScale(.small).foregroundStyle(style.ink)
        }
    }

    private func menu(style: ChartStyle, metrics: SwissMetrics) -> some View {
        Menu {
            ForEach(options, id: \.self) { option in
                Button { selection = option } label: {
                    if option == selection { Label(name(option), systemImage: "checkmark") } else { Text(name(option)) }
                }
            }
        } label: {
            // The title is the first thing to go when the width is short: the value alone, on one line, before a word is broken.
            ViewThatFits(in: .horizontal) {
                menuLabel(style: style, metrics: metrics, showsTitle: true)
                menuLabel(style: style, metrics: metrics, showsTitle: false)
            }
            .padding(.horizontal, metrics.step(3))
            .padding(.vertical, metrics.step(2))
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(metrics.controlShape.strokeBorder(style.ink, lineWidth: metrics.hairline))
            .swissTouchTarget(metrics)
        }
        .menuStyle(.button)
        .menuIndicator(.hidden)
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityValue(name(selection))
        .modifier(CellProbe(key: "segmented/menu"))
    }
}

/// A toggle as a square-cornered box with an ink border and a check, the label in the body role. `.toggleStyle(.swiss)`.
@available(macOS 14.0, iOS 17.0, visionOS 1.0, tvOS 17.0, watchOS 10.0, *)
public struct SwissToggleStyle: ToggleStyle {
    /// Creates the style.
    public init() {}

    /// The toggle.
    public func makeBody(configuration: Configuration) -> some View {
        ChartStyleReader { style in
            let metrics = SwissMetrics(theme: style.theme)
            let onInk = ReadableText.on(style.value(.ink), style: style).colour.color
            Button { configuration.isOn.toggle() } label: {
                HStack(spacing: metrics.step(2)) {
                    ZStack {
                        metrics.controlShape.fill(configuration.isOn ? style.ink : Color.clear)
                        metrics.controlShape.strokeBorder(style.ink, lineWidth: metrics.hairline)
                        if configuration.isOn {
                            Image(systemName: "checkmark").uiText(.caption, ink: .custom(onInk)).fontWeight(.bold)
                        }
                    }
                    .frame(width: metrics.step(5), height: metrics.step(5))
                    .accessibilityHidden(true)
                    configuration.label.uiText(.body)
                    Spacer(minLength: 0)
                }
                .swissTouchTarget(metrics)
            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(.isToggle)
            .accessibilityValue(configuration.isOn ? "On" : "Off")
        }
    }
}

@available(macOS 14.0, iOS 17.0, visionOS 1.0, tvOS 17.0, watchOS 10.0, *)
public extension ToggleStyle where Self == SwissToggleStyle {
    /// The Swiss toggle.
    static var swiss: SwissToggleStyle { SwissToggleStyle() }
}

/// A form without the grouped, inset chrome: its content stacked on the base-unit grid. `.formStyle(.swiss)`.
///
/// A `FormStyle` receives the form's content and no more: it cannot restyle a `Section`'s header, so use ``SwissSection`` where the
/// design wants a rule and a heading, and ``SwissLabeledContentStyle`` for its rows.
@available(macOS 14.0, iOS 17.0, visionOS 1.0, tvOS 17.0, watchOS 10.0, *)
public struct SwissFormStyle: FormStyle {
    /// Creates the style.
    public init() {}

    /// The form.
    public func makeBody(configuration: Configuration) -> some View {
        ChartStyleReader { style in
            VStack(alignment: .leading, spacing: SwissMetrics(theme: style.theme).step(4)) {
                configuration.content
            }
        }
    }
}

@available(macOS 14.0, iOS 17.0, visionOS 1.0, tvOS 17.0, watchOS 10.0, *)
public extension FormStyle where Self == SwissFormStyle {
    /// The Swiss form.
    static var swiss: SwissFormStyle { SwissFormStyle() }
}

/// A text field as the design draws a control: the label role above, the control radius, an ink hairline border that becomes the
/// accent at the chip's weight while the field has focus.
///
/// A view and not a `TextFieldStyle`: SwiftUI gives `TextFieldStyle` no public requirements, so a custom style cannot be written.
@available(macOS 14.0, iOS 17.0, visionOS 1.0, tvOS 17.0, watchOS 10.0, *)
public struct SwissTextField: View {
    private let title: String
    private let prompt: String
    @Binding private var text: String
    @FocusState private var focused: Bool

    /// Creates a field.
    ///
    /// - Parameters:
    ///   - title: The label shown above the field and read by VoiceOver.
    ///   - prompt: The placeholder.
    ///   - text: The text.
    public init(_ title: String, prompt: String = "", text: Binding<String>) {
        self.title = title
        self.prompt = prompt
        self._text = text
    }

    /// The field.
    public var body: some View {
        ChartStyleReader { style in
            let metrics = SwissMetrics(theme: style.theme)
            VStack(alignment: .leading, spacing: metrics.step(1)) {
                Text(title).uiText(.label)
                TextField(title, text: $text, prompt: Text(prompt))
                    .textFieldStyle(.plain)
                    .uiText(.body)
                    .focused($focused)
                    .padding(metrics.step(2))
                    .frame(minHeight: metrics.minimumTouchTarget)
                    .overlay(metrics.controlShape.strokeBorder(focused ? style.accent : style.ink,
                                                               lineWidth: focused ? metrics.chipOutline : metrics.hairline))
            }
        }
    }
}
#endif
