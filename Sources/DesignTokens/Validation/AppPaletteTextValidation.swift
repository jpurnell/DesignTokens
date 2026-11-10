import Foundation

extension ThemeValidator {
    /// The surfaces a palette's text roles are measured on in one appearance: the declared list (named by hex), or
    /// the theme's `background` and `surface`.
    private static func textSurfaces(_ palette: AppPalette, theme: Theme, appearance: ValidationAppearance) -> [(String, ColorValue)] {
        guard let declared = palette.textSurfaces?.list(for: appearance) else {
            return [("background", surface(of: theme, role: .background, appearance: appearance)),
                    ("surface", surface(of: theme, role: .surface, appearance: appearance))]
        }
        let base = appearance.isDark ? ColorValue(RGB(rgb: 0x000000)) : ColorValue(RGB(rgb: 0xFFFFFF))
        var seen = Set<String>()
        var out: [(String, ColorValue)] = []
        for colour in declared {
            let opaque = resolved(colour, over: base)
            if seen.insert(opaque.rgb.hex).inserted { out.append((opaque.rgb.hex, opaque)) }
        }
        return out
    }

    /// The findings for a palette's text roles in one appearance: each role as text, on each surface.
    static func textRoleFindings(_ theme: Theme, palette: AppPalette, appearance: ValidationAppearance) -> [Finding] {
        let surfaces = textSurfaces(palette, theme: theme, appearance: appearance)
        var out: [Finding] = []
        for role in palette.textRoles {
            if appearance.isIncreased {
                let slot = appearance.isDark && theme.appearances != .fixedDark ? role.color.darkIncreased : role.color.lightIncreased
                guard slot != nil else { continue }
            }
            let colour = value(role.color, theme: theme, appearance: appearance)
            for (name, base) in surfaces {
                let ratio = Contrast.ratio(resolved(colour, over: base).rgb, base.rgb)
                if ratio < ValidationThresholds.textContrast {
                    out.append(Finding(severity: .fail, check: .textContrast, appearance: appearance,
                                       subject: "\(role.name) on \(name)", measured: Rounding.places(ratio, 2),
                                       threshold: ValidationThresholds.textContrast))
                }
            }
        }
        return out
    }

    /// Findings about the text declarations themselves, and, when the app names an ``AppTextRole`` enum, about
    /// whether the enum and the declared roles agree.
    static func textStructureFindings(of palette: AppPalette, expectedRoles: [String]?) -> [Finding] {
        var out: [Finding] = []
        func add(_ subject: String) {
            out.append(Finding(severity: .fail, check: .structure, appearance: .light, subject: subject, measured: 0, threshold: 1))
        }
        var seen = Set<String>()
        var reported = Set<String>()
        for role in palette.textRoles where !seen.insert(role.name).inserted && reported.insert(role.name).inserted {
            add("text role \(role.name) (duplicate name)")
        }
        if let surfaces = palette.textSurfaces, !palette.textRoles.isEmpty {
            if surfaces.light.isEmpty { add("textSurfaces light (empty)") }
            if surfaces.dark?.isEmpty == true { add("textSurfaces dark (empty)") }
            if surfaces.lightIncreased?.isEmpty == true { add("textSurfaces lightIncreased (empty)") }
            if surfaces.darkIncreased?.isEmpty == true { add("textSurfaces darkIncreased (empty)") }
        }
        if let expectedRoles {
            for name in expectedRoles where !seen.contains(name) { add("text role \(name) (not declared)") }
            for role in palette.textRoles where !expectedRoles.contains(role.name) && reported.insert("case " + role.name).inserted {
                add("text role \(role.name) (no case in TextRoles)")
            }
        }
        return out
    }
}
