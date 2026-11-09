import Foundation

/// The identity of a pasted Tumblr block: which theme, which DesignTokens version, which template revision, and
/// the hash of the theme's canonical JSON.
///
/// The text form is `swiss 0.6.0 t1 fnv1a64:0123456789abcdef`: four fields separated by single spaces.
/// It is a staleness check, not a security control: the hash is FNV-1a, so it detects change and says nothing
/// about who made it.
public struct BlogStamp: Sendable, Hashable {
    /// The theme id (`swiss`).
    public var id: String
    /// The DesignTokens version (`0.5.0`).
    public var version: String
    /// The template revision: a change to the fixed Tumblr selectors, not to the theme.
    public var template: Int
    /// The hash, `fnv1a64:` followed by 16 lowercase hex digits.
    public var hash: String

    /// Creates a stamp.
    public init(id: String, version: String, template: Int, hash: String) {
        self.id = id
        self.version = version
        self.template = template
        self.hash = hash
    }

    /// The stamp as text: `swiss 0.6.0 t1 fnv1a64:0123456789abcdef`.
    public var text: String { "\(id) \(version) t\(template) \(hash)" }

    /// Parses stamp text, or returns `nil` when it is not exactly four well-formed fields.
    ///
    /// Leading and trailing whitespace is ignored. The version must be three dot-separated numbers, the template
    /// `t` and a number, and the hash `fnv1a64:` and 16 lowercase hex digits.
    public static func parse(_ text: String) -> BlogStamp? {
        let fields = text.split(whereSeparator: { $0.isWhitespace }).map(String.init)
        guard fields.count == 4 else { return nil }
        let id = fields[0], version = fields[1], template = fields[2], hash = fields[3]
        let versionParts = version.split(separator: ".", omittingEmptySubsequences: false)
        guard versionParts.count == 3, versionParts.allSatisfy(Self.isNumber) else { return nil }
        guard template.hasPrefix("t"), Self.isNumber(Substring(template.dropFirst())),
              let revision = Int(template.dropFirst()) else { return nil }
        let prefix = "fnv1a64:"
        guard hash.hasPrefix(prefix) else { return nil }
        let digits = hash.dropFirst(prefix.count)
        guard digits.count == 16, digits.allSatisfy({ $0.isASCII && ($0.isNumber || ("a"..."f").contains($0)) }) else {
            return nil
        }
        return BlogStamp(id: id, version: version, template: revision, hash: hash)
    }

    private static func isNumber(_ text: Substring) -> Bool {
        !text.isEmpty && text.allSatisfy { $0.isASCII && $0.isNumber }
    }
}
