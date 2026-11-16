/// Linear-light sRGB, before the IEC 61966-2-1 transfer function.
///
/// Components are scene-linear intensities. `1` is the D65 white produced by
/// encoded sRGB `(1, 1, 1)`. Values outside `0...1` are preserved.
public enum LinearSRGB: ColorSpace {
    public struct Components: Sendable, Equatable {
        /// Linear-light red intensity.
        public var red: Double
        /// Linear-light green intensity.
        public var green: Double
        /// Linear-light blue intensity.
        public var blue: Double

        public init(red: Double, green: Double, blue: Double) {
            self.red = red
            self.green = green
            self.blue = blue
        }
    }

    public static func components(fromXYZ xyz: XYZ.Components) -> Components {
        let (red, green, blue) = Colorimetry.xyzToLinearSRGB.multiply(xyz.x, xyz.y, xyz.z)
        return Components(red: red, green: green, blue: blue)
    }

    public static func xyz(from components: Components) -> XYZ.Components {
        let (x, y, z) = Colorimetry.linearSRGBToXYZ.multiply(components.red, components.green, components.blue)
        return XYZ.Components(x: x, y: y, z: z)
    }

    public static func interpolate(_ start: Components, _ end: Components, amount: Double) -> Components {
        if amount == 0 { return start }
        if amount == 1 { return end }
        return Components(
            red: lerp(start.red, end.red, amount),
            green: lerp(start.green, end.green, amount),
            blue: lerp(start.blue, end.blue, amount)
        )
    }
}

extension LinearSRGB.Components: CustomStringConvertible {
    public var description: String {
        "LinearSRGB(red: \(red), green: \(green), blue: \(blue))"
    }
}

extension Color where Space == LinearSRGB {
    /// Creates a linear-light sRGB color. Components are not clamped.
    public init(red: Double, green: Double, blue: Double) {
        self.init(components: .init(red: red, green: green, blue: blue))
    }

    public var red: Double {
        get { components.red }
        set { components.red = newValue }
    }

    public var green: Double {
        get { components.green }
        set { components.green = newValue }
    }

    public var blue: Double {
        get { components.blue }
        set { components.blue = newValue }
    }
}

/// IEC 61966-2-1 sRGB, with the standard piecewise transfer function.
///
/// Encoded components are not clamped to `0...1`. Negative components use the
/// CSS Color 4 extension: the linear segment and the power segment are mirrored
/// through the origin. The transfer thresholds are `0.04045` on the encoded side
/// and `0.0031308` on the linear-light side.
public enum SRGB: ColorSpace {
    public struct Components: Sendable, Equatable {
        /// Encoded red, nominally in `0...1` for in-gamut colors.
        public var red: Double
        /// Encoded green, nominally in `0...1` for in-gamut colors.
        public var green: Double
        /// Encoded blue, nominally in `0...1` for in-gamut colors.
        public var blue: Double

        public init(red: Double, green: Double, blue: Double) {
            self.red = red
            self.green = green
            self.blue = blue
        }
    }

    public static func components(fromXYZ xyz: XYZ.Components) -> Components {
        let linear = LinearSRGB.components(fromXYZ: xyz)
        return Components(
            red: SRGBTransfer.encodedValue(fromLinear: linear.red),
            green: SRGBTransfer.encodedValue(fromLinear: linear.green),
            blue: SRGBTransfer.encodedValue(fromLinear: linear.blue)
        )
    }

    public static func xyz(from components: Components) -> XYZ.Components {
        LinearSRGB.xyz(
            from: LinearSRGB.Components(
                red: SRGBTransfer.linearValue(fromEncoded: components.red),
                green: SRGBTransfer.linearValue(fromEncoded: components.green),
                blue: SRGBTransfer.linearValue(fromEncoded: components.blue)
            )
        )
    }

    public static func interpolate(_ start: Components, _ end: Components, amount: Double) -> Components {
        if amount == 0 { return start }
        if amount == 1 { return end }
        return Components(
            red: lerp(start.red, end.red, amount),
            green: lerp(start.green, end.green, amount),
            blue: lerp(start.blue, end.blue, amount)
        )
    }
}

extension SRGB.Components: CustomStringConvertible {
    public var description: String {
        "SRGB(red: \(red), green: \(green), blue: \(blue))"
    }
}

extension Color where Space == SRGB {
    /// Creates an encoded sRGB color. Components are not clamped.
    public init(red: Double, green: Double, blue: Double) {
        self.init(components: .init(red: red, green: green, blue: blue))
    }

    public var red: Double {
        get { components.red }
        set { components.red = newValue }
    }

    public var green: Double {
        get { components.green }
        set { components.green = newValue }
    }

    public var blue: Double {
        get { components.blue }
        set { components.blue = newValue }
    }

    /// WCAG 2 relative luminance of this opaque sRGB color.
    ///
    /// The encoded channels are linearized with the IEC transfer function, then
    /// weighted by the WCAG coefficients `0.2126`, `0.7152`, and `0.0722`.
    /// Those coefficients are the ones required by WCAG 2.2; they are not the
    /// full-precision `Y` row of the sRGB matrix. Channels are not clamped.
    public var relativeLuminance: Double {
        let red = SRGBTransfer.linearValue(fromEncoded: self.red)
        let green = SRGBTransfer.linearValue(fromEncoded: self.green)
        let blue = SRGBTransfer.linearValue(fromEncoded: self.blue)
        return WCAGLuminance.red * red + WCAGLuminance.green * green + WCAGLuminance.blue * blue
    }
}
