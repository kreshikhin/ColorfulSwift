import Colorful

func contrastRatioExample() {
    // BEGIN EXAMPLE
    let gray = Color<SRGB>(
        red: 118.0 / 255.0,
        green: 118.0 / 255.0,
        blue: 118.0 / 255.0
    )
    let white = Color<SRGB>(red: 1, green: 1, blue: 1)
    let ratio = gray.contrastRatio(against: white)
    // END EXAMPLE
    print(ratio)
}
