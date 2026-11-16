# Mathematical conventions

Colorful follows the published definitions below and does not clamp components.

## White points

``XYZ``, ``SRGB``, ``LinearSRGB``, ``OKLab``, and ``OKLCH`` use CIE D65 from the
sRGB chromaticity in IEC 61966-2-1:

- `x = 0.3127`, `y = 0.3290`
- `X = 0.3127 / 0.3290`, `Y = 1`, `Z = (1 - 0.3127 - 0.3290) / 0.3290`

``Lab`` and ``LCH`` use CIELAB with the D50 chromaticity adopted by CSS Color 4
and the ICC, at four figures:

- `x = 0.3457`, `y = 0.3585`
- `X = 0.3457 / 0.3585`, `Y = 1`, `Z = (1 - 0.3457 - 0.3585) / 0.3585`

`Y = 1` is the reference white. CIELAB `L*` is on the `0...100` scale.
OKLab lightness is on the `0...1` scale.

## sRGB

Encoded sRGB uses the IEC 61966-2-1 piecewise curve. A channel `c` becomes
linear-light by:

- `c / 12.92`, when `abs(c) <= 0.04045`
- `sign(c) * ((abs(c) + 0.055) / 1.055) ^ 2.4`, otherwise

The inverse uses the threshold `0.0031308`. Those two IEC constants are not
exact inverses: `0.04045 / 12.92` is slightly larger than `0.0031308`, so a
channel at the encoded boundary round-trips about `3e-8` away.
Negative channels mirror the positive curve through the origin, which is the
extension defined by CSS Color 4. In-gamut colors otherwise match IEC 61966-2-1.

Linear sRGB converts to D65 XYZ with the exact rational matrix from the CSS
Color 4 sample code, derived from the IEC primaries
`(0.64, 0.33)`, `(0.30, 0.60)`, and `(0.15, 0.06)`.

## Chromatic adaptation

CIELAB is defined on D50 XYZ. Conversions between D65 and D50 use the linear
Bradford transform published in the CSS Color 4 sample code. D65 white adapted
to D50 is the CIELAB reference white, so sRGB white is `L* = 100`, `a* = 0`,
`b* = 0`.

## CIELAB

The forward nonlinearity uses the CIE fractions:

- `ε = 216 / 24389`
- `κ = 24389 / 27`
- `f(t) = cbrt(t)` when `t > ε`, otherwise `(κ t + 16) / 116`

The inverse uses the numerically stable form of the same definition: the `Y`
term is `L* / κ` when `L* <= 8`, and the `a*` / `b*` linear branch is written
so it does not cancel the `16` term. Cube roots are sign-preserving, and a
negative ratio takes the linear branch because it is below `ε`.

``LCH`` is that rectangular color in polar form. Hue is degrees in `[0, 360)`
after conversion. Chroma at or below ``LCH/achromaticChroma`` (`1e-6`) has a
missing hue. A missing hue converts back to `a* = 0` and `b* = 0`.

## OKLab

OKLab uses Björn Ottosson's transform: XYZ D65 to an LMS cone response, a
sign-preserving cube root, then the OKLab matrix. The matrices are the
D65-consistent values from CSS Color 4, not the earlier blog-post matrices,
which used a different white point and left neutral sRGB slightly chromatic.

``OKLCH`` is the polar form. Hue is missing when chroma is at or below
``OKLCH/achromaticChroma`` (`1e-8`).

## Interpolation

Interpolation is component-wise in the requested space. Hue uses the shorter
arc, at most 180 degrees. A hue is ignored while chroma is at or below the
achromatic threshold, so a neutral color does not drag the hue. Amount `0`
returns the start components unchanged, amount `1` returns the end components
unchanged, and other amounts may extrapolate.

## CIE76

``ColorProtocol/deltaE76(to:)`` is the Euclidean distance in CIELAB. It is not
CIEDE2000.

## WCAG contrast

``ColorProtocol/contrastRatio(against:)`` converts both colors to opaque sRGB
and applies the WCAG 2.2 relative-luminance formula:

`L = 0.2126 R + 0.7152 G + 0.0722 B`

with the IEC transfer above. The returned number is `(L1 + 0.05) / (L2 + 0.05)`.
Black against white is `21`. The WCAG weights are the specification's rounded
coefficients; they are not the full-precision `Y` row of the sRGB matrix.
WCAG defines the ratio for in-gamut sRGB. Out-of-gamut channels are not clamped
and can produce a ratio outside `1...21`.

## Tolerances

A full round trip of an ordinary color stays within about `1e-7`, and an
extreme out-of-gamut color within about `1e-6`. Comparisons against the
reference values above agree to `1e-8` or better. Those bounds are much tighter
than a perceptible difference. Identity conversions do not go through XYZ, so
they keep the original components exactly.
