#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// The few string operations the core needs that full Foundation provides through `NSString` bridging, written against
/// the standard library so the core links `FoundationEssentials` alone.
///
/// Full Foundation drags in the ICU data tables, about 18 MB gzipped, which matters to the WebAssembly build. Each
/// helper is checked against Foundation's own answer in `TextHelpersTests`.
extension StringProtocol {
    /// Every non-overlapping occurrence of `target` replaced by `replacement`, matched literally.
    ///
    /// An empty `target` returns the text unchanged, as Foundation's `replacingOccurrences(of:with:)` does.
    func replacingAll(_ target: String, with replacement: String) -> String {
        var text = String(self)
        guard !target.isEmpty else { return text }
        // One pass over the UTF-8 bytes: the target's first byte is compared at every position and the rest only on a hit.
        // Matching bytes is what Foundation's literal replacement does (so "\n" is found inside "\r\n", which a
        // Character-by-Character scan misses), and it avoids a scan that was over half of the time to emit Platinum in
        // WebAssembly. A UTF-8 needle can only match on scalar boundaries, so the output is always valid UTF-8.
        let needle = Array(target.utf8)
        let substitute = Array(replacement.utf8)
        let first = needle[0]
        let output: [UInt8] = text.withUTF8 { source in
            var out = [UInt8]()
            out.reserveCapacity(source.count)
            let count = source.count
            var index = 0
            while index < count {
                if source[index] == first, index + needle.count <= count, bytesMatch(source, at: index, needle) {
                    out.append(contentsOf: substitute)
                    index += needle.count
                } else {
                    out.append(source[index])
                    index += 1
                }
            }
            return out
        }
        return String(decoding: output, as: UTF8.self)
    }

    /// The text without leading and trailing spaces and tabs: Foundation's `CharacterSet.whitespaces`, which on Apple
    /// platforms is the Unicode space separators (Zs), the tab and the zero-width space (U+200B).
    func trimmedSpaces() -> String {
        trimmed { $0.isHorizontalSpace }
    }

    /// The text without leading and trailing white space and line breaks: `CharacterSet.whitespacesAndNewlines`.
    func trimmedWhitespace() -> String {
        trimmed { $0.isHorizontalSpace || $0.properties.isWhitespace }
    }

    private func trimmed(_ isTrimmed: (Unicode.Scalar) -> Bool) -> String {
        let scalars = unicodeScalars
        guard let first = scalars.firstIndex(where: { !isTrimmed($0) }),
              let last = scalars.lastIndex(where: { !isTrimmed($0) }) else { return "" }
        return String(String.UnicodeScalarView(scalars[first...last]))
    }
}

extension StringProtocol where Index == String.Index {
    /// The first occurrence of `needle` inside `range`, optionally ignoring case.
    ///
    /// Case is compared one character at a time, so a match never changes length: this is for ASCII needles such as
    /// `<style`. An empty `needle` finds nothing, as in Foundation, so a search loop cannot stall on a zero-width match.
    func firstRange(of needle: String, in range: Range<String.Index>, ignoringCase: Bool = false) -> Range<String.Index>? {
        guard !needle.isEmpty else { return nil }
        let window = self[range]
        var start = window.startIndex
        while start < window.endIndex {
            let tail = window[start...]
            let matches = ignoringCase
                ? tail.starts(with: needle, by: { $0.lowercased() == $1.lowercased() })
                : tail.starts(with: needle)
            if matches {
                guard let end = window.index(start, offsetBy: needle.count, limitedBy: window.endIndex) else { return nil }
                return start..<end
            }
            start = window.index(after: start)
        }
        return nil
    }
}

extension Unicode.Scalar {
    /// Space, tab, the other Zs separators and the zero-width space: Foundation's `CharacterSet.whitespaces`.
    fileprivate var isHorizontalSpace: Bool {
        value == 0x09 || value == 0x200B || properties.generalCategory == .spaceSeparator
    }

    /// Whether the scalar is a control or format character (Unicode categories Cc and Cf): Foundation's
    /// `CharacterSet.controlCharacters`, which on Apple platforms includes the format characters (soft hyphen,
    /// zero-width space, direction marks, byte-order mark) as well as the C0 and C1 controls.
    var isControlCharacter: Bool {
        properties.generalCategory == .control || properties.generalCategory == .format
    }
}

/// Whether `needle` occurs in `source` starting at `index`; the caller has checked it fits.
private func bytesMatch(_ source: UnsafeBufferPointer<UInt8>, at index: Int, _ needle: [UInt8]) -> Bool {
    var offset = 1
    while offset < needle.count {
        if source[index + offset] != needle[offset] { return false }
        offset += 1
    }
    return true
}
