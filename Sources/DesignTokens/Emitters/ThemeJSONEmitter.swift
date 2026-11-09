import Foundation

/// Emits one ``Theme`` as JSON: the full model in its canonical form (``ThemeCodec``), byte for byte.
///
/// The file is for tools that cannot import Swift (slide and spreadsheet generators). It is an output, never
/// an authoring format. JSON has no comments, so the version and hash live in the file name's neighbour, the
/// CSS header, and ``ThemeCodec/fingerprint(of:)`` gives the same hash from the bytes.
public enum ThemeJSONEmitter {
    /// The canonical JSON text of a theme, ending in one newline.
    ///
    /// - Throws: An encoding error if the theme cannot be encoded (a NaN weight, for instance).
    public static func emit(_ theme: Theme) throws -> String {
        String(decoding: try ThemeCodec.encode(theme), as: UTF8.self)
    }
}
