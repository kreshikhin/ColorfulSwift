struct RGBA: Equatable, Hashable {
    var r, g, b: UInt8

    static let paper = RGBA(r: 244, g: 241, b: 234)
    static let ink = RGBA(r: 28, g: 25, b: 23)
}

struct Canvas {
    let width: Int
    let height: Int
    private(set) var pixels: [RGBA]

    init(width: Int, height: Int, fill: RGBA) {
        self.width = width
        self.height = height
        self.pixels = Array(repeating: fill, count: width * height)
    }

    mutating func set(_ x: Int, _ y: Int, _ color: RGBA) {
        guard x >= 0, y >= 0, x < width, y < height else { return }
        pixels[y * width + x] = color
    }

    mutating func blend(_ x: Int, _ y: Int, _ color: RGBA, coverage: Double) {
        guard coverage > 0, x >= 0, y >= 0, x < width, y < height else { return }
        let cover = coverage > 1 ? 1.0 : coverage
        let index = y * width + x
        let destination = pixels[index]
        pixels[index] = RGBA(
            r: mixChannel(destination.r, color.r, cover),
            g: mixChannel(destination.g, color.g, cover),
            b: mixChannel(destination.b, color.b, cover)
        )
    }

    mutating func fill(_ x: Int, _ y: Int, _ w: Int, _ h: Int, _ color: RGBA) {
        let x0 = max(0, x)
        let y0 = max(0, y)
        let x1 = min(width, x + w)
        let y1 = min(height, y + h)
        guard x0 < x1, y0 < y1 else { return }
        for row in y0..<y1 {
            for column in x0..<x1 {
                pixels[row * width + column] = color
            }
        }
    }

    func scaled(by factor: Int) -> Canvas {
        precondition(factor >= 1)
        var canvas = Canvas(width: width * factor, height: height * factor, fill: pixels[0])
        for y in 0..<height {
            for x in 0..<width {
                let color = pixels[y * width + x]
                canvas.fill(x * factor, y * factor, factor, factor, color)
            }
        }
        return canvas
    }

    func png() -> [UInt8] {
        var palette: [RGBA] = []
        var indexOf: [RGBA: UInt8] = [:]
        var indices = [UInt8]()
        indices.reserveCapacity(pixels.count)
        for pixel in pixels {
            if let existing = indexOf[pixel] {
                indices.append(existing)
                continue
            }
            guard palette.count < 256 else {
                preconditionFailure("PNG palette exceeded 256 colors")
            }
            let index = UInt8(palette.count)
            palette.append(pixel)
            indexOf[pixel] = index
            indices.append(index)
        }

        var raw = [UInt8]()
        raw.reserveCapacity((width + 1) * height)
        for y in 0..<height {
            raw.append(0)
            raw.append(contentsOf: indices[(y * width)..<((y + 1) * width)])
        }

        var ihdr = [UInt8]()
        appendBigEndian(UInt32(width), to: &ihdr)
        appendBigEndian(UInt32(height), to: &ihdr)
        ihdr.append(contentsOf: [8, 3, 0, 0, 0])

        var plte = [UInt8]()
        plte.reserveCapacity(palette.count * 3)
        for color in palette {
            plte.append(color.r)
            plte.append(color.g)
            plte.append(color.b)
        }

        let compressed = zlibWrap(uncompressed: raw, deflate: deflate(raw))
        var png = [UInt8](PNG.signature)
        png.append(contentsOf: pngChunk("IHDR", ihdr))
        png.append(contentsOf: pngChunk("PLTE", plte))
        png.append(contentsOf: pngChunk("IDAT", compressed))
        png.append(contentsOf: pngChunk("IEND", []))
        return png
    }

    func pngTruecolor() -> [UInt8] {
        var raw = [UInt8]()
        raw.reserveCapacity((width * 3 + 1) * height)
        for y in 0..<height {
            raw.append(0)
            let start = y * width
            for pixel in pixels[start..<(start + width)] {
                raw.append(pixel.r)
                raw.append(pixel.g)
                raw.append(pixel.b)
            }
        }

        var ihdr = [UInt8]()
        appendBigEndian(UInt32(width), to: &ihdr)
        appendBigEndian(UInt32(height), to: &ihdr)
        ihdr.append(contentsOf: [8, 2, 0, 0, 0])

        let compressed = zlibWrap(uncompressed: raw, deflate: deflate(raw))
        var png = [UInt8](PNG.signature)
        png.append(contentsOf: pngChunk("IHDR", ihdr))
        png.append(contentsOf: pngChunk("IDAT", compressed))
        png.append(contentsOf: pngChunk("IEND", []))
        return png
    }
}

private func mixChannel(_ destination: UInt8, _ source: UInt8, _ coverage: Double) -> UInt8 {
    let value = Double(destination) + (Double(source) - Double(destination)) * coverage
    return UInt8(Int(value.rounded()))
}

enum Font {
    static let scale = 2

    static func size(of text: String) -> (width: Int, height: Int) {
        let count = text.count
        let width = count == 0 ? 0 : (count * 6 - 1) * scale
        return (width, 7 * scale)
    }

    static func draw(_ text: String, x: Int, y: Int, color: RGBA, into canvas: inout Canvas) {
        var cursor = x
        for character in text {
            let rows = glyph(character)
            for (rowIndex, row) in rows.enumerated() {
                for column in 0..<5 {
                    let bit = (row >> (4 - column)) & 1
                    guard bit == 1 else { continue }
                    canvas.fill(
                        cursor + column * scale,
                        y + rowIndex * scale,
                        scale,
                        scale,
                        color
                    )
                }
            }
            cursor += 6 * scale
        }
    }

    private static func glyph(_ character: Character) -> [UInt8] {
        if let rows = glyphs[character] {
            return rows
        }
        preconditionFailure("No bitmap glyph for \(character)")
    }

    private static let glyphs: [Character: [UInt8]] = [
        "A": [0x0E, 0x11, 0x11, 0x1F, 0x11, 0x11, 0x11],
        "B": [0x1E, 0x11, 0x11, 0x1E, 0x11, 0x11, 0x1E],
        "C": [0x0E, 0x11, 0x10, 0x10, 0x10, 0x11, 0x0E],
        "D": [0x1E, 0x11, 0x11, 0x11, 0x11, 0x11, 0x1E],
        "E": [0x1F, 0x10, 0x10, 0x1E, 0x10, 0x10, 0x1F],
        "G": [0x0E, 0x11, 0x10, 0x17, 0x11, 0x11, 0x0F],
        "H": [0x11, 0x11, 0x11, 0x1F, 0x11, 0x11, 0x11],
        "I": [0x1F, 0x04, 0x04, 0x04, 0x04, 0x04, 0x1F],
        "K": [0x11, 0x12, 0x14, 0x18, 0x14, 0x12, 0x11],
        "L": [0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x1F],
        "N": [0x11, 0x19, 0x15, 0x13, 0x11, 0x11, 0x11],
        "O": [0x0E, 0x11, 0x11, 0x11, 0x11, 0x11, 0x0E],
        "R": [0x1E, 0x11, 0x11, 0x1E, 0x14, 0x12, 0x11],
        "S": [0x0F, 0x10, 0x10, 0x0E, 0x01, 0x01, 0x1E],
        "a": [0x00, 0x00, 0x0E, 0x01, 0x0F, 0x11, 0x0F],
        "0": [0x0E, 0x11, 0x13, 0x15, 0x19, 0x11, 0x0E],
        "1": [0x04, 0x0C, 0x04, 0x04, 0x04, 0x04, 0x0E],
        "2": [0x0E, 0x11, 0x01, 0x02, 0x04, 0x08, 0x1F],
        "3": [0x1E, 0x01, 0x01, 0x0E, 0x01, 0x01, 0x1E],
        "4": [0x02, 0x06, 0x0A, 0x12, 0x1F, 0x02, 0x02],
        "5": [0x1F, 0x10, 0x1E, 0x01, 0x01, 0x11, 0x0E],
        "6": [0x0E, 0x10, 0x10, 0x1E, 0x11, 0x11, 0x0E],
        "7": [0x1F, 0x01, 0x02, 0x04, 0x08, 0x08, 0x08],
        "8": [0x0E, 0x11, 0x11, 0x0E, 0x11, 0x11, 0x0E],
        "9": [0x0E, 0x11, 0x11, 0x0F, 0x01, 0x01, 0x0E],
        ".": [0x00, 0x00, 0x00, 0x00, 0x00, 0x0C, 0x0C],
        ":": [0x00, 0x0C, 0x0C, 0x00, 0x0C, 0x0C, 0x00],
        " ": [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00],
    ]
}

enum PNG {
    static let signature: [UInt8] = [137, 80, 78, 71, 13, 10, 26, 10]
}

func deflateSelfCheck() {
    let hello = Array("Hello, Colorful!!!".utf8)
    let encoded = deflate(hello)
    let expected = "f348cdc9c9d75170cecfc92f4a2bcd5154540400"
    precondition(hex(encoded) == expected, "Deflate bitstream drifted: \(hex(encoded))")
}

private func deflate(_ data: [UInt8]) -> [UInt8] {
    let lengthBase = [3, 4, 5, 6, 7, 8, 9, 10, 11, 13, 15, 17, 19, 23, 27, 31, 35, 43, 51, 59, 67, 83, 99, 115, 131, 163, 195, 227, 258]
    let lengthExtra = [0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5, 0]
    let distanceBase = [1, 2, 3, 4, 5, 7, 9, 13, 17, 25, 33, 49, 65, 97, 129, 193, 257, 385, 513, 769, 1025, 1537, 2049, 3073, 4097, 6145, 8193, 12289, 16385, 24577]
    let distanceExtra = [0, 0, 0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8, 9, 9, 10, 10, 11, 11, 12, 12, 13, 13]

    var writer = BitWriter()
    writer.write(value: 1, bits: 1)
    writer.write(value: 1, bits: 2)

    let count = data.count
    var head = [Int](repeating: -1, count: 32768)
    var previous = [Int](repeating: -1, count: count)

    func hash(at index: Int) -> Int {
        ((Int(data[index]) << 10) ^ (Int(data[index + 1]) << 5) ^ Int(data[index + 2])) & 32767
    }

    func insert(_ index: Int) {
        guard index + 2 < count else { return }
        let hashed = hash(at: index)
        previous[index] = head[hashed]
        head[hashed] = index
    }

    var index = 0
    while index < count {
        var bestLength = 0
        var bestDistance = 0
        if index + 2 < count {
            var node = head[hash(at: index)]
            var steps = 0
            while node >= 0 && steps < 32 {
                let distance = index - node
                if distance > 32768 {
                    break
                }
                var length = 0
                while length < 258 && index + length < count && data[node + length] == data[index + length] {
                    length += 1
                }
                if length > bestLength {
                    bestLength = length
                    bestDistance = distance
                }
                if length == 258 {
                    break
                }
                node = previous[node]
                steps += 1
            }
            insert(index)
        }

        if bestLength >= 3 {
            var cursor = index + 1
            while cursor < index + bestLength {
                insert(cursor)
                cursor += 1
            }
            let (lengthSymbol, extra, extraBits) = symbol(for: bestLength, bases: lengthBase, extras: lengthExtra, firstSymbol: 257)
            let (code, codeBits) = literalCode(lengthSymbol)
            writer.writeHuffman(code: code, bits: codeBits)
            if extra > 0 {
                writer.write(value: extraBits, bits: extra)
            }
            let (distanceSymbol, distanceExtraBits, distanceExtraValue) = symbol(
                for: bestDistance,
                bases: distanceBase,
                extras: distanceExtra,
                firstSymbol: 0
            )
            writer.writeHuffman(code: distanceSymbol, bits: 5)
            if distanceExtraBits > 0 {
                writer.write(value: distanceExtraValue, bits: distanceExtraBits)
            }
            index += bestLength
        } else {
            let (code, codeBits) = literalCode(Int(data[index]))
            writer.writeHuffman(code: code, bits: codeBits)
            index += 1
        }
    }

    let (endCode, endBits) = literalCode(256)
    writer.writeHuffman(code: endCode, bits: endBits)
    return writer.finish()
}

private func symbol(for value: Int, bases: [Int], extras: [Int], firstSymbol: Int) -> (symbol: Int, extra: Int, bits: Int) {
    for offset in bases.indices {
        let span = 1 << extras[offset]
        if value < bases[offset] + span {
            return (firstSymbol + offset, extras[offset], value - bases[offset])
        }
    }
    preconditionFailure("No deflate symbol for \(value)")
}

private func literalCode(_ symbol: Int) -> (code: Int, bits: Int) {
    if symbol <= 143 {
        return (0b0011_0000 + symbol, 8)
    }
    if symbol <= 255 {
        return (0b1_1001_0000 + (symbol - 144), 9)
    }
    if symbol <= 279 {
        return (symbol - 256, 7)
    }
    return (0b1100_0000 + (symbol - 280), 8)
}

private struct BitWriter {
    private var bytes: [UInt8] = []
    private var accumulator: UInt8 = 0
    private var count = 0

    mutating func write(value: Int, bits: Int) {
        var remaining = value
        for _ in 0..<bits {
            if remaining & 1 == 1 {
                accumulator |= 1 << count
            }
            remaining >>= 1
            count += 1
            if count == 8 {
                bytes.append(accumulator)
                accumulator = 0
                count = 0
            }
        }
    }

    mutating func writeHuffman(code: Int, bits: Int) {
        var reversed = 0
        var cursor = code
        for _ in 0..<bits {
            reversed = (reversed << 1) | (cursor & 1)
            cursor >>= 1
        }
        write(value: reversed, bits: bits)
    }

    func finish() -> [UInt8] {
        var copy = self
        if copy.count > 0 {
            copy.bytes.append(copy.accumulator)
        }
        return copy.bytes
    }
}

private func zlibWrap(uncompressed: [UInt8], deflate: [UInt8]) -> [UInt8] {
    var wrapped = [UInt8](arrayLiteral: 0x78, 0x01)
    wrapped.append(contentsOf: deflate)
    appendBigEndian(adler32(uncompressed), to: &wrapped)
    return wrapped
}

private func adler32(_ data: [UInt8]) -> UInt32 {
    var a: UInt32 = 1
    var b: UInt32 = 0
    for byte in data {
        a = (a + UInt32(byte)) % 65521
        b = (b + a) % 65521
    }
    return (b << 16) | a
}

private func crc32(_ data: [UInt8]) -> UInt32 {
    var crc: UInt32 = 0xFFFF_FFFF
    for byte in data {
        crc ^= UInt32(byte)
        for _ in 0..<8 {
            if crc & 1 == 1 {
                crc = (crc >> 1) ^ 0xEDB8_8320
            } else {
                crc >>= 1
            }
        }
    }
    return crc ^ 0xFFFF_FFFF
}

private func pngChunk(_ type: String, _ data: [UInt8]) -> [UInt8] {
    var chunk = [UInt8]()
    appendBigEndian(UInt32(data.count), to: &chunk)
    let typeBytes = Array(type.utf8)
    chunk.append(contentsOf: typeBytes)
    chunk.append(contentsOf: data)
    var signed = typeBytes
    signed.append(contentsOf: data)
    appendBigEndian(crc32(signed), to: &chunk)
    return chunk
}

private func appendBigEndian(_ value: UInt32, to data: inout [UInt8]) {
    data.append(UInt8((value >> 24) & 0xFF))
    data.append(UInt8((value >> 16) & 0xFF))
    data.append(UInt8((value >> 8) & 0xFF))
    data.append(UInt8(value & 0xFF))
}

private func hex(_ bytes: [UInt8]) -> String {
    let digits = Array("0123456789abcdef")
    var text = ""
    text.reserveCapacity(bytes.count * 2)
    for byte in bytes {
        text.append(digits[Int(byte >> 4)])
        text.append(digits[Int(byte & 0x0F)])
    }
    return text
}
