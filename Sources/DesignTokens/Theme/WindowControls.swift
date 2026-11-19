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

    /// Creates a placement.
    public init(leading: [WindowControl], trailing: [WindowControl]) {
        self.leading = leading
        self.trailing = trailing
    }

    /// The value of GTK's `gtk-decoration-layout` setting: leading names, a colon, trailing names (`close:maximize,minimize`).
    /// GTK calls the zoom control `maximize`.
    public var gtkDecorationLayout: String {
        func name(_ control: WindowControl) -> String { control == .zoom ? "maximize" : control.rawValue }
        return leading.map(name).joined(separator: ",") + ":" + trailing.map(name).joined(separator: ",")
    }
}
