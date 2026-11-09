# ``DesignTokens``

The design system's values, held once as typed Swift and generated for the surfaces that cannot import Swift.

## Overview

``ColorToken`` names the colour roles, ``Palette`` holds the chart colours (validated for adjacency and colour-vision separation; see ``SwissLedger`` for the slots that fail the lightness band), and ``Rule``,
``Grid`` and ``Radius`` hold the structural metrics. ``CSSEmitter`` and ``JSONEmitter`` turn them into
files; the `design-tokens` executable writes those files into `Generated/`.

System colours here are a snapshot (``Snapshot/systemRelease``). Apple platforms should defer to the
system's own colours and use these values only where the system cannot reach.

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
- ``Generator``
- ``GeneratedFile``
- ``Snapshot``
