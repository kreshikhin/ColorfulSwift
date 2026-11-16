struct Snippets {
    var conversions: String
    var difference: String
    var contrast: String
}

struct TextFile {
    var relativePath: String
    var text: String
}

struct ImageFile {
    var relativePath: String
    var png: [UInt8]
}

struct BuiltDocs {
    var readmeUsage: String
    var readmeExamples: String
    var texts: [TextFile]
    var images: [ImageFile]
}

private enum DocStyle {
    case guide
    case wiki
    case docc

    func image(_ figure: Figure) -> String {
        let alt = figure.alt.replacingOccurrences(of: "\"", with: "&quot;")
        switch self {
        case .guide:
            return "<img src=\"../Images/\(figure.name).png\" alt=\"\(alt)\" width=\"\(figure.logicalWidth)\">"
        case .wiki:
            return "<img src=\"images/\(figure.name).png\" alt=\"\(alt)\" width=\"\(figure.logicalWidth)\">"
        case .docc:
            return "![\(figure.alt)](\(figure.name).png)"
        }
    }

    func code(_ symbol: String) -> String {
        if self == .docc {
            return "``\(symbol)``"
        }
        let short = symbol.split(separator: "/").last.map(String.init) ?? symbol
        return "`\(short)`"
    }
}

func buildDocs(catalog: Catalog, snippets: Snippets) -> BuiltDocs {
    let texts = [
        TextFile(relativePath: "Documentation/Guide/Conversions.md", text: conversionsPage(.guide, catalog, snippets)),
        TextFile(relativePath: "Documentation/Guide/Interpolation.md", text: interpolationPage(.guide, catalog)),
        TextFile(relativePath: "Documentation/Guide/Contrast.md", text: contrastPage(.guide, catalog, snippets)),
        TextFile(relativePath: "Documentation/Guide/Difference.md", text: differencePage(.guide, catalog, snippets)),
        TextFile(relativePath: "Documentation/Wiki/Home.md", text: wikiHome(catalog)),
        TextFile(relativePath: "Documentation/Wiki/_Sidebar.md", text: wikiSidebar),
        TextFile(relativePath: "Documentation/Wiki/Conversions.md", text: conversionsPage(.wiki, catalog, snippets)),
        TextFile(relativePath: "Documentation/Wiki/Interpolation.md", text: interpolationPage(.wiki, catalog)),
        TextFile(relativePath: "Documentation/Wiki/Contrast.md", text: contrastPage(.wiki, catalog, snippets)),
        TextFile(relativePath: "Documentation/Wiki/Difference.md", text: differencePage(.wiki, catalog, snippets)),
        TextFile(relativePath: "Sources/Colorful/Colorful.docc/Articles/Conversions.md", text: conversionsPage(.docc, catalog, snippets)),
        TextFile(relativePath: "Sources/Colorful/Colorful.docc/Articles/Interpolation.md", text: interpolationPage(.docc, catalog)),
        TextFile(relativePath: "Sources/Colorful/Colorful.docc/Articles/Contrast.md", text: contrastPage(.docc, catalog, snippets)),
        TextFile(relativePath: "Sources/Colorful/Colorful.docc/Articles/Difference.md", text: differencePage(.docc, catalog, snippets)),
    ]
    let figures = [catalog.interpolation, catalog.lightness, catalog.hue, catalog.contrast, catalog.difference]
    var images: [ImageFile] = [
        ImageFile(relativePath: "Documentation/Images/banner.png", png: makeBanner()),
    ]
    for figure in figures {
        images.append(ImageFile(relativePath: "Documentation/Images/\(figure.name).png", png: figure.png))
        images.append(ImageFile(relativePath: "Documentation/Wiki/images/\(figure.name).png", png: figure.png))
        images.append(ImageFile(relativePath: "Sources/Colorful/Colorful.docc/Resources/\(figure.name).png", png: figure.doccPNG))
    }
    return BuiltDocs(readmeUsage: readmeUsage(snippets), readmeExamples: readmeExamples(catalog), texts: texts, images: images)
}

private func readmeUsage(_ snippets: Snippets) -> String {
    [
        swiftFence(snippets.conversions),
        "",
        swiftFence(snippets.contrast),
        "",
        swiftFence(snippets.difference),
    ].joined(separator: "\n")
}

private func readmeExamples(_ catalog: Catalog) -> String {
    [
        catalog.interpolationCaption,
        "",
        readmeImage(catalog.interpolation),
        "",
        catalog.lightnessCaption,
        "",
        readmeImage(catalog.lightness),
        "",
        "WCAG 2 contrast.",
        "",
        readmeImage(catalog.contrast),
    ].joined(separator: "\n")
}

private func readmeImage(_ figure: Figure) -> String {
    let alt = figure.alt.replacingOccurrences(of: "\"", with: "&quot;")
    return "<img src=\"Documentation/Images/\(figure.name).png\" alt=\"\(alt)\" width=\"\(figure.logicalWidth)\">"
}

private func conversionsPage(_ style: DocStyle, _ catalog: Catalog, _ snippets: Snippets) -> String {
    var lines = pageTitle("Conversions")
    let stored = style == .docc ? "``SRGB``" : "sRGB"
    lines.append("Coral \(stored) `(0.8, 0.3, 0.2)`, converted with \(style.code("ColorProtocol/converted(to:)")).")
    lines.append("")
    lines.append(swiftFence(snippets.conversions))
    lines.append("")
    lines.append("The last row is that OKLCH color converted back to sRGB. CIE76 from the original is `\(formatDelta(catalog.roundTripDelta))`.")
    lines.append("")
    lines.append(markdownTable(["Space", "Components"], catalog.coordinateRows))
    lines.append("")
    lines.append("Hue is degrees. A neutral color has no hue. Components are not clamped.")
    lines.append("")
    lines.append(closing(style, seen: "Conversions"))
    return joined(lines)
}

private func interpolationPage(_ style: DocStyle, _ catalog: Catalog) -> String {
    var lines = pageTitle("Interpolation")
    lines.append("\(style.code("ColorProtocol/interpolated(toward:amount:in:)")) mixes both colors in the given space. Hue takes the shorter arc. A neutral color has no hue, so it does not pull the mix toward `0`.")
    lines.append("")
    lines.append(style.image(catalog.interpolation))
    lines.append("")
    lines.append("\(catalog.interpolationCaption) OKLCH hue runs from \(catalog.oklchRedHue)° to \(catalog.oklchGreenHue)°.")
    lines.append("")
    lines.append(style.image(catalog.lightness))
    lines.append("")
    lines.append(catalog.lightnessCaption)
    lines.append("")
    lines.append(style.image(catalog.hue))
    lines.append("")
    lines.append(catalog.hueCaption)
    lines.append("")
    lines.append("Amount `0` or `1` returns the original components. Other amounts can fall outside the gamut. The pictures clamp sRGB to `0...1` for display.")
    lines.append("")
    lines.append(closing(style, seen: "Interpolation"))
    return joined(lines)
}

private func contrastPage(_ style: DocStyle, _ catalog: Catalog, _ snippets: Snippets) -> String {
    var lines = pageTitle("Contrast")
    lines.append("\(style.code("ColorProtocol/contrastRatio(against:)")) is the WCAG 2 contrast ratio of two opaque colors. Black on white is `21`.")
    lines.append("")
    lines.append(style.image(catalog.contrast))
    lines.append("")
    lines.append(contrastTable(catalog))
    lines.append("")
    lines.append(swiftFence(snippets.contrast))
    lines.append("")
    lines.append("`#767676` on white is `\(formatRatio(catalog.grayOnWhite))`.")
    lines.append("")
    lines.append(closing(style, seen: "Contrast"))
    return joined(lines)
}

private func differencePage(_ style: DocStyle, _ catalog: Catalog, _ snippets: Snippets) -> String {
    var lines = pageTitle("Difference")
    lines.append("\(style.code("ColorProtocol/deltaE76(to:)")) is the CIE76 distance in CIELAB.")
    lines.append("")
    lines.append(style.image(catalog.difference))
    lines.append("")
    lines.append(differenceTable(catalog))
    lines.append("")
    lines.append(swiftFence(snippets.difference))
    lines.append("")
    lines.append(closing(style, seen: "Difference"))
    return joined(lines)
}

private func wikiHome(_ catalog: Catalog) -> String {
    """
    # Colorful

    Colorful converts, interpolates, and compares colors in Swift. The module is `Colorful`.

    <img src="images/\(catalog.interpolation.name).png" alt="\(catalog.interpolation.alt)" width="\(catalog.interpolation.logicalWidth)">

    \(catalog.interpolationCaption)

    - [[Conversions]]
    - [[Interpolation]]
    - [[Contrast]]
    - [[Difference]]
    """
}

private let wikiSidebar = """
    **Colorful**

    [[Home]]
    [[Conversions]]
    [[Interpolation]]
    [[Contrast]]
    [[Difference]]
    """

private func pageTitle(_ title: String) -> [String] {
    ["# \(title)", ""]
}

private func closing(_ style: DocStyle, seen: String) -> String {
    switch style {
    case .guide:
        let links = [
            ("Conversions", "Conversions.md"),
            ("Interpolation", "Interpolation.md"),
            ("Contrast", "Contrast.md"),
            ("Difference", "Difference.md"),
        ].filter { $0.0 != seen }.map { "[\($0.0)](\($0.1))" }
        return "See also " + links.joined(separator: ", ") + "."
    case .wiki:
        let links = ["Conversions", "Interpolation", "Contrast", "Difference"].filter { $0 != seen }.map { "[[\($0)]]" }
        return "See also " + links.joined(separator: ", ") + "."
    case .docc:
        return "The formulas are in <doc:MathematicalConventions>."
    }
}

private func contrastTable(_ catalog: Catalog) -> String {
    markdownTable(
        ["Pair", "Ratio"],
        catalog.contrastSamples.map { [$0.name, formatRatio($0.ratio)] }
    )
}

private func differenceTable(_ catalog: Catalog) -> String {
    markdownTable(
        ["Pair", "ΔE76"],
        catalog.differenceSamples.map { [$0.name, formatDelta($0.delta)] }
    )
}

private func swiftFence(_ snippet: String) -> String {
    "```swift\n" + snippet + "\n```"
}

private func joined(_ lines: [String]) -> String {
    var text = lines.joined(separator: "\n")
    while text.hasSuffix("\n") {
        text.removeLast()
    }
    return text
}
