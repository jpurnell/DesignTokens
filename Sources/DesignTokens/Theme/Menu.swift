#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// The geometry of a theme's menus, in logical pixels. The drawing is the theme's ``SurfaceRole/menuBar``, ``SurfaceRole/menu``,
/// ``SurfaceRole/menuTitle``, ``SurfaceRole/menuItem``, ``SurfaceRole/menuBarItem`` and ``SurfaceRole/menuSeparator`` recipes; this is the layout the web emitter lays them out with.
public struct MenuMetrics: Sendable, Hashable, Codable {
    /// The height of the menu bar, frame included, or `nil` when the theme has no bar across the top.
    public var barHeight: Double?
    /// Room between the menu bar's outer edge and its titles: the frame the bar's edges draw.
    public var barInset: Insets
    /// The height of a row in a menu, frame included.
    public var itemHeight: Double
    /// The height of a menu's title row, frame included, or `nil` when menus carry no title.
    public var titleHeight: Double?
    /// Space at each end of a row or a title along the line of text.
    public var itemPadding: Double
    /// The width of a menu, or `nil` to fit its widest row.
    public var menuWidth: Double?
    /// Space above a submenu arrow inside its row, frame included.
    public var arrowInset: Double
    /// Padding inside a menu's own frame, so its rows sit inside the outline but cover the rest of its edges (Platinum's lit row covers the white
    /// and grey lines), or `nil` for none.
    public var menuInset: Insets?
    /// Padding of a row when its two ends differ (the Mac's rows leave room for a check mark), or `nil` to use ``itemPadding`` at both.
    public var itemInset: Insets?
    /// The height of a separator row, or `nil` when menus have none.
    public var separatorHeight: Double?

    /// Creates menu metrics.
    public init(barHeight: Double? = nil, barInset: Insets = Insets(top: 0, leading: 0, bottom: 0, trailing: 0), itemHeight: Double,
                titleHeight: Double? = nil, itemPadding: Double, menuWidth: Double? = nil, arrowInset: Double = 0,
                menuInset: Insets? = nil, itemInset: Insets? = nil, separatorHeight: Double? = nil) {
        self.barHeight = barHeight
        self.barInset = barInset
        self.itemHeight = itemHeight
        self.titleHeight = titleHeight
        self.itemPadding = itemPadding
        self.menuWidth = menuWidth
        self.arrowInset = arrowInset
        self.menuInset = menuInset
        self.itemInset = itemInset
        self.separatorHeight = separatorHeight
    }
}
