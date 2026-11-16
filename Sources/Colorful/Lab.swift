/// CIELAB (`CIE L*a*b*`) with the D50 white point.
///
/// `lightness` is `L*` on the `0...100` scale for the reference white, but it is
/// not clamped. `a` and `b` are the CIE opponent coordinates. Conversion from
/// D65 XYZ uses the linear Bradford chromatic adaptation.
public enum Lab: ColorSpace {
    public struct Components: Sendable, Equatable {
        /// `L*`. The D50 white point is `100`.
        public var lightness: Double
        /// `a*`.
        public var a: Double
        /// `b*`.
        public var b: Double

        public init(lightness: Double, a: Double, b: Double) {
            self.lightness = lightness
            self.a = a
            self.b = b
        }
    }

    /// D50 reference white, as XYZ tristimulus values with `Y = 1`.
    public static let d50 = XYZ.Components(x: Colorimetry.d50X, y: Colorimetry.d50Y, z: Colorimetry.d50Z)

    public static func components(fromXYZ xyz: XYZ.Components) -> Components {
        let (x, y, z) = Colorimetry.adaptD65ToD50(xyz.x, xyz.y, xyz.z)
        let fx = labF(x / Colorimetry.d50X)
        let fy = labF(y / Colorimetry.d50Y)
        let fz = labF(z / Colorimetry.d50Z)
        return Components(
            lightness: 116 * fy - 16,
            a: 500 * (fx - fy),
            b: 200 * (fy - fz)
        )
    }

    public static func xyz(from components: Components) -> XYZ.Components {
        let (x, y, z) = labToD50XYZ(components)
        let (adaptedX, adaptedY, adaptedZ) = Colorimetry.adaptD50ToD65(x, y, z)
        return XYZ.Components(x: adaptedX, y: adaptedY, z: adaptedZ)
    }

    public static func interpolate(_ start: Components, _ end: Components, amount: Double) -> Components {
        if amount == 0 { return start }
        if amount == 1 { return end }
        return Components(
            lightness: lerp(start.lightness, end.lightness, amount),
            a: lerp(start.a, end.a, amount),
            b: lerp(start.b, end.b, amount)
        )
    }
}

extension Lab.Components: CustomStringConvertible {
    public var description: String {
        "Lab(lightness: \(lightness), a: \(a), b: \(b))"
    }
}

extension Color where Space == Lab {
    /// Creates a CIELAB color. `lightness` is `L*` and is not clamped.
    public init(lightness: Double, a: Double, b: Double) {
        self.init(components: .init(lightness: lightness, a: a, b: b))
    }

    public var lightness: Double {
        get { components.lightness }
        set { components.lightness = newValue }
    }

    public var a: Double {
        get { components.a }
        set { components.a = newValue }
    }

    public var b: Double {
        get { components.b }
        set { components.b = newValue }
    }
}

/// CIE `L*C*h` with the same D50 CIELAB coordinates as ``Lab``.
///
/// `hue` is in degrees. It is `nil` when the color has no meaningful hue, which
/// is when chroma is at or below ``achromaticChroma``. A missing hue converts
/// back to `a* = 0` and `b* = 0`.
public enum LCH: ColorSpace {
    public struct Components: Sendable, Equatable {
        /// `L*`, shared with ``Lab``.
        public var lightness: Double
        /// `C*`, the distance from the neutral axis in the `a*b*` plane.
        public var chroma: Double
        /// Hue angle in degrees. `nil` when the hue is undefined.
        public var hue: Double?

        public init(lightness: Double, chroma: Double, hue: Double?) {
            self.lightness = lightness
            self.chroma = chroma
            self.hue = hue
        }
    }

    /// Chroma at or below which conversion from ``Lab`` reports a missing hue.
    ///
    /// `1e-6` is far below a perceptible CIELAB difference and absorbs
    /// floating-point noise on neutral colors.
    public static let achromaticChroma = 1e-6

    public static func components(fromXYZ xyz: XYZ.Components) -> Components {
        components(fromLab: Lab.components(fromXYZ: xyz))
    }

    public static func xyz(from components: Components) -> XYZ.Components {
        Lab.xyz(from: labComponents(from: components))
    }

    public static func interpolate(_ start: Components, _ end: Components, amount: Double) -> Components {
        if amount == 0 { return start }
        if amount == 1 { return end }
        return Components(
            lightness: lerp(start.lightness, end.lightness, amount),
            chroma: lerp(start.chroma, end.chroma, amount),
            hue: interpolatedHue(effectiveHue(start), effectiveHue(end), amount)
        )
    }

    static func components(fromLab lab: Lab.Components) -> Components {
        let chroma = (lab.a * lab.a + lab.b * lab.b).squareRoot()
        guard chroma > achromaticChroma else {
            return Components(lightness: lab.lightness, chroma: chroma, hue: nil)
        }
        var hue = Angle.degrees(fromRadians: Elementary.arctangent(lab.b, lab.a))
        if hue < 0 {
            hue += 360
        }
        return Components(lightness: lab.lightness, chroma: chroma, hue: hue)
    }

    static func labComponents(from components: Components) -> Lab.Components {
        guard let hue = finiteHue(components.hue) else {
            return Lab.Components(lightness: components.lightness, a: 0, b: 0)
        }
        let radians = Angle.radians(fromDegrees: hue)
        return Lab.Components(
            lightness: components.lightness,
            a: components.chroma * Elementary.cosine(radians),
            b: components.chroma * Elementary.sine(radians)
        )
    }

    private static func effectiveHue(_ components: Components) -> Double? {
        guard components.chroma > achromaticChroma else { return nil }
        return components.hue
    }
}

extension LCH.Components: CustomStringConvertible {
    public var description: String {
        let hueDescription = hue.map { String(describing: $0) } ?? "nil"
        return "LCH(lightness: \(lightness), chroma: \(chroma), hue: \(hueDescription))"
    }
}

extension Color where Space == LCH {
    /// Creates an LCh color. `hue` is in degrees and may be `nil`.
    public init(lightness: Double, chroma: Double, hue: Double?) {
        self.init(components: .init(lightness: lightness, chroma: chroma, hue: hue))
    }

    public var lightness: Double {
        get { components.lightness }
        set { components.lightness = newValue }
    }

    public var chroma: Double {
        get { components.chroma }
        set { components.chroma = newValue }
    }

    public var hue: Double? {
        get { components.hue }
        set { components.hue = newValue }
    }
}

private func labF(_ value: Double) -> Double {
    if value > Colorimetry.labEpsilon {
        return Elementary.cubeRoot(value)
    }
    return (Colorimetry.labKappa * value + 16) / 116
}

/// Converts CIELAB to D50 XYZ.
///
/// The linear branch is written as `(L/116 ± a/500) * 116/κ`, which is algebraically
/// `(116 f - 16) / κ` without subtracting two close quantities. `Y` uses `L/κ`
/// below the `L* = 8` breakpoint for the same reason.
private func labToD50XYZ(_ lab: Lab.Components) -> (Double, Double, Double) {
    let lightnessOver116 = lab.lightness / 116
    let aOver500 = lab.a / 500
    let bOver200 = lab.b / 200
    let fy = lightnessOver116 + 16.0 / 116.0
    let fx = fy + aOver500
    let fz = fy - bOver200

    let x = labRestore(f: fx, linearTerm: lightnessOver116 + aOver500)
    let z = labRestore(f: fz, linearTerm: lightnessOver116 - bOver200)
    let y: Double
    if lab.lightness > Colorimetry.labKappa * Colorimetry.labEpsilon {
        y = fy * fy * fy
    } else {
        y = lab.lightness / Colorimetry.labKappa
    }
    return (x * Colorimetry.d50X, y * Colorimetry.d50Y, z * Colorimetry.d50Z)
}

private func labRestore(f: Double, linearTerm: Double) -> Double {
    let cubed = f * f * f
    if cubed > Colorimetry.labEpsilon {
        return cubed
    }
    return linearTerm * (116 / Colorimetry.labKappa)
}
