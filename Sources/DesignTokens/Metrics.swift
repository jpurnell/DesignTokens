/// Rule weights in points. Weight is information: heavier means higher in the hierarchy.
public enum Rule: Sendable, Hashable, CaseIterable {
    /// Hairline: captions, row separation.
    case hairline
    /// Section rule: a new day or section.
    case section
    /// Page rule: the header of a page.
    case page

    /// The weight in points.
    public var points: Int {
        switch self {
        case .hairline: 1
        case .section: 3
        case .page: 8
        }
    }

    /// The name used in generated files.
    public var name: String {
        switch self {
        case .hairline: "hairline"
        case .section: "section"
        case .page: "page"
        }
    }
}

/// The 12-column grid, in points and column numbers.
public enum Grid {
    /// Number of columns.
    public static let columns = 12
    /// Gutter between columns, in points.
    public static let gutter = 16
    /// The base unit that every spacing value is a multiple of, in points.
    public static let baseUnit = 4
    /// The label column: columns 1 to 3.
    public static let label = 1...3
    /// The reading column: columns 4 to 10.
    public static let reading = 4...10
    /// Wide media: columns 4 to 12.
    public static let wide = 4...12
}

/// Corner radii in points.
public enum Radius {
    /// Containers have square corners.
    public static let container = 0
    /// Controls have a 4 point radius.
    public static let control = 4
}
