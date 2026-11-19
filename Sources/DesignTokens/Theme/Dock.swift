import Foundation

/// The geometry of a theme's dock, in logical pixels. The drawing is the theme's ``SurfaceRole/dockTile`` recipe.
public struct DockMetrics: Sendable, Hashable, Codable {
    /// The side of a square tile, frame included.
    public var tileSize: Double

    /// Creates dock metrics.
    public init(tileSize: Double) {
        self.tileSize = tileSize
    }
}
