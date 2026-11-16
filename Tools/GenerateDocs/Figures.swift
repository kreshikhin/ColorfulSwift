import Colorful

struct Figure {
    var name: String
    var alt: String
    var logicalWidth: Int
    var png: [UInt8]
    var doccPNG: [UInt8]
}

struct ContrastSample {
    var name: String
    var background: Color<SRGB>
    var foreground: Color<SRGB>
    var ratio: Double
}

struct DifferenceSample {
    var name: String
    var left: Color<SRGB>
    var right: Color<SRGB>
    var delta: Double
}

struct Catalog {
    var interpolation: Figure
    var lightness: Figure
    var hue: Figure
    var contrast: Figure
    var difference: Figure
    var interpolationCaption: String
    var lightnessCaption: String
    var hueCaption: String
    var oklchRedHue: String
    var oklchGreenHue: String
    var contrastSamples: [ContrastSample]
    var differenceSamples: [DifferenceSample]
    var coordinateRows: [[String]]
    var roundTripDelta: Double
    var grayOnWhite: Double
}

private let exportScale = 2
private let red = Color<SRGB>(red: 1, green: 0, blue: 0)
private let green = Color<SRGB>(red: 0, green: 1, blue: 0)
private let blue = Color<SRGB>(red: 0, green: 0, blue: 1)
private let yellow = Color<SRGB>(red: 1, green: 1, blue: 0)
private let white = Color<SRGB>(red: 1, green: 1, blue: 1)
private let black = Color<SRGB>(red: 0, green: 0, blue: 0)
private let coral = Color<SRGB>(red: 0.8, green: 0.3, blue: 0.2)
private let orange = Color<SRGB>(red: 1, green: 0.5, blue: 0)
private let wcagGray = Color<SRGB>(red: 118.0 / 255.0, green: 118.0 / 255.0, blue: 118.0 / 255.0)

func makeCatalog() -> Catalog {
    let interpolationSteps = 13
    let interpolation = drawStrips(
        rows: [
            ("SRGB", ramp(interpolationSteps) { start, end, amount in
                start.interpolated(toward: end, amount: amount)
            }),
            ("OKLAB", ramp(interpolationSteps) { start, end, amount in
                start.interpolated(toward: end, amount: amount, in: OKLab.self)
            }),
            ("OKLCH", ramp(interpolationSteps) { start, end, amount in
                start.interpolated(toward: end, amount: amount, in: OKLCH.self)
            }),
        ],
        swatchWidth: 32,
        swatchHeight: 48,
        gap: 6
    )

    let lightnessSteps = 13
    let lightness = drawStrips(
        rows: [
            ("LINEAR", shown((0..<lightnessSteps).map { step in
                let amount = Double(step) / Double(lightnessSteps - 1)
                return Color<LinearSRGB>(red: amount, green: amount, blue: amount)
            })),
            ("SRGB", (0..<lightnessSteps).map { step in
                let amount = Double(step) / Double(lightnessSteps - 1)
                return Color<SRGB>(red: amount, green: amount, blue: amount)
            }),
            ("OKLAB", shown((0..<lightnessSteps).map { step in
                let amount = Double(step) / Double(lightnessSteps - 1)
                return Color<OKLab>(lightness: amount, a: 0, b: 0)
            })),
        ],
        swatchWidth: 32,
        swatchHeight: 48,
        gap: 6
    )

    let hueSteps = 24
    let oklchLightness = 0.74
    let oklchChroma = fittedChroma(startMilli: 150, stepMilli: 5, minimumMilli: 40) { milli in
        let chroma = Double(milli) / 1000
        return hueFits(hueSteps) { step in
            let hue = Double(step) / Double(hueSteps) * 360
            return Color<OKLCH>(lightness: oklchLightness, chroma: chroma, hue: hue)
        }
    }
    let lchLightness = 60.0
    let lchChroma = fittedChroma(startMilli: 45_000, stepMilli: 1000, minimumMilli: 8000) { milli in
        let chroma = Double(milli) / 1000
        return hueFits(hueSteps) { step in
            let hue = Double(step) / Double(hueSteps) * 360
            return Color<LCH>(lightness: lchLightness, chroma: chroma, hue: hue)
        }
    }
    let hue = drawStrips(
        rows: [
            ("LCH", shown((0..<hueSteps).map { step in
                let angle = Double(step) / Double(hueSteps) * 360
                return Color<LCH>(lightness: lchLightness, chroma: lchChroma, hue: angle)
            })),
            ("OKLCH", shown((0..<hueSteps).map { step in
                let angle = Double(step) / Double(hueSteps) * 360
                return Color<OKLCH>(lightness: oklchLightness, chroma: oklchChroma, hue: angle)
            })),
        ],
        swatchWidth: 18,
        swatchHeight: 40,
        gap: 3
    )

    let contrastSamples = [
        ContrastSample(name: "White on black", background: black, foreground: white, ratio: white.contrastRatio(against: black)),
        ContrastSample(name: "#767676 on white", background: white, foreground: wcagGray, ratio: wcagGray.contrastRatio(against: white)),
        ContrastSample(name: "Yellow on white", background: white, foreground: yellow, ratio: yellow.contrastRatio(against: white)),
        ContrastSample(name: "Coral on black", background: black, foreground: coral, ratio: coral.contrastRatio(against: black)),
    ]
    let contrast = drawContrast(contrastSamples)

    let differenceSamples = [
        DifferenceSample(
            name: "Near grays",
            left: Color<SRGB>(red: 0.5, green: 0.5, blue: 0.5),
            right: Color<SRGB>(red: 0.56, green: 0.56, blue: 0.56),
            delta: Color<SRGB>(red: 0.5, green: 0.5, blue: 0.5).deltaE76(to: Color<SRGB>(red: 0.56, green: 0.56, blue: 0.56))
        ),
        DifferenceSample(name: "Red and orange", left: red, right: orange, delta: red.deltaE76(to: orange)),
        DifferenceSample(name: "Blue and yellow", left: blue, right: yellow, delta: blue.deltaE76(to: yellow)),
    ]
    let difference = drawDifferences(differenceSamples)

    let redHue = red.converted(to: OKLCH.self).hue ?? 0
    let greenHue = green.converted(to: OKLCH.self).hue ?? 0
    let restored = coral.converted(to: OKLCH.self).converted(to: SRGB.self)

    return Catalog(
        interpolation: figure(
            "interpolation",
            alt: "Red to green in sRGB, OKLab, and OKLCH.",
            canvas: interpolation
        ),
        lightness: figure(
            "lightness",
            alt: "Equal steps from black to white in linear sRGB, encoded sRGB, and OKLab.",
            canvas: lightness
        ),
        hue: figure(
            "hue",
            alt: "CIELCH and OKLCH hue strips.",
            canvas: hue
        ),
        contrast: figure(
            "contrast",
            alt: "WCAG 2 contrast samples.",
            canvas: contrast
        ),
        difference: figure(
            "difference",
            alt: "CIE76 distance for three color pairs.",
            canvas: difference
        ),
        interpolationCaption: "Red to green in sRGB, OKLab, and OKLCH.",
        lightnessCaption: "Equal steps from 0 to 1 in linear sRGB, encoded sRGB, and OKLab.",
        hueCaption: "CIELCH at L* = \(formatFixed(lchLightness, fractionDigits: 0)) and C* = \(formatFixed(lchChroma, fractionDigits: 0)). OKLCH at L = \(formatFixed(oklchLightness, fractionDigits: 2)) and C = \(formatFixed(oklchChroma, fractionDigits: 3)).",
        oklchRedHue: formatFixed(redHue, fractionDigits: 1),
        oklchGreenHue: formatFixed(greenHue, fractionDigits: 1),
        contrastSamples: contrastSamples,
        differenceSamples: differenceSamples,
        coordinateRows: coordinateRows(for: coral, restored: restored),
        roundTripDelta: coral.deltaE76(to: restored),
        grayOnWhite: wcagGray.contrastRatio(against: white)
    )
}

private func coordinateRows(for color: Color<SRGB>, restored: Color<SRGB>) -> [[String]] {
    let linear = color.converted(to: LinearSRGB.self)
    let xyz = color.converted(to: XYZ.self)
    let lab = color.converted(to: Lab.self)
    let lch = color.converted(to: LCH.self)
    let oklab = color.converted(to: OKLab.self)
    let oklch = color.converted(to: OKLCH.self)
    return [
        ["`SRGB`", triple(color.red, color.green, color.blue)],
        ["`LinearSRGB`", triple(linear.red, linear.green, linear.blue)],
        ["`XYZ`", triple(xyz.x, xyz.y, xyz.z)],
        ["`Lab`", triple(lab.lightness, lab.a, lab.b)],
        ["`LCH`", polar(lch.lightness, lch.chroma, lch.hue)],
        ["`OKLab`", triple(oklab.lightness, oklab.a, oklab.b)],
        ["`OKLCH`", polar(oklch.lightness, oklch.chroma, oklch.hue)],
        ["`SRGB` round trip", triple(restored.red, restored.green, restored.blue)],
    ]
}

private func triple(_ a: Double, _ b: Double, _ c: Double) -> String {
    "\(formatFixed(a, fractionDigits: 4)), \(formatFixed(b, fractionDigits: 4)), \(formatFixed(c, fractionDigits: 4))"
}

private func polar(_ lightness: Double, _ chroma: Double, _ hue: Double?) -> String {
    let angle = hue.map { formatFixed($0, fractionDigits: 1) + "°" } ?? "none"
    return "\(formatFixed(lightness, fractionDigits: 4)), \(formatFixed(chroma, fractionDigits: 4)), \(angle)"
}

private func ramp<Mixed: ColorProtocol>(
    _ steps: Int,
    mix: (Color<SRGB>, Color<SRGB>, Double) -> Mixed
) -> [Color<SRGB>] {
    (0..<steps).map { step in
        let amount = Double(step) / Double(steps - 1)
        return mix(red, green, amount).converted(to: SRGB.self)
    }
}

private func hueFits<Sample: ColorProtocol>(_ steps: Int, color: (Int) -> Sample) -> Bool {
    for step in 0..<steps {
        let srgb = color(step).converted(to: SRGB.self)
        if srgb.red < -0.001 || srgb.red > 1.001 { return false }
        if srgb.green < -0.001 || srgb.green > 1.001 { return false }
        if srgb.blue < -0.001 || srgb.blue > 1.001 { return false }
    }
    return true
}

private func fittedChroma(startMilli: Int, stepMilli: Int, minimumMilli: Int, fits: (Int) -> Bool) -> Double {
    var milli = startMilli
    while milli > minimumMilli && !fits(milli) {
        milli -= stepMilli
    }
    return Double(milli) / 1000
}

private func shown<Sample: ColorProtocol>(_ colors: [Sample]) -> [Color<SRGB>] {
    colors.map { $0.converted(to: SRGB.self) }
}

private func displayed(_ color: some ColorProtocol) -> RGBA {
    let srgb = color.converted(to: SRGB.self)
    return RGBA(r: channelByte(srgb.red), g: channelByte(srgb.green), b: channelByte(srgb.blue))
}

private func channelByte(_ channel: Double) -> UInt8 {
    let clamped = min(max(channel, 0), 1)
    return UInt8(Int((clamped * 255).rounded()))
}

private func figure(_ name: String, alt: String, canvas: Canvas) -> Figure {
    Figure(
        name: name,
        alt: alt,
        logicalWidth: canvas.width,
        png: canvas.scaled(by: exportScale).png(),
        doccPNG: canvas.png()
    )
}

private func drawStrips(rows: [(String, [Color<SRGB>])], swatchWidth: Int, swatchHeight: Int, gap: Int) -> Canvas {
    let margin = 16
    let labelWidth = 84
    let columns = rows[0].1.count
    let width = margin + labelWidth + columns * swatchWidth + (columns - 1) * gap + margin
    let height = margin + rows.count * swatchHeight + (rows.count - 1) * gap + margin
    var canvas = Canvas(width: width, height: height, fill: .paper)
    for (rowIndex, row) in rows.enumerated() {
        let y = margin + rowIndex * (swatchHeight + gap)
        let textSize = Font.size(of: row.0)
        Font.draw(
            row.0,
            x: margin,
            y: y + (swatchHeight - textSize.height) / 2,
            color: .ink,
            into: &canvas
        )
        for (column, color) in row.1.enumerated() {
            let x = margin + labelWidth + column * (swatchWidth + gap)
            canvas.fill(x, y, swatchWidth, swatchHeight, displayed(color))
        }
    }
    return canvas
}

private func drawContrast(_ samples: [ContrastSample]) -> Canvas {
    let margin = 16
    let cardWidth = 120
    let cardHeight = 78
    let gap = 12
    let captionGap = 10
    let captionHeight = Font.size(of: "0").height
    let width = margin + samples.count * cardWidth + (samples.count - 1) * gap + margin
    let height = margin + cardHeight + captionGap + captionHeight + margin
    var canvas = Canvas(width: width, height: height, fill: .paper)
    for (index, sample) in samples.enumerated() {
        let x = margin + index * (cardWidth + gap)
        let y = margin
        canvas.fill(x, y, cardWidth, cardHeight, displayed(sample.background))
        let sampleText = "Aa"
        let sampleSize = Font.size(of: sampleText)
        Font.draw(
            sampleText,
            x: x + (cardWidth - sampleSize.width) / 2,
            y: y + (cardHeight - sampleSize.height) / 2,
            color: displayed(sample.foreground),
            into: &canvas
        )
        let caption = formatRatio(sample.ratio)
        let captionSize = Font.size(of: caption)
        Font.draw(
            caption,
            x: x + (cardWidth - captionSize.width) / 2,
            y: y + cardHeight + captionGap,
            color: .ink,
            into: &canvas
        )
    }
    return canvas
}

private func drawDifferences(_ samples: [DifferenceSample]) -> Canvas {
    let margin = 16
    let swatch = 64
    let innerGap = 6
    let pairGap = 22
    let captionGap = 10
    let pairWidth = swatch * 2 + innerGap
    let captionHeight = Font.size(of: "0").height
    let width = margin + samples.count * pairWidth + (samples.count - 1) * pairGap + margin
    let height = margin + swatch + captionGap + captionHeight + margin
    var canvas = Canvas(width: width, height: height, fill: .paper)
    for (index, sample) in samples.enumerated() {
        let x = margin + index * (pairWidth + pairGap)
        let y = margin
        canvas.fill(x, y, swatch, swatch, displayed(sample.left))
        canvas.fill(x + swatch + innerGap, y, swatch, swatch, displayed(sample.right))
        let caption = formatDelta(sample.delta)
        let captionSize = Font.size(of: caption)
        Font.draw(
            caption,
            x: x + (pairWidth - captionSize.width) / 2,
            y: y + swatch + captionGap,
            color: .ink,
            into: &canvas
        )
    }
    return canvas
}
