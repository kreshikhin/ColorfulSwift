# Difference

`deltaE76(to:)` is the CIE76 distance in CIELAB.

<img src="images/difference.png" alt="CIE76 distance for three color pairs." width="478">

| Pair | ΔE76 |
| --- | --- |
| Near grays | 5.94 |
| Red and orange | 37.88 |
| Blue and yellow | 232.14 |

```swift
let red = Color<SRGB>(red: 1, green: 0, blue: 0)
let orange = Color<SRGB>(red: 1, green: 0.5, blue: 0)
let difference = red.deltaE76(to: orange)
```

See also [[Conversions]], [[Interpolation]], [[Contrast]].
