import Foundation

/// The exact measurements the validator makes of each registered theme, recorded as data. A test fails if
/// any of them changes, appears or disappears (see ``ThemeValidator/deviations(of:)``); this is a ledger, not
/// a suppression. Regenerate a ledger only by deciding that the change is intended.
extension Theme {
    /// Swiss's ledger: Apple's system colours are kept for the series and the accent (owner decision 2026-11-09), so these are the exact findings of the dataviz method on them, light, dark and with Increase Contrast on. `positive` and `negative` are NOT system colours (owner decision 2026-11-09, same day): they are the text-safe pair and have no row here, because they reach 4.5:1 in every appearance. Rows beyond the 0.4.0 ledger (accent contrast, the increased-contrast appearances, ramps) were first measured in 0.5.0. See `SwissConformanceLedger.md`.
    static var swissConformance: Conformance {
        Conformance(kind: .ledger, entries: [
            ledgerFail(.lightnessBand, .light, "yellow", 0.865, 0.77),
            ledgerWarn(.markContrast, .light, "orange on background", 2.21, 3.0),
            ledgerWarn(.markContrast, .light, "green on background", 2.13, 3.0),
            ledgerWarn(.markContrast, .light, "yellow on background", 1.45, 3.0),
            ledgerWarn(.markContrast, .light, "cyan on background", 2.07, 3.0),
            ledgerWarn(.markContrast, .light, "orange on surface", 2.31, 3.0),
            ledgerWarn(.markContrast, .light, "green on surface", 2.22, 3.0),
            ledgerWarn(.markContrast, .light, "yellow on surface", 1.51, 3.0),
            ledgerWarn(.markContrast, .light, "cyan on surface", 2.16, 3.0),
            ledgerWarn(.markContrast, .light, "accent on background", 2.21, 3.0),
            ledgerWarn(.markContrast, .light, "accent on surface", 2.31, 3.0),
            ledgerWarn(.markContrast, .light, "muted on background", 1.84, 3.0),
            ledgerWarn(.markContrast, .light, "muted on surface", 1.93, 3.0),
            ledgerFail(.rampLightEnd, .light, "sequential", 1.37, 2.0),
            ledgerFail(.lightnessBand, .dark, "orange", 0.762, 0.67),
            ledgerFail(.lightnessBand, .dark, "green", 0.756, 0.67),
            ledgerFail(.lightnessBand, .dark, "yellow", 0.885, 0.67),
            ledgerFail(.lightnessBand, .dark, "cyan", 0.808, 0.67),
            ledgerWarn(.markContrast, .dark, "muted on background", 2.34, 3.0),
            ledgerWarn(.markContrast, .dark, "muted on surface", 2.2, 3.0),
            ledgerFail(.textContrast, .lightIncreased, "onAccent on accent", 4.12, 4.5),
            ledgerFail(.lightnessBand, .darkIncreased, "orange", 0.789, 0.67),
            ledgerFail(.lightnessBand, .darkIncreased, "indigo", 0.769, 0.67),
            ledgerFail(.lightnessBand, .darkIncreased, "green", 0.784, 0.67),
            ledgerFail(.lightnessBand, .darkIncreased, "purple", 0.781, 0.67),
            ledgerFail(.lightnessBand, .darkIncreased, "yellow", 0.904, 0.67),
            ledgerFail(.lightnessBand, .darkIncreased, "blue", 0.756, 0.67),
            ledgerFail(.lightnessBand, .darkIncreased, "red", 0.698, 0.67),
            ledgerFail(.lightnessBand, .darkIncreased, "cyan", 0.836, 0.67),
        ])
    }

    /// House's ledger: the exact findings on its current `EditorialTheme.house` colours, kept as they are.
    static var houseConformance: Conformance {
        Conformance(kind: .ledger, entries: [
            ledgerWarn(.markContrast, .light, "cyan on background", 2.98, 3.0),
            ledgerWarn(.markContrast, .light, "cyan on surface", 2.85, 3.0),
            ledgerFail(.textContrast, .light, "secondaryInk on background", 4.02, 4.5),
            ledgerFail(.textContrast, .light, "secondaryInk on surface", 3.83, 4.5),
            ledgerWarn(.textContrast, .light, "positive on background", 3.49, 4.5),
            ledgerWarn(.textContrast, .light, "positive on surface", 3.33, 4.5),
            ledgerWarn(.textContrast, .light, "negative on background", 4.38, 4.5),
            ledgerWarn(.textContrast, .light, "negative on surface", 4.18, 4.5),
            ledgerFail(.rampLightEnd, .light, "sequential", 1.08, 2.0),
        ])
    }

    /// Princeton's ledger: the exact findings on the composed palette. Its one failing check is the light end of Swiss's grey-to-orange sequential ramp, which it inherits (printed values carry those cells); every other finding is a mark that needs a direct label or printed value. Its `positive` and `negative` are Swiss's text-safe pair, so they have no rows.
    static var princetonConformance: Conformance {
        Conformance(kind: .ledger, entries: [
            ledgerWarn(.markContrast, .light, "orange on background", 2.9, 3.0),
            ledgerWarn(.markContrast, .light, "sky on background", 2.15, 3.0),
            ledgerWarn(.markContrast, .light, "teal on background", 2.09, 3.0),
            ledgerWarn(.markContrast, .light, "periwinkle on background", 2.27, 3.0),
            ledgerWarn(.markContrast, .light, "sky on surface", 2.25, 3.0),
            ledgerWarn(.markContrast, .light, "teal on surface", 2.18, 3.0),
            ledgerWarn(.markContrast, .light, "periwinkle on surface", 2.37, 3.0),
            ledgerWarn(.markContrast, .light, "accent on background", 2.9, 3.0),
            ledgerWarn(.markContrast, .light, "muted on background", 1.84, 3.0),
            ledgerWarn(.markContrast, .light, "muted on surface", 1.93, 3.0),
            ledgerFail(.rampLightEnd, .light, "sequential", 1.37, 2.0),
        ])
    }

    /// FT's ledger: the exact findings on the FT's own light colours (kept as they are) and on our authored dark variant.
    static var ftConformance: Conformance {
        Conformance(kind: .ledger, entries: [
            ledgerFail(.lightnessBand, .light, "purple", 0.407, 0.43),
            ledgerFail(.chromaFloor, .light, "teal", 0.086, 0.1),
            ledgerWarn(.markContrast, .light, "orange on background", 2.15, 3.0),
            ledgerWarn(.markContrast, .light, "orange on surface", 1.93, 3.0),
            ledgerWarn(.textContrast, .light, "positive on surface", 4.34, 4.5),
            ledgerWarn(.markContrast, .light, "warning on background", 2.15, 3.0),
            ledgerWarn(.markContrast, .light, "warning on surface", 1.93, 3.0),
            ledgerFail(.rampLightEnd, .light, "sequential", 1.09, 2.0),
            ledgerWarn(.markContrast, .dark, "claret on surface", 2.89, 3.0),
            ledgerWarn(.markContrast, .dark, "purple on surface", 2.85, 3.0),
        ])
    }

    /// Economist's ledger: the exact findings on the Economist's own light colours (kept as they are) and on our authored dark variant.
    static var economistConformance: Conformance {
        Conformance(kind: .ledger, entries: [
            ledgerFail(.lightnessBand, .light, "yellow", 0.8, 0.77),
            ledgerFail(.chromaFloor, .light, "green", 0.094, 0.1),
            ledgerFail(.chromaFloor, .light, "plum", 0.086, 0.1),
            ledgerWarn(.markContrast, .light, "cyan on background", 2.25, 3.0),
            ledgerWarn(.markContrast, .light, "yellow on background", 1.89, 3.0),
            ledgerWarn(.markContrast, .light, "cyan on surface", 2.01, 3.0),
            ledgerWarn(.markContrast, .light, "yellow on surface", 1.69, 3.0),
            ledgerFail(.textContrast, .light, "secondaryInk on background", 3.48, 4.5),
            ledgerFail(.textContrast, .light, "secondaryInk on surface", 3.11, 4.5),
            ledgerWarn(.textContrast, .light, "positive on background", 3.41, 4.5),
            ledgerWarn(.textContrast, .light, "positive on surface", 3.05, 4.5),
            ledgerWarn(.textContrast, .light, "negative on surface", 4.31, 4.5),
            ledgerWarn(.markContrast, .light, "warning on background", 1.89, 3.0),
            ledgerWarn(.markContrast, .light, "warning on surface", 1.69, 3.0),
            ledgerFail(.rampLightEnd, .light, "sequential", 1.36, 2.0),
            ledgerWarn(.markContrast, .dark, "blue on surface", 2.79, 3.0),
            ledgerWarn(.markContrast, .dark, "yellow on surface", 2.77, 3.0),
            ledgerWarn(.markContrast, .dark, "plum on surface", 2.81, 3.0),
        ])
    }

    /// Legacy Default's ledger: findings on the snapshotted system colours. Nothing tuned.
    static var legacyDefaultConformance: Conformance {
        Conformance(kind: .legacy, entries: [
            ledgerFail(.seriesCount, .light, "series", 10.0, 8.0),
            ledgerFail(.lightnessBand, .light, "yellow", 0.865, 0.77),
            ledgerWarn(.cvdSeparation, .light, "green / orange", 6.6, 8.0),
            ledgerWarn(.markContrast, .light, "green on background", 2.22, 3.0),
            ledgerWarn(.markContrast, .light, "orange on background", 2.31, 3.0),
            ledgerWarn(.markContrast, .light, "cyan on background", 2.16, 3.0),
            ledgerWarn(.markContrast, .light, "yellow on background", 1.51, 3.0),
            ledgerWarn(.markContrast, .light, "mint on background", 2.12, 3.0),
            ledgerFail(.textContrast, .light, "secondaryInk on background", 3.26, 4.5),
            ledgerFail(.textContrast, .light, "secondaryInk on surface", 3.26, 4.5),
            ledgerFail(.textContrast, .light, "link on background", 3.52, 4.5),
            ledgerFail(.textContrast, .light, "link on surface", 3.52, 4.5),
            ledgerWarn(.textContrast, .light, "positive on background", 2.22, 4.5),
            ledgerWarn(.textContrast, .light, "positive on surface", 2.22, 4.5),
            ledgerWarn(.textContrast, .light, "negative on background", 3.57, 4.5),
            ledgerWarn(.textContrast, .light, "negative on surface", 3.57, 4.5),
            ledgerWarn(.markContrast, .light, "accent on background", 2.31, 3.0),
            ledgerWarn(.markContrast, .light, "accent on surface", 2.31, 3.0),
            ledgerWarn(.markContrast, .light, "warning on background", 1.51, 3.0),
            ledgerWarn(.markContrast, .light, "warning on surface", 1.51, 3.0),
            ledgerFail(.rampMonotone, .light, "sequential", 3.0, 0.0),
            ledgerFail(.rampStepGap, .light, "sequential 1-2", 0.034, 0.06),
            ledgerFail(.rampStepGap, .light, "sequential 2-3", 0.05, 0.06),
            ledgerFail(.rampLightEnd, .light, "sequential", 1.53, 2.0),
            ledgerFail(.rampSingleHue, .light, "sequential", 106.0, 40.0),
            ledgerFail(.rampLightEnd, .light, "extraRamps.distribution", 1.45, 2.0),
            ledgerFail(.rampMonotone, .light, "extraRamps.sharpe", 1.0, 0.0),
            ledgerFail(.rampLightEnd, .light, "extraRamps.sharpe", 1.51, 2.0),
            ledgerFail(.rampSingleHue, .light, "extraRamps.sharpe", 122.0, 40.0),
            ledgerFail(.rampMonotone, .light, "extraRamps.volatility", 3.0, 0.0),
            ledgerFail(.rampStepGap, .light, "extraRamps.volatility 1-2", 0.034, 0.06),
            ledgerFail(.rampStepGap, .light, "extraRamps.volatility 2-3", 0.05, 0.06),
            ledgerFail(.rampLightEnd, .light, "extraRamps.volatility", 1.53, 2.0),
            ledgerFail(.rampSingleHue, .light, "extraRamps.volatility", 106.0, 40.0),
            ledgerFail(.lightnessBand, .dark, "green", 0.756, 0.67),
            ledgerFail(.lightnessBand, .dark, "orange", 0.762, 0.67),
            ledgerFail(.lightnessBand, .dark, "cyan", 0.808, 0.67),
            ledgerFail(.lightnessBand, .dark, "yellow", 0.885, 0.67),
            ledgerFail(.lightnessBand, .dark, "mint", 0.797, 0.67),
            ledgerFail(.cvdSeparation, .dark, "green / orange", 4.9, 6.0),
            ledgerFail(.rampMonotone, .dark, "sequential", 3.0, 0.0),
            ledgerFail(.rampStepGap, .dark, "sequential 1-2", 0.034, 0.06),
            ledgerFail(.rampStepGap, .dark, "sequential 2-3", 0.05, 0.06),
            ledgerFail(.rampSingleHue, .dark, "sequential", 106.0, 40.0),
            ledgerFail(.rampLightEnd, .dark, "extraRamps.distribution", 1.56, 2.0),
            ledgerFail(.rampMonotone, .dark, "extraRamps.sharpe", 1.0, 0.0),
            ledgerFail(.rampSingleHue, .dark, "extraRamps.sharpe", 122.0, 40.0),
            ledgerFail(.rampMonotone, .dark, "extraRamps.volatility", 3.0, 0.0),
            ledgerFail(.rampStepGap, .dark, "extraRamps.volatility 1-2", 0.034, 0.06),
            ledgerFail(.rampStepGap, .dark, "extraRamps.volatility 2-3", 0.05, 0.06),
            ledgerFail(.rampSingleHue, .dark, "extraRamps.volatility", 106.0, 40.0),
            ledgerWarn(.cvdSeparation, .lightIncreased, "green / orange", 6.3, 8.0),
            ledgerWarn(.cvdSeparation, .lightIncreased, "yellow / pink", 7.9, 8.0),
            ledgerWarn(.markContrast, .lightIncreased, "mint on background", 2.12, 3.0),
            ledgerFail(.lightnessBand, .darkIncreased, "blue", 0.756, 0.67),
            ledgerFail(.lightnessBand, .darkIncreased, "green", 0.784, 0.67),
            ledgerFail(.lightnessBand, .darkIncreased, "orange", 0.789, 0.67),
            ledgerFail(.lightnessBand, .darkIncreased, "purple", 0.781, 0.67),
            ledgerFail(.lightnessBand, .darkIncreased, "red", 0.698, 0.67),
            ledgerFail(.lightnessBand, .darkIncreased, "cyan", 0.836, 0.67),
            ledgerFail(.lightnessBand, .darkIncreased, "yellow", 0.904, 0.67),
            ledgerFail(.lightnessBand, .darkIncreased, "mint", 0.797, 0.67),
            ledgerFail(.lightnessBand, .darkIncreased, "indigo", 0.769, 0.67),
            ledgerFail(.cvdSeparation, .darkIncreased, "green / orange", 3.4, 6.0),
        ])
    }

    /// Legacy Dark's ledger: findings on `DarkTheme`'s colours on its own `#1A1A1F` background. Nothing tuned.
    static var legacyDarkConformance: Conformance {
        Conformance(kind: .legacy, entries: [
            ledgerFail(.seriesCount, .dark, "series", 10.0, 8.0),
            ledgerFail(.lightnessBand, .dark, "blue", 0.747, 0.67),
            ledgerFail(.lightnessBand, .dark, "green", 0.817, 0.67),
            ledgerFail(.lightnessBand, .dark, "orange", 0.819, 0.67),
            ledgerFail(.lightnessBand, .dark, "purple", 0.703, 0.67),
            ledgerFail(.lightnessBand, .dark, "red", 0.704, 0.67),
            ledgerFail(.lightnessBand, .dark, "cyan", 0.794, 0.67),
            ledgerFail(.lightnessBand, .dark, "yellow", 0.894, 0.67),
            ledgerFail(.lightnessBand, .dark, "pink", 0.757, 0.67),
            ledgerFail(.lightnessBand, .dark, "mint", 0.849, 0.67),
            ledgerFail(.lightnessBand, .dark, "lavender", 0.726, 0.67),
            ledgerFail(.cvdSeparation, .dark, "green / orange", 3.6, 6.0),
            ledgerFail(.rampMonotone, .dark, "sequential", 1.0, 0.0),
            ledgerFail(.rampStepGap, .dark, "sequential 0-1", 0.047, 0.06),
            ledgerFail(.rampStepGap, .dark, "sequential 1-2", 0.023, 0.06),
            ledgerFail(.rampSingleHue, .dark, "sequential", 133.0, 40.0),
            ledgerFail(.rampLightEnd, .dark, "extraRamps.distribution", 1.85, 2.0),
            ledgerFail(.rampMonotone, .dark, "extraRamps.sharpe", 1.0, 0.0),
            ledgerFail(.rampSingleHue, .dark, "extraRamps.sharpe", 123.0, 40.0),
            ledgerFail(.rampMonotone, .dark, "extraRamps.volatility", 1.0, 0.0),
            ledgerFail(.rampStepGap, .dark, "extraRamps.volatility 0-1", 0.047, 0.06),
            ledgerFail(.rampStepGap, .dark, "extraRamps.volatility 1-2", 0.023, 0.06),
            ledgerFail(.rampSingleHue, .dark, "extraRamps.volatility", 133.0, 40.0),
        ])
    }

    /// Legacy Financial's ledger: findings on `FinancialTheme`'s colours. Nothing tuned.
    static var legacyFinancialConformance: Conformance {
        Conformance(kind: .legacy, entries: [
            ledgerFail(.lightnessBand, .light, "blue", 0.424, 0.43),
            ledgerFail(.chromaFloor, .light, "bronze", 0.094, 0.1),
            ledgerFail(.chromaFloor, .light, "slate", 0.085, 0.1),
            ledgerWarn(.markContrast, .light, "gold on background", 2.57, 3.0),
            ledgerWarn(.markContrast, .light, "gold on surface", 2.47, 3.0),
            ledgerWarn(.markContrast, .light, "accent on background", 2.57, 3.0),
            ledgerWarn(.markContrast, .light, "accent on surface", 2.47, 3.0),
            ledgerWarn(.markContrast, .light, "warning on background", 1.96, 3.0),
            ledgerWarn(.markContrast, .light, "warning on surface", 1.88, 3.0),
            ledgerFail(.rampMonotone, .light, "sequential", 1.0, 0.0),
            ledgerFail(.rampSingleHue, .light, "sequential", 147.0, 40.0),
            ledgerFail(.rampLightEnd, .light, "extraRamps.distribution", 1.41, 2.0),
            ledgerFail(.rampMonotone, .light, "extraRamps.sharpe", 1.0, 0.0),
            ledgerFail(.rampLightEnd, .light, "extraRamps.sharpe", 1.96, 2.0),
            ledgerFail(.rampSingleHue, .light, "extraRamps.sharpe", 125.0, 40.0),
            ledgerFail(.rampMonotone, .light, "extraRamps.volatility", 2.0, 0.0),
            ledgerFail(.rampStepGap, .light, "extraRamps.volatility 0-1", 0.05, 0.06),
            ledgerFail(.rampLightEnd, .light, "extraRamps.volatility", 1.96, 2.0),
            ledgerFail(.rampSingleHue, .light, "extraRamps.volatility", 147.0, 40.0),
        ])
    }

    /// Legacy Accessible's ledger: findings on `AccessibleTheme`'s colours, which advertise colour-blind safety. Nothing tuned.
    static var legacyAccessibleConformance: Conformance {
        Conformance(kind: .legacy, entries: [
            ledgerFail(.lightnessBand, .light, "blue", 0.309, 0.43),
            ledgerFail(.chromaFloor, .light, "grey", 0.0, 0.1),
            ledgerFail(.chromaFloor, .light, "teal", 0.093, 0.1),
            ledgerWarn(.markContrast, .light, "olive on background", 2.27, 3.0),
            ledgerWarn(.markContrast, .light, "olive on surface", 2.03, 3.0),
            ledgerWarn(.textContrast, .light, "positive on surface", 4.47, 4.5),
            ledgerWarn(.markContrast, .light, "warning on background", 2.58, 3.0),
            ledgerWarn(.markContrast, .light, "warning on surface", 2.31, 3.0),
            ledgerFail(.rampMonotone, .light, "sequential", 1.0, 0.0),
            ledgerFail(.rampSingleHue, .light, "sequential", 149.0, 40.0),
            ledgerFail(.rampStepGap, .light, "diverging.high 0-1", 0.02, 0.06),
            ledgerFail(.rampMonotone, .light, "extraRamps.sharpe", 1.0, 0.0),
            ledgerFail(.rampSingleHue, .light, "extraRamps.sharpe", 128.0, 40.0),
            ledgerFail(.rampMonotone, .light, "extraRamps.volatility", 1.0, 0.0),
            ledgerFail(.rampSingleHue, .light, "extraRamps.volatility", 149.0, 40.0),
        ])
    }

    /// Console's ledger: the findings the package's validator makes about the page's own colours on its own `#1A1A2E` background, in the
    /// dark appearance (a fixed-dark theme is measured as dark only). Nothing tuned: these are the measured numbers, recorded as
    /// they came out, not written to look clean.
    ///
    /// In words: all eight series sit above the dark band's 0.67 OKLCH lightness ceiling (they are the Tailwind 400 shades, which
    /// are light), and green and orange are 7.1 apart under colour-vision simulation against the method's 8. The roles (ink, the
    /// three status colours, the link and the accent against the page and card surfaces) and both ramps pass.
    /// A chart in this theme labels series directly or prints values, as Swiss's does for its flagged slots.
    static var consoleConformance: Conformance {
        Conformance(kind: .ledger, entries: [
            ledgerFail(.lightnessBand, .dark, "blue", 0.714, 0.67),
            ledgerFail(.lightnessBand, .dark, "green", 0.8, 0.67),
            ledgerFail(.lightnessBand, .dark, "orange", 0.758, 0.67),
            ledgerFail(.lightnessBand, .dark, "purple", 0.722, 0.67),
            ledgerFail(.lightnessBand, .dark, "red", 0.711, 0.67),
            ledgerFail(.lightnessBand, .dark, "cyan", 0.797, 0.67),
            ledgerFail(.lightnessBand, .dark, "yellow", 0.861, 0.67),
            ledgerFail(.lightnessBand, .dark, "pink", 0.725, 0.67),
            ledgerWarn(.cvdSeparation, .dark, "green / orange", 7.1, 8.0),
        ])
    }
}
