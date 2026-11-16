import Colorful

func colorDifference() {
    // BEGIN EXAMPLE
    let red = Color<SRGB>(red: 1, green: 0, blue: 0)
    let orange = Color<SRGB>(red: 1, green: 0.5, blue: 0)
    let difference = red.deltaE76(to: orange)
    // END EXAMPLE
    print(difference)
}
