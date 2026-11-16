# ``Colorful``

Convert colors between sRGB, CIEXYZ, CIELAB, and OKLab without leaving Swift.

## Overview

Colorful is a small, dependency-free color-math library. A color is a value in one
``ColorSpace``, stored as ``Color``. Converting to another space is one call:

```swift
let color = Color<SRGB>(red: 0.8, green: 0.3, blue: 0.2)
let lab = color.converted(to: Lab.self)
let oklch = color.converted(to: OKLCH.self)
```

Components use `Double` and are not clamped. A conversion may land outside the
destination gamut, and those values are kept.

Any type can conform to ``ColorProtocol``. ``XYZ`` with the D65 white point is the
connection space, so a new ``ColorSpace`` only has to convert to and from that.

## Topics

### Essentials

- ``Color``
- ``ColorProtocol``
- ``ColorSpace``

### Color spaces

- ``SRGB``
- ``LinearSRGB``
- ``XYZ``
- ``Lab``
- ``LCH``
- ``OKLab``
- ``OKLCH``

### Operations

- ``ColorProtocol/converted(to:)``
- ``ColorProtocol/interpolated(toward:amount:in:)``
- ``ColorProtocol/deltaE76(to:)``
- ``ColorProtocol/contrastRatio(against:)``
- ``Color/relativeLuminance``

### Guides

- <doc:Conversions>
- <doc:Interpolation>
- <doc:Contrast>
- <doc:Difference>

### Conventions

- <doc:MathematicalConventions>
