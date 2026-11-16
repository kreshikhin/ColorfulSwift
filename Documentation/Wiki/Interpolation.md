# Interpolation

`interpolated(toward:amount:in:)` mixes both colors in the given space. Hue takes the shorter arc. A neutral color has no hue, so it does not pull the mix toward `0`.

<img src="images/interpolation.png" alt="Red to green in sRGB, OKLab, and OKLCH." width="604">

Red to green in sRGB, OKLab, and OKLCH. OKLCH hue runs from 29.2° to 142.5°.

<img src="images/lightness.png" alt="Equal steps from black to white in linear sRGB, encoded sRGB, and OKLab." width="604">

Equal steps from 0 to 1 in linear sRGB, encoded sRGB, and OKLab.

<img src="images/hue.png" alt="CIELCH and OKLCH hue strips." width="617">

CIELCH at L* = 60 and C* = 37. OKLCH at L = 0.74 and C = 0.125.

Amount `0` or `1` returns the original components. Other amounts can fall outside the gamut. The pictures clamp sRGB to `0...1` for display.

See also [[Conversions]], [[Contrast]], [[Difference]].
