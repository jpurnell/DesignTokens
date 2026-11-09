import Foundation

public extension Theme {
    /// Every theme the package ships, in a stable order: Swiss, House, Princeton, FT, Economist, then the
    /// four legacy themes. Tests iterate this list, so a theme added here is validated, round-tripped and
    /// held to its ledger automatically.
    static var all: [Theme] {
        [swiss, house, princeton, ft, economist, legacyDefault, legacyDark, legacyFinancial, legacyAccessible]
    }

    /// The registered theme with an id, or `nil`.
    static func named(_ id: String) -> Theme? {
        all.first { $0.id == id }
    }
}
