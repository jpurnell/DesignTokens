#if canImport(SwiftUI) && (canImport(AppKit) || canImport(UIKit))
import DesignTokens
import SwiftUI
import Testing
@testable import DesignTokensSwiftUI
#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

#if canImport(AppKit)
private struct PlatformColorBox { let native: NSColor }
#else
private struct PlatformColorBox { let native: UIColor }
#endif

/// `Adaptive.dynamicColor` resolved the way the system resolves it when drawing, under each appearance and contrast setting,
/// against the stored values. Runs under `swift test` (AppKit) and `xcodebuild test` on an iOS Simulator (UIKit).
@Suite("Dynamic colour from an Adaptive")
struct DynamicColorTests {
    private let adaptive = Adaptive(light: ColorValue(RGB(rgb: 0x112233)), dark: ColorValue(RGB(rgb: 0x445566)),
                                    lightIncreased: ColorValue(RGB(rgb: 0x778899)), darkIncreased: ColorValue(RGB(rgb: 0xAABBCC)))

    /// The colour as the system resolves it, as 0 to 255 sRGB bytes and alpha.
    private func resolved(_ color: PlatformColorBox, dark: Bool, increased: Bool) -> [Int] {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        #if canImport(AppKit)
        let name: NSAppearance.Name = switch (dark, increased) {
        case (false, false): .aqua
        case (true, false): .darkAqua
        case (false, true): .accessibilityHighContrastAqua
        case (true, true): .accessibilityHighContrastDarkAqua
        }
        let appearance = NSAppearance(named: name) ?? NSAppearance.currentDrawing()
        appearance.performAsCurrentDrawingAppearance {
            color.native.usingColorSpace(.sRGB)?.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        }
        #else
        let traits = UITraitCollection(traitsFrom: [UITraitCollection(userInterfaceStyle: dark ? .dark : .light),
                                                    UITraitCollection(accessibilityContrast: increased ? .high : .normal)])
        color.native.resolvedColor(with: traits).getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        #endif
        return [Int((red * 255).rounded()), Int((green * 255).rounded()), Int((blue * 255).rounded()), Int((alpha * 255).rounded())]
    }

    private func bytes(_ value: ColorValue) -> [Int] {
        [Int(value.rgb.red), Int(value.rgb.green), Int(value.rgb.blue), Int((value.alpha * 255).rounded())]
    }

    @Test("resolved as the system draws it, light and dark each give the stored value of that slot")
    func lightAndDark() {
        let color = PlatformColorBox(native: adaptive.platformColor)
        #expect(resolved(color, dark: false, increased: false) == bytes(ColorValue(RGB(rgb: 0x112233))))
        #expect(resolved(color, dark: true, increased: false) == bytes(ColorValue(RGB(rgb: 0x445566))))
    }

    #if canImport(UIKit)
    @Test("on UIKit the trait collection's contrast chooses the increased slots")
    func increasedTraits() {
        let color = PlatformColorBox(native: adaptive.platformColor)
        #expect(resolved(color, dark: false, increased: true) == bytes(ColorValue(RGB(rgb: 0x778899))))
        #expect(resolved(color, dark: true, increased: true) == bytes(ColorValue(RGB(rgb: 0xAABBCC))))
    }
    #endif

    #if canImport(AppKit)
    @Test("on a Mac light and dark choose their slot, and the system's Increase Contrast setting chooses the increased slot (macOS 27 reports a high-contrast appearance by its plain name, so the setting is what says it)")
    func appearanceNames() throws {
        let cases: [(NSAppearance.Name, Bool, UInt32)] = [(.aqua, false, 0x112233), (.darkAqua, false, 0x445566),
                                                          (.aqua, true, 0x778899), (.darkAqua, true, 0xAABBCC)]
        for (name, system, expected) in cases {
            let appearance = try #require(NSAppearance(named: name))
            #expect(adaptive.value(for: appearance, systemIncreasesContrast: system) == ColorValue(RGB(rgb: expected)), "\(name.rawValue) system=\(system)")
        }
    }
    #endif

    @Test("the SwiftUI colour wraps that platform colour: light and dark come back through Color")
    func throughColor() {
        #if canImport(AppKit)
        let viaColor = PlatformColorBox(native: NSColor(adaptive.dynamicColor))
        #else
        let viaColor = PlatformColorBox(native: UIColor(adaptive.dynamicColor))
        #endif
        #expect(resolved(viaColor, dark: false, increased: false) == bytes(ColorValue(RGB(rgb: 0x112233))))
        #expect(resolved(viaColor, dark: true, increased: false) == bytes(ColorValue(RGB(rgb: 0x445566))))
    }

    @Test("missing slots fall back as the model says: no dark is the light value, no increased value the standard one")
    func fallbacks() {
        let lightOnly = Adaptive(light: ColorValue(RGB(rgb: 0x123456)))
        let color = PlatformColorBox(native: lightOnly.platformColor)
        let expected = bytes(ColorValue(RGB(rgb: 0x123456)))
        #expect(resolved(color, dark: true, increased: false) == expected)
        #expect(lightOnly.value(in: .light, increasedContrast: true) == ColorValue(RGB(rgb: 0x123456)))
        #expect(lightOnly.value(in: .dark, increasedContrast: true) == ColorValue(RGB(rgb: 0x123456)))
    }

    @Test("alpha survives: a translucent value resolves translucent")
    func alpha() {
        let clear = Adaptive(light: ColorValue(RGB(rgb: 0xECECEC), alpha: 0), dark: ColorValue(RGB(rgb: 0x323232), alpha: 0))
        #expect(resolved(PlatformColorBox(native: clear.platformColor), dark: false, increased: false)[3] == 0)
        #expect(resolved(PlatformColorBox(native: clear.platformColor), dark: true, increased: false)[3] == 0)
    }

    @Test("every Swiss role resolves to the model's value in every appearance")
    func swissRoles() {
        for role in ColorRole.allCases {
            let value = Theme.swiss.palette[role]
            for (dark, increased) in [(false, false), (true, false)] {
                let expected = bytes(value.value(in: dark ? .dark : .light, increasedContrast: increased))
                #expect(resolved(PlatformColorBox(native: value.platformColor), dark: dark, increased: increased) == expected, "\(role) dark=\(dark) increased=\(increased)")
            }
        }
    }
}
#endif
