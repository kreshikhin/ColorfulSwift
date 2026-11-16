import Foundation

struct GeneratorError: Error, CustomStringConvertible {
    var description: String

    init(_ description: String) {
        self.description = description
    }
}

do {
    try run()
} catch let error as GeneratorError {
    FileHandle.standardError.write(Data((error.description + "\n").utf8))
    Foundation.exit(1)
} catch {
    FileHandle.standardError.write(Data((String(describing: error) + "\n").utf8))
    Foundation.exit(1)
}

private func run() throws {
    let arguments = Array(CommandLine.arguments.dropFirst()).filter { $0 != "--" }
    let check = arguments.contains("--check")
    let unknown = arguments.filter { $0 != "--check" }
    if !unknown.isEmpty {
        throw GeneratorError("Unknown arguments: \(unknown.joined(separator: " "))")
    }

    deflateSelfCheck()

    let root = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()

    let snippets = try loadSnippets(root: root)
    let docs = buildDocs(catalog: makeCatalog(), snippets: snippets)
    for body in [docs.readmeUsage, docs.readmeExamples] {
        precondition(!body.contains("<!--"), "Generated README text contains a marker")
    }

    var stale: [String] = []
    try updateReadme(
        root: root,
        beginToken: "<!-- BEGIN GENERATED USAGE -->",
        endToken: "<!-- END GENERATED USAGE -->",
        body: docs.readmeUsage,
        check: check,
        stale: &stale
    )
    try updateReadme(
        root: root,
        beginToken: "<!-- BEGIN GENERATED EXAMPLES -->",
        endToken: "<!-- END GENERATED EXAMPLES -->",
        body: docs.readmeExamples,
        check: check,
        stale: &stale
    )
    for file in docs.texts {
        try updateText(root: root, relativePath: file.relativePath, text: file.text, check: check, stale: &stale)
    }
    for image in docs.images {
        try updateBytes(root: root, relativePath: image.relativePath, bytes: image.png, check: check, stale: &stale)
    }

    if !stale.isEmpty {
        let lines = stale.map { "stale: \($0)" }.joined(separator: "\n")
        throw GeneratorError(lines)
    }
}

private func loadSnippets(root: URL) throws -> Snippets {
    let conversions = try extractExample(root: root, file: "Examples/BasicConversions.swift")
    let difference = try extractExample(root: root, file: "Examples/ColorDifference.swift")
    let contrast = try extractExample(root: root, file: "Examples/ContrastRatio.swift")
    try require(conversions, file: "Examples/BasicConversions.swift", contains: "Color<SRGB>")
    try require(conversions, file: "Examples/BasicConversions.swift", contains: "0.8")
    try require(conversions, file: "Examples/BasicConversions.swift", contains: "converted(to: OKLab.self)")
    try require(conversions, file: "Examples/BasicConversions.swift", contains: "converted(to: OKLCH.self)")
    try require(conversions, file: "Examples/BasicConversions.swift", contains: "converted(to: SRGB.self)")
    try require(difference, file: "Examples/ColorDifference.swift", contains: "deltaE76")
    try require(difference, file: "Examples/ColorDifference.swift", contains: "0.5")
    try require(contrast, file: "Examples/ContrastRatio.swift", contains: "contrastRatio")
    try require(contrast, file: "Examples/ContrastRatio.swift", contains: "118.0 / 255.0")
    return Snippets(conversions: conversions, difference: difference, contrast: contrast)
}

private func extractExample(root: URL, file: String) throws -> String {
    let source = try readText(root.appendingPathComponent(file))
    let beginToken = "    // BEGIN EXAMPLE\n"
    let endToken = "\n    // END EXAMPLE"
    guard let begin = source.range(of: beginToken),
          source.range(of: beginToken, range: begin.upperBound..<source.endIndex) == nil,
          let end = source.range(of: endToken, range: begin.upperBound..<source.endIndex),
          source.range(of: endToken, range: end.upperBound..<source.endIndex) == nil
    else {
        throw GeneratorError("\(file) needs exactly one example region")
    }
    let body = source[begin.upperBound..<end.lowerBound]
    var lines: [String] = []
    for line in body.split(separator: "\n", omittingEmptySubsequences: false) {
        if line.isEmpty {
            lines.append("")
            continue
        }
        guard line.hasPrefix("    ") else {
            throw GeneratorError("\(file) example line is not indented by four spaces")
        }
        lines.append(String(line.dropFirst(4)))
    }
    return lines.joined(separator: "\n")
}

private func require(_ snippet: String, file: String, contains needle: String) throws {
    if !snippet.contains(needle) {
        throw GeneratorError("\(file) no longer contains \(needle)")
    }
}

private func updateReadme(
    root: URL,
    beginToken: String,
    endToken: String,
    body: String,
    check: Bool,
    stale: inout [String]
) throws {
    let url = root.appendingPathComponent("README.md")
    let original = try readText(url)
    guard let begin = original.range(of: beginToken),
          original.range(of: beginToken, range: begin.upperBound..<original.endIndex) == nil,
          let end = original.range(of: endToken, range: begin.upperBound..<original.endIndex),
          original.range(of: endToken, range: end.upperBound..<original.endIndex) == nil,
          begin.upperBound <= end.lowerBound
    else {
        throw GeneratorError("README.md is missing \(beginToken)")
    }
    let updated = original[..<begin.upperBound] + "\n\n" + body + "\n\n" + original[end.lowerBound...]
    try store(url, relativePath: "README.md", bytes: Array(String(updated).utf8), check: check, stale: &stale)
}

private func updateText(root: URL, relativePath: String, text: String, check: Bool, stale: inout [String]) throws {
    precondition(!text.contains("\r"))
    let url = root.appendingPathComponent(relativePath)
    let payload = text + "\n"
    try store(url, relativePath: relativePath, bytes: Array(payload.utf8), check: check, stale: &stale)
}

private func updateBytes(root: URL, relativePath: String, bytes: [UInt8], check: Bool, stale: inout [String]) throws {
    let url = root.appendingPathComponent(relativePath)
    try store(url, relativePath: relativePath, bytes: bytes, check: check, stale: &stale)
}

private func store(_ url: URL, relativePath: String, bytes: [UInt8], check: Bool, stale: inout [String]) throws {
    let data = Data(bytes)
    if FileManager.default.fileExists(atPath: url.path) {
        let existing = try Data(contentsOf: url)
        if existing == data {
            return
        }
    }
    if check {
        stale.append(relativePath)
        return
    }
    try FileManager.default.createDirectory(
        at: url.deletingLastPathComponent(),
        withIntermediateDirectories: true
    )
    try data.write(to: url, options: .atomic)
}

private func readText(_ url: URL) throws -> String {
    let data = try Data(contentsOf: url)
    guard let text = String(data: data, encoding: .utf8) else {
        throw GeneratorError("\(url.lastPathComponent) is not UTF-8")
    }
    return text
}
