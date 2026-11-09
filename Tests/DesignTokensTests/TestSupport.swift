import Foundation

/// Whether two lists of measured numbers are the same, element by element, to within a tolerance of 1e-9.
///
/// Every number compared this way was rounded to at most three decimals by the same code on both sides, so
/// the tolerance is far below the rounding step: it only absorbs the representation of the decimal.
func same(_ a: [Double], _ b: [Double]) -> Bool {
    a.count == b.count && zip(a, b).allSatisfy { abs($0 - $1) < 1e-9 }
}
