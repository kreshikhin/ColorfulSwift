#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#elseif canImport(Musl)
import Musl
#elseif canImport(Android)
import Android
#elseif canImport(ucrt)
import ucrt
#elseif canImport(WASILibc)
import WASILibc
#endif

enum Elementary {
    static func cubeRoot(_ value: Double) -> Double {
        cbrt(value)
    }

    static func power(_ value: Double, _ exponent: Double) -> Double {
        pow(value, exponent)
    }

    static func cosine(_ radians: Double) -> Double {
        cos(radians)
    }

    static func sine(_ radians: Double) -> Double {
        sin(radians)
    }

    static func arctangent(_ y: Double, _ x: Double) -> Double {
        atan2(y, x)
    }
}

func lerp(_ start: Double, _ end: Double, _ amount: Double) -> Double {
    start * (1 - amount) + end * amount
}

enum Angle {
    static func degrees(fromRadians radians: Double) -> Double {
        radians * 180 / .pi
    }

    static func radians(fromDegrees degrees: Double) -> Double {
        degrees * .pi / 180
    }

    /// Folds a finite angle into `[0, 360)`. Non-finite values pass through.
    static func wrappedDegrees(_ degrees: Double) -> Double {
        guard degrees.isFinite else { return degrees }
        let wrapped = degrees.truncatingRemainder(dividingBy: 360)
        if wrapped < 0 {
            return wrapped + 360
        }
        return wrapped
    }
}

/// Shortest-path hue interpolation in degrees.
///
/// A missing hue is ignored. When both hues are missing the result is missing.
/// Endpoints are normalized into `[0, 360)`.
func interpolatedHue(_ start: Double?, _ end: Double?, _ amount: Double) -> Double? {
    switch (finiteHue(start), finiteHue(end)) {
    case (nil, nil):
        return nil
    case (let hue?, nil), (nil, let hue?):
        return Angle.wrappedDegrees(hue)
    case (let start?, let end?):
        let start = Angle.wrappedDegrees(start)
        var end = Angle.wrappedDegrees(end)
        let delta = end - start
        if delta > 180 {
            end -= 360
        } else if delta < -180 {
            end += 360
        }
        return Angle.wrappedDegrees(lerp(start, end, amount))
    }
}

func finiteHue(_ hue: Double?) -> Double? {
    guard let hue, hue.isFinite else { return nil }
    return hue
}

struct Matrix3: Sendable {
    var m11, m12, m13: Double
    var m21, m22, m23: Double
    var m31, m32, m33: Double

    func multiply(_ x: Double, _ y: Double, _ z: Double) -> (Double, Double, Double) {
        (
            m11 * x + m12 * y + m13 * z,
            m21 * x + m22 * y + m23 * z,
            m31 * x + m32 * y + m33 * z
        )
    }
}

/// White points and conversion matrices.
///
/// sRGB and OKLab use D65 from the IEC 61966-2-1 chromaticity `(0.3127, 0.3290)`.
/// CIELAB uses D50 from the four-figure chromaticity `(0.3457, 0.3585)` adopted by
/// CSS Color 4 and the ICC. Both are scaled so that `Y = 1`.
///
/// The sRGB matrices are the exact rational forms from the CSS Color 4 sample code,
/// derived from the IEC primaries. OKLab uses Björn Ottosson's transform with the
/// D65-consistent matrices published in that same sample code. Chromatic adaptation
/// is the linear Bradford transform from that sample code.
enum Colorimetry {
    static let d65X = 0.3127 / 0.3290
    static let d65Y = 1.0
    static let d65Z = (1.0 - 0.3127 - 0.3290) / 0.3290

    static let d50X = 0.3457 / 0.3585
    static let d50Y = 1.0
    static let d50Z = (1.0 - 0.3457 - 0.3585) / 0.3585

    /// CIE constants `(6/29)^3` and `(29/3)^3`.
    static let labEpsilon = 216.0 / 24389.0
    static let labKappa = 24389.0 / 27.0

    static let linearSRGBToXYZ = Matrix3(
        m11: 506752.0 / 1228815.0, m12: 87881.0 / 245763.0, m13: 12673.0 / 70218.0,
        m21: 87098.0 / 409605.0, m22: 175762.0 / 245763.0, m23: 12673.0 / 175545.0,
        m31: 7918.0 / 409605.0, m32: 87881.0 / 737289.0, m33: 1001167.0 / 1053270.0
    )

    static let xyzToLinearSRGB = Matrix3(
        m11: 12831.0 / 3959.0, m12: -329.0 / 214.0, m13: -1974.0 / 3959.0,
        m21: -851781.0 / 878810.0, m22: 1648619.0 / 878810.0, m23: 36519.0 / 878810.0,
        m31: 705.0 / 12673.0, m32: -2585.0 / 12673.0, m33: 705.0 / 667.0
    )

    static let d65ToD50 = Matrix3(
        m11: 1.0479297925449969, m12: 0.022946870601609652, m13: -0.05019226628920524,
        m21: 0.02962780877005599, m22: 0.9904344267538799, m23: -0.017073799063418826,
        m31: -0.009243040646204504, m32: 0.015055191490298152, m33: 0.7518742814281371
    )

    static let d50ToD65 = Matrix3(
        m11: 0.955473421488075, m12: -0.02309845494876471, m13: 0.06325924320057072,
        m21: -0.0283697093338637, m22: 1.0099953980813041, m23: 0.021041441191917323,
        m31: 0.012314014864481998, m32: -0.020507649298898964, m33: 1.330365926242124
    )

    static let xyzToLMS = Matrix3(
        m11: 0.8190224379967030, m12: 0.3619062600528904, m13: -0.1288737815209879,
        m21: 0.0329836539323885, m22: 0.9292868615863434, m23: 0.0361446663506424,
        m31: 0.0481771893596242, m32: 0.2642395317527308, m33: 0.6335478284694309
    )

    static let lmsToOKLab = Matrix3(
        m11: 0.2104542683093140, m12: 0.7936177747023054, m13: -0.0040720430116193,
        m21: 1.9779985324311684, m22: -2.4285922420485799, m23: 0.4505937096174110,
        m31: 0.0259040424655478, m32: 0.7827717124575296, m33: -0.8086757549230774
    )

    static let lmsToXYZ = Matrix3(
        m11: 1.2268798758459243, m12: -0.5578149944602171, m13: 0.2813910456659647,
        m21: -0.0405757452148008, m22: 1.1122868032803170, m23: -0.0717110580655164,
        m31: -0.0763729366746601, m32: -0.4214933324022432, m33: 1.5869240198367816
    )

    static let oklabToLMS = Matrix3(
        m11: 1.0000000000000000, m12: 0.3963377773761749, m13: 0.2158037573099136,
        m21: 1.0000000000000000, m22: -0.1055613458156586, m23: -0.0638541728258133,
        m31: 1.0000000000000000, m32: -0.0894841775298119, m33: -1.2914855480194092
    )

    static func adaptD65ToD50(_ x: Double, _ y: Double, _ z: Double) -> (Double, Double, Double) {
        d65ToD50.multiply(x, y, z)
    }

    static func adaptD50ToD65(_ x: Double, _ y: Double, _ z: Double) -> (Double, Double, Double) {
        d50ToD65.multiply(x, y, z)
    }
}

enum SRGBTransfer {
    /// IEC 61966-2-1 threshold on the encoded side.
    static let encodedLinearLimit = 0.04045
    /// IEC 61966-2-1 threshold on the linear-light side.
    static let linearEncodedLimit = 0.0031308
    private static let slope = 12.92
    private static let offset = 0.055
    private static let scale = 1.055
    private static let gamma = 2.4

    /// Extended sRGB electro-optical transfer. Negative values mirror the positive curve.
    static func linearValue(fromEncoded value: Double) -> Double {
        let magnitude = value.magnitude
        if magnitude <= encodedLinearLimit {
            return value / slope
        }
        let sign: Double = value < 0 ? -1 : 1
        return sign * Elementary.power((magnitude + offset) / scale, gamma)
    }

    /// Extended sRGB opto-electronic transfer. Negative values mirror the positive curve.
    static func encodedValue(fromLinear value: Double) -> Double {
        let magnitude = value.magnitude
        if magnitude <= linearEncodedLimit {
            return value * slope
        }
        let sign: Double = value < 0 ? -1 : 1
        return sign * (scale * Elementary.power(magnitude, 1 / gamma) - offset)
    }
}

/// WCAG 2.x relative-luminance weights. They sum to 1 and are the values required
/// by the specification, which are slightly coarser than the sRGB `Y` row.
enum WCAGLuminance {
    static let red = 0.2126
    static let green = 0.7152
    static let blue = 0.0722
}

enum Hub {
    static func components<Source: ColorSpace, Target: ColorSpace>(
        _ source: Source.Components,
        from sourceSpace: Source.Type,
        to targetSpace: Target.Type
    ) -> Target.Components {
        if sourceSpace == targetSpace, let same = source as Any as? Target.Components {
            return same
        }
        return Target.components(fromXYZ: Source.xyz(from: source))
    }
}
