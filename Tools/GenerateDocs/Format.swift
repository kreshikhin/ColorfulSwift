import Foundation

func formatFixed(_ value: Double, fractionDigits: Int) -> String {
    precondition(value.isFinite)
    precondition(fractionDigits >= 0 && fractionDigits < 9)
    let negative = value < 0
    let magnitude = negative ? -value : value
    var scale = 1.0
    for _ in 0..<fractionDigits {
        scale *= 10
    }
    let scaled = (magnitude * scale).rounded()
    let digits = Int(scaled)
    let divisor = Int(scale)
    let whole = fractionDigits == 0 ? digits : digits / divisor
    let fraction = fractionDigits == 0 ? 0 : digits % divisor
    let sign = negative && (whole != 0 || fraction != 0) ? "-" : ""
    if fractionDigits == 0 {
        return sign + String(whole)
    }
    var fractionText = String(fraction)
    while fractionText.count < fractionDigits {
        fractionText = "0" + fractionText
    }
    return sign + String(whole) + "." + fractionText
}

func formatRatio(_ value: Double) -> String {
    if abs(value - value.rounded()) < 1e-6 {
        return formatFixed(value.rounded(), fractionDigits: 0) + ":1"
    }
    return formatFixed(value, fractionDigits: 2) + ":1"
}

func formatDelta(_ value: Double) -> String {
    formatFixed(value, fractionDigits: 2)
}

func markdownTable(_ headers: [String], _ rows: [[String]]) -> String {
    let head = "| " + headers.joined(separator: " | ") + " |"
    let rule = "| " + headers.map { _ in "---" }.joined(separator: " | ") + " |"
    let body = rows.map { "| " + $0.joined(separator: " | ") + " |" }
    return ([head, rule] + body).joined(separator: "\n")
}
