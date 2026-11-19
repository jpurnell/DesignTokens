import Foundation

/// A button in a window's title bar.
public enum WindowControl: String, Sendable, Hashable, Codable {
    /// Closes the window (System 7 and Platinum's close box, Aqua's red light).
    case close
    /// Collapses the window (Platinum's windowshade box, Aqua's yellow light, NeXTSTEP's miniaturize button).
    case minimize
    /// Resizes the window to fit its content or the screen (System 7 and Platinum's zoom box, Aqua's green light).
    case zoom
}

/// Where a theme puts the controls in a window's title bar, each side listed outermost first.
///
/// The original platforms disagree, and the placement is part of the look: System 7 has the close box at the leading edge and the zoom
/// box at the trailing edge; Mac OS 8 has the close box leading and zoom then windowshade trailing; Aqua has all three lights leading.
/// "Leading" and "trailing" follow the reading direction, so a right-to-left layout mirrors them.
public struct WindowControls: Sendable, Hashable, Codable {
    /// Controls on the leading side, from the edge inward.
    public var leading: [WindowControl]
    /// Controls on the trailing side, from the inside outward.
    public var trailing: [WindowControl]

    /// The title bar's measurements, or `nil` when the theme places controls but draws no bar of its own.
    public var titleBar: TitleBarMetrics?

    /// Creates a placement.
    public init(leading: [WindowControl], trailing: [WindowControl], titleBar: TitleBarMetrics? = nil) {
        self.leading = leading
        self.trailing = trailing
        self.titleBar = titleBar
    }

    /// The value of GTK's `gtk-decoration-layout` setting: leading names, a colon, trailing names (`close:maximize,minimize`).
    /// GTK calls the zoom control `maximize`.
    public var gtkDecorationLayout: String {
        func name(_ control: WindowControl) -> String { control == .zoom ? "maximize" : control.rawValue }
        return leading.map(name).joined(separator: ",") + ":" + trailing.map(name).joined(separator: ",")
    }
}

/// The measurements of a drawn title bar, in logical pixels: the bar's size, the room its frame takes, and how its parts sit.
public struct TitleBarMetrics: Sendable, Hashable, Codable {
    /// The bar's height, frame included.
    public var height: Double
    /// Room between the bar's outer edge and its parts: the frame stripes plus the space inside them.
    public var inset: Insets
    /// The side of a square window control.
    public var boxSize: Double
    /// Space between neighbouring parts (control, stripes, title).
    public var gap: Double
    /// The stripes' height.
    public var stripeHeight: Double
    /// Space between two window controls on the same side, which can differ from ``gap``.
    public var boxGap: Double

    /// Creates the metrics.
    public init(height: Double, inset: Insets, boxSize: Double, gap: Double, stripeHeight: Double, boxGap: Double? = nil) {
        self.height = height
        self.inset = inset
        self.boxSize = boxSize
        self.gap = gap
        self.stripeHeight = stripeHeight
        self.boxGap = boxGap ?? gap
    }
}
