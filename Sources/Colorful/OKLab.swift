/// Björn Ottosson's OKLab, relative to XYZ D65.
///
/// `lightness` is on the `0...1` scale for D65 white, unlike CIELAB's `0...100`.
/// The matrices are the D65-consistent form published with CSS Color 4, so neutral
/// sRGB colors stay on the `a = b = 0` axis. Cube roots are sign-preserving, which
/// keeps out-of-gamut colors defined.
public enum OKLab: ColorSpace {
    public struct Components: Sendable, Equatable {
        /// OKLab lightness. D65 white is `1`.
        public var lightness: Double
        /// OKLab green–red opponent coordinate.
        public var a: Double
        /// OKLab blue–yellow opponent coordinate.
        public var b: Double

        public init(lightness: Double, a: Double, b: Double) {
            self.lightness = lightness
            self.a = a
            self.b = b
        }
    }

    public static func components(fromXYZ xyz: XYZ.Components) -> Components {
        let (l, m, s) = Colorimetry.xyzToLMS.multiply(xyz.x, xyz.y, xyz.z)
        let (lightness, a, b) = Colorimetry.lmsToOKLab.multiply(
            Elementary.cubeRoot(l),
            Elementary.cubeRoot(m),
            Elementary.cubeRoot(s)
        )
        return Components(lightness: lightness, a: a, b: b)
    }

    public static func xyz(from components: Components) -> XYZ.Components {
        let (l, m, s) = Colorimetry.oklabToLMS.multiply(components.lightness, components.a, components.b)
        let (x, y, z) = Colorimetry.lmsToXYZ.multiply(l * l * l, m * m * m, s * s * s)
        return XYZ.Components(x: x, y: y, z: z)
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

extension OKLab.Components: CustomStringConvertible {
    public var description: String {
        "OKLab(lightness: \(lightness), a: \(a), b: \(b))"
    }
}

extension Color where Space == OKLab {
    /// Creates an OKLab color. `lightness` is not clamped.
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

/// OKLCh, the polar form of ``OKLab``.
///
/// `hue` is in degrees. It is `nil` when chroma is at or below ``achromaticChroma``.
/// A missing hue converts back to `a = 0` and `b = 0`.
public enum OKLCH: ColorSpace {
    public struct Components: Sendable, Equatable {
        /// OKLab lightness, shared with ``OKLab``.
        public var lightness: Double
        /// Distance from the neutral axis in the OKLab `a`/`b` plane.
        public var chroma: Double
        /// Hue angle in degrees. `nil` when the hue is undefined.
        public var hue: Double?

        public init(lightness: Double, chroma: Double, hue: Double?) {
            self.lightness = lightness
            self.chroma = chroma
            self.hue = hue
        }
    }

    /// Chroma at or below which conversion from ``OKLab`` reports a missing hue.
    ///
    /// `1e-8` sits above the rounding noise of the OKLab matrices and well below
    /// a perceptible difference.
    public static let achromaticChroma = 1e-8

    public static func components(fromXYZ xyz: XYZ.Components) -> Components {
        components(fromOKLab: OKLab.components(fromXYZ: xyz))
    }

    public static func xyz(from components: Components) -> XYZ.Components {
        OKLab.xyz(from: oklabComponents(from: components))
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

    static func components(fromOKLab lab: OKLab.Components) -> Components {
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

    static func oklabComponents(from components: Components) -> OKLab.Components {
        guard let hue = finiteHue(components.hue) else {
            return OKLab.Components(lightness: components.lightness, a: 0, b: 0)
        }
        let radians = Angle.radians(fromDegrees: hue)
        return OKLab.Components(
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

extension OKLCH.Components: CustomStringConvertible {
    public var description: String {
        let hueDescription = hue.map { String(describing: $0) } ?? "nil"
        return "OKLCH(lightness: \(lightness), chroma: \(chroma), hue: \(hueDescription))"
    }
}

extension Color where Space == OKLCH {
    /// Creates an OKLCh color. `hue` is in degrees and may be `nil`.
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
