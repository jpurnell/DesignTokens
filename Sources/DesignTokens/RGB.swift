/// An sRGB colour with 8-bit channels.
public struct RGB: Sendable, Hashable {
    /// Red channel, 0 to 255.
    public var red: UInt8
    /// Green channel, 0 to 255.
    public var green: UInt8
    /// Blue channel, 0 to 255.
    public var blue: UInt8

    /// Creates a colour from its channels.
    public init(red: UInt8, green: UInt8, blue: UInt8) {
        self.red = red
        self.green = green
        self.blue = blue
    }

    /// Creates a colour from a packed `0xRRGGBB` value.
    public init(rgb: UInt32) {
        self.init(red: UInt8((rgb >> 16) & 0xFF), green: UInt8((rgb >> 8) & 0xFF), blue: UInt8(rgb & 0xFF))
    }

    /// Parses `#RRGGBB` or `RRGGBB`, in any case. Returns `nil` for anything else.
    ///
    /// Every character must be an ASCII hex digit. `UInt32(_, radix: 16)` alone would also accept a leading
    /// `+` or `-` (`"#+12345"` is six characters), so the digits are checked first.
    public init?(hex: String) {
        let digits = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        guard digits.count == 6, Self.isHexDigits(digits), let packed = UInt32(digits, radix: 16) else { return nil }
        self.init(rgb: packed)
    }

    /// Whether `text` is non-empty and made only of ASCII hex digits (no sign, no space, no other script).
    static func isHexDigits(_ text: String) -> Bool {
        !text.isEmpty && text.utf8.allSatisfy { ($0 >= 0x30 && $0 <= 0x39) || ($0 >= 0x41 && $0 <= 0x46) || ($0 >= 0x61 && $0 <= 0x66) }
    }

    /// The colour as uppercase `#RRGGBB`.
    public var hex: String {
        "#" + Self.pair(red) + Self.pair(green) + Self.pair(blue)
    }

    private static func pair(_ value: UInt8) -> String {
        let digits = String(value, radix: 16, uppercase: true)
        return digits.count == 1 ? "0" + digits : digits
    }
}
