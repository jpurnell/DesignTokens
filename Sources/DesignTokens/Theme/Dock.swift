import Foundation

/// The geometry of a theme's dock, in logical pixels. The drawing is the theme's ``SurfaceRole/dockTile`` recipe.
public struct DockMetrics: Sendable, Hashable, Codable {
    /// The side of a square tile, frame included.
    public var tileSize: Double
    /// The height of the label strip on a tile, or `nil` when tiles carry no label.
    public var labelHeight: Double?
    /// Space between the tile's top edge and its label strip.
    public var labelInset: Double

    /// Creates dock metrics.
    public init(tileSize: Double, labelHeight: Double? = nil, labelInset: Double = 0) {
        self.tileSize = tileSize
        self.labelHeight = labelHeight
        self.labelInset = labelInset
    }
}
