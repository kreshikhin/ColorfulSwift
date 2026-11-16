import Testing
import Colorful

@Suite("Round trips and gamut boundaries")
struct RoundTripTests {
    @Test(arguments: [-1.5, -0.2, 0.0, 0.02, 0.04045, 0.5, 1.0, 1.4])
    func sRGBThroughEverySpace(_ red: Double) {
        let color = Color<SRGB>(red: red, green: 0.25, blue: -0.15)
        let restored = color
            .converted(to: LinearSRGB.self)
            .converted(to: XYZ.self)
            .converted(to: Lab.self)
            .converted(to: LCH.self)
            .converted(to: OKLab.self)
            .converted(to: OKLCH.self)
            .converted(to: SRGB.self)

        let tolerance = abs(red) > 1 ? 1e-6 : 1e-7
        expectApprox(restored.red, color.red, tolerance: tolerance)
        expectApprox(restored.green, color.green, tolerance: tolerance)
        expectApprox(restored.blue, color.blue, tolerance: tolerance)
    }

    @Test func labExtremesRoundTrip() {
        let samples = [
            Color<Lab>(lightness: 0, a: 0, b: 0),
            Color<Lab>(lightness: 100, a: 0, b: 0),
            Color<Lab>(lightness: 50, a: 80, b: -120),
            Color<Lab>(lightness: -10, a: 200, b: 200),
            Color<Lab>(lightness: 120, a: -150, b: 40),
        ]
        for sample in samples {
            let restored = sample.converted(to: XYZ.self).converted(to: Lab.self)
            let tolerance = abs(sample.a) > 100 || sample.lightness < 0 || sample.lightness > 100 ? 1e-6 : 1e-8
            expectApprox(restored.lightness, sample.lightness, tolerance: tolerance)
            expectApprox(restored.a, sample.a, tolerance: tolerance)
            expectApprox(restored.b, sample.b, tolerance: tolerance)
        }
    }

    @Test func oklabExtremesRoundTrip() {
        let sample = Color<OKLab>(lightness: 0.4, a: -0.3, b: 0.5)
        let restored = sample.converted(to: XYZ.self).converted(to: OKLab.self)
        expectApprox(restored.lightness, sample.lightness)
        expectApprox(restored.a, sample.a)
        expectApprox(restored.b, sample.b)
    }

    @Test func polarFormsMatchRectangularForms() {
        let lab = Color<Lab>(lightness: 60, a: 30, b: -40)
        let lch = lab.converted(to: LCH.self)
        let restored = lch.converted(to: Lab.self)
        expectApprox(restored.lightness, lab.lightness, tolerance: 1e-12)
        expectApprox(restored.a, lab.a, tolerance: 1e-12)
        expectApprox(restored.b, lab.b, tolerance: 1e-12)

        let oklab = Color<OKLab>(lightness: 0.7, a: -0.1, b: 0.2)
        let oklch = oklab.converted(to: OKLCH.self)
        let restoredOK = oklch.converted(to: OKLab.self)
        expectApprox(restoredOK.lightness, oklab.lightness, tolerance: 1e-12)
        expectApprox(restoredOK.a, oklab.a, tolerance: 1e-12)
        expectApprox(restoredOK.b, oklab.b, tolerance: 1e-12)
    }

    @Test func equivalentHuesProduceTheSameLab() {
        let zero = Color<LCH>(lightness: 50, chroma: 20, hue: 0)
        let fullTurn = Color<LCH>(lightness: 50, chroma: 20, hue: 360)
        let negative = Color<LCH>(lightness: 50, chroma: 20, hue: -90)
        let positive = Color<LCH>(lightness: 50, chroma: 20, hue: 270)

        let fromZero = zero.converted(to: Lab.self)
        let fromTurn = fullTurn.converted(to: Lab.self)
        expectApprox(fromTurn.a, fromZero.a, tolerance: 1e-12)
        expectApprox(fromTurn.b, fromZero.b, tolerance: 1e-12)

        let fromNegative = negative.converted(to: Lab.self)
        let fromPositive = positive.converted(to: Lab.self)
        expectApprox(fromNegative.a, fromPositive.a, tolerance: 1e-12)
        expectApprox(fromNegative.b, fromPositive.b, tolerance: 1e-12)
    }

    @Test func missingHueIsNeutral() {
        let lch = Color<LCH>(lightness: 40, chroma: 25, hue: nil)
        let lab = lch.converted(to: Lab.self)
        expectApprox(lab.lightness, 40, tolerance: 1e-12)
        expectApprox(lab.a, 0, tolerance: 1e-12)
        expectApprox(lab.b, 0, tolerance: 1e-12)
        #expect(lab.converted(to: LCH.self).hue == nil)
    }

    @Test func transferBoundaryIsTheIECConstant() {
        // 0.04045 / 12.92 is slightly above 0.0031308, so the two IEC thresholds
        // are not exact inverses. The encoded boundary round-trips a few ulps away.
        let color = Color<SRGB>(red: 0.04045, green: 0, blue: 0)
        let linear = color.converted(to: LinearSRGB.self)
        expectApprox(linear.red, 0.04045 / 12.92, tolerance: 1e-15)
        #expect(linear.red > 0.0031308)
        let restored = linear.converted(to: SRGB.self)
        expectApprox(restored.red, 0.04045, tolerance: 1e-7)
    }

    @Test func neutralLabHasNoHue() {
        let lch = Color<Lab>(lightness: 30, a: 0, b: 0).converted(to: LCH.self)
        #expect(lch.hue == nil)
        expectApprox(lch.chroma, 0, tolerance: 0)
    }

    @Test func componentsAreNotClamped() {
        let color = Color<SRGB>(red: -0.4, green: 1.8, blue: 0.2)
        let lab = color.converted(to: Lab.self)
        let restored = lab.converted(to: SRGB.self)
        #expect(restored.red < 0)
        #expect(restored.green > 1)
        expectApprox(restored.red, color.red)
        expectApprox(restored.green, color.green)
        expectApprox(restored.blue, color.blue)
    }
}
