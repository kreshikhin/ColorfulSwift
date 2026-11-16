import Testing
import Colorful

struct ReferenceSample: Sendable, CustomTestStringConvertible {
    var testDescription: String { name }
    var name: String
    var red: Double
    var green: Double
    var blue: Double
    var linearRed: Double
    var linearGreen: Double
    var linearBlue: Double
    var x: Double
    var y: Double
    var z: Double
    var lightness: Double
    var a: Double
    var b: Double
    var chroma: Double
    var hue: Double?
    var okLightness: Double
    var okA: Double
    var okB: Double
    var okChroma: Double
    var okHue: Double?
}

/// Values computed independently from the CSS Color 4 sample conversion code:
/// rational sRGB matrices, CIE Lab fractions, linear Bradford D65↔D50, and the
/// D65-consistent OKLab matrices.
private let references: [ReferenceSample] = [
    ReferenceSample(
        name: "black",
        red: 0, green: 0, blue: 0,
        linearRed: 0, linearGreen: 0, linearBlue: 0,
        x: 0, y: 0, z: 0,
        lightness: 0, a: 0, b: 0, chroma: 0, hue: nil,
        okLightness: 0, okA: 0, okB: 0, okChroma: 0, okHue: nil
    ),
    ReferenceSample(
        name: "white",
        red: 1, green: 1, blue: 1,
        linearRed: 1, linearGreen: 1, linearBlue: 1,
        x: 0.9504559270516717, y: 1, z: 1.089057750759878,
        lightness: 100, a: 0, b: 0, chroma: 0, hue: nil,
        okLightness: 1, okA: 0, okB: 0, okChroma: 0, okHue: nil
    ),
    ReferenceSample(
        name: "red",
        red: 1, green: 0, blue: 0,
        linearRed: 1, linearGreen: 0, linearBlue: 0,
        x: 0.4123907992659595, y: 0.2126390058715104, z: 0.01933081871559185,
        lightness: 54.29054140467193, a: 80.80492817043528, b: 69.89096476862429,
        chroma: 106.8371816032147, hue: 40.8576565050116,
        okLightness: 0.6279553639214313, okA: 0.2248630684262742, okB: 0.125846277330585,
        okChroma: 0.2576833038053606, okHue: 29.23388027962789
    ),
    ReferenceSample(
        name: "green",
        red: 0, green: 1, blue: 0,
        linearRed: 0, linearGreen: 1, linearBlue: 0,
        x: 0.357584339383878, y: 0.7151686787677559, z: 0.119194779794626,
        lightness: 87.8185343650279, a: -79.27106077555146, b: 80.99458148439909,
        chroma: 113.331475355764, hue: 134.3838563618216,
        okLightness: 0.8664396175234367, okA: -0.2338875809365577, okB: 0.1794984451609376,
        okChroma: 0.2948272245426954, okHue: 142.4953450414439
    ),
    ReferenceSample(
        name: "blue",
        red: 0, green: 0, blue: 1,
        linearRed: 0, linearGreen: 0, linearBlue: 1,
        x: 0.1804807884018343, y: 0.07219231536073371, z: 0.9505321522496606,
        lightness: 29.56830197909668, a: 68.28736460254686, b: -112.0297095251052,
        chroma: 131.2014480889621, hue: 301.3642677330783,
        okLightness: 0.4520137181744237, okA: -0.03245697517079771, okB: -0.3115281656775778,
        okChroma: 0.3132143886344849, okHue: 264.0520226163699
    ),
    ReferenceSample(
        name: "gray",
        red: 0.5, green: 0.5, blue: 0.5,
        linearRed: 0.2140411404822326, linearGreen: 0.2140411404822326, linearBlue: 0.2140411404822326,
        x: 0.2034366706042374, y: 0.2140411404822326, z: 0.2331031630236593,
        lightness: 53.38896474111432, a: 0, b: 0, chroma: 0, hue: nil,
        okLightness: 0.5981807305268477, okA: 0, okB: 0, okChroma: 0, okHue: nil
    ),
    ReferenceSample(
        name: "rebeccapurple",
        red: 102.0 / 255.0, green: 51.0 / 255.0, blue: 153.0 / 255.0,
        linearRed: 0.132868321553818, linearGreen: 0.03310476657088506, linearBlue: 0.3185467781250919,
        x: 0.1241229930662937, y: 0.07492510943998718, z: 0.3093033234020097,
        lightness: 32.39271642037794, a: 38.42299376262082, b: -47.69112551144578,
        chroma: 61.2435294723522, hue: 308.8571210509701,
        okLightness: 0.4402717960022946, okA: 0.0881767611858455, okB: -0.1338643574830734,
        okChroma: 0.1602959993810878, okHue: 303.3729884885564
    ),
    ReferenceSample(
        name: "example",
        red: 0.8, green: 0.3, blue: 0.2,
        linearRed: 0.6038273388553378, linearGreen: 0.07323895587840543, linearBlue: 0.03310476657088506,
        x: 0.2811767169147067, y: 0.1831653621103566, z: 0.05186932305959163,
        lightness: 50.55336719200241, a: 50.51325062593676, b: 42.33693944823014,
        chroma: 65.90906561803016, hue: 39.96756198673058,
        okLightness: 0.586649448677417, okA: 0.1398753726245419, okB: 0.09148449883928989,
        okChroma: 0.1671362719302141, okHue: 33.18640898352172
    ),
]

@Suite("Published reference conversions")
struct ConversionTests {
    @Test(arguments: references)
    func matchesReference(_ sample: ReferenceSample) {
        let color = Color<SRGB>(red: sample.red, green: sample.green, blue: sample.blue)
        let linear = color.converted(to: LinearSRGB.self)
        let xyz = color.converted(to: XYZ.self)
        let lab = color.converted(to: Lab.self)
        let lch = color.converted(to: LCH.self)
        let oklab = color.converted(to: OKLab.self)
        let oklch = color.converted(to: OKLCH.self)

        expectApprox(linear.red, sample.linearRed)
        expectApprox(linear.green, sample.linearGreen)
        expectApprox(linear.blue, sample.linearBlue)

        expectApprox(xyz.x, sample.x)
        expectApprox(xyz.y, sample.y)
        expectApprox(xyz.z, sample.z)

        expectApprox(lab.lightness, sample.lightness)
        expectApprox(lab.a, sample.a)
        expectApprox(lab.b, sample.b)

        expectApprox(lch.lightness, sample.lightness)
        expectApprox(lch.chroma, sample.chroma)
        expectHue(lch.hue, sample.hue)

        expectApprox(oklab.lightness, sample.okLightness, tolerance: 1e-8)
        expectApprox(oklab.a, sample.okA)
        expectApprox(oklab.b, sample.okB)

        expectApprox(oklch.lightness, sample.okLightness)
        expectApprox(oklch.chroma, sample.okChroma)
        expectHue(oklch.hue, sample.okHue)
    }

    @Test func whitePointIsD65() {
        let white = Color<SRGB>(red: 1, green: 1, blue: 1).converted(to: XYZ.self)
        expectApprox(white.x, XYZ.d65.x, tolerance: 1e-12)
        expectApprox(white.y, XYZ.d65.y, tolerance: 1e-12)
        expectApprox(white.z, XYZ.d65.z, tolerance: 1e-12)
    }

    @Test func d65WhiteIsLabAndOKLabNeutral() {
        let xyz = Color<XYZ>(x: XYZ.d65.x, y: XYZ.d65.y, z: XYZ.d65.z)
        let lab = xyz.converted(to: Lab.self)
        let oklab = xyz.converted(to: OKLab.self)
        let lch = xyz.converted(to: LCH.self)
        let oklch = xyz.converted(to: OKLCH.self)

        expectApprox(lab.lightness, 100, tolerance: 1e-10)
        expectApprox(lab.a, 0, tolerance: 1e-10)
        expectApprox(lab.b, 0, tolerance: 1e-10)
        #expect(lch.hue == nil)

        expectApprox(oklab.lightness, 1, tolerance: 1e-12)
        expectApprox(oklab.a, 0, tolerance: 1e-12)
        expectApprox(oklab.b, 0, tolerance: 1e-12)
        #expect(oklch.hue == nil)
    }

    @Test func labReferenceWhiteAdaptsToD65() {
        let xyz = Color<Lab>(lightness: 100, a: 0, b: 0).converted(to: XYZ.self)
        expectApprox(xyz.x, XYZ.d65.x, tolerance: 1e-12)
        expectApprox(xyz.y, XYZ.d65.y, tolerance: 1e-12)
        expectApprox(xyz.z, XYZ.d65.z, tolerance: 1e-12)
    }

    @Test func encodedTransferFollowsIEC() {
        let below = Color<SRGB>(red: 0.04, green: 0, blue: 0).converted(to: LinearSRGB.self)
        expectApprox(below.red, 0.04 / 12.92, tolerance: 1e-15)

        let above = Color<SRGB>(red: 0.5, green: 0, blue: 0).converted(to: LinearSRGB.self)
        expectApprox(above.red, 0.2140411404822326, tolerance: 1e-12)
    }

    @Test func negativeTransferMirrorsPositive() {
        let positive = Color<SRGB>(red: 0.4, green: 0.02, blue: 1.2).converted(to: LinearSRGB.self)
        let negative = Color<SRGB>(red: -0.4, green: -0.02, blue: -1.2).converted(to: LinearSRGB.self)
        expectApprox(negative.red, -positive.red, tolerance: 1e-15)
        expectApprox(negative.green, -positive.green, tolerance: 1e-15)
        expectApprox(negative.blue, -positive.blue, tolerance: 1e-15)
    }

    @Test func sameSpaceConversionKeepsComponents() {
        let color = Color<SRGB>(red: 0.2, green: -0.4, blue: 1.5)
        let same = color.converted(to: SRGB.self)
        #expect(same.red == color.red)
        #expect(same.green == color.green)
        #expect(same.blue == color.blue)

        let lch = Color<LCH>(lightness: 40, chroma: 0, hue: 370)
        let sameLCH = lch.converted(to: LCH.self)
        #expect(sameLCH.lightness == lch.lightness)
        #expect(sameLCH.chroma == lch.chroma)
        #expect(sameLCH.hue == lch.hue)
    }

    @Test func readmeExampleRoundTrips() {
        let color = Color<SRGB>(red: 0.8, green: 0.3, blue: 0.2)
        let lab = color.converted(to: Lab.self)
        let oklch = color.converted(to: OKLCH.self)
        let restored = oklch.converted(to: SRGB.self)

        expectApprox(lab.lightness, 50.55336719200241)
        expectApprox(oklch.lightness, 0.586649448677417)
        expectApprox(restored.red, color.red)
        expectApprox(restored.green, color.green)
        expectApprox(restored.blue, color.blue)
    }
}
