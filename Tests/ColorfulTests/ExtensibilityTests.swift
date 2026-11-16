import Testing
import Colorful

private struct Swatch: ColorProtocol {
    typealias Space = SRGB
    var components: SRGB.Components

    init(components: SRGB.Components) {
        self.components = components
    }
}

/// A space outside the module. Components are D65 XYZ multiplied by two.
private enum ScaledXYZ: ColorSpace {
    struct Components: Sendable, Equatable {
        var x: Double
        var y: Double
        var z: Double
    }

    static func components(fromXYZ xyz: XYZ.Components) -> Components {
        Components(x: xyz.x * 2, y: xyz.y * 2, z: xyz.z * 2)
    }

    static func xyz(from components: Components) -> XYZ.Components {
        XYZ.Components(x: components.x / 2, y: components.y / 2, z: components.z / 2)
    }

    static func interpolate(_ start: Components, _ end: Components, amount: Double) -> Components {
        Components(
            x: start.x * (1 - amount) + end.x * amount,
            y: start.y * (1 - amount) + end.y * amount,
            z: start.z * (1 - amount) + end.z * amount
        )
    }
}

@Suite("Extensibility")
struct ExtensibilityTests {
    @Test func externalColorUsesTheSameOperations() {
        let swatch = Swatch(components: .init(red: 1, green: 0, blue: 0))
        let srgb = swatch.converted(to: SRGB.self)
        #expect(srgb.red == 1)
        #expect(srgb.green == 0)
        #expect(srgb.blue == 0)

        let lab = swatch.converted(to: Lab.self)
        expectApprox(lab.lightness, 54.29054140467193)
        expectApprox(swatch.deltaE76(to: swatch), 0, tolerance: 0)
    }

    @Test func externalColorSpaceRoundTrips() {
        let white = Color<SRGB>(red: 1, green: 1, blue: 1)
        let scaled = white.converted(to: ScaledXYZ.self)
        expectApprox(scaled.components.x, XYZ.d65.x * 2, tolerance: 1e-12)
        expectApprox(scaled.components.y, XYZ.d65.y * 2, tolerance: 1e-12)
        expectApprox(scaled.components.z, XYZ.d65.z * 2, tolerance: 1e-12)

        let restored = scaled.converted(to: SRGB.self)
        expectApprox(restored.red, 1, tolerance: 1e-12)
        expectApprox(restored.green, 1, tolerance: 1e-12)
        expectApprox(restored.blue, 1, tolerance: 1e-12)
    }
}
