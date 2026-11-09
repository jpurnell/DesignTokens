import Foundation

/// A stable content hash, FNV-1a 64-bit, as 16 lowercase hex digits.
///
/// Foundation-only and expected to be byte-stable on every platform, untested off macOS (`CryptoKit` is not available on Linux). It is a
/// change detector, not a security control, and is not collision-resistant against an adversary.
public enum Fingerprint {
    /// The FNV-1a 64-bit hash of `data`.
    public static func fnv1a64(_ data: Data) -> String {
        let offsetBasis: UInt64 = 0xcbf2_9ce4_8422_2325
        let prime: UInt64 = 0x0000_0100_0000_01b3
        var hash = offsetBasis
        for byte in data {
            hash ^= UInt64(byte)
            hash = hash &* prime
        }
        let digits = String(hash, radix: 16)
        return String(repeating: "0", count: max(0, 16 - digits.count)) + digits
    }
}

/// The canonical JSON form of a theme: the same bytes every time, on every platform.
///
/// Keys are sorted, output is pretty-printed, slashes are not escaped and the text ends in one newline.
/// Every field is a fixed struct field or a `String`-keyed dictionary. A dictionary keyed by an enum would
/// not do: Swift encodes it as an array in unspecified order, and the same model would then produce
/// different bytes from one run to the next.
public enum ThemeCodec {
    /// The canonical bytes of a theme.
    public static func encode(_ theme: Theme) throws -> Data {
        try canonical(theme)
    }

    /// The canonical bytes of an app palette.
    public static func encode(_ palette: AppPalette) throws -> Data {
        try canonical(palette)
    }

    /// Decodes a theme and refuses one whose values contradict its declared appearance support.
    ///
    /// - Throws: `DecodingError` for malformed input, ``ThemeError/invalid(_:)`` for an inconsistent theme.
    public static func decode(_ data: Data) throws -> Theme {
        let theme = try JSONDecoder().decode(Theme.self, from: data)
        let issues = theme.appearanceIssues
        guard issues.isEmpty else { throw ThemeError.invalid(issues) }
        return theme
    }

    /// Decodes an app palette.
    public static func decodeAppPalette(_ data: Data) throws -> AppPalette {
        try JSONDecoder().decode(AppPalette.self, from: data)
    }

    /// The fingerprint of a theme's canonical bytes.
    ///
    /// - Throws: An encoding error if the theme cannot be encoded (a NaN weight, for instance).
    public static func fingerprint(of theme: Theme) throws -> String {
        Fingerprint.fnv1a64(try encode(theme))
    }

    private static func canonical<T: Encodable>(_ value: T) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        var data = try encoder.encode(value)
        data.append(0x0A)
        return data
    }
}
