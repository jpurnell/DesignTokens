import Foundation

/// The dataviz method's checks, ported to Swift from `validate_palette.js`.
///
/// ``validate(_:)`` measures a theme in every appearance it declares and returns every finding. It does
/// not decide whether a finding is acceptable: a theme's ``Theme/conformance`` does that, and
/// ``deviations(of:)`` compares the two. The measurements are exposed too (``measure(series:on:dark:pairs:)``,
/// ``measureRamp(hexes:surface:dark:)``) so a test can compare them to the JavaScript's.
public enum ThemeValidator {
    // MARK: Resolving colours

    /// A colour composited over an opaque surface in gamma-encoded sRGB, as a screen does. An opaque colour
    /// is returned as it is; a translucent colour has no contrast of its own.
    public static func resolved(_ colour: ColorValue, over surface: ColorValue) -> ColorValue {
        guard colour.alpha < 1 else { return ColorValue(colour.rgb) }
        func mix(_ top: UInt8, _ bottom: UInt8) -> UInt8 {
            let value = (Double(top) * colour.alpha + Double(bottom) * (1 - colour.alpha)).rounded()
            // alpha is a multiple of 1/255 in 0...1, so the blend is inside 0...255; a failure keeps the surface's channel
            guard let channel = UInt8(exactly: value) else { return bottom }
            return channel
        }
        return ColorValue(RGB(red: mix(colour.rgb.red, surface.rgb.red), green: mix(colour.rgb.green, surface.rgb.green),
                              blue: mix(colour.rgb.blue, surface.rgb.blue)))
    }

    /// The value of an adaptive colour in a validated appearance. A ``AppearanceSupport/fixedDark`` theme
    /// keeps its colours in the `light` slot.
    public static func value(_ adaptive: Adaptive, theme: Theme, appearance: ValidationAppearance) -> ColorValue {
        if theme.appearances == .fixedDark {
            return appearance.isIncreased ? (adaptive.lightIncreased ?? adaptive.light) : adaptive.light
        }
        return adaptive.value(in: appearance.isDark ? .dark : .light, increasedContrast: appearance.isIncreased)
    }

    /// A surface role resolved to an opaque colour. A translucent surface is composited over white, or
    /// over black on a dark surface.
    public static func surface(of theme: Theme, role: ColorRole, appearance: ValidationAppearance) -> ColorValue {
        let raw = value(theme.palette[role], theme: theme, appearance: appearance)
        let base = appearance.isDark ? ColorValue(RGB(rgb: 0x000000)) : ColorValue(RGB(rgb: 0xFFFFFF))
        return resolved(raw, over: base)
    }

    // MARK: Measuring

    /// Measures a categorical series against one surface.
    ///
    /// - Parameters:
    ///   - series: The colours, in order; translucent ones are composited over `surface` first.
    ///   - surface: The surface.
    ///   - dark: Whether the dark lightness band applies.
    ///   - pairs: Which pairs the separation checks compare.
    public static func measure(series: [ColorValue], on surface: ColorValue, dark: Bool, pairs: PairSelection) -> SeriesMeasurement {
        let colours = series.map { resolved($0, over: surface).rgb }
        return measure(colours: colours, surface: surface.rgb, dark: dark, pairs: pairs)
    }

    /// Measures colours given as `#RRGGBB` strings.
    ///
    /// - Throws: ``ValidationInputError/invalidHex(_:)`` naming the first string (a colour or the surface) that
    ///   is not a colour. It is never measured as black: a typo is an error, not a plausible-looking result.
    public static func measure(hexes: [String], surface: String, dark: Bool, pairs: PairSelection) throws -> SeriesMeasurement {
        let colours = try hexes.map(parseHex)
        return measure(colours: colours, surface: try parseHex(surface), dark: dark, pairs: pairs)
    }

    private static func parseHex(_ text: String) throws -> RGB {
        guard let colour = RGB(hex: text) else { throw ValidationInputError.invalidHex(text) }
        return colour
    }

    static func measure(colours: [RGB], surface: RGB, dark: Bool, pairs: PairSelection) -> SeriesMeasurement {
        let band = dark ? ValidationThresholds.darkBand : ValidationThresholds.lightBand
        let lightness = colours.map(ColorAnalysis.lightness)
        let chroma = colours.map(ColorAnalysis.chroma)
        let outOfBand = lightness.enumerated().filter { !band.contains($0.element) }.map { IndexedValue(index: $0.offset, value: $0.element) }
        let lowChroma = chroma.enumerated().filter { $0.element < ValidationThresholds.chromaFloor }.map { IndexedValue(index: $0.offset, value: $0.element) }
        let pairList = pairIndices(count: colours.count, pairs)

        var cvd: [PairMeasurement] = []
        var normal: [PairMeasurement] = []
        var worstCVD: PairMeasurement?
        var worstNormal: PairMeasurement?
        for kind in [CVDKind.protan, .deutan] {
            for (i, j) in pairList {
                let d = ColorAnalysis.deltaE(colours[i], colours[j], kind)
                if worstCVD == nil || d < (worstCVD?.value ?? d) {
                    worstCVD = PairMeasurement(first: i, second: j, value: d, kind: CVDKindName(rawValue: kind.rawValue))
                }
            }
        }
        for (i, j) in pairList {
            let protan = ColorAnalysis.deltaE(colours[i], colours[j], .protan)
            let deutan = ColorAnalysis.deltaE(colours[i], colours[j], .deutan)
            cvd.append(deutan < protan ? PairMeasurement(first: i, second: j, value: deutan, kind: .deutan)
                                       : PairMeasurement(first: i, second: j, value: protan, kind: .protan))
            let d = ColorAnalysis.deltaE(colours[i], colours[j], nil)
            normal.append(PairMeasurement(first: i, second: j, value: d, kind: nil))
            if worstNormal == nil || d < (worstNormal?.value ?? d) {
                worstNormal = PairMeasurement(first: i, second: j, value: d, kind: nil)
            }
        }
        let tritan = pairList.map { ColorAnalysis.deltaE(colours[$0.0], colours[$0.1], .tritan) }.min() ?? 99
        return SeriesMeasurement(
            hexes: colours.map(\.hex), lightness: lightness, chroma: chroma,
            contrast: colours.map { Contrast.ratio($0, surface) }, outOfBand: outOfBand,
            chromaBelowFloor: lowChroma, pairs: pairList, cvdByPair: cvd, normalByPair: normal,
            worstCVD: worstCVD, worstNormal: worstNormal, worstTritan: tritan)
    }

    private static func pairIndices(count: Int, _ selection: PairSelection) -> [(Int, Int)] {
        guard count > 1 else { return [] }
        switch selection {
        case .adjacent: return (0..<(count - 1)).map { ($0, $0 + 1) }
        case .all: return (0..<count).flatMap { i in ((i + 1)..<count).map { (i, $0) } }
        }
    }

    /// Measures an ordinal ramp, given as `#RRGGBB` strings, as the JavaScript's `validateOrdinal` does,
    /// except that steps with no hue (chroma under ``ValidationThresholds/achromaticChroma``) are left out of
    /// the hue spread, because the hue of a grey is numerical noise. (A diverging ramp's neutral midpoint is
    /// likewise left out of each arm's hue spread, which the JavaScript has no check for.)
    ///
    /// - Throws: ``ValidationInputError/invalidHex(_:)`` for a string that is not a colour.
    public static func measureRamp(hexes: [String], surface: String, dark: Bool) throws -> RampMeasurement {
        measureRamp(colours: try hexes.map(parseHex), surface: try parseHex(surface), dark: dark)
    }

    static func measureRamp(colours: [RGB], surface: RGB, dark: Bool, ignoringHueAt ignored: Int? = nil) -> RampMeasurement {
        let ls = colours.map(ColorAnalysis.lightness)
        let order = ls.indices.sorted { ls[$0] < ls[$1] }
        let forward = order.enumerated().allSatisfy { $0.offset == $0.element }
        let reverse = order.enumerated().allSatisfy { $0.element == ls.count - 1 - $0.offset }
        var reversals = 0
        var previous = 0.0
        for index in 1..<max(1, ls.count) {
            let delta = ls[index] - ls[index - 1]
            if previous != 0, delta != 0, (delta > 0) != (previous > 0) { reversals += 1 }
            if delta != 0 { previous = delta }
        }
        var thin: [(Int, Int, Double)] = []
        for index in 1..<max(1, ls.count) {
            let gap = abs(ls[index] - ls[index - 1])
            if gap < ValidationThresholds.rampMinStep { thin.append((index - 1, index, gap)) }
        }
        let byL = colours.indices.sorted { ls[$0] < ls[$1] }
        let endIndex = dark ? byL.first : byL.last
        let endContrast = endIndex.map { Contrast.ratio(colours[$0], surface) } ?? 21
        let hues = colours.enumerated()
            .filter { $0.offset != ignored && ColorAnalysis.chroma($0.element) >= ValidationThresholds.achromaticChroma }
            .map { ColorAnalysis.hue($0.element) }
        var spread = (hues.max() ?? 0) - (hues.min() ?? 0)
        if spread > 180 { spread = 360 - spread }
        return RampMeasurement(monotone: forward || reverse, reversals: reversals, thinSteps: thin,
                               lightEndContrast: endContrast, hueSpread: spread)
    }

    // MARK: Validating a theme

    /// Every finding for a theme, in every appearance it declares.
    ///
    /// Appearances: light and dark for a ``AppearanceSupport/both`` theme, light for a light-only one, dark
    /// for a fixed-dark one, and an increased-contrast appearance wherever the theme holds an
    /// increased-contrast value for a series. Checks: series band, chroma, colour-vision and normal
    /// separation, mark contrast on the background and surface; ramps; text, accent, status and
    /// on-accent contrast; structure.
    public static func validate(_ theme: Theme) -> [Finding] {
        var findings = structureFindings(theme)
        let appearances = validatedAppearances(theme)
        for (position, appearance) in appearances.enumerated() {
            findings += seriesFindings(theme, series: theme.palette.series, appearance: appearance, pairs: .adjacent,
                                       includeCount: position == 0)
            findings += roleFindings(theme, appearance: appearance)
            findings += rampFindings(theme, appearance: appearance)
        }
        return findings
    }

    static func validatedAppearances(_ theme: Theme) -> [ValidationAppearance] {
        let hasLightIncreased = theme.palette.series.contains { $0.color.lightIncreased != nil }
        let hasDarkIncreased = theme.palette.series.contains { $0.color.darkIncreased != nil }
        switch theme.appearances {
        case .both:
            return [.light, .dark] + (hasLightIncreased ? [.lightIncreased] : []) + (hasDarkIncreased ? [.darkIncreased] : [])
        case .lightOnly:
            return [.light] + (hasLightIncreased ? [.lightIncreased] : [])
        case .fixedDark:
            return [.dark] + (hasLightIncreased ? [.darkIncreased] : [])
        }
    }

    static func structureFindings(_ theme: Theme) -> [Finding] {
        var out: [Finding] = []
        let appearance: ValidationAppearance = theme.appearances == .fixedDark ? .dark : .light
        func add(_ subject: String, _ measured: Double, _ threshold: Double) {
            out.append(Finding(severity: .fail, check: .structure, appearance: appearance, subject: subject,
                               measured: Rounding.places(measured, 3), threshold: threshold))
        }
        for issue in theme.appearanceIssues { add(issue.subject, issue.kind == .missingDark ? 0 : 1, issue.kind == .missingDark ? 1 : 0) }
        let rules = theme.structure.rules
        let weights: [(String, Double)] = [
            ("rules.title.weight", rules.title.weight), ("rules.section", rules.section), ("rules.hairline", rules.hairline),
            ("rules.gridline", rules.gridline), ("rules.baseline", rules.baseline), ("rules.page", rules.page),
            ("rules.reference.weight", rules.reference.weight), ("rules.plotBorder", rules.plotBorder),
        ]
        for (subject, weight) in weights where !(weight >= 0) { add(subject, weight, 0) }
        if rules.title.weight > 0, rules.title.position == .none { add("rules.title.position", rules.title.weight, 0) }
        if rules.title.weight == 0, rules.title.position != .none { add("rules.title.weight", 0, 0) }
        return out
    }

    static func seriesFindings(_ theme: Theme, series: [NamedAdaptive], appearance: ValidationAppearance,
                                       pairs: PairSelection, includeCount: Bool) -> [Finding] {
        var out: [Finding] = []
        let background = surface(of: theme, role: .background, appearance: appearance)
        let panel = surface(of: theme, role: .surface, appearance: appearance)
        if includeCount, series.count > ValidationThresholds.maxSeries {
            out.append(Finding(severity: .fail, check: .seriesCount, appearance: appearance, subject: "series",
                               measured: Double(series.count), threshold: Double(ValidationThresholds.maxSeries)))
        }
        let colours = series.map { value($0.color, theme: theme, appearance: appearance) }
        let m = measure(series: colours, on: background, dark: appearance.isDark, pairs: pairs)
        let band = appearance.isDark ? ValidationThresholds.darkBand : ValidationThresholds.lightBand
        for item in m.outOfBand {
            let bound = item.value < band.lowerBound ? band.lowerBound : band.upperBound
            out.append(Finding(severity: .fail, check: .lightnessBand, appearance: appearance, subject: series[item.index].name,
                               measured: Rounding.places(item.value, 3), threshold: bound))
        }
        for item in m.chromaBelowFloor {
            out.append(Finding(severity: .fail, check: .chromaFloor, appearance: appearance, subject: series[item.index].name,
                               measured: Rounding.places(item.value, 3), threshold: ValidationThresholds.chromaFloor))
        }
        for pair in m.cvdByPair where pair.value < ValidationThresholds.cvdTarget {
            let fails = pair.value < ValidationThresholds.cvdFloor
            out.append(Finding(severity: fails ? .fail : .warn, check: .cvdSeparation, appearance: appearance,
                               subject: "\(series[pair.first].name) / \(series[pair.second].name)",
                               measured: Rounding.places(pair.value, 1),
                               threshold: fails ? ValidationThresholds.cvdFloor : ValidationThresholds.cvdTarget))
        }
        for pair in m.normalByPair where pair.value < ValidationThresholds.normalFloor {
            out.append(Finding(severity: .fail, check: .normalSeparation, appearance: appearance,
                               subject: "\(series[pair.first].name) / \(series[pair.second].name)",
                               measured: Rounding.places(pair.value, 1), threshold: ValidationThresholds.normalFloor))
        }
        for (index, entry) in series.enumerated() where m.contrast[index] < ValidationThresholds.markContrast {
            out.append(Finding(severity: .warn, check: .markContrast, appearance: appearance, subject: "\(entry.name) on background",
                               measured: Rounding.places(m.contrast[index], 2), threshold: ValidationThresholds.markContrast))
        }
        if panel != background {
            for (index, colour) in colours.enumerated() {
                let ratio = Contrast.ratio(resolved(colour, over: panel).rgb, panel.rgb)
                if ratio < ValidationThresholds.markContrast {
                    out.append(Finding(severity: .warn, check: .markContrast, appearance: appearance,
                                       subject: "\(series[index].name) on surface", measured: Rounding.places(ratio, 2),
                                       threshold: ValidationThresholds.markContrast))
                }
            }
        }
        return out
    }

    static func roleFindings(_ theme: Theme, appearance: ValidationAppearance) -> [Finding] {
        var out: [Finding] = []
        let surfaces: [(String, ColorValue)] = [
            ("background", surface(of: theme, role: .background, appearance: appearance)),
            ("surface", surface(of: theme, role: .surface, appearance: appearance)),
        ]
        func has(_ role: ColorRole) -> Bool {
            guard appearance.isIncreased else { return true }
            let adaptive = theme.palette[role]
            return appearance.isDark && theme.appearances != .fixedDark ? adaptive.darkIncreased != nil : adaptive.lightIncreased != nil
        }
        func check(_ role: ColorRole, _ kind: Check, _ severity: Severity, _ minimum: Double) {
            guard has(role) else { return }
            for (surfaceName, base) in surfaces {
                let colour = resolved(value(theme.palette[role], theme: theme, appearance: appearance), over: base)
                let ratio = Contrast.ratio(colour.rgb, base.rgb)
                if ratio < minimum {
                    out.append(Finding(severity: severity, check: kind, appearance: appearance,
                                       subject: "\(role.rawValue) on \(surfaceName)", measured: Rounding.places(ratio, 2), threshold: minimum))
                }
            }
        }
        check(.ink, .textContrast, .fail, ValidationThresholds.textContrast)
        check(.secondaryInk, .textContrast, .fail, ValidationThresholds.textContrast)
        check(.link, .textContrast, .fail, ValidationThresholds.textContrast)
        check(.positive, .textContrast, .warn, ValidationThresholds.textContrast)
        check(.negative, .textContrast, .warn, ValidationThresholds.textContrast)
        check(.accent, .markContrast, .warn, ValidationThresholds.markContrast)
        check(.warning, .markContrast, .warn, ValidationThresholds.markContrast)
        // `muted` is a mark colour only where it is the default fill (neutral marks); elsewhere it is a pale accent
        // helper that no chart draws as a mark by default, and the check would not describe anything drawn.
        if theme.structure.marks.defaultFill == .muted {
            check(.muted, .markContrast, .warn, ValidationThresholds.markContrast)
        }
        if has(.onAccent) || has(.accent) {
            let base = surface(of: theme, role: .background, appearance: appearance)
            let accent = resolved(value(theme.palette.accent, theme: theme, appearance: appearance), over: base)
            let ink = resolved(value(theme.palette.onAccent, theme: theme, appearance: appearance), over: accent)
            let ratio = Contrast.ratio(ink.rgb, accent.rgb)
            if ratio < ValidationThresholds.textContrast {
                out.append(Finding(severity: .fail, check: .textContrast, appearance: appearance, subject: "onAccent on accent",
                                   measured: Rounding.places(ratio, 2), threshold: ValidationThresholds.textContrast))
            }
        }
        return out
    }

    static func rampFindings(_ theme: Theme, appearance: ValidationAppearance) -> [Finding] {
        // Ramps have no increased-contrast values, so an increased appearance would only repeat the standard one.
        guard !appearance.isIncreased else { return [] }
        var out: [Finding] = []
        let base = surface(of: theme, role: .background, appearance: appearance)
        func steps(_ ramp: Ramp) -> [RGB] {
            let chosen = appearance.isDark && theme.appearances != .fixedDark ? (ramp.dark ?? ramp.light) : ramp.light
            return chosen.map { resolved($0, over: base).rgb }
        }
        // `outer` is the step that must clear the surface when it is not simply the lightest (or darkest):
        // an arm of a diverging ramp ends in its neutral midpoint, which is meant to sit near the surface.
        func emit(_ subject: String, _ colours: [RGB], outer: RGB?, midpoint: Int? = nil) {
            guard colours.count > 1 else { return }
            var m = measureRamp(colours: colours, surface: base.rgb, dark: appearance.isDark, ignoringHueAt: midpoint)
            if let outer { m.lightEndContrast = Contrast.ratio(outer, base.rgb) }
            if !m.monotone {
                out.append(Finding(severity: .fail, check: .rampMonotone, appearance: appearance, subject: subject,
                                   measured: Double(m.reversals), threshold: 0))
            }
            for (from, to, gap) in m.thinSteps {
                out.append(Finding(severity: .fail, check: .rampStepGap, appearance: appearance, subject: "\(subject) \(from)-\(to)",
                                   measured: Rounding.places(gap, 3), threshold: ValidationThresholds.rampMinStep))
            }
            if m.lightEndContrast < ValidationThresholds.rampEndContrast {
                out.append(Finding(severity: .fail, check: .rampLightEnd, appearance: appearance, subject: subject,
                                   measured: Rounding.places(m.lightEndContrast, 2), threshold: ValidationThresholds.rampEndContrast))
            }
            if m.hueSpread > ValidationThresholds.rampMaxHueSpread {
                out.append(Finding(severity: .fail, check: .rampSingleHue, appearance: appearance, subject: subject,
                                   measured: Rounding.places(m.hueSpread, 0), threshold: ValidationThresholds.rampMaxHueSpread))
            }
        }
        emit("sequential", steps(theme.palette.sequential), outer: nil)
        let diverging = steps(theme.palette.diverging)
        if diverging.count >= 3 {
            let middle = diverging.count / 2
            emit("diverging.low", Array(diverging[0...middle]), outer: diverging.first, midpoint: middle)
            emit("diverging.high", Array(diverging[middle...]), outer: diverging.last, midpoint: 0)
        } else {
            emit("diverging", diverging, outer: nil)
        }
        for name in theme.palette.extraRamps.keys.sorted() {
            if let ramp = theme.palette.extraRamps[name] { emit("extraRamps.\(name)", steps(ramp), outer: nil) }
        }
        return out
    }
}
