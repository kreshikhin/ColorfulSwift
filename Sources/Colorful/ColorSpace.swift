/// A color space that can be converted through CIE XYZ with the D65 white point.
///
/// `XYZ` is the connection space. A space whose native white point is D50 adapts
/// to and from D65 inside its own conversion. Components are `Double` and are not
/// clamped: values outside the gamut are preserved.
///
/// Implement ``xyz(from:)`` and ``components(fromXYZ:)`` to add a space.
/// ``interpolate(_:_:amount:)`` defines how colors mix in that space. Polar spaces
/// should take the shortest hue path and treat a zero-chroma hue as missing.
public protocol ColorSpace: Sendable {
    associatedtype Components: Sendable & Equatable

    /// Converts D65 XYZ components into this space.
    static func components(fromXYZ xyz: XYZ.Components) -> Components

    /// Converts components of this space into D65 XYZ.
    static func xyz(from components: Components) -> XYZ.Components

    /// Interpolates from `start` toward `end`.
    ///
    /// An amount of `0` returns `start` and an amount of `1` returns `end`.
    /// Amounts outside `0...1` extrapolate.
    static func interpolate(_ start: Components, _ end: Components, amount: Double) -> Components
}
