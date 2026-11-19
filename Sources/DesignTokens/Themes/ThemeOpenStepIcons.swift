import Foundation

extension Theme {
    /// OPENSTEP's icons: **original drawings** in the look of the 4.2 dock (a one-pixel black outline, a white highlight and a `#555555` shade on
    /// every raised part, flat bodies with a few saturated accents), not copies of NeXT's artwork. Each is drawn on a 48-unit grid of whole-unit
    /// shapes, so it is as sharp at 2x and 3x as at 1x and keeps the pixel look. The 4.2 icons are NeXT's and Apple's; nothing here is traced from them.
    static var openstepIcons: IconSet {
        let (k, w, g, d) = ("#000000", "#FFFFFF", "#AAAAAA", "#555555")
        func r(_ x: Int, _ y: Int, _ width: Int, _ height: Int, _ fill: String) -> String {
            "<rect x=\"\(x)\" y=\"\(y)\" width=\"\(width)\" height=\"\(height)\" fill=\"\(fill)\"/>"
        }
        func p(_ points: String, _ fill: String) -> String { "<polygon points=\"\(points)\" fill=\"\(fill)\"/>" }
        /// A raised part: black outline, body, white highlight on top and left, shade at the bottom and right.
        func bevel(_ x: Int, _ y: Int, _ width: Int, _ height: Int, _ fill: String, light: String = "#FFFFFF", shade: String = "#555555") -> String {
            r(x, y, width, height, k) + r(x + 1, y + 1, width - 2, height - 2, fill) + r(x + 1, y + 1, width - 3, 1, light) + r(x + 1, y + 1, 1, height - 3, light)
                + r(x + 2, y + height - 2, width - 3, 1, shade) + r(x + width - 2, y + 2, 1, height - 3, shade)
        }
        func lines(_ x: Int, _ y: Int, _ width: Int, count: Int, step: Int, _ fill: String) -> String {
            (0..<count).map { r(x, y + $0 * step, width, 1, fill) }.joined()
        }
        let art: [(String, String)] = [
            ("application",
             bevel(5, 7, 38, 34, g) + r(7, 9, 34, 5, k) + r(9, 10, 3, 3, w) + r(14, 10, 10, 1, w) + r(14, 12, 10, 1, w)
                + r(8, 16, 32, 23, w) + r(8, 16, 32, 1, d) + r(8, 16, 1, 23, d)
                + r(12, 21, 6, 6, "#C03030") + r(21, 21, 6, 6, "#3070C0") + r(30, 21, 6, 6, "#30A050")
                + r(12, 30, 6, 6, "#E0B030") + r(21, 30, 6, 6, "#8040A0") + r(30, 30, 6, 6, g)),
            ("calendar",
             bevel(7, 6, 34, 37, w) + r(8, 7, 32, 8, "#C03030") + r(11, 3, 4, 7, k) + r(33, 3, 4, 7, k)
                + r(12, 5, 2, 4, g) + r(34, 5, 2, 4, g) + r(19, 9, 10, 2, w)
                + r(20, 19, 8, 14, k) + r(21, 20, 6, 12, w) + r(22, 22, 4, 2, k) + r(24, 24, 2, 6, k) + r(22, 28, 4, 2, k)
                + lines(11, 36, 26, count: 1, step: 1, g)),
            ("clock",
             p("16,4 32,4 44,16 44,32 32,44 16,44 4,32 4,16", k) + p("17,6 31,6 42,17 42,31 31,42 17,42 6,31 6,17", g)
                + p("18,8 30,8 40,18 40,30 30,40 18,40 8,30 8,18", w) + p("19,9 29,9 39,19 39,29 29,39 19,39 9,29 9,19", w)
                + r(23, 12, 2, 4, k) + r(23, 32, 2, 4, k) + r(12, 23, 4, 2, k) + r(32, 23, 4, 2, k)
                + r(23, 14, 2, 11, k) + r(24, 24, 9, 2, "#C03030")),
            ("console",
             bevel(5, 5, 38, 30, g) + r(9, 9, 30, 21, k) + r(10, 10, 28, 1, d) + r(10, 10, 1, 19, d)
                + r(13, 14, 2, 2, "#30D060") + r(15, 16, 2, 2, "#30D060") + r(13, 18, 2, 2, "#30D060") + r(19, 19, 8, 2, "#30D060")
                + bevel(14, 35, 20, 5, g) + bevel(8, 40, 32, 5, g)),
            ("disk",
             p("16,4 32,4 44,16 44,32 32,44 16,44 4,32 4,16", k) + p("17,5 31,5 43,17 43,31 31,43 17,43 5,31 5,17", "#C8C8D0")
                + p("18,8 30,8 40,18 40,30 30,40 18,40 8,30 8,18", g) + p("19,12 29,12 36,19 36,29 29,36 19,36 12,29 12,19", "#8090C0")
                + p("21,19 27,19 29,21 29,27 27,29 21,29 19,27 19,21", k) + p("22,21 26,21 27,22 27,26 26,27 22,27 21,26 21,22", "#555577")
                + r(8, 20, 3, 8, w) + r(30, 8, 8, 3, w)),
            ("document",
             "<polygon points=\"10,3 30,3 39,12 39,45 10,45\" fill=\"\(k)\"/>" + "<polygon points=\"11,4 29,4 38,13 38,44 11,44\" fill=\"\(w)\"/>"
                + "<polygon points=\"29,4 38,13 29,13\" fill=\"\(g)\"/>" + r(29, 4, 1, 9, k) + r(29, 12, 9, 1, k)
                + r(37, 14, 1, 30, d) + r(12, 43, 26, 1, d)
                + lines(15, 18, 20, count: 6, step: 4, d)),
            ("edit",
             bevel(6, 6, 30, 38, w) + lines(11, 14, 20, count: 6, step: 4, d) + r(11, 12, 6, 1, "#C03030")
                + p("42,10 46,14 24,38 20,40 22,35", k) + p("41,12 44,15 24,36 22,37 23,34", "#E0B030") + p("41,12 44,15 43,16 40,13", "#C03030")
                + p("20,40 22,35 25,38", "#F0D8A0")),
            ("folder",
             bevel(4, 10, 18, 8, "#D8B468") + bevel(4, 15, 40, 27, "#D8B468", light: "#F4E0A8", shade: "#8C6A30")
                + r(6, 21, 36, 1, "#B88C40") + r(6, 22, 36, 1, "#F4E0A8")),
            ("home",
             p("24,4 45,22 3,22", k) + p("24,6 42,21 6,21", "#C03030") + p("24,6 24,21 6,21", "#E05050") + r(10, 21, 28, 21, k)
                + r(11, 22, 26, 19, "#E8D8A8") + r(37, 22, 1, 19, "#B09860") + r(11, 40, 26, 1, "#B09860")
                + r(20, 28, 9, 13, k) + r(21, 29, 7, 12, "#8C6A30") + r(26, 35, 1, 2, "#E0B030")
                + r(13, 27, 5, 5, k) + r(14, 28, 3, 3, "#80B0E0") + r(31, 27, 5, 5, k) + r(32, 28, 3, 3, "#80B0E0")
                + r(33, 8, 4, 8, k) + r(34, 9, 2, 7, "#C03030")),
            ("library",
             r(5, 8, 11, 34, k) + r(6, 9, 9, 32, "#3070C0") + r(6, 9, 1, 32, "#70A0E0") + r(8, 14, 5, 1, w) + r(8, 17, 5, 1, w) + r(8, 36, 5, 2, "#E0B030")
                + r(17, 4, 12, 38, k) + r(18, 5, 10, 36, "#C03030") + r(18, 5, 1, 36, "#E87070") + r(20, 10, 6, 1, w) + r(20, 13, 6, 1, w) + r(20, 36, 6, 2, "#E0B030")
                + r(30, 11, 13, 31, k) + r(31, 12, 11, 29, "#30A050") + r(31, 12, 1, 29, "#70D090") + r(33, 17, 7, 1, w) + r(33, 20, 7, 1, w) + r(33, 36, 7, 2, "#E0B030")
                + r(4, 42, 40, 2, k)),
            ("mail",
             bevel(4, 12, 40, 26, w) + p("5,13 24,28 43,13", g) + p("6,13 24,26 42,13", "#E8E8F0")
                + r(5, 37, 38, 1, d) + p("5,37 18,25 19,26 6,38", g) + p("43,37 30,25 29,26 42,38", g)
                + r(33, 16, 7, 8, "#C03030") + r(34, 17, 5, 6, "#F08080")),
            ("preferences",
             bevel(5, 7, 38, 34, g) + r(9, 12, 30, 1, d) + r(9, 13, 30, 1, w) + r(9, 22, 30, 1, d) + r(9, 23, 30, 1, w) + r(9, 32, 30, 1, d) + r(9, 33, 30, 1, w)
                + bevel(14, 9, 6, 8, g) + bevel(28, 19, 6, 8, g) + bevel(18, 29, 6, 8, g)),
            ("recycler",
             r(11, 11, 26, 2, k) + r(18, 8, 12, 3, k) + r(19, 9, 10, 1, g)
                + "<polygon points=\"12,13 36,13 34,43 14,43\" fill=\"\(k)\"/>" + "<polygon points=\"13,14 35,14 33,42 15,42\" fill=\"\(g)\"/>"
                + "<polygon points=\"13,14 17,14 19,42 15,42\" fill=\"\(w)\"/>" + "<polygon points=\"31,14 35,14 33,42 29,42\" fill=\"\(d)\"/>"
                + r(23, 17, 2, 22, d) + r(18, 17, 1, 22, d) + r(29, 17, 1, 22, d)
                + r(10, 11, 28, 1, w)),
        ]
        return IconSet(icons: art.map { Icon(literal: $0.0, $0.1) })
    }
}
