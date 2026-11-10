import Foundation

/// Reduces an sRGB colour to the xterm 256- and 16-colour palettes, deterministically.
///
/// Both reductions pick the entry with the smallest squared Euclidean distance in sRGB, and break a tie in favour of
/// the lowest index. There is no perceptual weighting: the rule is meant to be reproducible by hand and in any
/// language, not to be the best match.
///
/// - The 256-colour reduction searches indices 16 to 255 only: the 6x6x6 colour cube (levels 0, 95, 135, 175, 215,
///   255; index `16 + 36 r + 6 g + b`) and the 24 greys `8 + 10 k` (index `232 + k`). Indices 0 to 15 are the user's own
///   palette and are never chosen.
/// - The 16-colour reduction searches xterm's default sixteen. Terminals remap these, so the result names a
///   colour family, not an exact value.
public enum TerminalColour {
    private static let cubeLevels: [Int] = [0, 95, 135, 175, 215, 255]

    /// Entries 16 to 255 of the xterm table, in index order.
    private static let xterm256Table: [(index: Int, red: Int, green: Int, blue: Int)] = {
        var table: [(Int, Int, Int, Int)] = []
        for r in 0..<6 {
            for g in 0..<6 {
                for b in 0..<6 {
                    table.append((16 + 36 * r + 6 * g + b, cubeLevels[r], cubeLevels[g], cubeLevels[b]))
                }
            }
        }
        for k in 0..<24 {
            let level = 8 + 10 * k
            table.append((232 + k, level, level, level))
        }
        return table
    }()

    /// xterm's default colours 0 to 15.
    private static let xterm16Table: [(red: Int, green: Int, blue: Int)] = [
        (0x00, 0x00, 0x00), (0xCD, 0x00, 0x00), (0x00, 0xCD, 0x00), (0xCD, 0xCD, 0x00),
        (0x00, 0x00, 0xEE), (0xCD, 0x00, 0xCD), (0x00, 0xCD, 0xCD), (0xE5, 0xE5, 0xE5),
        (0x7F, 0x7F, 0x7F), (0xFF, 0x00, 0x00), (0x00, 0xFF, 0x00), (0xFF, 0xFF, 0x00),
        (0x5C, 0x5C, 0xFF), (0xFF, 0x00, 0xFF), (0x00, 0xFF, 0xFF), (0xFF, 0xFF, 0xFF),
    ]

    /// The xterm 256-colour index (16 to 255) nearest to a colour.
    public static func xterm256(_ rgb: RGB) -> Int {
        var best = xterm256Table[0].index
        var bestDistance = Int.max
        for entry in xterm256Table {
            let d = distance(rgb, entry.red, entry.green, entry.blue)
            if d < bestDistance {
                bestDistance = d
                best = entry.index
            }
        }
        return best
    }

    /// The index (0 to 15) of the default xterm colour nearest to a colour.
    public static func xterm16(_ rgb: RGB) -> Int {
        var best = 0
        var bestDistance = Int.max
        for (index, entry) in xterm16Table.enumerated() {
            let d = distance(rgb, entry.red, entry.green, entry.blue)
            if d < bestDistance {
                bestDistance = d
                best = index
            }
        }
        return best
    }

    /// The SGR parameter for a 16-colour index: 0 to 7 are 30 to 37 (background 40 to 47), 8 to 15 are 90 to 97
    /// (background 100 to 107). An index outside 0 to 15 is clamped into range.
    public static func sgr16(_ index: Int, background: Bool) -> Int {
        let i = min(max(index, 0), 15)
        if i < 8 { return (background ? 40 : 30) + i }
        return (background ? 100 : 90) + (i - 8)
    }

    private static func distance(_ rgb: RGB, _ r: Int, _ g: Int, _ b: Int) -> Int {
        let dr = Int(rgb.red) - r
        let dg = Int(rgb.green) - g
        let db = Int(rgb.blue) - b
        return dr * dr + dg * dg + db * db
    }
}
