#if canImport(SwiftUI) && os(macOS)
/// Whether two floating-point values are the same to within a tolerance (default 1e-9). Every value compared
/// this way is a point size or a weight copied from a theme through a `CGFloat` conversion, so the tolerance is
/// far below any real difference.
func near(_ a: some BinaryFloatingPoint, _ b: some BinaryFloatingPoint, tolerance: Double = 1e-9) -> Bool {
    abs(Double(a) - Double(b)) <= tolerance
}
#endif
