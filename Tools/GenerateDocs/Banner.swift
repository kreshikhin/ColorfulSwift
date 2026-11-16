import Colorful
import Foundation

private let bannerWidth = 1600
private let bannerHeight = 600
private let bannerBackground = RGBA(r: 13, g: 17, b: 23)
private let bannerMuted = RGBA(r: 139, g: 148, b: 158)
private let labLightness = 55.0
private let oklchLightness = 0.70
private let geistRegular = TrueTypeFont.load(named: "Geist-Regular.ttf")

func makeBanner() -> [UInt8] {
    var canvas = Canvas(width: bannerWidth, height: bannerHeight, fill: bannerBackground)
    let cube = drawCube(into: &canvas, center: (350, 258), scale: 128)
    let lab = drawLabSlice(into: &canvas, origin: (630, 118), side: 280)
    let wheel = drawOKLCHDisk(into: &canvas, center: (1220, 258), radius: 140 * 1.65)
    let linkY = (cube.midY + lab.midY + wheel.midY) / 3
    drawArrow(centerX: (cube.maxX + lab.minX) / 2, y: linkY, into: &canvas)
    drawArrow(centerX: (lab.maxX + wheel.minX) / 2, y: linkY, into: &canvas)

    let labelBaseline = 450.0
    drawCentered("sRGB", around: cube.midX, baseline: labelBaseline, size: 22, into: &canvas)
    drawCentered("CIELAB", around: lab.midX, baseline: labelBaseline, size: 22, into: &canvas)
    drawCentered("L* = 55", around: lab.midX, baseline: labelBaseline + 26, size: 16, into: &canvas)
    drawCentered("OKLCH", around: wheel.midX, baseline: labelBaseline, size: 22, into: &canvas)
    drawCentered("L = 0.70", around: wheel.midX, baseline: labelBaseline + 26, size: 16, into: &canvas)

    return canvas.pngTruecolor()
}

private func drawCentered(
    _ text: String,
    around midX: Double,
    baseline: Double,
    size: Double,
    into canvas: inout Canvas
) {
    let width = geistRegular.measure(text, size: size)
    geistRegular.draw(
        text,
        x: midX - width / 2,
        baseline: baseline,
        size: size,
        color: bannerMuted,
        into: &canvas
    )
}

private func drawArrow(centerX: Double, y: Double, into canvas: inout Canvas) {
    let tail = centerX - 15
    let head = centerX + 13
    stroke(tail, y, head, y, width: 1.6, color: bannerMuted, into: &canvas)
    stroke(head - 8, y - 5.5, head, y, width: 1.6, color: bannerMuted, into: &canvas)
    stroke(head - 8, y + 5.5, head, y, width: 1.6, color: bannerMuted, into: &canvas)
}

private struct Bounds {
    var minX: Double
    var maxX: Double
    var minY: Double
    var maxY: Double

    var midX: Double { (minX + maxX) / 2 }
    var midY: Double { (minY + maxY) / 2 }
}

private func drawCube(into canvas: inout Canvas, center: (Double, Double), scale: Double) -> Bounds {
    let steps = 8
    func project(_ red: Double, _ green: Double, _ blue: Double) -> (Double, Double) {
        let x = (red - green) * 0.8660254037844386 * scale
        let y = (red + green) * 0.5 * scale - blue * scale
        return (center.0 + x, center.1 + y)
    }
    func cell(
        _ a0: Double, _ b0: Double, _ a1: Double, _ b1: Double,
        corner: (Double, Double) -> (Double, Double, Double)
    ) {
        let inset = 0.045
        let u0 = a0 + (a1 - a0) * inset
        let v0 = b0 + (b1 - b0) * inset
        let u1 = a1 - (a1 - a0) * inset
        let v1 = b1 - (b1 - b0) * inset
        let samples = [corner(u0, v0), corner(u1, v0), corner(u1, v1), corner(u0, v1)]
        let points = samples.map { project($0.0, $0.1, $0.2) }
        let middle = corner((a0 + a1) / 2, (b0 + b1) / 2)
        fillQuad(points, displayed(Color<SRGB>(red: middle.0, green: middle.1, blue: middle.2)), into: &canvas)
    }

    for j in 0..<steps {
        for i in 0..<steps {
            let u0 = Double(i) / Double(steps)
            let u1 = Double(i + 1) / Double(steps)
            let v0 = Double(j) / Double(steps)
            let v1 = Double(j + 1) / Double(steps)
            cell(u0, v0, u1, v1) { green, blue in (1, green, blue) }
            cell(u0, v0, u1, v1) { red, blue in (red, 1, blue) }
        }
    }
    for j in 0..<steps {
        for i in 0..<steps {
            let u0 = Double(i) / Double(steps)
            let u1 = Double(i + 1) / Double(steps)
            let v0 = Double(j) / Double(steps)
            let v1 = Double(j + 1) / Double(steps)
            cell(u0, v0, u1, v1) { red, green in (red, green, 1) }
        }
    }

    let silhouette = [
        project(0, 0, 1), project(1, 0, 1), project(1, 0, 0),
        project(1, 1, 0), project(0, 1, 0), project(0, 1, 1),
    ]
    for index in silhouette.indices {
        let start = silhouette[index]
        let end = silhouette[(index + 1) % silhouette.count]
        stroke(start.0, start.1, end.0, end.1, width: 1.5, color: bannerMuted, into: &canvas)
    }
    axisMark("G", red: 0, green: 1, blue: 0, dx: -22, dy: 6, project: project, into: &canvas)
    axisMark("R", red: 1, green: 0, blue: 0, dx: 22, dy: 6, project: project, into: &canvas)
    axisMark("B", red: 0, green: 0, blue: 1, dx: 0, dy: -18, project: project, into: &canvas)
    let corners = silhouette + [project(0, 0, 0), project(1, 1, 1)]
    return Bounds(
        minX: corners.map(\.0).min() ?? center.0,
        maxX: corners.map(\.0).max() ?? center.0,
        minY: corners.map(\.1).min() ?? center.1,
        maxY: corners.map(\.1).max() ?? center.1
    )
}

private func drawLabSlice(into canvas: inout Canvas, origin: (Double, Double), side: Int) -> Bounds {
    let span = 170.0
    var filled = Array(repeating: false, count: side * side)
    for y in 0..<side {
        for x in 0..<side {
            let a = (Double(x) + 0.5) / Double(side) * span - span / 2
            let b = span / 2 - (Double(y) + 0.5) / Double(side) * span
            let linear = Color<Lab>(lightness: labLightness, a: a, b: b).converted(to: LinearSRGB.self)
            guard sampleInsideGamut(linear) else { continue }
            filled[y * side + x] = true
            let onA = isoline(a, span: span, side: side)
            let onB = isoline(b, span: span, side: side)
            let color = (onA || onB) ? bannerBackground : displayed(linear.converted(to: SRGB.self))
            canvas.set(Int(origin.0) + x, Int(origin.1) + y, color)
        }
    }
    return outlineGamut(filled, side: side, origin: origin, into: &canvas)
}

private func drawOKLCHDisk(into canvas: inout Canvas, center: (Double, Double), radius: Double) -> Bounds {
    let chromaLimit = maximumOKLCHChroma(lightness: oklchLightness)
    let margin = 2.0
    let side = Int((radius + margin) * 2)
    let origin = (center.0 - radius - margin, center.1 - radius - margin)
    var filled = Array(repeating: false, count: side * side)
    for y in 0..<side {
        for x in 0..<side {
            let dx = (Double(x) + 0.5) - (radius + margin)
            let dy = (Double(y) + 0.5) - (radius + margin)
            let distance = (dx * dx + dy * dy).squareRoot()
            let chroma = distance / radius * chromaLimit
            var hue = atan2(-dy, dx) * 180 / .pi
            if hue < 0 { hue += 360 }
            if hue >= 360 { hue = 0 }
            let linear = Color<OKLCH>(
                lightness: oklchLightness,
                chroma: chroma,
                hue: hue
            ).converted(to: LinearSRGB.self)
            guard sampleInsideGamut(linear) else { continue }
            filled[y * side + x] = true
            let onRing = chromaIsoline(chroma, limit: chromaLimit, radius: radius)
            let onSpoke = polarSpoke(hue, distance: distance)
            let color = (onRing || onSpoke) ? bannerBackground : displayed(linear.converted(to: SRGB.self))
            canvas.set(Int(origin.0) + x, Int(origin.1) + y, color)
        }
    }
    return outlineGamut(filled, side: side, origin: origin, into: &canvas)
}

private func maximumOKLCHChroma(lightness: Double) -> Double {
    var peak = 0.0
    for step in 0..<360 {
        let hue = Double(step)
        var low = 0.0
        var high = 0.4
        for _ in 0..<18 {
            let chroma = (low + high) / 2
            let linear = Color<OKLCH>(lightness: lightness, chroma: chroma, hue: hue).converted(to: LinearSRGB.self)
            if containsSRGBGamut(linear) {
                low = chroma
            } else {
                high = chroma
            }
        }
        if low > peak { peak = low }
    }
    return peak
}

private let isolineWidth = 1.05
private let oklchGridWidth = 0.85

private func isoline(_ value: Double, span: Double, side: Int) -> Bool {
    let step = 15.0
    let nearest = (value / step).rounded() * step
    guard abs(nearest) < span / 2 - step * 0.5 else { return false }
    let pixels = abs(value - nearest) / span * Double(side)
    return pixels < isolineWidth
}

private func chromaIsoline(_ chroma: Double, limit: Double, radius: Double) -> Bool {
    let step = 0.025
    let nearest = (chroma / step).rounded() * step
    guard nearest >= step * 0.5, nearest < limit - step * 0.25 else { return false }
    let pixels = abs(chroma - nearest) / limit * radius
    return pixels < oklchGridWidth
}

private func axisMark(
    _ text: String,
    red: Double,
    green: Double,
    blue: Double,
    dx: Double,
    dy: Double,
    project: (Double, Double, Double) -> (Double, Double),
    into canvas: inout Canvas
) {
    let point = project(red, green, blue)
    let size = 18.0
    let width = geistRegular.measure(text, size: size)
    geistRegular.draw(
        text,
        x: point.0 + dx - width / 2,
        baseline: point.1 + dy,
        size: size,
        color: bannerMuted,
        into: &canvas
    )
}

private func outlineGamut(
    _ filled: [Bool],
    side: Int,
    origin: (Double, Double),
    into canvas: inout Canvas
) -> Bounds {
    var minX = side
    var maxX = 0
    var minY = side
    var maxY = 0
    for y in 0..<side {
        for x in 0..<side {
            let index = y * side + x
            if filled[index] {
                minX = min(minX, x)
                maxX = max(maxX, x)
                minY = min(minY, y)
                maxY = max(maxY, y)
                continue
            }
            let left = x > 0 && filled[index - 1]
            let right = x + 1 < side && filled[index + 1]
            let above = y > 0 && filled[index - side]
            let below = y + 1 < side && filled[index + side]
            let neighbors = [left, right, above, below].filter { $0 }.count
            if neighbors > 0 {
                canvas.blend(Int(origin.0) + x, Int(origin.1) + y, bannerMuted, coverage: Double(neighbors) / 4)
            }
        }
    }
    return Bounds(
        minX: origin.0 + Double(minX),
        maxX: origin.0 + Double(maxX + 1),
        minY: origin.1 + Double(minY),
        maxY: origin.1 + Double(maxY + 1)
    )
}

private func polarSpoke(_ hue: Double, distance: Double) -> Bool {
    let step = 30.0
    var delta = abs(hue - (hue / step).rounded() * step)
    if delta > 180 { delta = 360 - delta }
    return distance * delta * .pi / 180 < oklchGridWidth
}

/// Linear-light sRGB gamut: the closed unit cube. The IEC transfer maps that
/// cube onto encoded sRGB, so the two descriptions are the same set.
private func containsSRGBGamut(_ color: Color<LinearSRGB>) -> Bool {
    let channels = [color.red, color.green, color.blue]
    return channels.allSatisfy { $0 >= 0 && $0 <= 1 }
}

/// Extra room for a pixel sample that lands on the boundary. This is not part
/// of the gamut test. Ordinary conversions round-trip to about 1e-7.
private let rasterSampleSlack = 1e-8

private func sampleInsideGamut(_ color: Color<LinearSRGB>) -> Bool {
    let channels = [color.red, color.green, color.blue]
    return channels.allSatisfy { $0 >= -rasterSampleSlack && $0 <= 1 + rasterSampleSlack }
}

private func displayed(_ color: Color<SRGB>) -> RGBA {
    RGBA(r: channelByte(color.red), g: channelByte(color.green), b: channelByte(color.blue))
}

private func channelByte(_ channel: Double) -> UInt8 {
    let clamped = min(max(channel, 0), 1)
    return UInt8(Int((clamped * 255).rounded()))
}

private func fillQuad(_ points: [(Double, Double)], _ color: RGBA, into canvas: inout Canvas) {
    let minX = Int(points.map(\.0).min()?.rounded(.down) ?? 0)
    let maxX = Int(points.map(\.0).max()?.rounded(.up) ?? 0)
    let minY = Int(points.map(\.1).min()?.rounded(.down) ?? 0)
    let maxY = Int(points.map(\.1).max()?.rounded(.up) ?? 0)
    guard points.count == 4 else { return }
    for y in minY...maxY {
        for x in minX...maxX {
            if inside(Double(x) + 0.5, Double(y) + 0.5, points) {
                canvas.set(x, y, color)
            }
        }
    }
}

private func inside(_ x: Double, _ y: Double, _ points: [(Double, Double)]) -> Bool {
    var sign = 0
    for index in points.indices {
        let start = points[index]
        let end = points[(index + 1) % points.count]
        let cross = (end.0 - start.0) * (y - start.1) - (end.1 - start.1) * (x - start.0)
        let next = cross > 0 ? 1 : (cross < 0 ? -1 : 0)
        if next == 0 { continue }
        if sign == 0 {
            sign = next
        } else if next != sign {
            return false
        }
    }
    return true
}

private func stroke(
    _ x0: Double, _ y0: Double, _ x1: Double, _ y1: Double,
    width: Double, color: RGBA, into canvas: inout Canvas
) {
    strokeSegment(x0, y0, x1, y1, radius: width / 2, color: color, into: &canvas)
}

private func strokeSegment(
    _ x0: Double, _ y0: Double, _ x1: Double, _ y1: Double,
    radius: Double, color: RGBA, into canvas: inout Canvas
) {
    let minX = Int((min(x0, x1) - radius - 1).rounded(.down))
    let maxX = Int((max(x0, x1) + radius + 1).rounded(.up))
    let minY = Int((min(y0, y1) - radius - 1).rounded(.down))
    let maxY = Int((max(y0, y1) + radius + 1).rounded(.up))
    for y in minY...maxY {
        for x in minX...maxX {
            let distance = distanceToSegment(Double(x) + 0.5, Double(y) + 0.5, x0, y0, x1, y1)
            let coverage = radius + 0.5 - distance
            if coverage > 0 {
                canvas.blend(x, y, color, coverage: coverage)
            }
        }
    }
}

private func distanceToSegment(
    _ px: Double, _ py: Double,
    _ x0: Double, _ y0: Double, _ x1: Double, _ y1: Double
) -> Double {
    let dx = x1 - x0
    let dy = y1 - y0
    let lengthSquared = dx * dx + dy * dy
    var t = 0.0
    if lengthSquared > 0 {
        t = ((px - x0) * dx + (py - y0) * dy) / lengthSquared
        t = min(1, max(0, t))
    }
    let qx = x0 + t * dx
    let qy = y0 + t * dy
    let ex = px - qx
    let ey = py - qy
    return (ex * ex + ey * ey).squareRoot()
}
