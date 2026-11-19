import Foundation

/// Why an icon was refused.
public enum IconError: Error, Sendable, Equatable {
    /// A name that is not lower-case letters, digits and hyphens.
    case name(String)
    /// A view box that is not four numbers.
    case viewBox(String)
    /// A drawing with no content.
    case emptyBody
}

/// One drawing of a theme's icon set: SVG shapes on a view box, with no scripts, styles or images in it.
public struct Icon: Sendable, Hashable, Codable {
    /// The icon's name: lower-case letters, digits and hyphens. It names the file (`<name>.svg`).
    public var name: String
    /// The SVG view box, four numbers: `0 0 56 56`.
    public var viewBox: String
    /// The SVG elements inside the root: rectangles, paths and the like.
    public var body: String

    /// Creates an icon.
    ///
    /// - Throws: ``IconError`` for a name that is not lower-case letters, digits and hyphens, a view box that is not four numbers, or an
    ///   empty body.
    public init(name: String, viewBox: String = "0 0 56 56", body: String) throws {
        guard !name.isEmpty, name.allSatisfy({ ($0 >= "a" && $0 <= "z") || ($0 >= "0" && $0 <= "9") || $0 == "-" }) else { throw IconError.name(name) }
        let numbers = viewBox.split(separator: " ").compactMap { Double($0) }
        guard numbers.count == 4, viewBox.split(separator: " ").count == 4 else { throw IconError.viewBox(viewBox) }
        guard !body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { throw IconError.emptyBody }
        self.name = name
        self.viewBox = viewBox
        self.body = body
    }

    /// An icon written as a literal in source, without the checks (see ``EdgeStep/init(literal:_:)``).
    init(literal name: String, _ body: String) {
        self.name = name
        self.viewBox = "0 0 56 56"
        self.body = body
    }

    private enum CodingKeys: String, CodingKey { case name, viewBox, body }

    /// Decodes an icon, applying the same checks as the initialiser.
    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(name: c.decode(String.self, forKey: .name), viewBox: c.decode(String.self, forKey: .viewBox), body: c.decode(String.self, forKey: .body))
    }
}

/// A theme's icons, drawn as vectors so they stay sharp at any scale: the dock's tiles, the applications and folders a skin pictures.
public struct IconSet: Sendable, Hashable, Codable {
    /// The icons, in the order the theme lists them.
    public var icons: [Icon]

    /// Creates a set.
    public init(icons: [Icon]) {
        self.icons = icons
    }
}
