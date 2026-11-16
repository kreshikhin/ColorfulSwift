/// A color described by the components of an associated ``ColorSpace``.
///
/// The module provides ``Color`` as the standard storage type. Another type can
/// conform to ``ColorProtocol`` and still convert, interpolate, and compare
/// through the same operations.
public protocol ColorProtocol: Sendable {
    associatedtype Space: ColorSpace

    var components: Space.Components { get }

    init(components: Space.Components)
}

extension ColorProtocol {
    /// Returns this color in `space`.
    ///
    /// Conversion to the color's own space keeps the components exactly.
    /// Every other conversion goes through D65 XYZ.
    public func converted<Target: ColorSpace>(to space: Target.Type = Target.self) -> Color<Target> {
        Color<Target>(components: Hub.components(components, from: Space.self, to: space))
    }

    /// Returns the color `amount` of the way from this color to `other` in `space`.
    ///
    /// Both colors are converted to `space` first. An amount of `0` is this color
    /// in `space`, and an amount of `1` is `other` in `space`. Amounts outside
    /// `0...1` extrapolate. Components are not clamped.
    public func interpolated<Target: ColorSpace>(
        toward other: some ColorProtocol,
        amount: Double,
        in space: Target.Type = Target.self
    ) -> Color<Target> {
        let start = convertedComponents(of: self, in: space)
        let end = convertedComponents(of: other, in: space)
        return Color<Target>(components: Target.interpolate(start, end, amount: amount))
    }

    /// CIE76 color difference, `ΔE*ab`, after converting both colors to CIELAB.
    ///
    /// This is the Euclidean distance in ``Lab``. It is not CIEDE2000.
    public func deltaE76(to other: some ColorProtocol) -> Double {
        let start = converted(to: Lab.self).components
        let end = other.converted(to: Lab.self).components
        let lightness = start.lightness - end.lightness
        let a = start.a - end.a
        let b = start.b - end.b
        return (lightness * lightness + a * a + b * b).squareRoot()
    }

    /// WCAG 2 contrast ratio of two opaque colors.
    ///
    /// Both colors are converted to sRGB and evaluated with the WCAG 2 relative
    /// luminance formula. The result is the dimensionless ratio `(L1 + 0.05) / (L2 + 0.05)`,
    /// so `21` means `21:1`. Channels are not clamped. WCAG defines the ratio for
    /// in-gamut sRGB; out-of-gamut components can produce a ratio outside `1...21`.
    public func contrastRatio(against other: some ColorProtocol) -> Double {
        let lighterPair = (
            converted(to: SRGB.self).relativeLuminance,
            other.converted(to: SRGB.self).relativeLuminance
        )
        let lighter = max(lighterPair.0, lighterPair.1)
        let darker = min(lighterPair.0, lighterPair.1)
        return (lighter + 0.05) / (darker + 0.05)
    }
}

/// Components of one color space, stored the way `Measurement` stores one unit.
public struct Color<Space: ColorSpace>: ColorProtocol, Sendable, Equatable {
    public var components: Space.Components

    public init(components: Space.Components) {
        self.components = components
    }
}

extension Color: CustomStringConvertible {
    public var description: String {
        String(describing: components)
    }
}

extension Color {
    /// Interpolates toward another color in this color's own space.
    public func interpolated(toward other: Color<Space>, amount: Double) -> Color<Space> {
        interpolated(toward: other, amount: amount, in: Space.self)
    }
}

func convertedComponents<Other: ColorProtocol, Target: ColorSpace>(
    of color: Other,
    in space: Target.Type
) -> Target.Components {
    Hub.components(color.components, from: Other.Space.self, to: space)
}
