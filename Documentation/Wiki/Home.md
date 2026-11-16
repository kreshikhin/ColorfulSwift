# Colorful

Colorful converts sRGB, CIE XYZ, CIELAB, and OKLab in Swift. The module is `Colorful`. The core does not depend on UIKit, AppKit, SwiftUI, CoreGraphics, or Foundation.

<img src="images/interpolation.png" alt="Thirteen-step blend from red to green in sRGB, OKLab, and OKLCH. The sRGB row turns olive. The OKLCH row stays saturated." width="604">

sRGB red to sRGB green, 13 steps. Encoded sRGB passes through olive. OKLab mixes the opponent axes. OKLCH keeps the chroma and takes the short hue arc from 29.2° to 142.5°, so the middle stays yellow.

- [[Conversions]] — one coral color in every built-in space
- [[Interpolation]] — sRGB, OKLab, and OKLCH blends, plus lightness and hue
- [[Contrast]] — WCAG 2 contrast ratio
- [[Difference]] — CIE76 distance in CIELAB

Components are `Double` and are not clamped. Pictures clamp sRGB into `0...1` only while drawing.
