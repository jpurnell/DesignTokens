# Design Proposal: the skins gallery

**Status:** Proposed, 2026-11-25. **Slice 2 built 2026-11-27 (the shell: page, switcher, one components scene; see Progress at the end).** Slice 5's skin scenes built 2026-11-27 (windows, menus, scroll bars, dock); slices 3, 4, 6 and 7 not started. Owner asked to see this before any Aqua ("Water") or Liquid Glass work starts.
**Branch:** new, from `main` at `0.15.0` (`feature/skins-gallery`).
**Master Plan Reference:** Skins theme the whole OS; Roadmap row "Skins" (open: Aqua, Liquid Glass, GTK/SwiftUI). Replaces the old backlog line "demo apps" for the skins.
**Companions:** `2026-11-20_AquaSkin.md`, `2026-11-20_LiquidGlassSkin.md`. Both skins need a backdrop and a forced-state view to be judged at all, which is half of this proposal.

## 1. Objective

A page that shows every theme, every component and every state, generated from the package so it cannot drift from the themes, and that opens in a browser with nothing to install. It is the place the owner looks at a skin, and the place a skin is judged against its reference before it is called done.

## 2. Motivation

**Current situation.** The three shipped skins have only ever been seen through a throwaway headless-Chrome harness in a scratchpad (`pm/m.html`), which nobody else can open and which is not in the repo. The only gallery in the repo is `swiss-gallery`, a macOS SwiftUI executable that draws the Swiss components and knows nothing of System 7, Platinum or OPENSTEP.

**Workarounds.** (a) Hand-written HTML per skin: drifts the day a recipe changes, and nothing compiles it. (b) Hovering and pressing real controls in a browser: states like pressed, inactive and disabled cannot be held, so most of what we measured on the live emulators cannot be looked at side by side with the result. (c) Reading CSS.

**Drawbacks.** No review artefact for the owner; every comparison against a live system is redone by hand; Aqua and Liquid Glass cannot be reviewed at all without a place to put them (Liquid Glass is meaningless without something behind it).

## 3. Proposed Architecture

The gallery is a **generated format**, like `gtk` or `icons`: one more `GeneratedFormat`, written by `design-tokens Generated`, compared with a fresh emit by a test.

**New files**
- `Sources/DesignTokens/Emitters/GalleryEmitter.swift`: builds the page and its data from `Theme.all` (Foundation only).
- `Sources/DesignTokens/Emitters/GalleryScenes.swift`: the scenes (see 3.2) as small typed values, not strings, so a test can enumerate them.
- `Tests/DesignTokensTests/GalleryEmitterTests.swift`.
- `scripts/gallery-shot.sh`: local headless-Chrome screenshots of the page (output is not committed; see 11).

**Modified files**
- `Generator.swift`: `GeneratedFormat.gallery`; writes `gallery/index.html`, `gallery/gallery.css`, `gallery/gallery.js`, and `gallery/states/<id>.css`.
- `ThemeCSSEmitter.swift`: an optional `forcedStates` mode (3.3). The default output is untouched.
- `README.md`, `CHANGELOG.md`, `master_plan.md` (housekeeping, last).

**Output layout** (under `Generated/`, links are relative, so it works from `file://` and from any static host):

```
Generated/gallery/index.html      the page
Generated/gallery/gallery.css     the page's own chrome only (never themed)
Generated/gallery/gallery.js      ~150 lines, no dependencies
Generated/gallery/states/<id>.css forced-state copies of a theme's rules (3.3)
Generated/components.css          linked as is
Generated/themes/<id>.css         linked as is (every theme is scoped by [data-theme-name], so all can be linked at once)
Generated/themes/<id>.icons/*.svg used as <img>
```

### 3.1 The page

A fixed frame (the gallery's own neutral chrome, never themed) with: a **theme switcher** (every theme in `Theme.all`; the skins first), **appearance** (system, light, dark; 3.4), **backdrop** (3.5), **scale** (1x, 2x, 3x: the pixel skins are drawn for whole scales and the page lets you see that), and a **state** switch (rest, or hold every control in one state: hover, pressed, focus, disabled, invalid, inactive window). The selected theme is set as `data-theme-name` on one stage element, so the page is the production CSS contract exercised for real, not a re-implementation of it. The choice is kept in the URL hash, so a link names a view.

### 3.2 The scenes, generated from the model

The page is not hand-authored. Two kinds of section, both enumerated from data:

1. **Role x state matrix** (one per theme with `surfaces`): a table of every `SurfaceRole` the theme defines against every `ComponentState` it defines, each cell a real element carrying the class the emitter writes for that role and the forced-state class for that state. A cell the theme does not define is shown as empty, so a gap is visible. A test asserts that every (role, state) in `SurfaceSet.recipes` appears exactly once.
2. **Composed scenes** (hand-written markup, a few lines each, parametrised only by class names): a window with title bar, scroll bars and content; an inactive window beside it; a menu bar with a dropdown held open and a lit row; a dock (where the theme has one) with its icons and labels; a form (buttons, default button, fields, check, select, segmented); and, for every theme, the existing `dt-` components (card, table, chip, banner, meter). The scenes use only classes the CSS emitters document, so a class the emitter stops writing makes the scene visibly unstyled and a test (3 in section 11) fail.

Themes without `surfaces` (Swiss, House, Console, and the rest) get the components scene only. They stay in the switcher because the gallery is also the way to see that `components.css` still works for every theme.

### 3.3 Forced states (the one real design decision)

A pressed button cannot be on screen at the same time as a rest button if the only selector is `:active`. Options:

- **A. Interactive only.** Cheap, and cannot show inactive, disabled-under-hover or the matrix.
- **B. Emit forced-state copies**: for each rule whose selector uses `:hover`, `:active`, `:focus-visible` or `:disabled`, a gallery-only copy with `.dt-force-hover`, `.dt-force-active`, `.dt-force-focus`, `.dt-force-disabled` added as an alternative selector. Written to `gallery/states/<id>.css`, loaded only by the gallery, so **production theme files stay byte-identical** (asserted by the existing golden tests, which must not change).
- **C. Rewrite the production selectors** to include the classes. Rejected: it changes every shipped file and every consumer pays.

**Recommendation: B.** It needs `ThemeCSSEmitter` to know the state-to-selector mapping it already has; the work is a second render of the same rules with an extra selector alternative, behind a flag that defaults off. Specificity must match the original (the forced copy must beat the rest rule the same way the pseudo-class does); a test checks that, per theme, forcing a state yields the same declaration block as the original rule for that state.

### 3.4 Light and dark

Theme files use `@media (prefers-color-scheme: dark)` and `prefers-contrast`; a page cannot force them from an attribute. The gallery's script walks `document.styleSheets` and rewrites the `mediaText` of those media rules (`(prefers-color-scheme: dark)` to `all` or `not all`) to force an appearance, and restores it for "system". This works on the CSSOM in Chrome, Safari and Firefox, needs no change to production CSS, and degrades to "follows the OS" if a sheet cannot be read (cross-origin on a hosted copy). It needs a spike in all three browsers before the page depends on it (Phase 1).

### 3.5 Backdrops

A desktop is part of a skin (System 7's checkerboard, Platinum's `#B3B3DA`, OPENSTEP's background). The gallery's backdrop control offers: **the skin's own desktop** (from the theme, where it has one), flat greys (the nine used for the Liquid Glass fit), a coloured gradient and a photo-like pattern (generated, so nothing is bundled). Aqua's pinstripe and translucent menus and all of Liquid Glass need this to be judged. The owner answered yes to capturing coloured and photo backdrops for the Liquid Glass fit; this is the page that shows them.

## 4. API Surface

```swift
public enum GeneratedFormat { /* existing */ case gallery }

public enum GalleryEmitter {
    /// The page, its script, its own stylesheet.
    public static func emit(themes: [Theme] = Theme.all) throws -> [GeneratedFile]
    /// Every (role, state) a theme's recipes define; what the matrix section must show.
    static func matrix(for theme: Theme) -> [(SurfaceRole, ComponentState)]
}

extension ThemeCSSEmitter {
    /// The same rules with `.dt-force-<state>` alternatives added to every state selector. Gallery only.
    public static func emitForcingStates(_ theme: Theme) throws -> String
}
```

`design-tokens emit --format gallery` is added through `GeneratedFormat`; no new command.

## 5. MCP Schema

Not applicable. (A later `list_skins` tool is conceivable; out of scope.)

## 6. Constraints & Compliance

- **No force unwraps, no suppressions**; Foundation only; Sendable; DocC on every public symbol; gate 0/0.
- **Original artwork only, no bundled fonts, no local pixel traces in the repo.** The gallery shows only what the emitters write plus generated backdrops. Reference captures stay in the scratchpad; the gallery never embeds them.
- **Auditors**: no `split(separator:"\n")` (use `.split(whereSeparator: \.isNewline)`), no weak `.contains` or `!= nil` assertions, no exact Double `==`, no double-backtick DocC links to private members.
- **Browser floor** Chrome 111, Edge 111, Safari 16.2, Firefox 113 for the page too. `gallery.js` is plain ES2020 with no modules, so `file://` works in all four.
- The page itself meets contrast and keyboard-operability on its own (neutral) chrome; the themed stage is what it is.

## 7. Source & API Compatibility

Purely additive: one enum case, one emitter, one extension method behind a flag. `GeneratedFormat` is `CaseIterable`, so switch statements over it in the package and its tests gain a case (the generator's `--format` error text lists the formats and must gain `gallery`; the earlier format additions did the same). No theme JSON changes. Every existing `Generated/` file is byte-identical, which the existing golden tests already prove.

## 8. Backend Abstraction

Not compute-intensive. Emission is string building over at most 13 themes.

## 9. Resource Budget

- **Page weight.** Linking every theme file is about 1.5 MB of CSS (Platinum 350 KB, OpenStep 236 KB, System 7 39 KB, the rest small) plus the forced-state copies (about the same again for the three skins). Acceptable for a local or static page; if a hosted copy needs it smaller, the script can add a theme's `<link>` on first use. Measured, not assumed, in Phase 1.
- **Generation time**: negligible next to the current `Generated` run (the pre-commit run is dominated by the test and gate).
- **Browser cost**: the matrix is a few hundred elements per theme; only the selected theme's stage is in the DOM.

## 10. Dependencies

None added. No JS libraries, no fonts, no images (backdrops are CSS gradients and patterns). `scripts/gallery-shot.sh` uses the Chrome already required by `check-blog`.

## 11. Test Strategy

Strict TDD, red then green, a commit per slice.

1. **Coverage:** for every theme with surfaces, every (role, state) in its recipes appears exactly once in the page, and no cell appears for a pair the theme does not define.
2. **Forcing:** for each skin, each forced class yields a declaration block equal to the block of the original rule it copies; the default `ThemeCSSEmitter.emit` output is unchanged (the existing goldens).
3. **Scene classes:** every class used in a scene is written by `ThemeCSSEmitter` or `ComponentsCSSEmitter` for the theme it is shown under, so renaming a class breaks a test, not the page.
4. **Golden:** `Generated/gallery/*` equals a fresh emit (the existing pattern).
5. **Links:** every `href` and `src` in the page resolves to a file the generator writes.
6. **Determinism:** two emits are byte-identical (no dates, no random ids).
7. **Browser, local, not in CI:** `scripts/gallery-shot.sh` screenshots each theme in light and dark at 1x and compares **against the previous run on the same machine** to catch a regression the string tests cannot (an unstyled scene). Live-system comparisons stay local; their traces are not committed.
8. **Manual matrix** before release: Chrome, Safari, Firefox, at 1x and 2x, light and dark, forced and system appearance. Recorded in the checklist, not claimed.

## 12. Architecture Decision Review

- A generated format keeps one source of truth and rides the existing golden-test discipline. The alternative of hand-written HTML in the repo is the thing this avoids.
- Forced states as a separate generated file (B) keeps production CSS untouched, at the price of a second render path that has to be kept equal to the first. Test 2 is what holds that line.
- The page switches `data-theme-name` rather than loading one theme at a time, which exercises the scoping contract consumers rely on.

## 13. Adversarial Review

- *The forced copy hides a bug the real pseudo-class has* (a specificity or ordering mistake only the real `:active` shows). Mitigation: the gallery keeps real interaction working on the same elements; test 2 compares blocks, and the manual matrix includes pressing for real.
- *The `mediaText` rewrite is fragile* across browsers. Mitigation: spike first; fallback is "follows the OS" with the toggle disabled and labelled.
- *The page flatters a skin* by showing only rows we built. Mitigation: the matrix shows gaps as empty cells, and the unmeasured list from `SkinMeasurements.md` is printed under each skin, so the page says what it does not know.
- *Scope creep into a design tool.* The page is read-only; no editing of themes.
- *Stale `Generated/gallery`*: the golden test fails.

## 14. Alternatives Considered

- **A SwiftUI app** (extend `swiss-gallery`): shows the SwiftUI path, but the skins are web and GTK today, it needs Xcode to run, and it cannot be handed to someone. Kept as a later companion once SwiftUI emits skins.
- **Hand-written static HTML**: drifts, rejected (section 2).
- **Screenshots in the repo**: stale on the first change, bulky, and would sit next to reference captures we must not commit. Rejected.
- **Hosting it (GitHub Pages or the owner's site)**: outward-facing, so the owner's call; the page is built to be hostable (relative links, no server) but nothing is published by this work.

## 15. Future Directions

SwiftUI and GTK galleries when those emitters carry skins; a side-by-side "reference vs ours" mode for skins whose reference may be stored privately by the owner; per-skin "unmeasured" ledger driven from `SkinMeasurements.md` instead of copied; animation controls when Aqua's `PulseSpec` lands; a scenes API a consumer can reuse in their own docs.

## 16. Open Questions

1. **Publish it?** Nothing leaves the machine under this proposal. If the owner wants a hosted copy, where, and is the Liquid Glass and Aqua naming (below) settled first?
2. **Is `Generated/gallery/` the right home**, or should it live outside `Generated/` (it is generated, but it is a viewer, not a consumable)? Recommendation: inside, so the golden test covers it with no new mechanism.
3. **Do the non-skin themes belong in the switcher?** Recommendation: yes, components scene only.
4. **Scale control**: 1x, 2x, 3x is what the pixel skins are specified for. Is 1.5x (a fractional scale, where `ScalePolicy.integer` should refuse to blur) worth showing as the "this is why" view? Recommendation: yes, labelled.
5. **Safari first for Liquid Glass.** The owner wants Safari as the better target for the glass work; the gallery's browser matrix should list Safari first. Safari does not accept SVG filters as a `backdrop-filter` input, which constrains the refraction demo; the Liquid Glass proposal needs that checked in Safari before it promises anything.

## 17. Documentation Strategy

DocC for `GalleryEmitter` and the new `GeneratedFormat` case; a README section "The skins gallery" (how to open `Generated/gallery/index.html`, what each control does, what it does not prove); CHANGELOG entry; `master_plan.md` Roadmap row struck through when shipped; `SkinMeasurements.md` links to the page for what each section looks like.

## Phased plan (commit slices, each red then green, gate 0/0)

1. **Spike (no commit of product code):** prove the `mediaText` appearance forcing in Chrome, Safari and Firefox; measure page weight with all themes linked.
2. **`GeneratedFormat.gallery` and an empty shell** that links every theme and switches `data-theme-name` (tests 4, 5, 6).
3. **Forced states** in `ThemeCSSEmitter` behind a flag (test 2) and `gallery/states/*.css`.
4. **Role x state matrix** (test 1), generated for the three skins.
5. **Composed scenes** (window, inactive window, menus, dock, form, components) (test 3).
6. **Backdrops, scale and appearance controls**, URL hash.
7. **`scripts/gallery-shot.sh`**, README, CHANGELOG, master plan, a handoff note. Then, and only then, the owner reviews the page before Water (Aqua) or Liquid Glass starts.

## Decisions, 2026-11-25 (owner)

1. All five open questions: **the recommendations stand** (the gallery lives in `Generated/gallery/`; the non-skin themes are in the switcher with the components scene only; 1.5x is shown as a labelled "why whole scales" view; nothing is published by this work). **Safari is first in the browser matrix** (section 11, item 8, and the Liquid Glass spike).
2. **Intended home: a top-line header entry on `www.justinpurnell.com`** (an Ignite static site), served as its own standalone page under a path such as `/skins/`, not inside the site's layout. Requirements this adds: relative links only; the CSS served from the same origin as the page (the appearance forcing in 3.4 reads the stylesheets, which a cross-origin host would block); no server, no build step on the site beyond copying `Generated/gallery/`. Publishing stays the owner's call.
3. **Isolation from the Princeton 2000 reunions site** (and every other consumer): none of them adopts this until it is well tested. So the work must not touch what they consume: no change to any existing `Generated/` file (the existing goldens prove it), no change to `Theme.princeton`, `components.css` or the public API except the additive `GeneratedFormat.gallery` case, and no new dependency. Reunions pins a tagged release; the gallery ships in a tag it does not have to take, and the adoption note in the release says so. The site on `justinpurnell.com` is the only adopter until the owner says otherwise.
4. **SwiftWASM** (owner asked 2026-11-25): a later, optional live mode, not the base. Same rule: it is a separate target that nothing else depends on, behind a spike that first proves the core builds for `wasm32` and measures the binary; installing the Swift Wasm SDK needs the owner's go-ahead.

## Spike results: SwiftWASM, 2026-11-25

Toolchain: swift.org Swift 6.4.3 through `swiftly` (the owner's default stays 6.4.1; every command selected `+6.4.3`) and `swift-6.4.3-RELEASE_wasm` (checksum verified). There is no 6.4.2 Wasm SDK. Work was done in a throwaway worktree on branch `spike/wasm` (nothing merged, nothing pushed); `main` was not touched.

| Question | Result |
|---|---|
| Does the core library build for `wasm32`? | **Yes, unmodified**, first try, debug and release (8.6 s and 40 s). All 63 source files, `import Foundation` and all. |
| Does it run, and is the output right? | **Yes.** A 12-line probe executable under Node's WASI emitted `ThemeCSSEmitter.emit` for **Platinum, System 7, OPENSTEP and Swiss, byte-identical** to the committed `Generated/themes/<id>.css` (312,552 / 15,915 / 143,760 / 13,837 bytes). Not yet run in a browser. |
| How big? | **Full Foundation is too heavy:** the probe is about 53 MB raw (`-Osize`, stripped) and **19.5 MB gzipped**. A 20-line Foundation program is 18.2 MB gzipped on its own, so almost all of it is Foundation's ICU internationalisation data, not our code. |
| Is that fixable? | **Very likely.** The same 20-line program on `FoundationEssentials` only is **3.5 MB gzipped (2.8 MB brotli)**. The core uses generic Foundation (JSON, `Data`, string replacement, `trimmingCharacters`, `range(of:)`); none of the locale, date or number formatting that needs ICU. Porting is mechanical (`#if canImport(FoundationEssentials)`, and stdlib `replacing(_:with:)` for `replacingOccurrences`) but touches up to 53 files and must keep the macOS output byte-identical; not attempted in the spike. |

**What this changes**
- SwiftWASM is **feasible, and the engine is already correct**: the browser would run the same emitter that produced the committed files.
- It is **not ready to ship as is** at 19.5 MB. Before any hosted use: port the core to `FoundationEssentials` on WebAssembly and re-measure (expected 3 to 6 MB gzipped), serve brotli, and load the module lazily behind the static gallery, which stays the first paint.
- The next spike steps: (1) ~~the `FoundationEssentials` port on a branch with the byte-identical comparison as the test~~ (done 2026-11-26, see below: 4.1 MB gzipped); (2) ~~a minimal browser page that loads the module and re-emits a theme in **Safari, then Chrome**, with iOS Safari memory checked~~ (done 2026-11-26: works in all three, see below; iPhone is slow, not memory-bound); (3) then, and only then, the standalone package below.

## Spike results: the FoundationEssentials port, 2026-11-26

Step 1 of the spike, done on the throwaway `spike/wasm` worktree. Nothing in `main` changed.

| Build | gzip | brotli q9 |
|---|---|---|
| Core on full Foundation (before) | 19.5 MB | not measured |
| Core on `FoundationEssentials`, debug and name sections left in | 5.95 MB | 4.89 MB |
| Same, custom sections stripped (what a release would ship) | **4.13 MB** | **3.33 MB** |

CSS from the ported module under Node WASI is **byte-identical** to `Generated/themes/<id>.css` for platinum, system7, openstep and swiss, and the stripped binary also emits identical output. The size was not a matter of Foundation APIs in the core alone; three things pulled ICU in, and only the first was obvious:

1. **SwiftPM's generated resource accessor.** `.copy("DesignTokens.docc")` on the core target makes SwiftPM emit a `resource_bundle_accessor.swift` that does `import Foundation` (for `Bundle`). Merely linking the core was enough to pull in all of Foundation: a program that only printed `DesignTokens.version` was 21.7 MB gzipped. That import also leaked `String` extensions into every file in the module, which is why the first port attempt compiled with nothing but a handful of maths errors. The fix is to stop declaring the catalogue as a resource (`exclude:` it, or let the docc plugin find it).
2. **Three `NSString`-bridged `String` APIs** that are not in `FoundationEssentials`: `replacingOccurrences(of:with:)` (9 files), `trimmingCharacters(in:)` (4) and `range(of:options:range:)` (`BlogCheck`, with `.caseInsensitive`). Each has a standard-library equivalent (`replacing(_:with:)`, scalar properties, `starts(with:)` scanning), gathered into one internal `TextHelpers.swift`.
3. **The maths functions** (`pow`, `cbrt`, `atan2`) come from the C library, not Foundation: `Colorimetry.swift` and `ColorAnalysis.swift` need a conditional `Darwin`/`Glibc`/`WASILibc` import. `CharacterSet.controlCharacters` becomes `generalCategory == .control`.

Also: the probe's own `main.swift` must not import `Foundation` either (it did, for `FileHandle`; that alone kept ICU linked).

What it means for the real port (a later slice, TDD, not done here): about 17 call sites in 8 files plus a helper file and two conditional imports, and the macOS and Linux suites stay as the oracle, with a new test that the helpers match Foundation's on the inputs the core uses (empty strings, Unicode spaces, case folding, overlapping needles). The `exclude:` change needs a check that DocC still builds the catalogue. The 4.1 MB figure is before `wasm-opt -Oz`, which usually takes a further 10 to 25 percent off code; not tried.

## Spike results: in the browser, 2026-11-26

Step 2 of the spike. The stripped 14.3 MB module (4.1 MB gzipped) was loaded by a static page through `@bjorn3/browser_wasi_shim` 0.4.2 (no JavaScriptKit needed for this: the module is a WASI command that writes CSS to stdout). The page captures stdout as raw bytes and compares them with the committed `Generated/themes/<id>.css`. Served over plain HTTP, uncompressed.

| Browser | Platinum (312,552 bytes) | Swiss (13,837 bytes) | Compile | Fetch |
|---|---|---|---|---|
| Chrome 157, headless, Mac | identical, 90 ms | identical, 4 ms | 18 ms | 17 ms |
| Chrome 157, windowed, Mac | identical, 94 ms | identical, 3 ms | 22 ms | 53 ms |
| Safari 27.2, Mac | identical, 127 ms | identical, 7 ms | 52 ms | 28 ms |
| Safari 27.3, iPhone (iOS 18.7) | identical, **2,727 ms** | identical, 74 ms | 97 ms | **6,005 ms** |

Every run exited 0 and was byte-identical. Wasm memory after a run was 4.6 MB (Platinum) and 2.9 MB (Swiss), so memory is not the constraint on iOS.

What the numbers say:

- **It works in Safari first, as wanted**, on Mac and on iPhone, from one binary.
- **The phone is the constraint, and it is time, not memory.** Emitting the 312 KB Platinum stylesheet took 2.7 s on the iPhone against about 0.1 s on a Mac (roughly 30 times slower; Swiss, 14 KB, took 74 ms). The fetch took 6 s for 14 MB over local Wi-Fi from a one-file Python server with no compression. Both are fixed by design rather than by tuning: serve brotli (about 3.3 MB), and keep the static gallery as first paint so the module loads lazily behind it. Re-emitting a whole theme on a phone should be a rare, explicit action (a "re-generate" button), not part of page load.
- Compile times are warm-cache figures (the same file was loaded just before on each desktop browser); the iPhone figure is its first load.
- **Not measured:** a cold compile on a slow connection; iOS 26 (the phone was on 18.7); peak memory under memory pressure with other tabs open; `wasm-opt`.

Method note: Safari could not be driven by `safaridriver` (remote automation was not enabled and needs an admin step), so Safari and iOS were opened by hand and the page posted its result to a local server. The throwaway worktree, page and server are deleted; the helper design is described in the FoundationEssentials section above.

## Standalone package (owner, 2026-11-25)

Whatever is built in SwiftWASM is a **separate, reusable package** (working name `DesignTokensWeb`, a sibling directory, not nested), depending on DesignTokens by tag and following the development guidelines (its own proposal first, strict TDD, gate 0/0). Layers: a pure-Swift core (model and theme-apply service, built and tested on macOS and Linux) under a thin WASM/DOM target. It serves two clients: this gallery's live mode, and, later, theming the whole `justinpurnell.com` Ignite site. DesignTokens itself gains no dependency and changes no public API for it. Its proposal is written after the next spike steps above, so it rests on measured facts.

## Progress, 2026-11-27 (owner asked for the first slice)

Built slice 2 of the phased plan: `GalleryEmitter` and `GeneratedFormat.gallery` write `Generated/gallery/{index.html,gallery.css,gallery.js}`. It links every theme and `components.css`, switches `data-theme-name` on one stage, keeps the choice in the URL hash, and shows one components scene. Tests (`GalleryEmitterTests`, 13) cover the file set, determinism, that every relative link resolves to a generated file, one link per theme, switcher order, name escaping, refusal of a non-slug id, that every `dt-` class in the scene is one `components.css` writes (test 3 of section 11), no network references or modules, a neutral chrome, and the hash. The existing golden test and file-set test include the new files. No existing `Generated/` file changed.

Seen in headless Chrome 158 (Swiss, Platinum, System 7): the switcher selects by hash and the shared components take each theme's tokens. **Platinum and System 7 look like themed forms, not like their operating systems yet**: the window, menu and dock scenes are slices 4 and 5.

Not done: slice 1's spike (the `mediaText` appearance forcing in Chrome, Safari and Firefox) was not run, so there is no appearance control yet; Safari and Firefox have not opened the page; page weight with every theme linked has not been measured.

### Progress, 2026-11-27 (later): the skin scenes (part of slice 5)

`GalleryScenes.skinScene(for:)` builds, per skin, an active and an inactive window (title bar, vertical and horizontal scroll bars), a menu bar with an open menu (selected, disabled, separator) and a dock, **only where the theme defines the part and its own stylesheet styles the class**. Tests check every `dt-` class against the skin's stylesheet, that each part follows the model, that every control a theme places appears iff it is styled, and the menu states. Findings from building it: a theme can have a menu bar and no menu column (System 7) or the reverse (OPENSTEP), and System 7 defines no title bar or scroll bars, so its scene is its menu bar alone; OPENSTEP's inactive window looks the same as its active one and Platinum's inactive scroll bars still draw a lit thumb (the emitter's `aria-disabled` on a bar means "nothing to scroll", not "inactive window"), both unmodelled, not fixed here. Seen in headless Chrome 158: Platinum reads as Mac OS 8. Still not built: forced states (slice 3), the role-by-state matrix (slice 4), backdrops, scale and appearance controls (slice 6), the screenshot script (slice 7).
