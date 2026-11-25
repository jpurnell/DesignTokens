# Design Proposal: Liquid Glass Skin (macOS 27.2)

**Status:** Proposed (awaiting approval). **Date:** 2026-11-20. **Branch:** `feature/skins-model`.
**Master Plan Reference:** Skins theme the whole OS (System 7, Platinum, OPENSTEP shipped; Aqua and Liquid Glass next).
**Companion:** an Aqua proposal. Aqua is the last opaque, pixel-measurable skin; Liquid Glass is the first one whose look depends on what is behind it.

## 1. Objective

Ship `Theme.liquidGlass`, a skin of the macOS 27 material, as web CSS and (separately) as a native SwiftUI path, with an honest ledger of what it does not reproduce.

Liquid Glass differs in kind from the three shipped skins. Those are opaque and pixel-exact, so a recipe is a fixed set of pixels. Glass is a function of its backdrop. The skin therefore needs to say, per recipe, what is measured, what is approximated and what is not reproduced.

## 2. Motivation

**Current situation.** `SurfaceRecipe` already has `backdropBlur`, translucent fills (`ColourReference.opacity`), per-side `Edges`, shadows and `ScalePolicy.free`. A light, single-tint "frosted" look can be written today.

**What the measurements say is missing** (SkinMeasurements.md, "Liquid Glass", macOS 27.2, captured 2026-11-17):

- Light appearance is linear in the backdrop: `out = (1-a)*bg + a*tint`, a = 0.525, tint about `#DEDEDE` (predicted 178, measured 179 over mid grey). One alpha fits.
- Dark appearance is **not** linear: over `#808080` it reads 114 where black and white predict 75, and over white it reads only `#808080`. The material adapts to its backdrop. A fixed alpha is wrong, and no number of tweaks to a single alpha repairs it.
- Blur: sigma about 6 to 8 pt (10% to 90% edge rise over 16 to 20 pt), same in both appearances.
- A 0.5 pt dark edge line exists over mid grey; its alpha and colour cannot be separated from the samples.
- No outer shadow was detected on any backdrop.
- Clear glass over grey: dark `#747474`, light `#9E9E9E`. Regular: `#727272` and `#B3B3B3`.

**Workaround today.** Write it as a frosted-glass card (blur plus a white 50% fill). It looks plausible in light mode, is wrong in dark mode over anything but black and white, and claims nothing about refraction.

**Drawback.** Without a ledger the theme would silently pretend to be the real material. The project's rule (original face first, honest fallbacks, measured values) applies: say what is approximated.

## 3. What Liquid Glass needs that the model lacks

| Need | In the model today? | Expressible on the web? | Decision |
|---|---|---|---|
| Backdrop blur | `backdropBlur: Double?` | Yes, `backdrop-filter: blur()` | Use as is, sigma about 7 px (CSS blur radius is the standard deviation). |
| Tint at about 0.5 alpha | `ColourReference.opacity` | Yes | Use as is for light. |
| Edge line, 0.5 pt | `Edges` (integer widths today) | Yes, `0.5px` is honoured on 2x screens | Allow a fractional width on `free`-scale skins only (see 4.1). |
| Specular edge highlight (inner top rim) | inset `ShadowLayer` | Yes, inset box-shadow | Express with inset shadows; **unmeasured** (flat greys cannot show it), so marked "assumed". |
| Concentric corner radii (inner radius = outer minus padding) | `CornerRadius` per surface | Partly: `calc()` on custom properties | Add a nested-radius rule to the emitter (4.2). |
| Adaptive tint over varying backdrops (dark) | No | Not honestly in CSS | Record as a limit. Offer a dark recipe with its own measured fill plus the ledger line "does not adapt". |
| Refraction / lensing | No | Only crudely, with an SVG `feDisplacementMap` in `backdrop-filter: url(#...)` (Chromium only) | **Out of scope for the web emitter**; recorded as a limit. Optional experiment behind a flag (section 6). |
| Light and dark as one skin | `appearances` exists | Yes | Two measured appearance sets. |
| Reduce transparency / increase contrast | No skin-level concept | Yes: `prefers-reduced-transparency` (Chrome 118+), `prefers-contrast` | Add an opaque fallback recipe per glass surface (4.4). |

## 4. Proposed architecture and API

### 4.1 Model additions (all optional, absent from the JSON of themes that do not use them)

```swift
/// How a surface is honest about what it cannot reproduce.
public enum Fidelity: String, Sendable, Hashable, Codable, CaseIterable {
    case measured      // pixel/number taken from the oracle
    case approximated  // fitted from few points (e.g. dark glass)
    case assumed       // not observable with the probe (specular rim)
}

public struct SurfaceRecipe {
    // existing fields unchanged
    /// Backdrop saturation multiplier applied with the blur (1 = unchanged). nil omits the term.
    public var backdropSaturation: Double?
    /// A solid recipe used when the user asks for reduced transparency or the browser lacks backdrop-filter.
    public var opaqueFallback: Fill?          // a ColourReference, never a layer list
    /// What this recipe claims. Defaults to .measured for the shipped skins (not encoded when .measured).
    public var fidelity: Fidelity
}
```

- `Edges` widths become `Double` with a documented rule: a skin whose `scale` is `.integer` keeps whole-pixel widths (a unit test enforces it), `.free` skins may use `0.5`.
- `Theme.liquidGlass` carries `ScalePolicy.free` and two appearance sets (`light`, `dark`).
- A new theme-level `Ledger` list (`[LedgerEntry(topic:, status: Fidelity, note:)]`) is emitted into the CSS header and `SkinMeasurements.md`. This is the "honest" part and it is data, not prose, so a test can check that refraction and dark adaptation are listed.

### 4.2 Concentric radii

Glass nests: a button inside a panel inside a window use radii that shrink by the padding. Add `CornerRadius.concentric(inset: Double)`, which the emitter writes as `calc(var(--dt-parent-radius) - <inset>px)` (floor at 0). Parents set `--dt-parent-radius`. Chrome 111, Safari 16.2 and Firefox 113 all support `calc()` with custom properties.

### 4.3 Measured values for the recipes

Light appearance (measured, linear):

| Part | Blur | Fill | Edge | Radius |
|---|---|---|---|---|
| Panel (regular) | 7 px | `#DEDEDE` at 0.525 | 0.5 px, dark, alpha **assumed** 0.25 | what the layout specifies |
| Clear | 7 px | derived from `#9E9E9E` over `#808080` | same | |
| Glass button | 7 px | as panel | same | capsule |

Dark appearance: **approximated**. The black/white two-point fit (alpha 0.58, tint `#242424`) is the only expressible form and is wrong over mid backdrops (114 measured against 75 predicted). The proposal is to ship that fit marked `.approximated`, and to take **more backdrops** (at least 9 greys plus colour) in Phase 0 to see whether a three-parameter curve (gain, lift, floor) fits well enough to approximate with a gradient-free layer stack. If it does not, the dark fill is the grey-backdrop value (`#727272`) with the ledger line stating it does not adapt.

Typography and spacing are not measured yet and are a Phase 0 item (menu bar, Dock, window chrome and sidebars on a real 27.2 screen, via the same throwaway-window probe).

### 4.4 Accessibility

- `@media (prefers-reduced-transparency: reduce)` swaps every glass recipe for its `opaqueFallback` and removes `backdrop-filter`. Supported in Chrome 118+ and Safari 17.2+; **below those versions the query is ignored**, so the opaque look is also the `@supports not (backdrop-filter: blur(1px))` fallback and the default for the high-contrast case (below the browser floor we cannot detect the preference; documented).
- `@media (prefers-contrast: more)` raises the edge line to 1 px at 0.6 alpha and forces ink to full contrast. The existing contrast tests run for the opaque fallback, which is the guaranteed-legible case; the glass case is only claimed legible over the backdrops measured.
- Ink over glass cannot be proven against an unknown backdrop. The ledger says so. The guide recommends a scrim (the opaque fallback) behind long text.

### 4.5 Browser floor and fallbacks (Chrome 111 / Edge 111 / Safari 16.2 / Firefox 113)

| Feature | Floor | Status |
|---|---|---|
| `backdrop-filter` | Chrome 76, Safari 9 (prefixed), Firefox 103 | OK at the floor; keep `-webkit-` prefix for Safari 16.2. |
| `0.5px` borders/shadows | all | OK; renders as 1 device pixel on 2x, hairline-or-thicker on 1x. |
| `calc()` with custom properties | all | OK. |
| `prefers-reduced-transparency` | Chrome 118, Safari 17.2, Firefox behind a flag | Below floor: unknown, treated as default; ledgered. |
| SVG refraction filter in `backdrop-filter` | Chromium only | Not shipped by default. |

Fallback order for an unsupported browser: opaque fallback fill, edge line, no blur. The skin stays legible, only not glassy.

### 4.6 SwiftUI native path versus CSS

`GlassEmitter` (SwiftUI) is a separate emitter with a different honesty position:

- On macOS 26+/iOS 26+, emit `.glassEffect(.regular, in: shape)` and `.buttonStyle(.glass)`. The OS then draws the real material, including refraction and adaptive tint, so the **model's numbers are not used** and the emitted code says why in a comment. The theme still supplies ink, shape, concentric radii and the metrics.
- On earlier OS versions, emit `.background(.ultraThinMaterial)` inside `#available`, then the 0.5 pt overlay stroke.
- This path is the right way to be exact. The CSS path is the portable approximation. Both are generated from the same `Theme.liquidGlass`, and the golden test compares emitted source, not renderings.
- Needs a Swift availability story: the package targets macOS 15 in places, so the emitted code, not the package, uses `if #available`.

### 4.7 Fonts

The system face is SF Pro. Rule applies: **bundle nothing**. CSS font stack: `-apple-system, BlinkMacSystemFont, "SF Pro Text", system-ui, "Segoe UI", Roboto, sans-serif`. On Apple platforms the original face renders; elsewhere the honest fallback does (ledger line "typeface differs off Apple platforms"). Optical sizes (SF Display at 20 pt and up) are approximated by `font-optical-sizing: auto` where the system face supports it.

### 4.8 New and modified files

New:
- `Sources/DesignTokens/Themes/ThemeLiquidGlass.swift`
- `Sources/DesignTokens/Theme/Ledger.swift`
- `Sources/DesignTokens/Emitters/GlassEmitter.swift` (SwiftUI source)
- `Tests/DesignTokensTests/LiquidGlassTests.swift`
- `Generated/` goldens for the theme (CSS, JSON)

Modified:
- `Theme/Surface.swift` (new optional recipe fields, `CornerRadius.concentric`, fractional edge widths for `.free`)
- `Emitters/ThemeCSSEmitter.swift` (saturation, reduced-transparency block, `@supports` fallback, concentric radii, ledger header)
- `Emitters/BrowserSupport.swift` (add the two new floors)
- `Theme/ThemeCodec` (canonical optional keys)
- `project/docs/technical/SkinMeasurements.md`, `CHANGELOG.md`

## 5. Constraints & compliance

- Swift 6 strict concurrency; all new types `Sendable`, `Hashable`, `Codable`.
- No force unwraps; guard clauses; division safety (blur and alpha are clamped to 0...1 / non-negative; a non-finite blur is omitted).
- Strict TDD, quality gate 0/0, no suppressions. All public API gets DocC.
- Original artwork only; no Apple assets or copied pixel traces in the repo.
- Absent optionals write no JSON key, so shipped goldens do not change (a test asserts the three existing goldens are byte-identical after Phase 1).

## 6. Error handling

Emitters are pure and total. Invalid numbers (NaN, negative blur) are dropped at emit time, never trapped. A theme that references a missing opaque fallback fails validation in `Theme.validate()` with a typed error (`glassRecipeMissingFallback(role)`), caught in tests before it can ship.

Optional experiment (not in the default path): an SVG-displacement refraction demo as a separate, clearly-labelled CSS file for Chromium. Gated behind an explicit option and excluded from goldens. Decision in Phase 4.

## 7. Testing strategy

- **Measurement tests:** the light fit predicts the measured values within 2 levels across black, grey and white (this is the value the capture gives, so the test uses the table above, not an invented number).
- **Round trip and canonical JSON** for each new field; absent-optionals tests.
- **Emitter tests:** CSS contains `backdrop-filter` with the prefix, a `prefers-reduced-transparency` block containing opaque fills, an `@supports not` block, concentric `calc()`; no `backdrop-filter` inside the opaque block.
- **Ledger tests:** the theme lists refraction (not reproduced) and dark adaptation (approximated); any `.assumed` recipe is ledgered.
- **Integer-skin guard:** Platinum, System 7 and OPENSTEP edges stay whole numbers.
- **Golden tests:** committed files equal a fresh emit.
- **Rendered check:** headless Chrome over black, grey and white thirds, pixel runs compared with the table (same harness as `pm/`); recorded as numbers in SkinMeasurements.md.
- **SwiftUI emitter:** golden source plus a compile test of the emitted snippet in a throwaway package, not in this repo.

## 8. Performance and resource budget

Backdrop blur is the cost. At sigma 7 px it is cheap on a desktop GPU and costly when many large glass panes overlap or animate on low-end phones. The guide states a budget: at most a few glass surfaces per view, none under a scrolling list. The CSS size grows by about 2 KB. No runtime code.

## 9. Phased TDD plan (commit slices)

0. **Measure more** (no repo change beyond notes): dark appearance over 9 or more greys and 3 colours, clear versus regular, tint under a coloured backdrop, text and menu bar metrics, the edge-line alpha on a coloured backdrop. Re-measure date stamped; 27.2 is a moving target.
1. **Model slice:** fractional edges for `.free`, `backdropSaturation`, `opaqueFallback`, `fidelity`, `Ledger`; goldens unchanged.
2. **Concentric radii** and the browser-floor entries.
3. **Light skin** `Theme.liquidGlass` (light) with measured values, emitter reduced-transparency and `@supports` fallbacks.
4. **Dark skin** approximation plus ledger; decide on the refraction demo.
5. **SwiftUI `GlassEmitter`.**
6. **Docs:** SkinMeasurements, CHANGELOG, README, master plan.

Each slice is red/green, gate 0/0, one commit, no push.

## 10. Risks

- The OS look is "still in flux"; numbers go stale with each release. Mitigation: date stamp, one-command probe (the throwaway window), and ledger.
- Dark adaptation may need more than a table. Mitigation: ship as approximated and say so.
- Reduced-transparency detection is absent below the floor browsers.
- Users may read "Liquid Glass" and expect refraction on the web. The ledger and README must say it is a blur-and-tint approximation there.
- Probe limits: flat backdrops cannot show lensing or specular rim.

## 11. Open questions

1. Is a refraction demo (Chromium-only SVG displacement) wanted at all, or is "not reproduced" the permanent answer on the web?
2. For dark glass: ship the two-point fit, the grey-backdrop value, or wait for the nine-grey fit?
3. May the Phase 0 probe capture over a coloured and a detailed backdrop (a photo), in addition to flat greys?
4. Should the SwiftUI emitter target `glassEffect` only (macOS 26+), or also emit the `ultraThinMaterial` fallback?
5. Is raising the Chrome floor for `prefers-reduced-transparency` (118) acceptable for this theme only, or should the skin stay at 111 with the documented gap?

## Decisions, 2026-11-25 (owner)

Hold: **no Liquid Glass work starts until the skins gallery (`2026-11-25_SkinsGallery.md`) has been reviewed.** The gallery's backdrop control is what lets the glass be judged.

1. **Refraction demo: yes, Chromium first, and the owner wants Safari more.** Open and to be checked before it is promised: Safari does not take an SVG filter as a `backdrop-filter` input, so a Safari path may need a different technique (layered `backdrop-filter` blur and saturate, highlight edges drawn as gradients, no true displacement). The first task is a browser spike in Safari, then Chromium, reporting what each can and cannot show; the demo stays a separate, labelled CSS file outside the default theme path.
2. **Dark glass: wait for the nine-grey fit**; do not ship the two-point fit.
3. **Extra capture: yes**, coloured and photo backdrops as well as flat greys, on Lightspeed. The captures feed the gallery's backdrop control.
4. **SwiftUI: `glassEffect` plus an `ultraThinMaterial` fallback.**
5. **`prefers-reduced-transparency`: floor Chrome 118 for this theme** (the rest of the package stays at 111; the gap is documented).
