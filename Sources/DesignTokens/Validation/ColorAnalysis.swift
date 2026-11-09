import Foundation

/// Rounds a measurement to a fixed number of decimal places, the way the JavaScript validator displays it.
enum Rounding {
    /// `value` rounded half away from zero to `places` decimals.
    static func places(_ value: Double, _ places: Int) -> Double {
        let factor = pow(10.0, Double(places))
        return (value * factor).rounded() / factor
    }
}

/// The kinds of colour-vision deficiency the validator simulates.
enum CVDKind: String, Sendable {
    /// Missing long-wavelength cones.
    case protan
    /// Missing medium-wavelength cones.
    case deutan
    /// Missing short-wavelength cones (reported, not gated).
    case tritan
}

/// OKLCH and colour-vision-deficiency maths, ported from the dataviz skill's `validate_palette.js`.
enum ColorAnalysis {
    /// Machado, Oliveira and Fernandes (2009) transforms at severity 1.0, applied to linear sRGB.
    /// The thresholds in ``ValidationThresholds`` are calibrated to this model; changing it changes them.
    private static func matrix(_ kind: CVDKind) -> [[Double]] {
        switch kind {
        case .protan: [[0.152286, 1.052583, -0.204868], [0.114503, 0.786281, 0.099216], [-0.003882, -0.048116, 1.051998]]
        case .deutan: [[0.367322, 0.860646, -0.227968], [0.280085, 0.672501, 0.047413], [-0.011820, 0.042940, 0.968881]]
        case .tritan: [[1.255528, -0.076749, -0.178779], [-0.078411, 0.930809, 0.147602], [0.004733, 0.691367, 0.303900]]
        }
    }

    static func lightness(_ color: RGB) -> Double { OKLab.convert(color).0 }

    /// OKLCH chroma.
    static func chroma(_ color: RGB) -> Double {
        let (_, a, b) = OKLab.convert(color)
        return (a * a + b * b).squareRoot()
    }

    /// OKLCH hue in degrees, 0 up to 360. Meaningless for an achromatic colour; callers check chroma first.
    static func hue(_ color: RGB) -> Double {
        let (_, a, b) = OKLab.convert(color)
        let remainder = (atan2(b, a) * 180 / Double.pi).truncatingRemainder(dividingBy: 360)
        return remainder < 0 ? remainder + 360 : remainder
    }

    /// Linear-light sRGB after simulating a deficiency, clamped to 0...1.
    static func simulate(_ color: RGB, _ kind: CVDKind) -> (Double, Double, Double) {
        let r = OKLab.linear(color.red), g = OKLab.linear(color.green), b = OKLab.linear(color.blue)
        let m = matrix(kind)
        func clamp(_ x: Double) -> Double {
            guard !x.isNaN else { return x }
            return min(1, max(0, x))
        }
        return (clamp(m[0][0] * r + m[0][1] * g + m[0][2] * b),
                clamp(m[1][0] * r + m[1][1] * g + m[1][2] * b),
                clamp(m[2][0] * r + m[2][1] * g + m[2][2] * b))
    }

    /// OKLab distance times 100, under a simulated deficiency or, for `nil`, normal vision.
    static func deltaE(_ a: RGB, _ b: RGB, _ kind: CVDKind?) -> Double {
        guard let kind else { return OKLab.distance(a, b) }
        let (l1, a1, b1) = OKLab.fromLinear(simulate(a, kind))
        let (l2, a2, b2) = OKLab.fromLinear(simulate(b, kind))
        let dl = l1 - l2, da = a1 - a2, db = b1 - b2
        return (dl * dl + da * da + db * db).squareRoot() * 100
    }
}
