import Foundation

/// Where a scroll bar's two arrow buttons sit.
public enum ScrollArrowPlacement: String, Sendable, Hashable, Codable {
    /// One at each end, with the track between (the Macintosh's default, and Windows').
    case bothEnds
    /// Both at the end, start arrow first (NeXT's).
    case together
}

/// The geometry of a theme's scroll bars, in logical pixels. The drawing is the theme's ``SurfaceRole/scrollTrack``, ``SurfaceRole/scrollThumb``,
/// ``SurfaceRole/scrollGrip`` and arrow recipes; this is the layout the web emitter lays them out with.
public struct ScrollBarMetrics: Sendable, Hashable, Codable {
    /// The bar's thickness: its height when horizontal, its width when vertical.
    public var thickness: Double
    /// The length of an arrow button along the bar.
    public var arrowLength: Double
    /// Where the arrows sit.
    public var arrows: ScrollArrowPlacement
    /// Space between the bar's edge and what it holds, on every side.
    public var inset: Double
    /// Space between the arrows, and between the track and an arrow beside it.
    public var gap: Double

    /// Creates scroll bar metrics.
    public init(thickness: Double, arrowLength: Double, arrows: ScrollArrowPlacement, inset: Double = 0, gap: Double = 0) {
        self.thickness = thickness
        self.arrowLength = arrowLength
        self.arrows = arrows
        self.inset = inset
        self.gap = gap
    }
}
