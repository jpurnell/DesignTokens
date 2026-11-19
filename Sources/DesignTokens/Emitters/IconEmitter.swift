import Foundation

/// Writes an ``Icon`` as a standalone SVG file.
public enum IconEmitter {
    /// The SVG document for an icon. The drawing is made of whole-unit shapes, so `crispEdges` keeps the pixel look the look-alike skins want;
    /// the file has no fixed size, so it scales with the element that shows it.
    public static func emit(_ icon: Icon) -> String {
        "<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"\(icon.viewBox)\" shape-rendering=\"crispEdges\">\(icon.body)</svg>\n"
    }
}
