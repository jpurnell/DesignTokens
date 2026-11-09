import Foundation
import Testing
@testable import DesignTokens

/// Owner decision 2026-11-09: Swiss `positive` and `negative` (gain and loss, printed as text and used as marks
/// in charts) are the text-safe pair, not the system green and red, whose light-mode contrast as text on the
/// Swiss background is 2.13:1 and 3.42:1. `ColorToken.success` and `.destructive` stay the system colours.
///
/// Expected values come from WCAG 2.x's 4.5:1 text threshold (``ValidationThresholds/textContrast``), from the
/// dataviz method's colour-vision floor (``ValidationThresholds/cvdFloor``), and from the chosen hex values
/// themselves, which are a decision and are written out. None is read back from the code under test.
@Suite("Swiss text-safe positive and negative")
struct SwissTextSafeStatusTests {
    private static let root = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()

    private func hex(_ value: String) -> ColorValue {
        ColorValue(hex: value) ?? ColorValue(RGB(red: 0, green: 0, blue: 0))
    }

    private func value(_ role: ColorRole, _ appearance: ValidationAppearance) -> ColorValue {
        ThemeValidator.value(Theme.swiss.palette[role], theme: .swiss, appearance: appearance)
    }

    private let statusRoles: [ColorRole] = [.positive, .negative]

    // MARK: The chosen values

    @Test("the four slots of each role are the chosen values")
    func chosenValues() {
        let positive = Theme.swiss.palette.positive
        #expect(positive.light == hex("#268053"))
        #expect(positive.dark == hex("#30D158"))
        #expect(positive.lightIncreased == hex("#0E6B3A"))
        #expect(positive.darkIncreased == hex("#4AD968"))
        let negative = Theme.swiss.palette.negative
        #expect(negative.light == hex("#DB2C2C"))
        #expect(negative.dark == hex("#FF4245"))
        #expect(negative.lightIncreased == hex("#B81D1D"))
        #expect(negative.darkIncreased == hex("#FF6165"))
    }

    // MARK: Contrast as text

    @Test("as text, both roles reach 4.5:1 on the Swiss background and on the card surface in all four appearances")
    func textContrastEverywhere() {
        for appearance in ValidationAppearance.allCases {
            for role in statusRoles {
                for surfaceRole in [ColorRole.background, .surface] {
                    let surface = ThemeValidator.surface(of: .swiss, role: surfaceRole, appearance: appearance)
                    let ratio = Contrast.ratio(value(role, appearance).rgb, surface.rgb)
                    #expect(ratio >= ValidationThresholds.textContrast, "\(role.rawValue) on \(surfaceRole.rawValue) \(appearance): \(ratio)")
                }
            }
        }
    }

    @Test("the measured light ratios, at the validator's rounding: positive 4.68 and 4.89, negative 4.56 and 4.76")
    func measuredLightRatios() {
        func ratio(_ role: ColorRole, _ surfaceRole: ColorRole) -> Double {
            let surface = ThemeValidator.surface(of: .swiss, role: surfaceRole, appearance: .light)
            return Rounding.places(Contrast.ratio(value(role, .light).rgb, surface.rgb), 2)
        }
        #expect(same([ratio(.positive, .background), ratio(.positive, .surface), ratio(.negative, .background), ratio(.negative, .surface)],
                     [4.68, 4.89, 4.56, 4.76]))
    }

    @Test("Increase Contrast never lowers the contrast: each increased value is at least as strong as the standard one")
    func increasedIsStronger() {
        for role in statusRoles {
            let light = Contrast.ratio(value(role, .light).rgb, ThemeValidator.surface(of: .swiss, role: .background, appearance: .light).rgb)
            let lightMore = Contrast.ratio(value(role, .lightIncreased).rgb, ThemeValidator.surface(of: .swiss, role: .background, appearance: .lightIncreased).rgb)
            #expect(lightMore > light, "\(role.rawValue) light")
            let dark = Contrast.ratio(value(role, .dark).rgb, ThemeValidator.surface(of: .swiss, role: .background, appearance: .dark).rgb)
            let darkMore = Contrast.ratio(value(role, .darkIncreased).rgb, ThemeValidator.surface(of: .swiss, role: .background, appearance: .darkIncreased).rgb)
            #expect(darkMore > dark, "\(role.rawValue) dark")
        }
    }

    // MARK: Still green and red, still a pair

    @Test("neither role is any series colour or the system pair, in any slot")
    func distinctFromSeriesAndSystem() {
        let system: [ColorRole: ColorToken] = [.positive: .success, .negative: .destructive]
        for role in statusRoles {
            let adaptive = Theme.swiss.palette[role]
            let slots = [adaptive.light, adaptive.dark, adaptive.lightIncreased, adaptive.darkIncreased].compactMap { $0 }
            #expect(slots.count == 4)
            for entry in Theme.swiss.palette.series {
                let seriesSlots = [entry.color.light, entry.color.dark, entry.color.lightIncreased, entry.color.darkIncreased].compactMap { $0 }
                // the dark standard value IS the system dark colour and the series' dark green: shared on purpose
                for slot in [adaptive.light, adaptive.lightIncreased].compactMap({ $0 }) {
                    #expect(!seriesSlots.contains(slot), "\(role.rawValue) light slot \(slot.hex) equals series \(entry.name)")
                }
            }
            if let token = system[role] {
                #expect(adaptive.light != ColorValue(token.light), "\(role.rawValue) light is not the system colour")
            }
        }
    }

    @Test("positive is still nearest the green series and negative the red one: they have not drifted off their hue")
    func stillGreenAndRed() {
        func nearest(_ role: ColorRole) -> String {
            let colour = value(role, .light).rgb
            let ranked = Theme.swiss.palette.series.map { ($0.name, ColorAnalysis.deltaE(colour, $0.color.light.rgb, nil)) }
            return ranked.min { $0.1 < $1.1 }?.0 ?? ""
        }
        #expect(nearest(.positive) == "green")
        #expect(nearest(.negative) == "red")
    }

    @Test("positive and negative stay apart for colour-blind readers: at or above the 6 floor under deutan and protan, every appearance")
    func colourVisionSeparation() {
        for appearance in ValidationAppearance.allCases {
            let p = value(.positive, appearance).rgb, n = value(.negative, appearance).rgb
            for kind in [CVDKind.deutan, .protan] {
                let distance = ColorAnalysis.deltaE(p, n, kind)
                #expect(distance >= ValidationThresholds.cvdFloor, "\(appearance) \(kind): \(distance)")
            }
            #expect(ColorAnalysis.deltaE(p, n, nil) >= ValidationThresholds.normalFloor, "\(appearance) normal")
        }
    }

    // MARK: They are deliberately not system colours

    @Test("neither role names a system colour, so nothing defers to Apple's green or red; the series still do")
    func noSystemDeferral() {
        #expect(Theme.swiss.palette.positive.system == nil)
        #expect(Theme.swiss.palette.negative.system == nil)
        #expect(Theme.swiss.palette.series.map(\.color.system) == [.orange, .indigo, .green, .purple, .yellow, .blue, .red, .cyan])
        #expect(Theme.swiss.palette.accent.system == .orange)
    }

    @Test("the system tokens are untouched: success and destructive keep the system values in all four slots")
    func tokensUnchanged() {
        #expect(ColorToken.success.light == RGB(rgb: 0x34C759))
        #expect(ColorToken.success.dark == RGB(rgb: 0x30D158))
        #expect(ColorToken.success.increasedContrastLight == RGB(rgb: 0x008932))
        #expect(ColorToken.success.increasedContrastDark == RGB(rgb: 0x4AD968))
        #expect(ColorToken.destructive.light == RGB(rgb: 0xFF383C))
        #expect(ColorToken.destructive.dark == RGB(rgb: 0xFF4245))
        #expect(ColorToken.destructive.increasedContrastLight == RGB(rgb: 0xE9152D))
        #expect(ColorToken.destructive.increasedContrastDark == RGB(rgb: 0xFF6165))
    }

    @Test("tokens.css and tokens.json are byte-identical to the 0.6.0 candidate: pinned by FNV-1a 64 of the committed bytes")
    func defaultFilesPinned() throws {
        let css = try Data(contentsOf: Self.root.appendingPathComponent("Generated/tokens.css"))
        let json = try Data(contentsOf: Self.root.appendingPathComponent("Generated/tokens.json"))
        #expect(Fingerprint.fnv1a64(css) == "e369026e87dc1c4e")
        #expect(Fingerprint.fnv1a64(json) == "1212e00e2d6ae09c")
        #expect(String(decoding: css, as: UTF8.self) == CSSEmitter.emit())
        #expect(String(decoding: json, as: UTF8.self) == JSONEmitter.emit())
    }

    @Test("other themes are untouched: Princeton (composed on Swiss) keeps the system green and red it had, House keeps its own")
    func otherThemesUnchanged() {
        let princeton = Theme.princeton.palette
        #expect(princeton.positive.light == ColorValue(ColorToken.success.light))
        #expect(princeton.negative.light == ColorValue(ColorToken.destructive.light))
        #expect(princeton.positive.system == .green)
        #expect(princeton.negative.system == .red)
        #expect(princeton.positive.dark == nil && princeton.negative.dark == nil)
        #expect(Theme.house.palette.positive.light == hex("#1F9D55"))
        #expect(Theme.house.palette.negative.light == hex("#D64545"))
    }

    // MARK: The ledger

    @Test("Swiss's ledger no longer carries any positive or negative row, and the validator agrees with it")
    func ledgerHasNoStatusRows() {
        let rows = Theme.swissConformance.entries
        #expect(rows.filter { $0.subject.hasPrefix("positive") || $0.subject.hasPrefix("negative") }.isEmpty)
        // 25 findings before the chart alignment; then the orange dark ramp row left and four muted rows arrived
        #expect(rows.count == 28)
        #expect(rows.filter { $0.severity == .fail }.count == 14)
        #expect(ThemeValidator.deviations(of: .swiss).isEmpty)
        #expect(ThemeValidator.validate(.swiss).filter { $0.subject.hasPrefix("positive") || $0.subject.hasPrefix("negative") }.isEmpty)
    }

    @Test("Princeton's ledger is unchanged: it still records the system green and red as text")
    func princetonLedgerKeepsStatusRows() {
        let rows = Theme.princetonConformance.entries.filter { $0.subject.hasPrefix("positive") || $0.subject.hasPrefix("negative") }
        #expect(same(rows.map(\.measured), [2.13, 2.22, 3.42, 3.57]))
        #expect(ThemeValidator.deviations(of: .princeton).isEmpty)
    }

    // MARK: The emitted files

    @Test("the committed Swiss files carry the new light and increased values as --positive and --negative, and not the system ones")
    func emittedSwissFiles() throws {
        let css = try String(contentsOf: Self.root.appendingPathComponent("Generated/themes/swiss.css"), encoding: .utf8)
        #expect(css.contains("--positive: #268053;"))
        #expect(css.contains("--negative: #DB2C2C;"))
        #expect(css.contains("--positive: #0E6B3A;"))
        #expect(css.contains("--negative: #B81D1D;"))
        #expect(css.contains("--positive: #34C759;") == false)
        #expect(css.contains("--negative: #FF383C;") == false)
        let princeton = try String(contentsOf: Self.root.appendingPathComponent("Generated/themes/princeton.css"), encoding: .utf8)
        #expect(princeton.contains("--positive: #34C759;"))
    }
}
