# Skin measurements: System 7, Platinum, OPENSTEP, Aqua 10.0

**Measured 2026-11-17.** Step 1 of `project/plans/proposals/2026-11-17_SkinsSpike.md`. Pixel values were read with Python Pillow from period screenshots; nothing here is from memory except where marked **(general knowledge)**. Liquid Glass was captured from this machine in both appearances (its own section).

## Sources

Screenshots from the GUIdebook gallery (https://guidebookgallery.org), fetched 2026-11-17 into the session scratchpad. They are **not committed**: they are someone else's captures of Apple and NeXT software and are used here only to read numbers. Each file is a PNG of 1 to 120 KB.

| Look | Screenshot set | Image used (path under `/pics/gui/`) | Size |
|---|---|---|---|
| System 7.0 | `screenshots/macos70` | `interface/dialogs/openfile/macos70.png`, `desktop/empty/macos70.png` | 360 x 246, 640 x 480 |
| Platinum, Mac OS 8.0 | `screenshots/macos80` | `interface/dialogs/openfile/macos80.png`, `desktop/empty/macos80.png` | 460 x 194, 640 x 480 |
| OPENSTEP **4.2** | `screenshots/openstep42` | `interface/dialogs/openfile/openstep42.png` | 297 x 339 |
| Aqua, Mac OS X 10.0 | `screenshots/macosx100` | `interface/dialogs/openfile/macosx100.png` | 486 x 397 |

**Gap: the NeXTSTEP reference is 4.2, not 4.0.** GUIdebook's page for OPENSTEP 4.0 (`screenshots/openstep4`) returned 404 and I did not look further. I have not verified that 4.0 and 4.2 draw controls identically; treat the NeXT numbers as 4.2 until a 4.0 capture is compared.

## Method

For each look, a vertical and a horizontal line of pixels was read through the centre of the **Cancel** button, and run-length encoded (`colour x count`). Everything below is a quotation of those runs, then an interpretation.

## System 7.0 (1-bit)

Raw, vertical through Cancel: `FFFFFF x6, 000000 x1, FFFFFF x7, 000000 x6 (the text), FFFFFF x5, 000000 x1, FFFFFF x6`.

- The only two colours are `#000000` and `#FFFFFF`. No greys anywhere in the sampled lines.
- A button is a **1 px black outline on white**; there is **no bevel**, no inner highlight, no shadow.
- The default button (Open) has an extra black ring around it (visible in the capture; its width was not sampled).
- The desktop is a **50% checkerboard**: rows alternate `000000 FFFFFF …` and `FFFFFF 000000 …`, period 2 px each way.
- Therefore: contrast is exactly 21:1 for text; there is **no dark appearance**; the "palette" is two colours plus a dither pattern. Corner radius is visibly small (a few px); not sampled.
- Fonts **(general knowledge, not measured)**: Chicago for the system face, Geneva for lists.

## Platinum (Mac OS 8.0)

Vertical through Cancel: `000000 x1, DDDDDD x1, FFFFFF x1, DDDDDD x14, AAAAAA x1, 777777 x1, 000000 x1`.
Horizontal: `000000 x1, DDDDDD x1, FFFFFF x1, DDDDDD x17 … DDDDDD x17, AAAAAA x1, 777777 x1, 000000 x1`.

Read from the outside in:

| Side | Steps (outer to inner) |
|---|---|
| Top and left | `#000000` outline, `#DDDDDD` (one pixel of body colour), `#FFFFFF` highlight, then the body |
| Bottom and right | the body, then `#AAAAAA`, `#777777`, `#000000` outline |

- Body fill `#DDDDDD`, flat (no gradient across the 14 body rows sampled).
- The bevel is **asymmetric**: light side has a gap pixel between outline and highlight; dark side has **two** shadow steps and no gap.
- The desktop and window background greys read `#DDDDDD`; the empty-desktop sample at the centre reads `#9C9CCE` (the default blue-grey pattern, shown flat).
- Square-ish: corner radius not sampled.
- Fonts **(general knowledge)**: Charcoal for the system face in 8.x, Geneva for lists.

## OPENSTEP 4.2 (standing in for NeXTSTEP 4.0)

Vertical through Cancel: `FFFFFF x1, AAAAAA x…, 000000 x6 (text), AAAAAA x8, 555555 x1, 000000 x1, AAAAAA x4`.
Horizontal: `… FFFFFF x1, AAAAAA x15 …, AAAAAA x16, 555555 x1, 000000 x1, AAAAAA x8, FFFFFF x1`.

| Side | Steps |
|---|---|
| Top and left | `#FFFFFF`, **one** pixel |
| Bottom and right | `#555555` then `#000000`, **two** pixels |

- Body `#AAAAAA`, flat. Window background `#AAAAAA`. Title bar `#000000`. A text field is white with a `#555555` two-pixel top edge (inset) above it: `AAAAAA x8, 555555 x2, FFFFFF …`.
- Radius 0. The bevel widths are 1 light, 2 dark, which is not the same as Platinum's.
- Font **(general knowledge)**: Helvetica.

## Aqua (Mac OS X 10.0)

Pinstripe, vertical at x=20: `F1F1F1, FFFFFF, F1F1F1, EAEAEA` repeating, **period 4 px**. (Horizontally the stripe is flat away from the window edge: `F1F1F1 x4` at x=18 to 21.)

Cancel button, vertical (excluding the text rows): outer line `#7D7D7C` at the top and `#7E7E7E` at the bottom; the fill runs `B6B6B4, D1D1D1, DCDCDC, E1E1E1, E5E5E5` downward in the upper half, then `E1E1E1, E9E9E9, F5F5F5, FDFDFD, F9F9F9` in the lower half; below the bottom outline a **drop shadow** `959595, B4B4B4, D9D9D9`, three pixels.

Blue scroll thumb (a default-button-coloured control), vertical: `ABABAB` outline, `0039B3` (a dark blue top edge), then `77A3DE, 92BBE6, 8EBAE7, 84B4E9` (upper band, lightening then settling), a **hard step** to `4A91E3`, then `5EA2EE, 6FB2FD, 81C4FF, 90D4FF, 9AE0FF, 93D5FF` (lower band, lightening), then `5C5C5C` and `ABABAB`.

- So Aqua's gel is **two bands with a discontinuity at about the midpoint**, each its own gradient: a gradient with a hard stop, not one smooth ramp.
- The title bar is also pinstriped, with dark `111111`/`191919` rows that are text and window-control outlines, and a `7E7E7E` bottom line.
- Pill buttons: the Cancel and Add to Favorites buttons are capsule-shaped in the capture (radius equal to half the height).
- Font **(general knowledge)**: Lucida Grande.

## Liquid Glass (macOS 27.2, captured 2026-11-17 on Lightspeed)

**Method.** A throwaway SwiftUI window (not in this repo): 640 x 420 pt, three vertical thirds of `#000000`, `#808080` and `#FFFFFF`, holding a 420 x 120 pt `.glassEffect(.regular, in: .rect(cornerRadius: 24))` panel across all three, a `.buttonStyle(.glass)` button and a `.glassEffect(.clear, in: .capsule)` label over the grey. The probe captured **only its own window** through CoreGraphics at 2x, so none of the user's screen was captured. (`screencapture -l` failed, and `NSView.cacheDisplay` omits the glass because the window server composites it.) Both appearances were set on the window explicitly. An earlier run happened while the display was idle and returned fully transparent images; `caffeinate -u` then `caffeinate -d` fixed that.

**Regular glass, pixel at the panel's centre row (grey level, red channel):**

| Background | Dark appearance | Light appearance |
|---|---|---|
| `#000000` | `#151515` | `#757575` |
| `#808080` | `#727272` | `#B3B3B3` |
| `#FFFFFF` | `#808080` | `#EEEEEE` |
| Linear prediction for the grey from the black and white | 75 | 178 |
| Measured grey | **114** | 179 |

- **Light appearance is linear** (prediction 178, measured 179), so it fits `out = (1-a)*bg + a*tint` with **a = 0.525 and tint about `#DEDEDE`**.
- **Dark appearance is not linear**: over the grey the glass is 114, where the black and white ends predict 75; over white it is only `#808080`. So the dark material **adapts to what is behind it** (it compresses and lifts), and a single tint alpha is wrong. The two-point fit from black and white (alpha 0.58, tint `#242424`) holds only at those two points.
- **Clear glass over the grey:** dark `#747474`, light `#9E9E9E` (regular over the same grey: `#727272` and `#B3B3B3`).
- **Blur:** the edge between two backgrounds under the panel rises over about **16 to 20 pt** between 10% and 90% (a Gaussian sigma of about **6 to 8 pt**), in both appearances. Sampled every 4 px at 2x.
- **An edge line exists**, one device pixel (0.5 pt) wide, darker than both sides where the background is mid-grey: top edge over the grey reads `80 80 80 80 80 | 58 | 72 …` in dark and `80 … | 60 | B3 …` in light. Over black and over white it is not distinguishable from antialiasing. Consistent with a thin low-alpha dark stroke; its alpha and colour cannot be separated from these samples.
- The glass button over the grey reads `#7F7F7F` (dark, almost the background) and `#B3B3B3` (light, as the panel).
- Radius is what the code specifies (24 pt reads as about 48 px at 2x). No outer shadow was detected on any background.

**Limits.**
- Flat black, grey and white cannot show lensing or a specular highlight; either may appear over detailed or coloured content. Not tested.
- Dark appearance needs a fit with more than three backgrounds before it can be expressed as numbers; with three points the only safe statement is "non-linear".
- This is a moving target (the owner noted Liquid Glass is "still in flux"): these numbers are for **macOS 27.2 on 2026-11-17** and need re-measuring with the OS.

**What it means for the model.** A web approximation in light appearance is a backdrop blur of about 7 px under a tint layer at about 0.5 alpha with a 0.5 px dark edge line. That is expressible as `SurfaceRecipe` (blur, a translucent fill, an `Edges` line). **Dark appearance cannot be a fixed alpha**: a theme may give the dark glass its own measured fill, and its ledger should say it does not adapt. Refraction is not expressible in CSS and stays recorded as a limit.

## What the measurements change in the spike note

1. **Bevel is per-side ordered pixel steps, not one light and one dark colour.** Platinum: top `[000, DDD, FFF]`, bottom `[AAA, 777, 000]`; NeXT: top `[FFF]` (1 px), bottom `[555, 000]` (2 px). `BevelSpec(width, light, dark)` in the spike note cannot say either. Replace it with `Edges` whose sides are **ordered lists of (colour, width)**, which also covers a plain 1 px outline.
2. **System 7 needs a 1-bit pattern layer** (a 2 x 2 checkerboard, period 2 px). `PatternSpec` must be able to express a small repeating cell of two colours; the guide must treat the theme as **light-only with two colours**.
3. **Aqua needs a gradient with a hard stop** (two stops at the same position), and a **repeating** vertical pinstripe of period 4 px with four colours. CSS can express both; our `GradientSpec` must allow duplicate positions and a `repeating` flag.
4. **Drop shadows here are 3 px, tight**: they fit `ShadowSpec` (outer, one) already; the Aqua button also needs the outline, so it needs a *list* of layers, which `SurfaceLayer` provides.
5. **Pixel-exact metrics.** Every edge above is 1 or 2 px with no anti-aliasing. Our spacing is on a 4 pt base unit and our hairline is a fraction of it. A skin needs **device-pixel-snapped** widths (CSS `1px`, not `rem`), which the current emitters do not promise.
6. **Contrast needs care for System 7 and Platinum disabled states.** Not measured here (Eject was disabled in the captures: its colours were not sampled). It is a Step 2 item.

## Not measured yet

- Corner radii of System 7, Platinum and Aqua buttons; Platinum and System 7 title bars (stripes); default-button rings and the Aqua default button's blue; menus; scrollbars. All present in the captured sets; deferred to Step 2.
- **Liquid Glass:** lensing and highlights over detailed or coloured content, a fit for dark appearance with more backgrounds, and button states.
- **NeXTSTEP 4.0** proper: **not needed** (owner, 2026-11-17: 4.2 is fine).

## System 7.0 on a running oracle (Infinite Mac, 2026-11-18)

**Method.** Infinite Mac (https://infinitemac.org, `System 7.0`) was opened in Chrome and its screen canvas (a 2D canvas, 832 x 624, one canvas pixel per CSS pixel) was read with `getImageData`: exact pixel values, no screenshot scaling. Light, read-only use of the public site; its terms say nothing about the system images or automated use (the repository is Apache 2.0), so nothing was downloaded. The numbers are about borders and sizes. Quoted from the **Open dialog** shown by SimpleText.

- **This machine runs 8-bit colour, not 1-bit.** The canvas holds greys (`#EEEEEE`, `#CCCCCC`, `#777777`, `#333333`, `#888888`), and a window title bar has a shaded frame. The 1-bit GUIdebook shots above are a different depth. `Theme.system7` remains the 1-bit look; a colour System 7 would be its own theme.
- **Desktop:** `000000 FFFFFF` alternating per pixel, each row offset by one from the last. Confirms the 2 x 2 checkerboard.
- **Cancel button:** 78 x 20 px at x 493 to 570, y 235 to 254. 1 px black outline, white fill, no bevel, no shadow. The top line runs x 495 to 568; row 2 has two black pixels at each end and row 3 one: the corner steps in two pixels, **radius 3**.
- **Default button (Open):** the same 78 x 20 button with a **3 px ring** outside it, **1 px of white**, then the 1 px black outline. In this 8-bit session the ring reads `#888888`; the 1-bit shots have it black. Its outer corner steps in about 6 px (radius about 7). The ring is **outside** the 78 x 20 box, so on the web a default button needs 4 px more room on each side or the ring overlaps its neighbours.
- **Not measured:** the pressed state (needs a held mouse), the disabled state, scroll bars, the title bar of a 1-bit window.
