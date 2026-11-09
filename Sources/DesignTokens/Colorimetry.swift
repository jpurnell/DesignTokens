import Foundation

/// WCAG contrast between two colours.
enum Contrast {
    /// The contrast ratio, from 1 to 21, order-independent.
    static func ratio(_ a: RGB, _ b: RGB) -> Double {
        let la = luminance(a)
        let lb = luminance(b)
        let (hi, lo) = la >= lb ? (la, lb) : (lb, la)
        return (hi + 0.05) / (lo + 0.05)
    }

    static func luminance(_ color: RGB) -> Double {
        0.2126 * OKLab.linear(color.red) + 0.7152 * OKLab.linear(color.green) + 0.0722 * OKLab.linear(color.blue)
    }
}

/// OKLab distance, scaled by 100, used as the normal-vision separation measure.
enum OKLab {
    static func distance(_ a: RGB, _ b: RGB) -> Double {
        let (l1, a1, b1) = convert(a)
        let (l2, a2, b2) = convert(b)
        let dl = l1 - l2
        let da = a1 - a2
        let db = b1 - b2
        return (dl * dl + da * da + db * db).squareRoot() * 100
    }

    /// Perceptual lightness, 0 (black) to 1 (white): the L of OKLab, which is also the L of OKLCH.
    static func lightness(_ color: RGB) -> Double {
        convert(color).0
    }

    static func linear(_ channel: UInt8) -> Double {
        let c = Double(channel) / 255
        return c <= 0.04045 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
    }

    /// OKLab coordinates (L, a, b) of an sRGB colour.
    static func convert(_ color: RGB) -> (Double, Double, Double) {
        fromLinear((linear(color.red), linear(color.green), linear(color.blue)))
    }

    /// OKLab coordinates of a colour given as linear-light sRGB.
    static func fromLinear(_ rgb: (Double, Double, Double)) -> (Double, Double, Double) {
        let (r, g, b) = rgb
        let l = cbrt(0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b)
        let m = cbrt(0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b)
        let s = cbrt(0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b)
        return (
            0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s,
            1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s,
            0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s
        )
    }
}
