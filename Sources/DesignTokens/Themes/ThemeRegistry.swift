import Foundation

public extension Theme {
    /// Every theme the package ships, in a stable order: Swiss, House, Princeton, FT, Economist, then the
    /// four legacy themes and Console. Tests iterate this list, so a theme added here is validated, round-tripped and
    /// held to its ledger automatically.
    ///
    /// Built once: the list and ``named(_:)`` read stored values, not a fresh construction per access.
    static let all: [Theme] = [swiss, house, princeton, ft, economist, legacyDefault, legacyDark, legacyFinancial, legacyAccessible, console]

    private static let byID: [String: Theme] = Dictionary(all.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })

    /// The registered theme with an id, or `nil`. Ids are exact: `"Swiss"` is not `"swiss"`.
    static func named(_ id: String) -> Theme? {
        byID[id]
    }
}
