/// CIE XYZ with the D65 white point, scaled so that the white point has `Y = 1`.
///
/// This is the connection space used by every other ``ColorSpace``. The white point
/// is the sRGB D65 chromaticity `(x = 0.3127, y = 0.3290)`.
public enum XYZ: ColorSpace {
    /// Tristimulus values relative to ``d65``.
    public struct Components: Sendable, Equatable {
        public var x: Double
        public var y: Double
        public var z: Double

        public init(x: Double, y: Double, z: Double) {
            self.x = x
            self.y = y
            self.z = z
        }
    }

    /// D65 white point used by this space.
    public static let d65 = Components(x: Colorimetry.d65X, y: Colorimetry.d65Y, z: Colorimetry.d65Z)

    public static func components(fromXYZ xyz: Components) -> Components {
        xyz
    }

    public static func xyz(from components: Components) -> Components {
        components
    }

    public static func interpolate(_ start: Components, _ end: Components, amount: Double) -> Components {
        if amount == 0 { return start }
        if amount == 1 { return end }
        return Components(
            x: lerp(start.x, end.x, amount),
            y: lerp(start.y, end.y, amount),
            z: lerp(start.z, end.z, amount)
        )
    }
}

extension XYZ.Components: CustomStringConvertible {
    public var description: String {
        "XYZ(x: \(x), y: \(y), z: \(z))"
    }
}

extension Color where Space == XYZ {
    /// Creates an XYZ color. Components are relative to ``XYZ/d65`` and are not clamped.
    public init(x: Double, y: Double, z: Double) {
        self.init(components: .init(x: x, y: y, z: z))
    }

    public var x: Double {
        get { components.x }
        set { components.x = newValue }
    }

    public var y: Double {
        get { components.y }
        set { components.y = newValue }
    }

    public var z: Double {
        get { components.z }
        set { components.z = newValue }
    }
}
