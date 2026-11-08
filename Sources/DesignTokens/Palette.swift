/// The chart palette: eight series colours in a fixed, validated order, plus the ramps.
///
/// The order was validated for neighbour separation, lightness band and colour-blind separation. A ninth
/// series is never a generated hue: fold it into "Other", facet, or use a composite encoding.
public enum Palette {
    /// The series colours: Apple's system orange, indigo, green, purple, yellow, blue, red and cyan.
    public static let series: [RGB] = [
        RGB(rgb: 0xFF8D28), RGB(rgb: 0x6155F5), RGB(rgb: 0x34C759), RGB(rgb: 0xCB30E0),
        RGB(rgb: 0xFFCC00), RGB(rgb: 0x0088FF), RGB(rgb: 0xFF383C), RGB(rgb: 0x00C0E8),
    ]

    /// The names of ``series``, in the same order.
    public static let seriesNames = ["orange", "indigo", "green", "purple", "yellow", "blue", "red", "cyan"]

    /// One-hue magnitude ramp, light to dark, built on system orange.
    public static let sequential: [RGB] = [
        RGB(rgb: 0xFF9134), RGB(rgb: 0xDF7502), RGB(rgb: 0xB85F01), RGB(rgb: 0x924A01), RGB(rgb: 0x6E3700),
    ]

    /// Two-pole ramp with a neutral midpoint: blue, neutral grey, orange.
    public static let diverging: [RGB] = [
        RGB(rgb: 0x0088FF), RGB(rgb: 0x8ABBF8), RGB(rgb: 0xE8E8E8), RGB(rgb: 0xF7BD95), RGB(rgb: 0xFF8D28),
    ]

    /// Princeton orange, kept as a custom accent option. It is not the default.
    public static let princetonAccent = RGB(rgb: 0xE77500)
}
