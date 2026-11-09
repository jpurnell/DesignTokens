/// The chart palette: eight series colours in a fixed order, plus the ramps.
///
/// The order is validated for adjacency and colour-vision separation. It fails the dataviz lightness band
/// for these slots: yellow in the light appearance (OKLCH L 0.865, band 0.43 to 0.77), and orange, green,
/// yellow and cyan in the dark appearance (0.762, 0.756, 0.885, 0.808; band 0.48 to 0.67), because Apple's
/// system colours are kept as they are. Orange, green, yellow and cyan are also under 3:1 against the light
/// surface (2.21, 2.13, 1.45, 2.07). Those slots need direct labels or printed values; see ``SwissLedger``.
/// A ninth series is never a generated hue: fold it into "Other", facet, or use a composite encoding.
public enum Palette {
    /// The series colours: Apple's system orange, indigo, green, purple, yellow, blue, red and cyan.
    public static let series: [RGB] = [
        RGB(rgb: 0xFF8D28), RGB(rgb: 0x6155F5), RGB(rgb: 0x34C759), RGB(rgb: 0xCB30E0),
        RGB(rgb: 0xFFCC00), RGB(rgb: 0x0088FF), RGB(rgb: 0xFF383C), RGB(rgb: 0x00C0E8),
    ]

    /// The series colours in the dark appearance, in the same order as ``series``.
    ///
    /// Measured: Apple's system colours resolved in the dark appearance on ``Snapshot/systemRelease``.
    public static let seriesDark: [RGB] = [
        RGB(rgb: 0xFF9230), RGB(rgb: 0x6D7CFF), RGB(rgb: 0x30D158), RGB(rgb: 0xDB34F2),
        RGB(rgb: 0xFFD600), RGB(rgb: 0x0091FF), RGB(rgb: 0xFF4245), RGB(rgb: 0x3CD3FE),
    ]

    /// The series colours with Increase Contrast on, light appearance, in the same order as ``series``.
    ///
    /// Measured on ``Snapshot/systemRelease``.
    public static let seriesIncreasedContrast: [RGB] = [
        RGB(rgb: 0xC55300), RGB(rgb: 0x564ADE), RGB(rgb: 0x008932), RGB(rgb: 0xB02FC2),
        RGB(rgb: 0xA16A00), RGB(rgb: 0x1E6EF4), RGB(rgb: 0xE9152D), RGB(rgb: 0x007EAE),
    ]

    /// The series colours with Increase Contrast on, dark appearance, in the same order as ``series``.
    ///
    /// Measured on ``Snapshot/systemRelease``.
    public static let seriesIncreasedContrastDark: [RGB] = [
        RGB(rgb: 0xFFA056), RGB(rgb: 0xA7AAFF), RGB(rgb: 0x4AD968), RGB(rgb: 0xEA8DFF),
        RGB(rgb: 0xFEDF43), RGB(rgb: 0x5CB8FF), RGB(rgb: 0xFF6165), RGB(rgb: 0x6DD9FF),
    ]

    /// The names of ``series``, in the same order.
    public static let seriesNames = ["orange", "indigo", "green", "purple", "yellow", "blue", "red", "cyan"]

    /// One-hue magnitude ramp, light to dark, built on system orange.
    public static let sequential: [RGB] = [
        RGB(rgb: 0xFF9134), RGB(rgb: 0xDF7502), RGB(rgb: 0xB85F01), RGB(rgb: 0x924A01), RGB(rgb: 0x6E3700),
    ]

    /// The sequential ramp for a dark surface: ``sequential`` reversed, so a larger magnitude is lighter.
    ///
    /// Derived, not measured. There is no dark diverging ramp yet: its tints would have to be invented,
    /// so a dark surface uses ``diverging`` as it is.
    public static var sequentialDark: [RGB] { sequential.reversed() }

    /// Two-pole ramp with a neutral midpoint: blue, neutral grey, orange.
    public static let diverging: [RGB] = [
        RGB(rgb: 0x0088FF), RGB(rgb: 0x8ABBF8), RGB(rgb: 0xE8E8E8), RGB(rgb: 0xF7BD95), RGB(rgb: 0xFF8D28),
    ]

    /// Princeton orange, kept as a custom accent option. It is not the default.
    public static let princetonAccent = RGB(rgb: 0xE77500)
}
