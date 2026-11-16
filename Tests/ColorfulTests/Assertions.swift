import Testing
import Colorful

func expectApprox(
    _ actual: Double,
    _ expected: Double,
    tolerance: Double = 1e-8,
    sourceLocation: SourceLocation = #_sourceLocation
) {
    #expect(
        abs(actual - expected) <= tolerance,
        "expected \(expected) ± \(tolerance), got \(actual)",
        sourceLocation: sourceLocation
    )
}

func expectHue(
    _ actual: Double?,
    _ expected: Double?,
    tolerance: Double = 1e-8,
    sourceLocation: SourceLocation = #_sourceLocation
) {
    switch (actual, expected) {
    case (nil, nil):
        break
    case (let actual?, let expected?):
        let delta = abs(actual - expected).truncatingRemainder(dividingBy: 360)
        let wrapped = min(delta, 360 - delta)
        #expect(wrapped <= tolerance, "expected hue \(expected), got \(actual)", sourceLocation: sourceLocation)
    default:
        #expect(Bool(false), "expected hue \(String(describing: expected)), got \(String(describing: actual))", sourceLocation: sourceLocation)
    }
}
