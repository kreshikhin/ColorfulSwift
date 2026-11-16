import Foundation

// Rasterizes the vendored Geist fonts. The outlines are read from the
// TrueType glyf table, so the banner does not depend on a system font
// or on Core Text, and the pixels stay the same on every machine.

struct TrueTypeFont {
    let unitsPerEm: Double
    private let glyphs: [UInt32: Glyph]

    func measure(_ text: String, size: Double) -> Double {
        let scale = size / unitsPerEm
        return text.unicodeScalars.reduce(0) { total, scalar in
            total + (glyphs[scalar.value]?.advance ?? 0) * scale
        }
    }

    func draw(
        _ text: String,
        x: Double,
        baseline: Double,
        size: Double,
        color: RGBA,
        into canvas: inout Canvas
    ) {
        let scale = size / unitsPerEm
        var pen = x
        for scalar in text.unicodeScalars {
            guard let glyph = glyphs[scalar.value] else {
                fatalError("Missing glyph for U+\(String(scalar.value, radix: 16))")
            }
            let contours = glyph.contours.map { contour in
                contour.map { point in
                    Point(pen + point.x * scale, baseline - point.y * scale)
                }
            }
            fill(contours, color: color, into: &canvas)
            pen += glyph.advance * scale
        }
    }

    static func load(named name: String) -> TrueTypeFont {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("Fonts")
            .appendingPathComponent(name)
        guard let bytes = try? Data(contentsOf: url) else {
            fatalError("Missing font \(name)")
        }
        return TrueTypeFont(parsing: Array(bytes))
    }
}

private struct Glyph {
    var advance: Double
    var contours: [[Point]]
}

private struct Point {
    var x: Double
    var y: Double

    init(_ x: Double, _ y: Double) {
        self.x = x
        self.y = y
    }
}

private struct CurvePoint {
    var x: Double
    var y: Double
    var onCurve: Bool
}

extension TrueTypeFont {
    fileprivate init(parsing bytes: [UInt8]) {
        let data = FontBytes(bytes: bytes)
        let tables = data.tables()
        let head = tables["head"] ?? 0
        let maxp = tables["maxp"] ?? 0
        let hhea = tables["hhea"] ?? 0
        let hmtx = tables["hmtx"] ?? 0
        let loca = tables["loca"] ?? 0
        let glyf = tables["glyf"] ?? 0
        unitsPerEm = Double(data.u16(head + 18))
        let glyphCount = data.u16(maxp + 4)
        let longOffsets = data.i16(head + 50) == 1
        var offsets = [Int](repeating: 0, count: glyphCount + 1)
        for index in 0...glyphCount {
            if longOffsets {
                offsets[index] = data.u32(loca + index * 4)
            } else {
                offsets[index] = data.u16(loca + index * 2) * 2
            }
        }
        let metrics = data.u16(hhea + 34)
        let cmap = data.format4(at: tables["cmap"] ?? 0)
        var parsed: [UInt32: Glyph] = [:]
        for code in UInt32(32)...UInt32(126) {
            let index = cmap[code] ?? 0
            parsed[code] = data.glyph(
                index: index,
                glyf: glyf,
                offsets: offsets,
                hmtx: hmtx,
                metrics: metrics
            )
        }
        glyphs = parsed
    }
}

private struct FontBytes {
    let bytes: [UInt8]

    func u8(_ offset: Int) -> Int { Int(bytes[offset]) }

    func u16(_ offset: Int) -> Int {
        Int(bytes[offset]) << 8 | Int(bytes[offset + 1])
    }

    func i16(_ offset: Int) -> Int {
        let value = u16(offset)
        return value >= 0x8000 ? value - 0x10000 : value
    }

    func u32(_ offset: Int) -> Int {
        u16(offset) << 16 | u16(offset + 2)
    }

    func f2dot14(_ offset: Int) -> Double {
        Double(i16(offset)) / 16384
    }

    func tables() -> [String: Int] {
        var result: [String: Int] = [:]
        let count = u16(4)
        var cursor = 12
        for _ in 0..<count {
            let tag = String(bytes: bytes[cursor..<(cursor + 4)], encoding: .ascii) ?? ""
            result[tag] = u32(cursor + 8)
            cursor += 16
        }
        return result
    }

    func format4(at cmap: Int) -> [UInt32: Int] {
        let subtables = u16(cmap + 2)
        var chosen = 0
        for index in 0..<subtables {
            let record = cmap + 4 + index * 8
            let platform = u16(record)
            let encoding = u16(record + 2)
            let offset = cmap + u32(record + 4)
            guard u16(offset) == 4 else { continue }
            if platform == 0 || (platform == 3 && encoding == 1) {
                chosen = offset
                if platform == 3 { break }
            }
        }
        let segments = u16(chosen + 6) / 2
        let endBase = chosen + 14
        let startBase = endBase + segments * 2 + 2
        let deltaBase = startBase + segments * 2
        let rangeBase = deltaBase + segments * 2
        var map: [UInt32: Int] = [:]
        for code in 32...126 {
            for index in 0..<segments {
                let end = u16(endBase + index * 2)
                if code > end { continue }
                let start = u16(startBase + index * 2)
                if code < start { break }
                let delta = i16(deltaBase + index * 2)
                let range = u16(rangeBase + index * 2)
                let glyph: Int
                if range == 0 {
                    glyph = (code + delta) & 0xFFFF
                } else {
                    let address = rangeBase + index * 2 + range + (code - start) * 2
                    let raw = u16(address)
                    glyph = raw == 0 ? 0 : (raw + delta) & 0xFFFF
                }
                map[UInt32(code)] = glyph
                break
            }
        }
        return map
    }

    func glyph(index: Int, glyf: Int, offsets: [Int], hmtx: Int, metrics: Int) -> Glyph {
        let advance: Double
        if index < metrics {
            advance = Double(u16(hmtx + index * 4))
        } else {
            advance = Double(u16(hmtx + (metrics - 1) * 4))
        }
        let start = offsets[index]
        let end = offsets[index + 1]
        if start >= end {
            return Glyph(advance: advance, contours: [])
        }
        let count = i16(glyf + start)
        if count < 0 {
            return Glyph(advance: advance, contours: composite(at: glyf + start, glyf: glyf, offsets: offsets, hmtx: hmtx, metrics: metrics))
        }
        if count == 0 {
            return Glyph(advance: advance, contours: [])
        }
        return Glyph(advance: advance, contours: simple(at: glyf + start, contours: count))
    }

    func simple(at offset: Int, contours: Int) -> [[Point]] {
        var cursor = offset + 10
        var ends: [Int] = []
        ends.reserveCapacity(contours)
        for _ in 0..<contours {
            ends.append(u16(cursor))
            cursor += 2
        }
        let instructions = u16(cursor)
        cursor += 2 + instructions
        let pointCount = (ends.last ?? -1) + 1
        var flags: [Int] = []
        flags.reserveCapacity(pointCount)
        while flags.count < pointCount {
            let flag = u8(cursor)
            cursor += 1
            let repeats = (flag & 8) == 0 ? 1 : 1 + u8(cursor)
            if (flag & 8) != 0 { cursor += 1 }
            for _ in 0..<repeats {
                flags.append(flag)
            }
        }
        var raw: [CurvePoint] = []
        raw.reserveCapacity(pointCount)
        var x = 0
        for flag in flags {
            if (flag & 2) != 0 {
                let delta = u8(cursor)
                cursor += 1
                x += (flag & 16) != 0 ? delta : -delta
            } else if (flag & 16) == 0 {
                x += i16(cursor)
                cursor += 2
            }
            raw.append(CurvePoint(x: Double(x), y: 0, onCurve: (flag & 1) != 0))
        }
        var y = 0
        for index in raw.indices {
            let flag = flags[index]
            if (flag & 4) != 0 {
                let delta = u8(cursor)
                cursor += 1
                y += (flag & 32) != 0 ? delta : -delta
            } else if (flag & 32) == 0 {
                y += i16(cursor)
                cursor += 2
            }
            raw[index].y = Double(y)
        }
        var polygons: [[Point]] = []
        var start = 0
        for end in ends {
            polygons.append(flatten(Array(raw[start...end])))
            start = end + 1
        }
        return polygons
    }

    func composite(at offset: Int, glyf: Int, offsets: [Int], hmtx: Int, metrics: Int) -> [[Point]] {
        var cursor = offset + 10
        var polygons: [[Point]] = []
        var more = true
        while more {
            let flags = u16(cursor)
            cursor += 2
            let index = u16(cursor)
            cursor += 2
            let argument1: Double
            let argument2: Double
            if (flags & 1) != 0 {
                argument1 = Double(i16(cursor))
                argument2 = Double(i16(cursor + 2))
                cursor += 4
            } else {
                argument1 = Double(i8(cursor))
                argument2 = Double(i8(cursor + 1))
                cursor += 2
            }
            var xx = 1.0
            var xy = 0.0
            var yx = 0.0
            var yy = 1.0
            if (flags & 8) != 0 {
                xx = f2dot14(cursor)
                yy = xx
                cursor += 2
            } else if (flags & 64) != 0 {
                xx = f2dot14(cursor)
                yy = f2dot14(cursor + 2)
                cursor += 4
            } else if (flags & 128) != 0 {
                xx = f2dot14(cursor)
                yx = f2dot14(cursor + 2)
                xy = f2dot14(cursor + 4)
                yy = f2dot14(cursor + 6)
                cursor += 8
            }
            let dx = (flags & 2) != 0 ? argument1 : 0
            let dy = (flags & 2) != 0 ? argument2 : 0
            let component = glyph(index: index, glyf: glyf, offsets: offsets, hmtx: hmtx, metrics: metrics)
            for contour in component.contours {
                polygons.append(contour.map { point in
                    Point(xx * point.x + xy * point.y + dx, yx * point.x + yy * point.y + dy)
                })
            }
            more = (flags & 32) != 0
        }
        return polygons
    }

    func i8(_ offset: Int) -> Int {
        let value = u8(offset)
        return value >= 128 ? value - 256 : value
    }
}

private func flatten(_ contour: [CurvePoint]) -> [Point] {
    guard let first = contour.first else { return [] }
    var points = contour
    if !first.onCurve {
        if points[points.count - 1].onCurve {
            points.insert(points.removeLast(), at: 0)
        } else {
            let last = points[points.count - 1]
            points.insert(
                CurvePoint(x: (first.x + last.x) / 2, y: (first.y + last.y) / 2, onCurve: true),
                at: 0
            )
        }
    }
    var polygon = [Point(points[0].x, points[0].y)]
    var index = 1
    while index < points.count {
        if points[index].onCurve {
            polygon.append(Point(points[index].x, points[index].y))
            index += 1
            continue
        }
        let control = points[index]
        let next: CurvePoint
        if index + 1 < points.count && points[index + 1].onCurve {
            next = points[index + 1]
            index += 2
        } else if index + 1 < points.count {
            let following = points[index + 1]
            next = CurvePoint(
                x: (control.x + following.x) / 2,
                y: (control.y + following.y) / 2,
                onCurve: true
            )
            index += 1
        } else {
            next = points[0]
            index += 1
        }
        flattenCurve(
            polygon[polygon.count - 1],
            Point(control.x, control.y),
            Point(next.x, next.y),
            into: &polygon
        )
    }
    return polygon
}

private func flattenCurve(_ start: Point, _ control: Point, _ end: Point, into polygon: inout [Point]) {
    let errorX = start.x - 2 * control.x + end.x
    let errorY = start.y - 2 * control.y + end.y
    if max(abs(errorX), abs(errorY)) <= 4 {
        polygon.append(end)
        return
    }
    let left = Point((start.x + control.x) / 2, (start.y + control.y) / 2)
    let right = Point((control.x + end.x) / 2, (control.y + end.y) / 2)
    let middle = Point((left.x + right.x) / 2, (left.y + right.y) / 2)
    flattenCurve(start, left, middle, into: &polygon)
    flattenCurve(middle, right, end, into: &polygon)
}

private func fill(_ contours: [[Point]], color: RGBA, into canvas: inout Canvas) {
    let points = contours.flatMap { $0 }
    guard let minPointX = points.map(\.x).min(), let maxPointX = points.map(\.x).max(),
          let minPointY = points.map(\.y).min(), let maxPointY = points.map(\.y).max() else {
        return
    }
    let minX = Int((minPointX - 1).rounded(.down))
    let maxX = Int((maxPointX + 1).rounded(.up))
    let minY = Int((minPointY - 1).rounded(.down))
    let maxY = Int((maxPointY + 1).rounded(.up))
    let samples = 4
    let step = 1.0 / Double(samples)
    let sampleCount = Double(samples * samples)
    for y in minY...maxY {
        for x in minX...maxX {
            var hits = 0
            for row in 0..<samples {
                for column in 0..<samples {
                    let sampleX = Double(x) + (Double(column) + 0.5) * step
                    let sampleY = Double(y) + (Double(row) + 0.5) * step
                    if covers(sampleX, sampleY, contours) {
                        hits += 1
                    }
                }
            }
            if hits > 0 {
                canvas.blend(x, y, color, coverage: Double(hits) / sampleCount)
            }
        }
    }
}

private func covers(_ x: Double, _ y: Double, _ contours: [[Point]]) -> Bool {
    var winding = 0
    for contour in contours {
        let count = contour.count
        guard count > 1 else { continue }
        var previous = contour[count - 1]
        for point in contour {
            if previous.y <= y {
                if point.y > y && side(previous, point, x, y) > 0 {
                    winding += 1
                }
            } else if point.y <= y && side(previous, point, x, y) < 0 {
                winding -= 1
            }
            previous = point
        }
    }
    return winding != 0
}

private func side(_ start: Point, _ end: Point, _ x: Double, _ y: Double) -> Double {
    (end.x - start.x) * (y - start.y) - (x - start.x) * (end.y - start.y)
}
