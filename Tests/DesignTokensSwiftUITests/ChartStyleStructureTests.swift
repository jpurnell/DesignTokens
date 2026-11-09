#if canImport(SwiftUI) && os(macOS)
import DesignTokens
import SwiftUI
import Testing
@testable import DesignTokensSwiftUI

@MainActor
@Suite("ChartStyle structure")
struct ChartStyleStructureTests {
    @Test("Swiss: a 3 pt title rule below the title in ink, 1 pt gridlines and baseline, a dashed reference line")
    func swissRules() throws {
        let style = ChartStyle(theme: .swiss, appearance: .light, defersToSystemColors: false)
        let rule = try #require(style.titleRule)
        #expect(near(rule.weight, 3))
        #expect(rule.position == .belowTitle)
        #expect(near(rule.inset, 0))
        #expect(near(style.gridlineWeight, 1))
        #expect(near(style.baselineWeight, 1))
        #expect(near(style.hairlineWeight, 1))
        #expect(near(style.sectionRuleWeight, 3))
        #expect(near(style.pageRuleWeight, 8))
        #expect(style.hasPlotBorder == false)
        #expect(near(style.referenceStroke.lineWidth, 1))
        #expect(style.referenceStroke.dash == [3, 3])
        #expect(style.gridlines == .horizontalFaint)
    }

    @Test("the title rule is nil when a theme has none, and Economist's is above the title")
    func titleRulePresence() throws {
        for theme in Theme.all {
            let rule = theme.structure.rules.title
            let style = ChartStyle(theme: theme, appearance: .light)
            if rule.weight > 0 && rule.position != .none {
                let drawn = try #require(style.titleRule, "\(theme.id)")
                #expect(near(drawn.weight, rule.weight), "\(theme.id)")
            } else {
                #expect(style.titleRule == nil, "\(theme.id)")
            }
        }
        let economist = try #require(ChartStyle(theme: .economist, appearance: .light).titleRule)
        #expect(economist.position == .aboveTitle)
        #expect(ChartStyle(theme: .house, appearance: .light).titleRule == nil)
    }

    @Test("value labels: a view's own setting wins, otherwise the theme's: Swiss on, House and the legacy themes off")
    func valueLabels() {
        let swiss = ChartStyle(theme: .swiss, appearance: .light)
        let house = ChartStyle(theme: .house, appearance: .light)
        let legacy = ChartStyle(theme: .legacyDefault, appearance: .light)
        #expect(swiss.showsValueLabels())
        #expect(!house.showsValueLabels())
        #expect(!legacy.showsValueLabels())
        #expect(!swiss.showsValueLabels(override: false))
        #expect(house.showsValueLabels(override: true))
        #expect(swiss.valueLabels == .aboveOrEnd)
    }

    @Test("label flags, layout and marks are the theme's numbers for every registered theme")
    func projectionOfEveryTheme() {
        for theme in Theme.all {
            let s = theme.structure
            let style = ChartStyle(theme: theme, appearance: .light)
            #expect(style.seriesLabeling == s.labels.series, "\(theme.id)")
            #expect(style.axisSide == s.labels.axisSide, "\(theme.id)")
            #expect(style.axisLabelPlacement == s.labels.axisLabelPlacement, "\(theme.id)")
            #expect(style.showsSourceLine == s.labels.sourceLine, "\(theme.id)")
            #expect(near(style.margins.top, s.layout.margins.top), "\(theme.id)")
            #expect(near(style.margins.leading, s.layout.margins.leading), "\(theme.id)")
            #expect(near(style.margins.bottom, s.layout.margins.bottom), "\(theme.id)")
            #expect(near(style.margins.trailing, s.layout.margins.trailing), "\(theme.id)")
            #expect(near(style.titleGap, s.layout.gaps.title), "\(theme.id)")
            #expect(near(style.subtitleGap, s.layout.gaps.subtitle), "\(theme.id)")
            #expect(near(style.plotGap, s.layout.gaps.plot), "\(theme.id)")
            #expect(near(style.sourceGap, s.layout.gaps.source), "\(theme.id)")
            #expect(near(style.gutter, s.layout.gutter), "\(theme.id)")
            #expect(style.columns == s.layout.columns, "\(theme.id)")
            #expect(near(style.baseUnit, s.layout.baseUnit), "\(theme.id)")
            #expect(near(style.containerRadius, s.layout.containerRadius), "\(theme.id)")
            #expect(near(style.controlRadius, s.layout.controlRadius), "\(theme.id)")
            #expect(near(style.annotationRadius, s.layout.annotationRadius), "\(theme.id)")
            #expect(near(style.lineWidth, s.marks.lineWidth), "\(theme.id)")
            #expect(near(style.pointSize, s.marks.pointSize), "\(theme.id)")
            #expect(near(style.bandOpacity, s.marks.bandOpacity), "\(theme.id)")
            #expect(near(style.areaOpacity, s.marks.areaOpacity), "\(theme.id)")
            #expect(near(style.fillOpacity, s.marks.fillOpacity), "\(theme.id)")
            #expect(near(style.detailLineWidth, s.marks.detailLineWidth), "\(theme.id)")
            #expect(near(style.selectedLineWidth, s.marks.selectedLineWidth), "\(theme.id)")
            #expect(style.barFill == s.marks.barFill, "\(theme.id)")
            #expect(near(style.barWidthRatio, s.marks.barWidthRatio), "\(theme.id)")
            #expect(near(style.barCornerRadius, s.marks.barCornerRadius), "\(theme.id)")
            #expect(style.lineEnd == s.marks.lineEnd, "\(theme.id)")
            for kind in NumberKind.allCases { #expect(style.numberFormat(kind) == s.numbers[kind], "\(theme.id) \(kind.rawValue)") }
        }
    }

    @Test("shadow and tag: legacy themes have the 4/0/2 shadow, Economist the 28 by 6 tag, Swiss neither")
    func shadowAndTag() throws {
        let legacy = try #require(ChartStyle(theme: .legacyDefault, appearance: .light).shadow)
        #expect(near(legacy.radius, 4))
        #expect(near(legacy.x, 0))
        #expect(near(legacy.y, 2))
        #expect(ChartStyle(theme: .swiss, appearance: .light).shadow == nil)
        let tag = try #require(ChartStyle(theme: .economist, appearance: .light).tag)
        #expect(near(tag.width, 28))
        #expect(near(tag.height, 6))
        #expect(ChartStyle(theme: .swiss, appearance: .light).tag == nil)
    }

    @Test("environment: the default theme is the legacy default, and a set theme is read back")
    func environmentValues() {
        var environment = EnvironmentValues()
        #expect(environment.theme == Theme.legacyDefault)
        environment.theme = .ft
        #expect(environment.theme == Theme.ft)
        environment.chartStyle = ChartStyle(theme: .ft, appearance: .dark, increasedContrast: true)
        #expect(environment.chartStyle.theme == Theme.ft)
        #expect(environment.chartStyle.appearance == .dark)
        #expect(environment.chartStyle.increasedContrast)
    }

    @Test("the style is built from the environment's scheme and contrast")
    func styleFromEnvironmentValues() {
        let style = ChartStyle(theme: .swiss, colorScheme: .dark, contrast: .increased)
        #expect(style.appearance == .dark)
        #expect(style.increasedContrast)
        let plain = ChartStyle(theme: .swiss, colorScheme: .light, contrast: .standard)
        #expect(plain.appearance == .light)
        #expect(!plain.increasedContrast)
    }

    @Test("chartTheme and ChartStyleReader deliver the theme and the colour scheme to the content")
    func modifierAndReader() {
        var probe: ChartStyle?
        let reader = ChartStyleReader { style -> Color in
            probe = style
            return .clear
        }
        .chartTheme(.economist)
        .environment(\.colorScheme, .dark)
        _ = ImageRenderer(content: reader.frame(width: 10, height: 10)).cgImage
        #expect(probe?.theme == Theme.economist)
        #expect(probe?.appearance == .dark)
        #expect(probe?.increasedContrast == false)
    }
}

@MainActor
@Suite("Fonts")
struct ChartTextTests {
    private let nothingInstalled: @Sendable (String) -> Bool = { _ in false }
    private let everythingInstalled: @Sendable (String) -> Bool = { _ in true }

    @Test("a missing named face falls back to its declared family, and an installed one is used")
    func namedFaceFallback() throws {
        let spec = Theme.economist.structure.type.title
        guard case .named(let name, let fallback) = spec.family else {
            Issue.record("Economist's title is a named face")
            return
        }
        #expect(name == "Econ Sans Cnd")
        #expect(fallback == .sans)
        #expect(FontPlan.make(spec, isInstalled: nothingInstalled) == .system(.standard, size: spec.size, weight: spec.weight))
        #expect(FontPlan.make(spec, isInstalled: everythingInstalled) == .custom("Econ Sans Cnd", size: spec.size, weight: spec.weight))
        #expect(FontPlan.make(spec, isInstalled: { $0 == "Econ Sans Cnd" }) == .custom("Econ Sans Cnd", size: spec.size, weight: spec.weight))
        #expect(FontPlan.make(spec, isInstalled: { $0 == "Something Else" }) == .system(.standard, size: spec.size, weight: spec.weight))
    }

    @Test("families map to system designs: sans, mono, New York, and Garamond only when installed")
    func families() {
        func spec(_ family: FontFamilyRef) -> TextSpec {
            TextSpec(family: family, size: 13, weight: 400, tracking: 0, italic: false, uppercase: false, lineHeight: 1.2)
        }
        #expect(FontPlan.make(spec(.sans), isInstalled: nothingInstalled) == .system(.standard, size: 13, weight: 400))
        #expect(FontPlan.make(spec(.mono), isInstalled: nothingInstalled) == .system(.monospaced, size: 13, weight: 400))
        #expect(FontPlan.make(spec(.serifNewYork), isInstalled: nothingInstalled) == .system(.serif, size: 13, weight: 400))
        #expect(FontPlan.make(spec(.serifGaramond), isInstalled: nothingInstalled) == .system(.serif, size: 13, weight: 400))
        #expect(FontPlan.make(spec(.serifGaramond), isInstalled: { $0 == "Garamond" }) == .custom("Garamond", size: 13, weight: 400))
        #expect(FontPlan.make(spec(.serifGaramond), isInstalled: everythingInstalled) == .custom("EB Garamond", size: 13, weight: 400))
        let nested = FontFamilyRef.named("A", fallback: .named("B", fallback: .mono))
        #expect(FontPlan.make(spec(nested), isInstalled: { $0 == "B" }) == .custom("B", size: 13, weight: 400))
        #expect(FontPlan.make(spec(nested), isInstalled: nothingInstalled) == .system(.monospaced, size: 13, weight: 400))
    }

    @Test("a platform text style wins over the numbers, for the legacy themes")
    func platformStyle() {
        let spec = Theme.legacyDefault.structure.type.title
        #expect(spec.platformStyle == .headline)
        #expect(FontPlan.make(spec, isInstalled: nothingInstalled) == .platform(.headline))
    }

    @Test("numeric weights map to the nearest SwiftUI weight, clamped to 100 through 900")
    func weights() {
        let cases: [(Int, Font.Weight)] = [
            (100, .ultraLight), (200, .thin), (300, .light), (400, .regular), (500, .medium),
            (600, .semibold), (700, .bold), (800, .heavy), (900, .black), (0, .ultraLight), (5000, .black), (449, .regular), (450, .medium),
        ]
        for (number, weight) in cases { #expect(ChartText.weight(number) == weight, "\(number)") }
    }

    @Test("tracking is the spec's em times its size, line spacing is the line height beyond one line, uppercase is carried")
    func trackingAndLineSpacing() {
        let spec = TextSpec(family: .sans, size: 11, weight: 600, tracking: 0.08, italic: false, uppercase: true, lineHeight: 1.3)
        let text = ChartText(role: .label, spec: spec, isInstalled: { _ in false })
        #expect(abs(text.tracking - 0.88) < 1e-9)
        #expect(abs(text.lineSpacing - 3.3) < 1e-9)
        #expect(text.isUppercase)
        let tight = ChartText(role: .display, spec: TextSpec(family: .sans, size: 100, weight: 800, tracking: -0.05, italic: false,
                                                           uppercase: false, lineHeight: 0.86), isInstalled: { _ in false })
        #expect(near(tight.lineSpacing, 0), "a line height under 1 never gives negative spacing")
        #expect(abs(tight.tracking + 5) < 1e-9)
    }

    @Test("every theme resolves every one of the fifteen roles")
    func everyRole() {
        for theme in Theme.all {
            let style = ChartStyle(theme: theme, appearance: .light)
            for role in TypeRole.allCases {
                let text = style.text(role)
                #expect(text.spec == theme.structure.type[role], "\(theme.id) \(role.rawValue)")
                #expect(text.role == role)
            }
        }
    }
}
#endif
