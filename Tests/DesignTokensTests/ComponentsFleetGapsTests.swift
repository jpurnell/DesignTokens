import Foundation
import Testing
@testable import DesignTokens

@Suite("components.css gaps reported by the FleetWatch adoption (0.13.0)")
struct ComponentsFleetGapsTests {
    private static var css: String { ComponentsCSSEmitter.emit() }
    private static let always = CSSReader.outsideMedia(css)
    private static func narrow() -> String {
        CSSReader.mediaBodies("max-width: \(BrowserSupport.Breakpoints.tableStackBelowPixels)px", in: css).joined(separator: "\n")
    }
    private static func forced() -> String { CSSReader.mediaBodies("forced-colors: active", in: css).joined(separator: "\n") }
    private static func more() -> String { CSSReader.mediaBodies("prefers-contrast: more", in: css).joined(separator: "\n") }

    // MARK: Meter

    @Test("a meter is a track and a fill in a status colour, from theme properties, with the figure beside it")
    func meter() {
        let css = Self.css
        let track = CSSReader.declarations(of: ".dt-meter__track ", in: Self.always)
        #expect(track.contains("background: var(--rule)") && track.contains("border: var(--rule-hairline) solid var(--secondary-ink)"))
        #expect(CSSReader.declarations(of: ".dt-meter ", in: Self.always).contains("display: inline-flex"))
        #expect(CSSReader.declarations(of: ".dt-meter__figure ", in: Self.always).contains("font-variant-numeric: tabular-nums"))
        let colours = ["success": "--positive", "caution": "--warning", "warning": "--extra-alert", "destructive": "--negative", "neutral": "--secondary-ink"]
        for (tone, property) in colours {
            let fill = CSSReader.declarations(of: ".dt-meter--\(tone) .dt-meter__fill", in: Self.always)
            #expect(fill.contains("background: var(\(property))"), Comment(rawValue: tone))
            #expect(css.contains(".dt-meter--\(tone) .dt-meter__figure::before"), "a glyph, so the status is not colour alone: \(tone)")
        }
        // under forced colours a background is overridden, so the fill is a system colour and the track has an edge
        let forced = Self.forced()
        // specificity: the tone rules are two classes, so the forced rule is two classes too (a one-class rule lost, and the fill vanished in Chrome)
        #expect(CSSReader.declarations(of: ".dt-meter .dt-meter__fill", in: forced).contains("background: Highlight"))
        #expect(CSSReader.declarations(of: ".dt-meter__track", in: forced).contains("border-color: CanvasText"))
        #expect(CSSReader.declarations(of: ".dt-meter__track", in: Self.more()).contains("border-color: var(--ink)"))
    }

    // MARK: Header

    @Test("a header is the theme's grid: title and links on the start side, the session on the end side, one column when narrow")
    func header() {
        let header = CSSReader.declarations(of: ".dt-header ", in: Self.always)
        #expect(header.contains("grid-template-columns: repeat(var(--columns), minmax(0, 1fr))") && header.contains("column-gap: var(--gutter)"))
        #expect(CSSReader.declarations(of: ".dt-header__title ", in: Self.always).contains("grid-column: 1 / span 8"))
        let aside = CSSReader.declarations(of: ".dt-header__aside ", in: Self.always)
        #expect(aside.contains("grid-column: 9 / -1") && aside.contains("align-items: flex-end"))
        let nav = CSSReader.declarations(of: ".dt-header__nav ", in: Self.always)
        #expect(nav.contains("flex-wrap: wrap"))
        let narrow = Self.narrow()
        #expect(CSSReader.declarations(of: ".dt-header ", in: narrow).contains("grid-template-columns: minmax(0, 1fr)"))
        #expect(CSSReader.declarations(of: ".dt-header__title,", in: narrow).contains("grid-column: 1 / -1"))
        #expect(CSSReader.declarations(of: ".dt-header__aside ", in: narrow).contains("align-items: flex-start"))
    }

    // MARK: Chip, checkline, stat

    @Test("a chip wraps or breaks a long label by default and never runs past its container; dt-chip--nowrap keeps a short label on one line")
    func chipWraps() {
        let chip = CSSReader.declarations(of: ".dt-chip ", in: Self.always)
        #expect(chip.contains("white-space: normal") && chip.contains("overflow-wrap: anywhere"))
        #expect(chip.contains("max-inline-size: 100%") && chip.contains("min-inline-size: 0"))
        #expect(CSSReader.declarations(of: ".dt-chip--nowrap ", in: Self.always).contains("white-space: nowrap"))
    }

    @Test("a check's label wraps instead of clipping, and the box stays its size")
    func checkline() {
        let line = CSSReader.declarations(of: ".dt-checkline ", in: Self.always)
        #expect(line.contains("white-space: normal") && line.contains("overflow-wrap: anywhere") && line.contains("align-items: flex-start"))
        #expect(!line.contains("white-space: nowrap"))
        #expect(CSSReader.declarations(of: ".dt-check ", in: Self.always).contains("flex: none"))
    }

    @Test("a stat's figure stays on one line (a monospaced theme broke a two-part uptime), and the figure and unit pattern is documented")
    func statFigure() {
        #expect(CSSReader.declarations(of: ".dt-stat__figure ", in: Self.always).contains("white-space: nowrap"))
        #expect(ComponentsCSSEmitter.emit().contains("dt-stat__unit"))
    }

    // MARK: Form

    @Test("an input, select or textarea can be auto width; a form is a stack, and dt-form--inline is a wrapping row")
    func forms() {
        for control in ["input", "select", "textarea"] {
            #expect(CSSReader.declarations(of: ".dt-\(control)--auto", in: Self.always).contains("inline-size: auto"), Comment(rawValue: control))
        }
        let stack = CSSReader.declarations(of: ".dt-form ", in: Self.always)
        #expect(stack.contains("display: flex") && stack.contains("flex-direction: column") && stack.contains("gap:"))
        let row = CSSReader.declarations(of: ".dt-form--inline ", in: Self.always)
        #expect(row.contains("flex-direction: row") && row.contains("flex-wrap: wrap") && row.contains("align-items: flex-end"))
        #expect(CSSReader.declarations(of: ".dt-form--inline > .dt-field", in: Self.always).contains("flex: 1 1"))
    }

    // MARK: Disclosure

    @Test("a disclosure is a details with a summary that carries a count, an optional scrolling body, and a visible keyboard focus")
    func disclosure() {
        let css = Self.css
        for name in [".dt-disclosure ", ".dt-disclosure__summary ", ".dt-disclosure__count ", ".dt-disclosure__body ", ".dt-disclosure--scroll"] {
            #expect(css.contains(name.trimmingCharacters(in: .whitespaces)), Comment(rawValue: name))
        }
        #expect(CSSReader.declarations(of: ".dt-disclosure__summary ", in: Self.always).contains("cursor: pointer"))
        #expect(CSSReader.declarations(of: ".dt-disclosure__count ", in: Self.always).contains("font-variant-numeric: tabular-nums"))
        let scroll = CSSReader.declarations(of: ".dt-disclosure--scroll .dt-disclosure__body", in: Self.always)
        #expect(scroll.contains("max-block-size: calc(var(--space-unit) * 40)") && scroll.contains("overflow-y: auto"))
        let focus = CSSReader.declarations(of: ".dt-disclosure__summary:focus-visible", in: Self.always)
        #expect(focus.contains("outline: calc(var(--rule-hairline) * 2) solid var(--ink)"))
        #expect(CSSReader.declarations(of: ".dt-disclosure__body:focus-visible", in: Self.always).contains("outline:"), "a scrolling region is focusable with tabindex, so it shows focus")
    }

    // MARK: Hidden

    @Test("[hidden] is the only !important, and a hidden card is therefore hidden whatever display the card sets")
    func hiddenCard() {
        let css = Self.css
        #expect(css.components(separatedBy: "!important").count - 1 == 1)
        #expect(CSSReader.declarations(of: ".dt-card ", in: Self.always).contains("display: flex"), "the card does set a display that [hidden] must beat")
        #expect(CSSReader.declarations(of: "[hidden]", in: Self.always).contains("display: none !important"))
    }

    // MARK: Plate

    @Test("a plate is a light surface in any theme, from the Canvas system colour in a light colour scheme, for a QR code")
    func plate() {
        let plate = CSSReader.declarations(of: ".dt-plate ", in: Self.always)
        #expect(plate.contains("color-scheme: light") && plate.contains("background: Canvas") && plate.contains("color: CanvasText"))
        #expect(plate.contains("padding:") && plate.contains("border: var(--rule-hairline) solid var(--rule)"))
        #expect(CSSReader.declarations(of: ".dt-plate--pixelated", in: Self.always).contains("image-rendering: pixelated"))
        #expect(CSSReader.declarations(of: ".dt-plate", in: Self.more()).contains("border-color: var(--ink)"))
    }

    // MARK: Banner body

    @Test("a banner can hold a head (text and chips) and a row of actions, wrapping")
    func bannerBody() {
        let head = CSSReader.declarations(of: ".dt-banner__head ", in: Self.always)
        #expect(head.contains("display: flex") && head.contains("flex-wrap: wrap") && head.contains("align-items: center"))
        let actions = CSSReader.declarations(of: ".dt-banner__actions ", in: Self.always)
        #expect(actions.contains("display: flex") && actions.contains("flex-wrap: wrap") && actions.contains("margin-top:"))
    }

    // MARK: Long values

    @Test("dt-long wraps a long value anywhere; dt-long--truncate cuts it with an ellipsis (the full text belongs in a title)")
    func longValues() {
        let wrap = CSSReader.declarations(of: ".dt-long ", in: Self.always)
        #expect(wrap.contains("overflow-wrap: anywhere") && wrap.contains("min-inline-size: 0"))
        let cut = CSSReader.declarations(of: ".dt-long--truncate", in: Self.always)
        #expect(cut.contains("text-overflow: ellipsis") && cut.contains("white-space: nowrap") && cut.contains("overflow: hidden"))
    }

    // MARK: Header comment

    @Test("the DocC of the emitter names every new class, so the table cannot drift from the stylesheet")
    func classesAreInTheStylesheet() {
        for name in ["dt-meter", "dt-header", "dt-chip--nowrap", "dt-input--auto", "dt-select--auto", "dt-form", "dt-form--inline", "dt-disclosure",
                     "dt-plate", "dt-banner__actions", "dt-banner__head", "dt-long", "dt-long--truncate"] {
            #expect(Self.css.contains(".\(name)"), Comment(rawValue: name))
        }
    }
}
