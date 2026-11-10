import Foundation

/// Emits one ``Theme`` for slide templates: a colour and font list to type into Keynote or PowerPoint, and
/// PowerPoint's own *Theme Colors* and *Theme Fonts* XML.
///
/// Three kinds of text:
/// 1. ``emitList(_:)``: a plain-text list. One `[slot]` block per ``ThemeSlot`` with every role, series and extra as
///    hex, then a `[type]` block with the fifteen ``TypeRole`` values (font chain, size in points, weight, tracking,
///    case, italic, line height).
/// 2. ``emitColourScheme(_:slot:)``: a DrawingML `<a:clrScheme>`, the root element of a Theme Colors file.
/// 3. ``emitFontScheme(_:)``: a DrawingML `<a:fontScheme>`, the root element of a Theme Fonts file.
///
/// ### Colour scheme mapping
/// - `dk1`, `dk2`, `lt1`, `lt2`: in a light slot, ink, secondary ink, background, surface. In a dark slot the dark pair is
///   the surfaces and the light pair is the text: `dk1` background, `dk2` surface, `lt1` ink, `lt2` secondary ink (use
///   the slide master's colour map `bg1="dk1" tx1="lt1"` with it).
/// - `accent1` is the accent; `accent2` to `accent6` are the first five series whose colour differs from the accent, in
///   order, padded with `muted` when a theme has fewer.
/// - `hlink` is the `link` role and `folHlink` is secondary ink.
///
/// The positive, negative and warning roles have no slot in a PowerPoint scheme; they are in the list only.
///
/// ### Fonts
/// ``fontChain(_:)`` resolves a ``FontFamilyRef`` to installable family names, dropping the CSS-only names
/// (`-apple-system`, `ui-monospace`, the generic families). Sans is SF Pro Text, SF Pro, Helvetica Neue, Helvetica, Arial.
/// A DrawingML typeface holds one name, so the font scheme names the first face (major: the `heading` role, minor: the `body`
/// role) and carries the rest of the chain in a comment.
///
/// Not produced: a `.thmx` or `.potx` package, a Keynote theme, or anything that sets the slide master's colour map. The
/// output has been checked for well-formedness and for the mapping above, not opened in Keynote or PowerPoint.
public enum SlidesEmitter {
    private static let cssOnlyNames: Set<String> = [
        "-apple-system", "BlinkMacSystemFont", "system-ui", "ui-sans-serif", "ui-serif", "ui-monospace",
        "sans-serif", "serif", "monospace",
    ]
    private static let namespace = "http://schemas.openxmlformats.org/drawingml/2006/main"

    // MARK: Fonts

    /// The installable family names for a font reference, in order of preference, with no repeats.
    public static func fontChain(_ ref: FontFamilyRef) -> [String] {
        switch ref {
        case .sans: names(in: FontStack.sans)
        case .mono: names(in: FontStack.mono)
        case .serifNewYork: names(in: FontStack.serifNewYork)
        case .serifGaramond: names(in: FontStack.serifGaramond)
        case .named(let name, let fallback): [name] + fontChain(fallback).filter { $0 != name }
        }
    }

    private static func names(in stack: String) -> [String] {
        stack.split(separator: ",").compactMap { part in
            let name = part.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "\"", with: "")
            return name.isEmpty || cssOnlyNames.contains(name) ? nil : name
        }
    }

    /// Apple's name for a numeric weight, rounded half up to the nearest hundred: 100 Ultralight, 200 Thin, 300 Light,
    /// 400 Regular, 500 Medium, 600 Semibold, 700 Bold, 800 Heavy, 900 Black.
    public static func weightName(_ weight: Int) -> String {
        let hundreds = min(max((weight + 50) / 100, 1), 9)
        return ["Ultralight", "Thin", "Light", "Regular", "Medium", "Semibold", "Bold", "Heavy", "Black"][hundreds - 1]
    }

    // MARK: List

    /// The plain-text colour and font list, ending in a newline.
    ///
    /// - Throws: An encoding error if the theme cannot be encoded for its content hash.
    public static func emitList(_ theme: Theme) throws -> String {
        var lines = [
            try header(theme, comment: "# ", close: ""),
            "# Colour and font list for Keynote and PowerPoint templates. Colours are hex per slot (appearance, standard or increased contrast).",
            "# Type rows: role, font chain (first installed wins), size, weight, tracking, case, italic, line height.",
        ]
        for slot in ThemeSlot.slots(for: theme) {
            lines.append("")
            lines.append("[\(slot.name)]")
            for role in ColorRole.allCases {
                lines.append(pad(role.rawValue, 20) + slot.rgb(theme.palette[role], in: theme).hex)
            }
            for (index, entry) in theme.palette.series.enumerated() {
                lines.append(pad("series-\(index + 1)", 20) + slot.rgb(entry.color, in: theme).hex + " " + entry.name)
            }
            for key in theme.palette.extras.keys.sorted() {
                guard let adaptive = theme.palette.extras[key] else { continue }
                lines.append(pad("extra.\(key)", 20) + slot.rgb(adaptive, in: theme).hex)
            }
        }
        lines.append("")
        lines.append("[type]")
        for role in TypeRole.allCases {
            let spec = theme.structure.type[role]
            let chain = fontChain(spec.family).joined(separator: ", ")
            let tracking = "tracking \(CSSNumber.string(spec.tracking)) em"
            lines.append(pad(role.rawValue, 14) + chain + "  \(CSSNumber.string(spec.size)) pt  \(weightName(spec.weight)) (\(spec.weight))  "
                         + "\(tracking)  case \(spec.uppercase ? "upper" : "normal")  italic \(spec.italic ? "yes" : "no")  line \(CSSNumber.string(spec.lineHeight))")
        }
        return lines.joined(separator: "\n") + "\n"
    }

    // MARK: PowerPoint colour scheme

    /// A DrawingML `<a:clrScheme>` for one slot, ending in a newline.
    ///
    /// - Throws: An encoding error if the theme cannot be encoded for its content hash.
    public static func emitColourScheme(_ theme: Theme, slot: ThemeSlot) throws -> String {
        let palette = theme.palette
        func value(_ adaptive: Adaptive) -> RGB { slot.rgb(adaptive, in: theme) }
        let accent = value(palette.accent)
        var accents = palette.series.map { value($0.color) }.filter { $0 != accent }.prefix(5).map { $0 }
        while accents.count < 5 { accents.append(value(palette.muted)) }
        let isDark = slot.appearance == .dark
        let entries: [(String, RGB)] = [
            ("dk1", isDark ? value(palette.background) : value(palette.ink)),
            ("lt1", isDark ? value(palette.ink) : value(palette.background)),
            ("dk2", isDark ? value(palette.surface) : value(palette.secondaryInk)),
            ("lt2", isDark ? value(palette.secondaryInk) : value(palette.surface)),
            ("accent1", accent),
            ("accent2", accents[0]), ("accent3", accents[1]), ("accent4", accents[2]),
            ("accent5", accents[3]), ("accent6", accents[4]),
            ("hlink", value(palette.link)),
            ("folHlink", value(palette.secondaryInk)),
        ]
        var lines = [
            "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>",
            try header(theme, comment: "<!-- ", close: " -->"),
            "<!-- PowerPoint Theme Colors: slot \(slot.name). dk1/dk2 and lt1/lt2 are the dark and light pairs; a dark slot expects the master's colour map bg1=dk1 tx1=lt1. -->",
            "<a:clrScheme xmlns:a=\"\(namespace)\" name=\"\(escape("\(theme.name) \(slot.name)"))\">",
        ]
        for (element, colour) in entries {
            lines.append("  <a:\(element)><a:srgbClr val=\"\(String(colour.hex.dropFirst()))\"/></a:\(element)>")
        }
        lines.append("</a:clrScheme>")
        return lines.joined(separator: "\n") + "\n"
    }

    // MARK: PowerPoint font scheme

    /// A DrawingML `<a:fontScheme>`, ending in a newline: major is the `heading` role's first face, minor the `body` role's.
    ///
    /// - Throws: An encoding error if the theme cannot be encoded for its content hash.
    public static func emitFontScheme(_ theme: Theme) throws -> String {
        let major = fontChain(theme.structure.type[.heading].family)
        let minor = fontChain(theme.structure.type[.body].family)
        func fallbacks(_ chain: [String]) -> String { chain.count > 1 ? chain.dropFirst().joined(separator: ", ") : "none" }
        var lines = [
            "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>",
            try header(theme, comment: "<!-- ", close: " -->"),
            "<!-- PowerPoint Theme Fonts. A typeface holds one name, so the fallback chains are here. Major (headings), role heading. Fallbacks: \(fallbacks(major)). Minor (body), role body. Fallbacks: \(fallbacks(minor)). -->",
            "<a:fontScheme xmlns:a=\"\(namespace)\" name=\"\(escape(theme.name))\">",
        ]
        for (element, chain) in [("majorFont", major), ("minorFont", minor)] {
            lines.append("  <a:\(element)>")
            lines.append("    <a:latin typeface=\"\(escape(chain.first ?? ""))\"/>")
            lines.append("    <a:ea typeface=\"\"/>")
            lines.append("    <a:cs typeface=\"\"/>")
            lines.append("  </a:\(element)>")
        }
        lines.append("</a:fontScheme>")
        return lines.joined(separator: "\n") + "\n"
    }

    // MARK: Helpers

    private static func header(_ theme: Theme, comment open: String, close: String) throws -> String {
        let hash = try ThemeCodec.fingerprint(of: theme)
        // "--" is not allowed inside an XML comment; a name that has it is spaced out
        let name = close.isEmpty ? theme.name : theme.name.replacingOccurrences(of: "--", with: "- -")
        return "\(open)Generated by design-tokens. Do not edit. Theme: \(theme.id) (\(name)) | DesignTokens \(DesignTokens.version) | System colours: snapshot of \(Snapshot.systemRelease) | hash fnv1a64:\(hash)\(close)"
    }

    private static func pad(_ text: String, _ width: Int) -> String {
        text + String(repeating: " ", count: max(1, width - text.count))
    }

    private static func escape(_ text: String) -> String {
        text.replacingOccurrences(of: "&", with: "&amp;").replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;").replacingOccurrences(of: "\"", with: "&quot;")
    }
}
