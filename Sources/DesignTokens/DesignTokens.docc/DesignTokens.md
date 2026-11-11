# ``DesignTokens``

The design system's values, held once as typed Swift and generated for the surfaces that cannot import Swift.

## Overview

``ColorToken`` names the colour roles, ``Palette`` holds the chart colours (validated for adjacency and colour-vision separation; see ``SwissLedger`` for the slots that fail the lightness band), and ``Rule``,
``Grid`` and ``Radius`` hold the structural metrics. ``CSSEmitter`` and ``JSONEmitter`` turn them into
files; the `design-tokens` executable writes those files into `Generated/`.

System colours here are a snapshot (``Snapshot/systemRelease``). Apple platforms should defer to the
system's own colours and use these values only where the system cannot reach.

## Browser support

The CSS the package emits needs Chrome 111, Edge 111, Safari 16.2 or Firefox 113, and provides no fallbacks; ``BrowserSupport`` lists each feature with its first versions and where it is used, and ``BrowserSupport/Breakpoints`` the size thresholds (a 600 px table stack, a 30 rem key and value stack, 88-base-unit cards). The 600 px breakpoint cannot be a custom property, so an app writing its own responsive rules uses ``BrowserSupport/Breakpoints/narrowMediaQuery``. Since 0.13.0 `components.css` also has a page shell with a sticky navigation column, `dt-prose` for rendered Markdown, `mark`, item meta and columns, banners that hold paragraphs and links, and verified hover, focus, forced-colour and increased-contrast states; for the FleetWatch adoption a usage meter, a page header, a disclosure, form helpers, a light plate, banner actions and long-value modifiers (the class list is in ``ComponentsCSSEmitter``).

## Topics

### Colour

- ``ColorToken``
- ``Appearance``
- ``Palette``
- ``RGB``

### Structure

- ``Rule``
- ``Grid``
- ``Radius``

### Themes

- ``Theme``
- ``Structure``
- ``ThemePalette``
- ``AppPalette``
- ``AppPaletteSource``
- ``AppPaletteConformance``
- ``LabelRequirement``
- ``ChartRuleViolation``
- ``Adaptive``
- ``ColorValue``
- ``ThemeCodec``
- ``ThemeError``
- ``Theme/all``
- ``SwissLedger``

### Validation

- ``ThemeValidator``
- ``ValidationThresholds``
- ``ValidationInputError``
- ``Finding``
- ``Conformance``
- ``Check``
- ``Severity``
- ``ValidationAppearance``
- ``SeriesMeasurement``
- ``RampMeasurement``

### Colour references and ramps

- ``Ramp``
- ``ColourReference``
- ``AppearanceSupport``
- ``SystemColorName``

### Generated files

- ``CSSEmitter``
- ``JSONEmitter``
- ``ThemeCSSEmitter``
- ``ThemeJSONEmitter``
- ``ComponentsCSSEmitter``
- ``BrowserSupport``
- ``CardChrome``
- ``Generator``
- ``GeneratedFile``
- ``Snapshot``
