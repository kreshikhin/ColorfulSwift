# Interpolation

``ColorProtocol/interpolated(toward:amount:in:)`` converts both colors into the space you name, then mixes the components. Hue takes the shorter arc. A neutral color does not pull the mix toward hue `0`.

![Thirteen-step blend from red to green in sRGB, OKLab, and OKLCH. The sRGB row turns olive. The OKLCH row stays saturated.](interpolation.png)

sRGB red to sRGB green, 13 steps. Encoded sRGB passes through olive. OKLab mixes the opponent axes. OKLCH keeps the chroma and takes the short hue arc from 29.2° to 142.5°, so the middle stays yellow.

![Gray ramps from black to white in linear light, encoded sRGB, and OKLab. Linear light jumps to light gray. OKLab keeps even steps.](lightness.png)

Each row takes 13 equal steps from 0 to 1. Linear light crushes the darks into the first tile and then jumps toward white. Encoded sRGB spreads the same numbers evenly across the file. OKLab lightness follows the ramp you see.

![Hue strips for CIELCH and OKLCH at fixed lightness and chroma. Each tile is one step around the wheel.](hue.png)

CIELCH at L* = 60 and C* = 37. OKLCH at L = 0.74 and C = 0.125. Twenty-four hues run from 0° up to, but not including, 360°. Chroma is the largest step that stays inside the sRGB cube.

Amount `0` and `1` return the original components in the destination space. Any other amount may extrapolate. The tiles above are drawn after clamping to the sRGB cube. The numbers in the library are not clamped.

The formulas are in <doc:MathematicalConventions>.
