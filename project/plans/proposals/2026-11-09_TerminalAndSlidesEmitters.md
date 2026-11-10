# Design Proposal: terminal (ANSI) and slides emitters

**Date:** 2026-11-09
**Status:** Implemented (tests 332 core / 42 SwiftUI, gate 0/0); on branch `feature/terminal-slides-emitters` (cut from 0.6.0, be033b8) as a 0.7.0 candidate. Unreleased.
**Related:** `2026-11-07_DesignSystemSingleSource.md` section 4 (the `ansi` and `slides` emitters) and `2026-11-09_ThemeModel.md` (5.3, the emitter list).

## 1. What and why

Two more pure functions from `Theme` to text, beside `ThemeCSSEmitter`, `ThemeJSONEmitter` and `TumblrEmitter`: one for terminals
(SwiftCLIKit and any shell script) and one for Keynote and PowerPoint templates. Same architecture: deterministic, header saying
the file is generated (theme id, DesignTokens version, snapshot, content hash), committed under `Generated/themes/`, golden-tested,
listed in `Generator`, with the existing "nothing else is in Generated" staleness test covering them.

## 2. Slots (shared)

A theme has up to four colour *slots*: `light`, `light-increased`, `dark`, `dark-increased`, resolved by
`Adaptive.value(in:increasedContrast:)` (an unmeasured increased value carries through, as everywhere).

| `appearances` | slots emitted |
|---|---|
| `both` | light, light-increased, dark, dark-increased |
| `lightOnly` | light, light-increased |
| `fixedDark` | dark, dark-increased (the values live in the `light` slot of the model; the emitter reads them there and names the slot `dark`) |

A colour with alpha below 1 is composited over the slot's `background` (per channel, rounded half up), because a terminal and a
slide palette have no alpha.

## 3. ANSI: `themes/<id>.ansi.txt`

A plain-text role table, one block per slot, one row per colour: the twelve roles, then `series-N`, then `extra.<key>` (sorted).
Columns: `role kind hex truecolor c256 c16 glyph ascii note`.

- `kind` is `bg` for `background` and `surface`, otherwise `fg`. The three columns are SGR *parameter lists* (the text between
  `ESC [` and `m`): truecolor `38;2;R;G;B` (`48;` for bg), 256-colour `38;5;N`, 16-colour `30-37` / `90-97` (`40-47` / `100-107`).
- **256-colour mapping.** Nearest entry (squared Euclidean distance in sRGB, ties to the lowest index) among indices 16 to 255 of
  the xterm table: the 6x6x6 cube with levels 0, 95, 135, 175, 215, 255 (index 16 + 36r + 6g + b) and the 24 greys 8 + 10k
  (index 232 + k). Indices 0 to 15 are never chosen for the 256 column: they are the user's own palette.
- **16-colour mapping.** Nearest (same metric and tie rule) among xterm's default sixteen: 000000 CD0000 00CD00 CDCD00 0000EE
  CD00CD 00CDCD E5E5E5 7F7F7F FF0000 00FF00 FFFF00 5C5CFF FF00FF 00FFFF FFFFFF. Terminals remap these, so the 16-colour column is
  the last resort and says which colour *family* is meant, not an exact value.
- **Status is never colour alone.** `positive`, `negative` and `warning` rows carry a glyph (`✓` `✗` `!`) and an ASCII fallback
  (`+` `x` `!`); other rows carry `-`. A consumer prints the glyph with the colour.
- The table does not set the terminal's background. The owner's terminal is green on black; the table is a role table, not a
  terminal theme, and the `background` and `surface` rows are for a consumer that paints a region.
- Not emitted: ramps (a terminal heatmap would sample `sequential`; no consumer has asked), contrast measurement of the 256 and
  16 approximations (they can fall under the theme's own contrast; the ledger measures the truecolor values only).

## 4. Slides

For Keynote and PowerPoint templates, three kinds of file per theme.

1. `themes/<id>.slides.txt`: the colour and font list a person types into a template. Per slot, the twelve roles, the series
   and the extras as hex; then the fifteen type roles (family chain, size in points, weight name and number, tracking in em,
   case, italic, line height). Font chains are the theme's `FontFamilyRef` resolved to installable names: the CSS-only names
   (`-apple-system`, `BlinkMacSystemFont`, `ui-*`, the generic families) are dropped, so sans is SF Pro Text, SF Pro,
   Helvetica Neue, Helvetica, Arial; mono SF Mono, Menlo, Consolas; New York and Garamond as in `FontStack`.
2. `themes/<id>.slides.colors.<slot>.xml`: a DrawingML `<a:clrScheme>` (the root element of a PowerPoint *Theme Colors* file:
   Design, Variants, Colors, Customize). Mapping: dk1, dk2, lt1, lt2 are ink, secondary ink, background, surface in a light slot and
   background, surface, ink, secondary ink in a dark slot (so a dark scheme still has the dark pair as `dk`; use the master's
   colour map `bg1="dk1" tx1="lt1"` for it); accent1 is the accent; accent2 to accent6 are the first five series whose hex
   differs from the accent (padded with `muted` if a theme has fewer); hlink is `link`; folHlink is `secondaryInk`.
3. `themes/<id>.slides.fonts.xml`: a DrawingML `<a:fontScheme>` (root of a *Theme Fonts* file): major = the `heading` role's first
   named face, minor = the `body` role's. A DrawingML typeface holds one name, so the fallback chain goes in a comment.

Not built: a `.thmx` or `.potx` package (a zip with a master, layouts and relationships that we cannot specify to a standard we
can test against), a Keynote theme file (a proprietary bundle), an Office `<a:theme>` wrapper, and anything that sets the colour
map. Neither the XML nor the text was opened in Keynote or PowerPoint here; the XML is checked for well-formedness and for the
mapping above, not for acceptance by Office.

## 5. API

Public, Foundation-only: `ThemeSlot` (`.slots(for:)`, `name`), `TerminalColour` (`xterm256(_:)`, `xterm16(_:)`),
`ANSIEmitter.emit(_:)`, `SlidesEmitter.emitList(_:)`, `.emitColourScheme(_:slot:)`, `.emitFontScheme(_:)`, `.fontChain(_:)`.
`Generator.files` adds, per theme after the existing files: `ansi.txt`, `slides.txt`, `slides.fonts.xml`, then one
`slides.colors.<slot>.xml` per slot. `design-tokens emit --theme <id>` writes them with the rest.

## 6. Tests (red first; expected values from closed forms, enumeration or hand computation)

- `TerminalColour`: xterm cube and grey entries built in the test from the published formula; every one of the 240 entries maps
  to its own index (enumeration); a tie (115,0,0 is equidistant from 95 and 135) goes to the lower index 52; known anchors
  (#FF8D28 to 208, #000000 to 16, #FFFFFF to 231, #808080 to 244; 16-colour #FF8D28 to 3, i.e. SGR 33, by hand: squared
  distance 8196 against 14596 and 21481).
- `ThemeSlot`: slots per appearance kind for real themes (Swiss both, Princeton light-only, Legacy Dark fixed-dark), and that
  fixed-dark reads the light slot.
- ANSI: Swiss light accent row has the exact fields; one row per role and series; glyphs only on the three status roles; alpha
  composite of a hand-built translucent colour; header; deterministic; every hex in the file is a value of the theme.
- Slides: font chains equal the owner's list; XML parses and carries the mapped values; dark swap; padding when series are short;
  list contains every type role.
- Golden files for all nine themes and the file-set test (count and order); the "nothing else in Generated" test already holds.

## 7. Open questions for the owner

1. Glyph choice (`✓ ✗ !`) and whether `positive` and `negative` should instead be `▲ ▼` for gain and loss.
2. Whether PowerPoint colour files for the increased-contrast slots are wanted at all (they are cheap, and clutter `Generated/`).
3. Whether the 0.7.0 release should also carry a `--format` filter on the CLI (not built).
