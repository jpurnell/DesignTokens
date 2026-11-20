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

### Platinum, further readings (Mac OS 8.0 captures, 2026-11-18)

Read from `macos80/…openfile…png` (Cancel) and `…colourselector…png` (OK, the default button, and a text field).

- **Button:** 80 x 20 px (outline rows 110 to 129, columns 361 to 440). The corner steps in 3 px: the top outline starts 3 px in, the left outline 3 px down, with one anti-aliased pixel at each end.
- **Default button:** a second three-pixel frame around the 20 px button, so the whole is 26 px high. Outside in, top and left `#000000 #DDDDDD #AAAAAA`, bottom and right `#000000 #777777 #AAAAAA`; the ordinary bevel is inside it. The frame's corner steps in 4 to 5 px. The ring is **outside** the measured button, so the web and GTK emitters grow the default button's box by the ring (`SurfaceSet.defaultRingExtra`).
- **Colours:** window body `#DDDDDD` (a list's body `#EEEEEE`, a pane `#FFFFFF`); the progress bar's rows are `#333399 #6666CC #9999FF #CCCCFF #FFFFFF #CCCCFF #9999FF #6666CC #333399 #000055` with a `#000000` base; a selected row is `#CCCCFF`; the empty desktop reads `#9C9CCE`.
- **Text field (colour picker):** a 1 px black outline on white, no bevel. The Appearance Manager's sunken field was not sampled.
- **Title bar (measured from the Appearance window of `macos80/…desktop_full…png`, 2026-11-18):** rows 106 to 127. Top: `#000000` then `#FFFFFF`; bottom: `#999999` then `#000000`; left: `#000000` then `#FFFFFF`; right: `#999999` then two `#000000` columns. Bar body `#CCCCCC`. Close box 13 x 13 at 2 px inside the frame (columns 233 to 245): `#888888` top and left, `#FFFFFF` bottom and right, a `#222222` frame, and a diagonal bevel inside (`#999999 #AAAAAA #BBBBBB #CCCCCC #DDDDDD #EEEEEE #FFFFFF` in two-pixel bands from top left to bottom right), pixel for pixel in the `windowBox` tile. Stripes: 12 rows from the box's top, `#FFFFFF` then `#777777` alternately, the grey row one pixel to the right of the white row; 4 px of bar between a box and the stripes, the title between two stripe runs 4 px from each. Close box at the left, zoom and windowshade boxes at the right. The generated CSS, rendered in headless Chrome at 1x, matches the capture except: the title text and the right box's glyph (not drawn), the one-pixel offset between white and grey stripe rows at the stripe ends, and a few pixels at the frame corners. The windowshade box (right, columns 608 to 620) is the close box's bevel with two full-width `#222222` lines at rows 5 and 7, and matches exactly; the zoom box (About window, `macos80/…aboutgui…png`, column 445) is the same bevel with one `#222222` line at row 5, and the two right-hand boxes sit 3 px apart (columns 445 and 461); both exact.
- **Verification:** Chrome rendering of the generated `platinum.css` at 1x, button 80 px wide, column read with PIL: `000000 x1, DDDDDD x1, FFFFFF x1, DDDDDD x14, AAAAAA x1, 777777 x1, 000000 x1` (the capture's own run), the same horizontally with a 74 px body, and the default button's 26 rows `000 DDD AAA 000 DDD FFF, DDD x14, AAA 777 000 AAA 777 000`. Exact matches.
- **Not measured:** pressed and disabled states (chosen: the bevel inverted over `#AAAAAA`), focus, scroll bars, menus, the typeface.

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

### OPENSTEP 4.2, further readings (captures of 2026-11-18)

- **Button (Open panel's Cancel):** 72 x 27 px (columns 137 to 208, rows 297 to 323). Reading inward, the right edge is `#000000` then `#555555`, the bottom the same, the top and left one `#FFFFFF` pixel. At the top-right and bottom-left corners the dark edge owns the pixel (`EdgeStacking.bottomTrailingFirst`). Generated CSS in headless Chrome matches every pixel outside the label.
- **Text field (Name):** 21 px high in the capture, `#555555` twice at the top and left, `#FFFFFF` then `#AAAAAA` at the bottom and right (outside in: white outermost). The theme draws fields at the control height (27 px), so the field's height is **not** yet authentic.
- **Title bar (Font Panel, 299 px wide):** rows 0 to 22. Top `#000000 #AAAAAA`, left the same, right `#000000 #555555` (outermost black), bottom `#000000 #555555`; body `#000000`; title text white and bold. **Miniaturize** button at the left, 15 x 15 (columns 4 to 18, rows 4 to 18): a raised bevel (white top and left, `#555555` bottom and right, with one `#555555` pixel beyond each of two corners) around a black 10 px frame holding a smaller `#AAAAAA` window. **Close** button at the right, 14 x 14 (columns 280 to 293): the same bevel around a black X with `#555555` anti-aliasing. Both are pixel for pixel in their tiles; headless Chrome matches the capture's bar except the title text.
- **Colours:** desktop `#555577`; body `#AAAAAA`; selection white; text black.
- **Not measured:** pressed, disabled, focus, scroll bars, menus, the typeface.

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

## Scroll bars (2026-11-19)

Platinum, from the live horizontal bar of the Mac OS 8.0 Appearance window (`pics_gui_desktop_full_macos80`, x 327 to 601, y 243 to 258): 16 px thick,
a 16 x 16 arrow button at each end (black outline, white top and left, #BBBBBB bottom and right, #DDDDDD body, a black triangle 4 px wide and 8 tall
whose base is on the outer side), a sunken track (rows #777777 #888888 ten of #AAAAAA #BBBBBB #CCCCCC between black lines) that starts again
just past the thumb with its own #777777 #888888 left edge, and a 17 px thumb: 1 px bevel #CCCCFF over #6666CC on #9999FF, with an 8 x 8 grip of
two-pixel grooves (#CCCCFF beside #333399). OPENSTEP 4.2, from the file viewer's vertical scroller (x 236 to 255 from y 394): 20 px wide, a black
outline, 1 px of #AAAAAA, a 16 px column, 1 px, the outline; the thumb is the button's raised bevel; a one-pixel checkerboard of #AAAAAA and
#555555 is the track; two 16 x 16 raised arrow buttons sit together at the bottom, 1 px apart. Assumed: Platinum's vertical bar is the horizontal one
turned about its diagonal, and OPENSTEP's horizontal bar the vertical one turned.

## Menus (2026-11-19)

Platinum menu bar (Mac OS 8.0 desktop capture): 20 rows (white, 17 of #DDDDDD, #999999, black), a white column at the left and a #999999 one at the
right; titles at x 43, 78 and 115 (8 px of padding each side). System 7.0: 19 white rows and a black one, same title positions. OPENSTEP 4.2 (Workspace
and Tools menus, x 0 to 92): 93 px wide; the title is 22 rows (white, 19 black, #555555, black), every row 20 (white, 17 of #AAAAAA, #555555, black) with
white on the left and #555555 then black on the right, which is the button's raised bevel; the highlighted row is white throughout; text starts 6 px in.
Assumed: the inverted highlight of the Macintosh titles (no open menu is in the captures). OPENSTEP's submenu arrow is a 7 x 7 triangle at x 80 to 86
(black down the left, #555555 on the upper diagonal, white on the lower; on the lit row the lower diagonal is #AAAAAA and the inside white), 6 px from the
row's end and 6 down. A disabled control (the Revert button, Application Inspector) keeps the raised bevel and draws its text in #555555. A dock tile is
64 x 64 and the tiles are contiguous: two white rows (top) and columns (leading), then the icon on a diagonal slate ground that fits
172 - 0.695 (x + y) in red and green and 185 - 0.669 (x + y) in blue (about #ACACB9 to #555565 corner to corner), and at the bottom and right a dark shade
row (#56575E to #3B3C44 over the ground; drawn as black at 40%) and a black line. The label strip (Preferences tile, y 705 to 715): black, 11 rows, its first row black at about 76% over the ground, white text 7 rows tall; the
labelled tile shows no white highlight under it. Icons are not measured: the set is original drawings in the dock's look, not traced.

## Disabled and inactive states (2026-11-19)

From the Open dialogs. Mac OS 8.0 (Eject and Create): a disabled button is flat #DDDDDD with a one-pixel #888888 outline (the same stepped corner as an
enabled one) and #888888 text; no white highlight and no shade. An inactive vertical scroll bar (x 326 to 341, y 35 to 162): the black outline stays,
the track and both arrows are flat #EEEEEE, an arrow's triangle is #888888 (the same 20 pixels as the live one), and the arrow's row facing the track is
#555555 between two black end pixels. System 7.0 (Eject): the outline stays black and the label is #808080. Chosen, not measured: focus rings (two
pixels outside the control: black on System 7 and OPENSTEP, the accent on Platinum), the disabled field and default button, the pressed states, and the
inactive window. The captures are still frames, so pressed states need a live session.

## Live measurements (Infinite Mac, 2026-11-19)

A button held down on a running System 7.0 and Mac OS 8.0 (synthetic pointer events on the emulator's canvas, pixels read with `getImageData`).
**System 7.0:** the pressed button is solid black inside the unchanged outline and stepped corner, with a white label; the default button keeps its
3 px black ring and the white gap, and fills black inside. **Mac OS 8.0 (24-bit):** at rest a button is a black outline, then `#E7E7E7`, a white
highlight row and column, an `#E7E7E7` fill, and `#C0C0C0`, `#969696` and black at the bottom and right; pressed, the same box is a black outline, `#666666`
and `#777777` inside the top and left, a `#878787` fill, `#969696` and `#A5A5A5` inside the bottom and right, and white text. The default button's
two outer rings (black, `#E7E7E7`, `#C0C0C0`) are unchanged. An open File menu: a black outline, a white top and left highlight, an `#E7E7E7` fill, a
`#B3B3B3` right edge, disabled rows grey; the highlighted row (16 px) is a `#8787DA` top row and left column over a `#5454B3` fill, and the highlighted
menu-bar title is `#5454B3` with a `#8787DA` top row, white text and a `#0000A5` row under it.

**Platinum was re-baselined to these live values (same day).** The earlier Platinum numbers were a 256-colour screenshot's nearest 8-bit colours. Read off
the Appearance control panel of a live Mac OS 8.0 and aligned tile by tile with the theme's (the close box, the thumb and its grip, an arrow, the
track, the title bar's rows, a button's bevel), the greys are a consistent ramp: `#3F3F3F` (was `#222222`), `#666666`, `#777777`, `#878787`, `#969696`
(`#777777`), `#A5A5A5` (`#888888`), `#B3B3B3` (`#999999`), `#C0C0C0` (`#AAAAAA`), `#CDCDCD` (`#BBBBBB`), `#DADADA` (`#CCCCCC`), `#E7E7E7` (`#DDDDDD`),
`#F3F3F3` (`#EEEEEE`). The lavender thumb: highlight `#DADAFF`, body `#B3B3FF`, shade `#8787DA`, grip dark `#5454B3`, grip light `#F3F3F3`. The title bar:
outline, white row, `#DADADA` bar, stripes white and `#969696` (12 rows), `#DADADA` below, `#B3B3B3`, black. The desktop here is a flat `#B3B3DA`. A panel's
content area is flat `#E7E7E7` with an etched separator (`#A5A5A5` over white); a window's frame area is a fine dither of `#DADADA`, `#E7E7E7`
and `#F3F3F3` that the theme draws flat. Not re-measured live: the inactive scroll bar's greys and the disabled button (tone-mapped by the same ramp,
`#A5A5A5` and `#F3F3F3`), the sequential chart ramp, and text colours.

## Inactive window, Platinum (live Mac OS 8.0, 2026-11-19)

Read from Infinite HD with another window in front. The title bar column (22 rows): `#777777` line, 20 rows of flat `#E7E7E7`, `#777777` line; no white row, no `#B3B3B3` row, no stripes, no close or zoom boxes. The title text is `#878787`. The frame is `#777777` on every side (two columns at the right and two rows at the bottom, as the shadow), and a scroll bar's outline is `#777777` where an active window's is black. A scroll bar with nothing to scroll in an *active* window is different: it keeps the black outline over `#F3F3F3` (already modelled as the inactive track). Modelled as the `disabled` state of the bar, its stripes and boxes, and the frame; the inactive scroll bar's grey outline is not yet.

## Pressed scroll bar parts, Platinum (live Mac OS 8.0, 2026-11-19)

Held with synthetic pointer events on a resized Infinite HD window (read with `getImageData`; the emulator draws its cursor into the canvas, so cells under it were skipped). **Down arrow**, 16 x 16 at rest: black outline, white top and leading, `#CDCDCD` bottom and trailing, `#E7E7E7` fill. Pressed: black outline, `#777777` on the whole top row and leading column, `#969696` fill, `#B3B3B3` bottom row and trailing column, with `#969696` at the two corners where the lines meet; the black triangle is unchanged. The tile reads the same turned about its diagonal, so one tile serves both directions. **Thumb**: every tone moves one step darker, so highlight `#DADAFF` becomes `#B3B3FF`, fill `#B3B3FF` becomes `#8787DA`, shade `#8787DA` becomes `#5454B3`; in the grip `#F3F3F3`, `#DADAFF`, `#B3B3FF` and `#5454B3` become `#DADAFF`, `#B3B3FF`, `#8787DA` and `#000077`.

## Platinum dropdown menu (live Mac OS 8.0, 2026-11-19)

File held open (synthetic pointer events, released off the menu so nothing ran). Outer box x 33 to 182 (150 px) and from the bar's black line down: black outline, white inside the top and leading, `#E7E7E7` fill, `#B3B3B3` inside the bottom and trailing, a 1 px `#3F3F3F` shadow right and below. Rows are 16 px, the first starting directly under the bar's black line; text starts 19 px in and ends 13 px short of the right edge; disabled text `#A5A5A5`. The lit row covers the edge columns: top row and leading column `#8787DA`, fill `#5454B3`, trailing column `#0000A5` (nothing at the bottom). Separator: 6 px, rows 3 and 4 are `#A5A5A5` and white across the whole inner width (edge columns included), the other four rows leave the menu's own edges. Not measured: the bottom-left corner pixel (it is `#E7E7E7` where the leading white column would be, one pixel off the model), check marks, submenu arrows, key-equivalent glyphs.

## Window frame and inactive scroll bar, Platinum (live Mac OS 8.0, 2026-11-20)

The "fine dither" the 256-colour screenshots suggested is **not on the live system**: the frame is flat. Active window, outside in on the leading side: black, white, two `#DADADA`, `#B3B3B3`, then the content's own black edge; on the bottom and trailing sides the light reverses (black, `#B3B3B3`, two `#DADADA`, white) with a 1 px black shadow below and right; the top is the title bar's black and white. Inactive: `#777777`, then four `#E7E7E7`, with a `#777777` shadow. An inactive scroll track is the same `#F3F3F3` with `#777777` outlines. Not measured: the inactive frame's bottom and trailing sides directly (assumed to mirror the leading), a disabled button (no dialog was reachable in the session), and the text and chart colours, which no Mac OS 8 surface shows as such (the chart ramp is a design choice, not an OS colour).

## Not measured yet

- **Fixed-pitch type** (all three skins): Monaco 9 on the Macintosh, Ohlfs then Courier on NeXT are general knowledge and chosen, not read from a capture. A terminal or code window in a capture would settle the size and line.
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
