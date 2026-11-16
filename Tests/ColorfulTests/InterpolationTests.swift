import Testing
import Colorful

@Suite("Interpolation")
struct InterpolationTests {
    @Test func endpointsAreExact() {
        let start = Color<SRGB>(red: -0.2, green: 0.3, blue: 1.4)
        let end = Color<SRGB>(red: 0.8, green: 0.1, blue: 0)
        let atStart = start.interpolated(toward: end, amount: 0)
        let atEnd = start.interpolated(toward: end, amount: 1)
        #expect(atStart == start)
        #expect(atEnd == end)
    }

    @Test func rectangularMidpoint() {
        let start = Color<LinearSRGB>(red: 0, green: 0.2, blue: 1)
        let end = Color<LinearSRGB>(red: 1, green: 0.6, blue: -1)
        let mid = start.interpolated(toward: end, amount: 0.25)
        expectApprox(mid.red, 0.25, tolerance: 1e-15)
        expectApprox(mid.green, 0.3, tolerance: 1e-15)
        expectApprox(mid.blue, 0.5, tolerance: 1e-15)
    }

    @Test func extrapolationIsNotClamped() {
        let start = Color<SRGB>(red: 0, green: 0, blue: 0)
        let end = Color<SRGB>(red: 1, green: -1, blue: 0.5)
        let beyond = start.interpolated(toward: end, amount: 2)
        #expect(beyond.red == 2)
        #expect(beyond.green == -2)
        #expect(beyond.blue == 1)
    }

    @Test func hueTakesTheShortestPath() {
        let start = Color<LCH>(lightness: 50, chroma: 20, hue: 350)
        let end = Color<LCH>(lightness: 50, chroma: 40, hue: 10)
        let mid = start.interpolated(toward: end, amount: 0.5)
        expectApprox(mid.lightness, 50, tolerance: 1e-15)
        expectApprox(mid.chroma, 30, tolerance: 1e-15)
        expectHue(mid.hue, 0)

        let reverse = end.interpolated(toward: start, amount: 0.5)
        expectHue(reverse.hue, 0)
    }

    @Test func achromaticHueDoesNotPullTheArc() {
        let gray = Color<LCH>(lightness: 50, chroma: 0, hue: 180)
        let red = Color<LCH>(lightness: 50, chroma: 40, hue: 20)
        let mid = gray.interpolated(toward: red, amount: 0.5)
        expectApprox(mid.chroma, 20, tolerance: 1e-15)
        expectHue(mid.hue, 20)

        let both = gray.interpolated(toward: Color<LCH>(lightness: 70, chroma: 0, hue: 10), amount: 0.5)
        #expect(both.hue == nil)
        expectApprox(both.lightness, 60, tolerance: 1e-15)
        expectApprox(both.chroma, 0, tolerance: 1e-15)
    }

    @Test func interpolatesAcrossSpaces() {
        let srgb = Color<SRGB>(red: 1, green: 0, blue: 0)
        let other = Color<Lab>(lightness: 100, a: 0, b: 0)
        let mid = srgb.interpolated(toward: other, amount: 0.5, in: Lab.self)
        let redLab = srgb.converted(to: Lab.self)
        expectApprox(mid.lightness, (redLab.lightness + 100) / 2)
        expectApprox(mid.a, redLab.a / 2)
        expectApprox(mid.b, redLab.b / 2)
    }

    @Test func oklchShortestHue() {
        let start = Color<OKLCH>(lightness: 0.6, chroma: 0.1, hue: 10)
        let end = Color<OKLCH>(lightness: 0.8, chroma: 0.1, hue: 350)
        let mid = start.interpolated(toward: end, amount: 0.5)
        expectHue(mid.hue, 0)
        expectApprox(mid.lightness, 0.7, tolerance: 1e-15)
    }
}
