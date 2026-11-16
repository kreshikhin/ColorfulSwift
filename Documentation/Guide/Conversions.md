# Conversions

A coral `Color<SRGB>`, with red `0.8`, green `0.3`, and blue `0.2`, converted with `converted(to:)`.

```swift
let color = Color<SRGB>(
    red: 0.8,
    green: 0.3,
    blue: 0.2
)
let oklab = color.converted(to: OKLab.self)
let oklch = color.converted(to: OKLCH.self)
let restored = oklch.converted(to: SRGB.self)
```

The last row is OKLCH converted back to sRGB. CIE76 from the original coral to that round trip is `0.00`.

| Space | Components |
| --- | --- |
| `SRGB` | 0.8000, 0.3000, 0.2000 |
| `LinearSRGB` | 0.6038, 0.0732, 0.0331 |
| `XYZ` | 0.2812, 0.1832, 0.0519 |
| `Lab` | 50.5534, 50.5133, 42.3369 |
| `LCH` | 50.5534, 65.9091, 40.0° |
| `OKLab` | 0.5866, 0.1399, 0.0915 |
| `OKLCH` | 0.5866, 0.1671, 33.2° |
| `SRGB` round trip | 0.8000, 0.3000, 0.2000 |

Hue is degrees. A neutral color has no hue, and the table would say `none`. Components are not clamped, so a conversion can leave the destination gamut and still be stored.

See also [Interpolation](Interpolation.md), [Contrast](Contrast.md), [Difference](Difference.md).
