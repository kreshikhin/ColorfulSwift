import Testing
import Colorful

@Suite("CIE76 and WCAG contrast")
struct MetricsTests {
    @Test func deltaE76IsEuclidean() {
        let start = Color<Lab>(lightness: 50, a: 0, b: 0)
        let end = Color<Lab>(lightness: 50, a: 3, b: 4)
        expectApprox(start.deltaE76(to: end), 5, tolerance: 1e-15)
        expectApprox(end.deltaE76(to: start), 5, tolerance: 1e-15)
        expectApprox(start.deltaE76(to: start), 0, tolerance: 0)
    }

    @Test func deltaE76ConvertsIntoLab() {
        let black = Color<SRGB>(red: 0, green: 0, blue: 0)
        let white = Color<SRGB>(red: 1, green: 1, blue: 1)
        expectApprox(black.deltaE76(to: white), 100, tolerance: 1e-8)
    }

    @Test func blackAndWhiteContrastIs21() {
        let black = Color<SRGB>(red: 0, green: 0, blue: 0)
        let white = Color<SRGB>(red: 1, green: 1, blue: 1)
        #expect(white.contrastRatio(against: black) == 21)
        #expect(black.contrastRatio(against: white) == 21)
        #expect(white.contrastRatio(against: white) == 1)
    }

    @Test func relativeLuminanceMatchesWCAG() {
        #expect(Color<SRGB>(red: 0, green: 0, blue: 0).relativeLuminance == 0)
        expectApprox(Color<SRGB>(red: 1, green: 1, blue: 1).relativeLuminance, 1, tolerance: 1e-15)

        let channel = 118.0 / 255.0
        let gray = Color<SRGB>(red: channel, green: channel, blue: channel)
        expectApprox(gray.relativeLuminance, 0.18116424424986022, tolerance: 1e-12)
        expectApprox(gray.contrastRatio(against: Color<SRGB>(red: 1, green: 1, blue: 1)), 4.542224959605253)
        expectApprox(gray.contrastRatio(against: Color<SRGB>(red: 0, green: 0, blue: 0)), 4.6232848849972035)
    }

    @Test func outOfGamutContrastIsNotClamped() {
        let hot = Color<SRGB>(red: 2, green: 2, blue: 2)
        let black = Color<SRGB>(red: 0, green: 0, blue: 0)
        #expect(hot.relativeLuminance > 1)
        #expect(hot.contrastRatio(against: black) > 21)
    }

    @Test func contrastConvertsToSRGB() {
        let white = Color<Lab>(lightness: 100, a: 0, b: 0)
        let black = Color<Lab>(lightness: 0, a: 0, b: 0)
        expectApprox(white.contrastRatio(against: black), 21, tolerance: 1e-8)
    }
}
