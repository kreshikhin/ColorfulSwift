import Colorful

func basicConversions() {
    // BEGIN EXAMPLE
    let color = Color<SRGB>(
        red: 0.8,
        green: 0.3,
        blue: 0.2
    )
    let oklab = color.converted(to: OKLab.self)
    let oklch = color.converted(to: OKLCH.self)
    let restored = oklch.converted(to: SRGB.self)
    // END EXAMPLE
    print(oklab.lightness, oklch.lightness, restored.red)
}
