import Foundation

/// Emits the Tumblr paste-in block for a ``Theme``.
///
/// The block is CSS only, delimited by sentinel comments, and is pasted by hand into the style element of the
/// blog's Tumblr theme. It is not a stylesheet to link and it carries no Tumblr markup: the `{Title}` and
/// `{block:Posts}` tags, the analytics snippet and the `<link>` elements stay in the theme HTML, which the
/// owner keeps. It has three parts, in this order:
///
/// 1. **Generated data** from the theme: colour variables for light, `prefers-contrast: more`, dark and dark
///    with `prefers-contrast: more` (from each ``Adaptive`` value), the rule weights, gutter and columns, the type
///    roles and the font stacks.
/// 2. **The Tumblr template** (`TumblrTemplate`): fixed selectors for the blog's own classes and Tumblr's
///    (`div.npf-link-block`, `.tumblr_video_container`), reading only those variables.
/// 3. **The stamp** (``BlogStamp``), in the header comment and in `--theme-stamp`, so ``BlogChecker`` can tell a
///    pasted block from the current theme.
///
/// The blog's link colour is a Tumblr-template decision, taken from the draft and not from the theme's `link` role:
/// links are ink in light and the accent in dark, with the accent as the underline in both.
public enum TumblrEmitter {
    /// The DesignTokens version written into every stamp: ``DesignTokens/version``, the package's one version string.
    public static var packageVersion: String { DesignTokens.version }

    /// The revision of `TumblrTemplate`. Bump it when the fixed selectors change, so a template-only change
    /// makes a pasted block stale even though no theme value moved.
    public static let templateRevision = 1

    /// The marker between the generated data and the template.
    static let templateMarker = "/* >>> Tumblr template: selectors only, no literals */"
    private static let beginSentinel = "/* >>> design-tokens block begin */"
    private static let endSentinel = "/* >>> design-tokens block end */"

    /// The class names the theme HTML must keep, because the template's selectors depend on them.
    static let contractClasses = ".header .nav .post .post.newday .datetime .day .my .type .row .k .caption .video "
        + ".short_quote .medium_quote .long_quote .pager, and Tumblr's div.npf-link-block, .tumblr_video_container"

    /// The stamp for a theme: its id, the package version, the template revision and the fingerprint of its
    /// canonical JSON.
    ///
    /// - Throws: An encoding error if the theme cannot be encoded.
    public static func stamp(for theme: Theme) throws -> BlogStamp {
        BlogStamp(id: theme.id, version: packageVersion, template: templateRevision,
                  hash: "fnv1a64:" + (try ThemeCodec.fingerprint(of: theme)))
    }

    /// The paste-in block for a theme, ending in one newline.
    ///
    /// - Throws: An encoding error if the theme cannot be encoded.
    public static func emit(_ theme: Theme) throws -> String {
        let stamp = try stamp(for: theme)
        var lines = [beginSentinel]
        lines.append("/* theme: \(theme.id) | DesignTokens \(stamp.version) | template \(stamp.template) | hash \(stamp.hash) "
                     + "| snapshot \(Snapshot.systemRelease) | generated, do not edit */")
        lines.append("/* contract: the theme HTML must keep these class names: \(contractClasses) */")
        lines.append("/* paste inside the theme's style element, replacing everything from the begin comment to the end comment */")

        let colours = colourVariables(theme)
        lines.append(":root {")
        lines.append("  --theme-stamp: \"\(stamp.text)\";")
        lines.append("  color-scheme: \(colourScheme(theme.appearances));")
        for variable in colours { lines.append("  --\(variable.name): \(variable.light.hex);") }
        lines.append(contentsOf: structureLines(theme.structure).map { "  " + $0 })
        lines.append("}")

        // Order is the cascade: light contrast, then dark, then dark contrast, so the dark scheme wins over
        // the light contrast block and the dark contrast block wins over the standard dark values.
        let lightMore = colours.compactMap { v in v.lightIncreased.map { (v.name, $0) } }
        appendBlock(&lines, media: "(prefers-contrast: more)", declarations: lightMore)
        if theme.appearances == .both {
            appendBlock(&lines, media: "(prefers-color-scheme: dark)", declarations: colours.map { ($0.name, $0.dark) })
            let darkMore = colours.compactMap { v in v.darkIncreased.map { (v.name, $0) } }
            appendBlock(&lines, media: "(prefers-contrast: more) and (prefers-color-scheme: dark)", declarations: darkMore)
        }

        lines.append(templateMarker)
        lines.append(TumblrTemplate.css)
        lines.append(endSentinel)
        return lines.joined(separator: "\n") + "\n"
    }

    // MARK: Colours

    private struct ColourVariable {
        var name: String
        var light: ColorValue
        var dark: ColorValue
        var lightIncreased: ColorValue?
        var darkIncreased: ColorValue?
    }

    /// The blog's six colour variables, each from the theme's own ``Adaptive`` values.
    private static func colourVariables(_ theme: Theme) -> [ColourVariable] {
        let p = theme.palette
        func variable(_ name: String, light: Adaptive, dark: Adaptive) -> ColourVariable {
            ColourVariable(name: name,
                           light: light.value(in: .light, increasedContrast: false),
                           dark: dark.value(in: .dark, increasedContrast: false),
                           lightIncreased: light.lightIncreased,
                           darkIncreased: dark.darkIncreased)
        }
        return [
            variable("bg", light: p.background, dark: p.background),
            variable("fg", light: p.ink, dark: p.ink),
            variable("muted", light: p.secondaryInk, dark: p.secondaryInk),
            variable("hair", light: p.rule, dark: p.rule),
            variable("accent", light: p.accent, dark: p.accent),
            variable("link", light: p.ink, dark: p.accent),
        ]
    }

    private static func colourScheme(_ support: AppearanceSupport) -> String {
        switch support {
        case .both: "light dark"
        case .lightOnly: "light"
        case .fixedDark: "dark"
        }
    }

    private static func appendBlock(_ lines: inout [String], media: String, declarations: [(String, ColorValue)]) {
        guard !declarations.isEmpty else { return }
        lines.append("@media \(media) {")
        lines.append("  :root {")
        for (name, value) in declarations { lines.append("    --\(name): \(value.hex);") }
        lines.append("  }")
        lines.append("}")
    }

    // MARK: Structure

    private static func structureLines(_ structure: Structure) -> [String] {
        var lines = [
            "--rule-page: \(px(structure.rules.page));",
            "--rule-section: \(px(structure.rules.section));",
            "--rule-hairline: \(px(structure.rules.hairline));",
            "--gutter: \(px(structure.layout.gutter));",
            "--columns: \(structure.layout.columns);",
            "--face: \(css(structure.type.body.family));",
            "--mono: \(css(.mono));",
        ]
        let roles: [(String, TextSpec)] = [
            ("label", structure.type.label), ("caption", structure.type.caption), ("body", structure.type.body),
            ("heading", structure.type.heading), ("title", structure.type.uiTitle), ("display", structure.type.display),
        ]
        for (name, spec) in roles {
            lines.append("--\(name)-size: \(name == "display" ? fluid(spec.size) : px(spec.size));")
            lines.append("--\(name)-line: \(CSSNumber.string(spec.lineHeight));")
            lines.append("--\(name)-weight: \(spec.weight);")
            lines.append("--\(name)-tracking: \(spec.tracking == 0 ? "0" : CSSNumber.string(spec.tracking) + "em");")
        }
        lines.append("--label-transform: \(structure.type.label.uppercase ? "uppercase" : "none");")
        return lines
    }

    /// The display register scales with the viewport: the package's fluid range, capped at the theme's display size.
    private static func fluid(_ size: Double) -> String {
        guard let range = TypeStyle.display.fluid else { return px(size) }
        return FluidSize(min: Swift.min(range.min, size), vw: range.vw, max: size).css
    }

    private static func px(_ value: Double) -> String { "\(CSSNumber.string(value))px" }

    /// A font family as a CSS `font-family` value; a named face is followed by its fallback stack.
    private static func css(_ family: FontFamilyRef) -> String {
        switch family {
        case .sans: FontStack.sans
        case .mono: FontStack.mono
        case .serifNewYork: FontStack.serifNewYork
        case .serifGaramond: FontStack.serifGaramond
        case .named(let name, let fallback): "\"\(name)\", \(css(fallback))"
        }
    }
}
