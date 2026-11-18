import Foundation
import Testing
@testable import DesignTokens

@Suite("GTK emitter")
struct GTKEmitterTests {
    private func emit(_ theme: Theme, _ slotName: String = "light") throws -> String {
        let slot = try #require(ThemeSlot.slots(for: theme).first { $0.name == slotName })
        return try GTKEmitter.emit(theme, slot: slot)
    }

    private func block(_ selector: String, in css: String) -> [String] {
        var lines: [String] = []
        var inside = false
        for line in css.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline) {
            if line == "\(selector) {" { inside = true; continue }
            if inside, line == "}" { return lines }
            if inside { lines.append(line.trimmingCharacters(in: .whitespaces)) }
        }
        return lines
    }

    @Test("named colours cover libadwaita and plain GTK, from the slot's palette")
    func namedColours() throws {
        let css = try emit(.swiss)
        for name in ["window_bg_color", "window_fg_color", "view_bg_color", "view_fg_color", "headerbar_bg_color", "card_bg_color",
                     "accent_bg_color", "accent_fg_color", "accent_color", "borders", "theme_bg_color", "theme_fg_color",
                     "theme_base_color", "theme_text_color", "theme_selected_bg_color", "theme_selected_fg_color",
                     "success_color", "warning_color", "error_color"] {
            #expect(css.contains("@define-color \(name) #"), "\(name)")
        }
    }

    @Test("light and dark slots give different background colours for a theme that has both")
    func slotsDiffer() throws {
        let light = try emit(.swiss, "light"), dark = try emit(.swiss, "dark")
        let lightBackground = ThemeSlot.slots(for: .swiss).first { $0.name == "light" }.map { ColorValue($0.rgb(Theme.swiss.palette.background, in: .swiss)).hex }
        let darkBackground = ThemeSlot.slots(for: .swiss).first { $0.name == "dark" }.map { ColorValue($0.rgb(Theme.swiss.palette.background, in: .swiss)).hex }
        #expect(light.contains("@define-color window_bg_color \(try #require(lightBackground));"))
        #expect(dark.contains("@define-color window_bg_color \(try #require(darkBackground));"))
        #expect(lightBackground != darkBackground)
    }

    @Test("GTK CSS has no var(), no color-mix and no data-URI image: GTK reads none of them")
    func onlyWhatGTKReads() throws {
        for theme in Theme.all {
            for slot in ThemeSlot.slots(for: theme) where !slot.increasedContrast {
                let css = try GTKEmitter.emit(theme, slot: slot)
                for forbidden in ["var(", "color-mix", "data:", "backdrop-filter", "image-rendering"] {
                    #expect(!css.contains(forbidden), "\(theme.id) \(slot.name) has \(forbidden)")
                }
            }
        }
    }

    @Test("System 7 buttons: outline as inset shadows, radius 3, no gradient, 20 px high, no padding above or below")
    func system7Button() throws {
        let css = try emit(.system7)
        let rest = block("button", in: css)
        #expect(rest.contains("box-shadow: inset -1px 0 0 0 #000000, inset 0 -1px 0 0 #000000, inset 1px 0 0 0 #000000, inset 0 1px 0 0 #000000;"))
        #expect(rest.contains("border-radius: 3px;"))
        #expect(rest.contains("background-image: none;"))
        #expect(rest.contains("min-height: 20px;"))
        #expect(rest.contains("border: none;"))
    }

    @Test("System 7 default button gets the 3/1/1 ring; pressed buttons invert")
    func system7DefaultAndPressed() throws {
        let css = try emit(.system7)
        let ring = block("button.suggested-action, button.default", in: css)
        #expect(ring.contains { $0.hasPrefix("box-shadow: inset -5px 0 0 0 #000000, inset 0 -5px 0 0 #000000, inset 5px 0 0 0 #000000, inset 0 5px 0 0 #000000, inset -4px 0 0 0 #FFFFFF") })
        #expect(ring.contains("border-radius: 7px;"))
        let active = block("button:active", in: css)
        #expect(active.contains("background-color: #000000;"))
        #expect(active.contains("color: #FFFFFF;"))
    }

    @Test("GTK stacks a shadow list the other way round, so stripes are listed deepest first and the outline comes last")
    func shadowOrder() throws {
        let slot = try #require(ThemeSlot.slots(for: .platinum).first)
        let css = try GTKEmitter.emit(.platinum, slot: slot)
        let shadow = try #require(block("button", in: css).first { $0.hasPrefix("box-shadow:") })
        #expect(shadow.hasPrefix("box-shadow: inset -3px 0 0 0 #AAAAAA, inset 0 -3px 0 0 #AAAAAA, inset 3px 0 0 0 #FFFFFF, inset 0 3px 0 0 #FFFFFF, "))
        #expect(shadow.hasSuffix("inset -1px 0 0 0 #000000, inset 0 -1px 0 0 #000000, inset 1px 0 0 0 #000000, inset 0 1px 0 0 #000000;"))
    }

    @Test("UI text takes the theme's family and size")
    func font() throws {
        let css = try emit(.system7)
        let rule = block("*", in: css)
        #expect(rule.contains("font-size: 12px;"))
        #expect(rule.contains { $0.hasPrefix("font-family: \"Chicago\", \"Geneva\"") })
    }

    @Test("selection and the title bar take the palette, so no system accent colour shows through")
    func selectionAndHeaderbar() throws {
        let css = try emit(.system7)
        #expect(block("selection, *:selected", in: css) == ["background-color: @theme_selected_bg_color;", "color: @theme_selected_fg_color;"])
        let bar = block("headerbar, .titlebar", in: css)
        #expect(bar.contains("background-color: @headerbar_bg_color;"))
        #expect(bar.contains("background-image: none;"))
        #expect(bar.contains("color: @headerbar_fg_color;"))
    }

    @Test("a theme without surfaces still gets its colours and the window rule, and no widget recipes")
    func noSurfaces() throws {
        let css = try emit(.swiss)
        #expect(css.contains("window, .background {"))
        #expect(block("button", in: css) == [] && block("entry, spinbutton", in: css) == [] && block(".card", in: css) == [])
    }

    @Test("emitting is deterministic and the header names the theme and slot")
    func deterministic() throws {
        let a = try emit(.system7), b = try emit(.system7)
        #expect(a == b)
        #expect(a.hasPrefix("/* Generated by design-tokens. Do not edit. Theme: system7 (System 7 (1-bit)), slot light"))
    }

    @Test("the generator writes <id>.gtk.css for every theme and <id>.gtk-dark.css only where there is a dark appearance")
    func generatorFiles() throws {
        let files = try Generator.files(formats: [.gtk]).map(\.path)
        for theme in Theme.all {
            #expect(files.contains("themes/\(theme.id).gtk.css"))
            #expect(files.contains("themes/\(theme.id).gtk-dark.css") == (theme.appearances == .both), "\(theme.id)")
        }
    }
}
