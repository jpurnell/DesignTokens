/// The design system's values, held once as typed Swift.
///
/// `DesignTokens` defines the colour roles, the chart palette (validated for adjacency and colour-vision separation), rule weights, grid and radii
/// that every surface of the portfolio shares, and emits them as CSS and JSON for the surfaces that
/// cannot import Swift. Apple platforms keep deferring to the system's own colours; the values here
/// are a labelled snapshot for the places the system cannot reach (web, SVG, slides, spreadsheets).
///
/// The package is Foundation-only and builds on macOS, iOS, visionOS and Linux. It holds data, not
/// `Color` values: a resolver on each surface maps the data to that surface's native type.
public enum DesignTokens {}
