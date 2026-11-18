# Spike note: can the theme model express Liquid Glass, Aqua, NeXTSTEP 4.0 and Mac OS 7-9?

**Status:** Proposed, 2026-11-17. A reading of our code against four reference looks; no code written. Companion to `2026-11-17_BrandStandardsGuide.md` (the Standards Guide), whose steps B and C it would change.
**Owner decision 2026-11-17:** "this is important, we should be able to handle these." So the model must be able to express them before the guide, specimen and MCP are built on it.
**Answers 2026-11-17:** these are **shipped themes** (so the trademark and design-right question, Q4, is open work, not a stress-test footnote); **both System 7 and Platinum**; **web first, then SwiftUI**; reference downloads are allowed. Step 1 is done: see `project/docs/technical/SkinMeasurements.md`, which **changes section 4** (a bevel is per-side ordered pixel steps, not one light and one dark colour; System 7 needs a 1-bit pattern; Aqua needs a hard-stop gradient and a 4 px repeating pinstripe; skins need device-pixel widths).
**Provenance:** what our model holds is **read from the code** (cited by file). What each reference look is made of is **from general knowledge of those interfaces, not measured here**: Step 1 below replaces it with measurements from reference screenshots before anything is built.

## 1. What our model can and cannot say (read from the code)

`Theme` is `Structure` plus `ThemePalette`. The surface vocabulary is small:

| Concept | Where | Limit |
|---|---|---|
| Fill | `ColorValue` (hex with alpha; light, dark, increased contrast) | one solid colour per role; no gradient |
| Border | `LayoutSpec.cardBorder`, `RuleSpec.hairline`, `LineSpec` (weight, dash) | one weight, one colour (`--rule`) on all four sides |
| Corner | `containerRadius`, `controlRadius`, `annotationRadius` | one number each; no per-corner |
| Shadow | `LayoutSpec.shadow: ShadowSpec?` (colour, radius, x, y) | **one, outer, on cards only**; no inset, no spread, no list |
| Chrome | `CardChrome`: `ruled` or `bordered` | two cases, cards only |
| Bar fill | `BarFill`: `flat` or `autoGradient` | a chart-mark flag, not a surface |
| Type | `TextSpec` (family with fallback, size, weight, tracking, italic, uppercase, line height) | no text shadow, no smoothing, no bitmap-font flag |

`ComponentsCSSEmitter.swift` confirms it: its borders are `var(--rule-hairline) solid var(--rule)` or `solid var(--ink)`, radii are `var(--radius-control)` or `var(--radius-container)`, and its one shadow is `var(--shadow)` (line 494). There is no `gradient`, no `backdrop-filter` and no inset-shadow-as-bevel anywhere in the file; its `inset` uses are an accent edge (lines 604, 659) and positioning.

**The structural gap is bigger than the missing fields.** The model describes *measurements* (weights, radii, colours); these four looks are described by *surface recipes*: an ordered stack of paints and edges per control, per state. Adding gradients, blur and inset shadows as separate optional fields (as the Standards Guide proposes) would let each be set but would leave nothing that says "a pushed button in this theme is these layers". That is the thing to add.

## 2. The four looks, by the properties that distinguish them

From general knowledge, to be measured in Step 1.

| Property | Mac OS 7-9 (Platinum, and System 7's flat 1-bit) | NeXTSTEP 4.0 | Aqua (Mac OS X 10.0 to 10.9) | Liquid Glass (macOS/iOS 26 on) |
|---|---|---|---|---|
| Fill | flat greys; a dither pattern in places | flat greys | multi-stop vertical gradient plus a gloss highlight; pinstripe background | translucent, tinted by what is behind it |
| Edges | 1 px outline plus a light top-left and dark bottom-right bevel | 2 px bevel: light top-left, dark bottom-right, raised and pressed | soft outline plus inner highlight and inner shadow | thin specular rim that varies around the shape |
| Corners | square, tiny radius on buttons | square | fully rounded (pill) buttons | large, continuous radii |
| Depth | none; pressed = inverted bevel | none; pressed = inverted bevel | drop shadow plus inner glow | blur, refraction, lensing |
| Type | Chicago and Geneva (bitmap-era), no smoothing | Helvetica, bold menus | Lucida Grande | the system face |
| Pressed state | bevel inverts | bevel inverts | gel darkens, pulses (animated) | material responds to touch and light |

## 3. Expressibility against the proposal as already written

| Look | Needs | In the Standards Guide proposal today? | Verdict |
|---|---|---|---|
| Platinum, NeXT | per-edge bevel, no radius, grey ramp, bitmap-era font stack | Radius yes. **Bevel no.** Per-edge colour no. | Needs a bevel; otherwise within reach |
| Aqua | gradient **stack**, highlight overlay, inner shadow, pinstripe | `GradientSpec` yes (single, fills only). Stack, inner shadow, repeating pattern no. | Needs layered paints, inset shadows, repeating gradients |
| Liquid Glass | backdrop blur and saturation, translucent tint, specular rim | `EffectSpec.backdropBlur` and `translucency` yes. Specular rim no; **refraction is not expressible in CSS** | Approximate on the web; real on Apple platforms only through the system material |

One conflict to resolve: the proposal says gradients are "fills only, never text, icon colour, stroke or a chart mark", and a validator enforces it. Aqua legitimately puts gradients on button fills and on bars (`BarFill.autoGradient` already exists for the legacy themes), so the rule stays but must say *what a gradient may be on*, not ban gradients from marks wholesale. Revisit with the owner.

## 4. Types (revised 2026-11-17 after `SkinMeasurements.md`; replaces the first draft)

Every type is `Sendable, Hashable, Codable`; every `Theme` field is optional with a default that reproduces today's output, so Swiss, House, FT, Economist, the legacy themes and Console emit byte-identical files until a theme opts in.

```swift
/// One pixel-aligned stripe of an edge, from the outside in.
public struct EdgeStep: Sendable, Hashable, Codable { public var colour: ColourReference; public var width: Double }   // device pixels, > 0

/// What is drawn along each side of a surface, outside in. A plain 1 px outline is one step on every side;
/// a Platinum button is top/leading [000, DDD, FFF] and bottom/trailing [(inside-out) AAA, 777, 000].
public struct Edges: Sendable, Hashable, Codable { public var top, leading, bottom, trailing: [EdgeStep] }

/// A repeating cell of logical pixels: System 7's 2 x 2 checkerboard, Aqua's 1 x 4 pinstripe.
public struct PatternSpec: Sendable, Hashable, Codable {
    public var width: Int, height: Int                  // cell size in logical pixels, 1...16
    public var cells: [ColourReference]                 // row-major, count == width * height
}

public struct GradientStop: Sendable, Hashable, Codable { public var colour: ColourReference; public var position: Double }   // 0...1; equal positions are a hard step
public struct GradientSpec: Sendable, Hashable, Codable {
    public enum Kind: String, Sendable, Hashable, Codable { case linear, radial }
    public var kind: Kind; public var angleDegrees: Double; public var stops: [GradientStop]   // >= 2, positions non-decreasing
}

public struct ShadowLayer: Sendable, Hashable, Codable { public var shadow: ShadowSpec; public var inset: Bool; public var spread: Double }

public enum SurfaceLayer: Sendable, Hashable, Codable {
    case fill(ColourReference)
    case gradient(GradientSpec)                          // Aqua's gel: two bands with a hard step
    case pattern(PatternSpec)                            // System 7 desktop, Aqua pinstripe
    case shadow(ShadowLayer)                             // outer or inset
}

public enum CornerRadius: Sendable, Hashable, Codable { case uniform(Double), capsule }   // per-corner deferred until a skin needs it

public struct SurfaceRecipe: Sendable, Hashable, Codable {
    public var layers: [SurfaceLayer]                    // bottom to top
    public var edges: Edges?
    public var radius: CornerRadius
    public var backdropBlur: Double?                     // CSS px (Gaussian sigma); Liquid Glass about 7
    public var ink: ColourReference                      // text on this surface; contrast is measured against its layers
    public var scale: ScalePolicy                        // .free or .integer: pixel skins snap to whole scales (1x, 2x, 3x) and sample nearest-neighbour
}

public enum SurfaceRole: String, Sendable, Hashable, Codable, CaseIterable {
    case window, panel, button, buttonDefault, field, menu, scrollTrack, scrollThumb, selection
}
public struct SurfaceSet: Sendable, Hashable, Codable {
    public var recipes: [SurfaceRole: [ComponentState: SurfaceRecipe]]   // missing state inherits rest; missing role inherits today's CSS
}
```

Changes from the first draft: `BevelSpec` is gone (replaced by ordered per-side `EdgeStep`s, because Platinum is `[000, DDD, FFF]` / `[AAA, 777, 000]` and NeXT is `[FFF]` / `[555, 000]`, which one light and one dark colour cannot say); `PatternSpec` is a literal pixel cell (so System 7's 1-bit checkerboard is exact); `GradientStop` allows equal positions (Aqua's hard step); `HighlightSpec` is dropped (a gloss is a gradient layer with a hard step); `pixelSnapped` is explicit.

**Validator rules (new):** every `EdgeStep.width` is a positive integer number of logical pixels when `pixelSnapped`; `PatternSpec.cells.count == width * height`; gradient stops are non-decreasing and at least two; an `ink` colour must meet 4.5:1 against the **darkest and lightest** point of the layers beneath it (every stop of a gradient, every cell of a pattern, the tint over the measured Liquid Glass range), or the finding goes in the theme's ledger with its reason. System 7 passes at 21:1 by construction.

**Appearance.** System 7 is light-only. Liquid Glass **dark does not adapt linearly** (measured), so a theme gives each appearance its own measured recipe; it does not derive one from the other.

## 5. What "replicate" is allowed to mean

We cannot compute "looks like Aqua". Fidelity is therefore stated as properties that can be tested, plus a human check:

- **Tested (derived from the reference, Step 1):** Platinum and NeXT buttons: top and left edge lighter than bottom and right by a stated luminance gap; pressed inverts it; radius is 0. Aqua: the default button's fill has at least three gradient stops, monotonic in luminance top to bottom, plus a highlight layer. Liquid Glass: blur at least a stated value and tint alpha below 1; reduced-transparency substitutes an opaque surface.
- **Checked by eye:** side-by-side screenshots against reference captures. Reviewed by the owner; not a pass/fail test.
- **Stated limits, recorded in the theme's ledger with reasons:** web Liquid Glass has no refraction; Aqua's animation is approximate; period fonts may be unavailable.
- **Do and Don't pairs** for each look come from the same machinery as the guide (a Don't is the look with one violation that the checker rejects).

## 6. Plan

| Step | Work | Output |
|---|---|---|
| 1 | Capture reference screenshots of each look at its native size; measure edge colours, gradient stops, radii, shadow offsets and fonts, the way the Princeton page was measured | `project/docs/technical/SkinMeasurements.md`; replaces section 2 |
| 2 | Re-run section 3 against the measurements; finalise the types in section 4 | updated types; the Standards Guide's steps B and C amended |
| 3 | Build the **cheapest** look end to end: **NeXTSTEP 4.0 or Platinum** (bevel, square, greys), as a registered theme through the real emitters | a theme and its `components.css`; golden files; screenshots |
| 4 | Aqua, then a Liquid Glass approximation on the web and the system material in SwiftUI | two themes; SwiftUI recipe drawing proven or its limit recorded |
| 5 | Resume the Standards Guide with the amended model | per its phasing |

Each step is reviewable alone, and stopping after Step 3 still leaves a working non-flat theme. Steps 1 and 2 are the "spike". Steps 3 and 4 are building, and are not approved by this note.

## 7. Open questions

1. **Which Platinum?** Mac OS 8 and 9's Platinum (greys, bevels) or System 7's flatter look? Recommend Platinum (8 and 9), then fold in System 7's 1-bit as a variant if wanted.
2. **Which Aqua?** 10.0 to 10.2 (pinstripes, gel) or 10.3 to 10.9 (brushed metal and flatter)? Recommend 10.0 to 10.2, the most recognisable and the hardest.
3. **Which Liquid Glass?** The macOS 26 and later release in use here. We would need reference captures from this machine, which is on 27.2 (measured via `xcodebuild -showsdks`).
4. **Are these shipped themes or a stress test?** If shipped, how closely may we follow Apple's and NeXT's visual design, and Apple's names (Aqua, Liquid Glass)? I have not researched trademark or design-right limits and would not assume they are clear.
5. **Fonts.** Name Chicago, Geneva, Lucida Grande and Helvetica with fallbacks and bundle nothing: agreed?
6. **Gradient rule.** Allow gradients on control fills and chart bars, and keep the ban for text, icons and strokes: agreed?
7. **Scope of "handle".** Web and SwiftUI both, or web first? Recommend web first (Steps 1 to 3), SwiftUI after.
8. **Reference captures.** Is there period software or screenshots to hand, or must references come from public emulators and archives? I should not download anything without asking.

## 8. Decisions and direction (owner, 2026-11-17)

- **System 7 is a look-and-feel re-implementation, drawn by us (not running the real 68k system), with a real System 7 as an oracle.** The oracle is a reference to compare pixels against, supplied by the owner; its captures are used to measure and are not shipped. This note does not verify the licensing of any ROM or system software, and none was downloaded.
- **Pixel skins are a first-class case.** Patterns are logical-pixel cells with an integer scale policy (`ScalePolicy.integer`): crisp at 1x, 2x, 3x, snapped to the nearest whole scale otherwise. Implemented in `Surface.swift`.
- **Gaps to close for System 7 as a superset** (not yet built): roles for title bar (striped), close, zoom and grow boxes, menu bar, scrollbar arrows; a bitmap-font role (Chicago and Geneva are fixed-size bitmaps; free recreations' licences are unchecked); 1-bit dithering of a colour theme; 1-bit cursors and icons.
- **A native renderer.** The test rasteriser in `SurfaceRecipeTests` is the seed of a Foundation-only renderer that draws recipes to a bitmap or framebuffer, independent of any toolkit (the Raspberry Pi and embedded case). Not started.
- **Toolkit targets** (GTK 3 and 4, libadwaita, Qt, terminals, compositors, LVGL) come after the surface model is wired into themes; the owner can set up a Linux machine to build and test on. Not started.
- **A browser, modern and not a Mosaic clone.** Draft boundary, not yet agreed: we own the System 7 look and feel, the document-browser chrome, a defined *document web* (an HTML subset, Markdown, Gemini, Gopher, feeds), layout of that subset onto our tokens, and a modern network layer (HTTP/2 and 3, TLS, caching, no tracking). We do not own a general web engine (JavaScript, full CSS, arbitrary sites); a page outside the subset says so and offers the system's own engine as a clearly separate mode. This is a separate project that uses the design system, not a step of this one.
