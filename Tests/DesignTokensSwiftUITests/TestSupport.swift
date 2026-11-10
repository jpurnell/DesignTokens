#if canImport(SwiftUI) && os(macOS)
/// Whether two floating-point values are the same to within a tolerance (default 1e-9). Every value compared
/// this way is a point size or a weight copied from a theme through a `CGFloat` conversion, so the tolerance is
/// far below any real difference.
func near(_ a: some BinaryFloatingPoint, _ b: some BinaryFloatingPoint, tolerance: Double = 1e-9) -> Bool {
    abs(Double(a) - Double(b)) <= tolerance
}
#endif

#if canImport(SwiftUI) && os(macOS)
import AppKit
import SwiftUI

/// Frames reported by views that call ``SwiftUI/View/probe(_:)``, in the coordinate space of the rendered root.
struct ProbeKey: PreferenceKey {
    static let defaultValue: [String: CGRect] = [:]
    static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) {
        value.merge(nextValue()) { _, new in new }
    }
}

extension View {
    /// Reports this view's frame under a name, for ``renderFrames(_:width:)``.
    func probe(_ name: String) -> some View {
        background(GeometryReader { proxy in
            Color.clear.preference(key: ProbeKey.self, value: [name: proxy.frame(in: .named("probe"))])
        })
    }
}

/// Renders a view at a width in a real window on the Swiss theme and returns the frames its probes reported: the measured layout,
/// not a recital of the arithmetic.
@MainActor
func renderFrames(_ view: some View, width: CGFloat, dark: Bool = false) -> [String: CGRect] {
    let box = FrameBox()
    let root = view
        .environment(\.theme, .swiss)
        .frame(width: width, alignment: .topLeading)
        .fixedSize(horizontal: false, vertical: true)
        .coordinateSpace(name: "probe")
        .onPreferenceChange(ProbeKey.self) { frames in MainActor.assumeIsolated { box.frames = frames } }
    let host = NSHostingView(rootView: root)
    host.appearance = NSAppearance(named: dark ? .darkAqua : .aqua)
    let size = host.fittingSize
    let window = NSWindow(contentRect: NSRect(origin: .zero, size: size), styleMask: [.borderless], backing: .buffered, defer: false)
    window.contentView = host
    host.frame = NSRect(origin: .zero, size: size)
    window.orderFrontRegardless()
    RunLoop.main.run(until: Date().addingTimeInterval(0.3))
    host.layoutSubtreeIfNeeded()
    window.orderOut(nil)
    return box.frames
}

@MainActor
private final class FrameBox {
    var frames: [String: CGRect] = [:]
}
#endif
