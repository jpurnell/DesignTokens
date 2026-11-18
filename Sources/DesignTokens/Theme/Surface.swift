import Foundation

// MARK: - Errors

/// Why a surface description was refused.
public enum SurfaceError: Error, Sendable, Hashable {
    /// An edge step's width is zero, negative or not a number.
    case width(Double)
    /// A recipe with an integer scale policy has an edge step whose width is not a whole number of logical pixels.
    case fractionalWidth(Double)
    /// A pattern's cell count is not its width times its height.
    case cellCount(expected: Int, got: Int)
    /// A pattern's width or height is outside 1 to 16.
    case cellSize(Int)
    /// A gradient has fewer than two stops.
    case stopCount(Int)
    /// A gradient's stop positions decrease.
    case stopOrder
    /// A gradient stop's position is outside 0 to 1, or not a number.
    case stopPosition(Double)
    /// A gradient's angle is not a finite number.
    case angle(Double)
}

// MARK: - Edges

/// One stripe of an edge, drawn from the outside in. Widths are logical pixels (CSS pixels, points): a skin whose edges are one pixel
/// wide stays one logical pixel at any scale, which is why this is not a multiple of the base unit. At an integer scale that is a whole
/// number of device pixels; ``ScalePolicy`` says what happens at a fractional one.
public struct EdgeStep: Sendable, Hashable, Codable {
    /// The stripe's colour, a role or an `extras` key.
    public var colour: ColourReference
    /// The stripe's width in logical pixels, greater than zero.
    public var width: Double

    /// Creates a step; throws ``SurfaceError/width(_:)`` when `width` is not greater than zero.
    public init(colour: ColourReference, width: Double) throws {
        guard width.isFinite, width > 0 else { throw SurfaceError.width(width) }
        self.colour = colour
        self.width = width
    }

    private enum CodingKeys: String, CodingKey { case colour, width }

    /// Decodes a step, applying the same check as the initialiser.
    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(colour: c.decode(ColourReference.self, forKey: .colour), width: c.decode(Double.self, forKey: .width))
    }
}

/// What is drawn along each side of a surface, as ordered stripes from the outside in.
///
/// A one-pixel outline is a single step on every side. A bevel is different stripes on opposite sides: a Mac OS 8 button is top and leading
/// `000000, DDDDDD, FFFFFF` and bottom and trailing `000000, 777777, AAAAAA` (outside in), as measured in `SkinMeasurements.md`.
public struct Edges: Sendable, Hashable, Codable {
    /// The top edge's stripes, outside in.
    public var top: [EdgeStep]
    /// The leading edge's stripes, outside in.
    public var leading: [EdgeStep]
    /// The bottom edge's stripes, outside in.
    public var bottom: [EdgeStep]
    /// The trailing edge's stripes, outside in.
    public var trailing: [EdgeStep]

    /// Creates edges.
    public init(top: [EdgeStep], leading: [EdgeStep], bottom: [EdgeStep], trailing: [EdgeStep]) {
        self.top = top
        self.leading = leading
        self.bottom = bottom
        self.trailing = trailing
    }
}

// MARK: - Patterns and gradients

/// A small repeating cell of logical pixels, such as System 7's two-by-two checkerboard or Aqua's one-by-four pinstripe.
public struct PatternSpec: Sendable, Hashable, Codable {
    /// Cell width in logical pixels, 1 to 16.
    public var width: Int
    /// Cell height in logical pixels, 1 to 16.
    public var height: Int
    /// The cell's pixels, row by row; `width * height` colours.
    public var cells: [ColourReference]

    /// Creates a pattern; throws ``SurfaceError/cellSize(_:)`` or ``SurfaceError/cellCount(expected:got:)``.
    public init(width: Int, height: Int, cells: [ColourReference]) throws {
        guard (1...16).contains(width) else { throw SurfaceError.cellSize(width) }
        guard (1...16).contains(height) else { throw SurfaceError.cellSize(height) }
        guard cells.count == width * height else { throw SurfaceError.cellCount(expected: width * height, got: cells.count) }
        self.width = width
        self.height = height
        self.cells = cells
    }

    private enum CodingKeys: String, CodingKey { case width, height, cells }

    /// Decodes a pattern, applying the same checks as the initialiser.
    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(width: c.decode(Int.self, forKey: .width), height: c.decode(Int.self, forKey: .height),
                      cells: c.decode([ColourReference].self, forKey: .cells))
    }
}

/// One colour stop of a gradient.
public struct GradientStop: Sendable, Hashable, Codable {
    /// The stop's colour.
    public var colour: ColourReference
    /// Where along the gradient, 0 to 1. Two stops at one position make a hard step.
    public var position: Double

    /// Creates a stop.
    public init(colour: ColourReference, position: Double) {
        self.colour = colour
        self.position = position
    }
}

/// A gradient. Aqua's gel is two bands with a hard step at the middle, so equal positions are allowed.
public struct GradientSpec: Sendable, Hashable, Codable {
    /// Linear or radial.
    public enum Kind: String, Sendable, Hashable, Codable, CaseIterable {
        /// A straight gradient along ``angleDegrees``.
        case linear
        /// A gradient outward from the centre.
        case radial
    }

    /// The kind.
    public var kind: Kind
    /// The angle in CSS degrees (180 runs top to bottom); ignored for radial.
    public var angleDegrees: Double
    /// At least two stops with non-decreasing positions in 0 to 1.
    public var stops: [GradientStop]

    /// Creates a gradient; throws ``SurfaceError/stopCount(_:)``, ``SurfaceError/stopPosition(_:)`` or ``SurfaceError/stopOrder``.
    public init(kind: Kind = .linear, angleDegrees: Double, stops: [GradientStop]) throws {
        guard angleDegrees.isFinite else { throw SurfaceError.angle(angleDegrees) }
        guard stops.count >= 2 else { throw SurfaceError.stopCount(stops.count) }
        var previous = 0.0
        for stop in stops {
            guard stop.position.isFinite, (0...1).contains(stop.position) else { throw SurfaceError.stopPosition(stop.position) }
            guard stop.position >= previous else { throw SurfaceError.stopOrder }
            previous = stop.position
        }
        self.kind = kind
        self.angleDegrees = angleDegrees
        self.stops = stops
    }

    private enum CodingKeys: String, CodingKey { case kind, angleDegrees, stops }

    /// Decodes a gradient, applying the same checks as the initialiser.
    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(kind: c.decode(Kind.self, forKey: .kind), angleDegrees: c.decode(Double.self, forKey: .angleDegrees),
                      stops: c.decode([GradientStop].self, forKey: .stops))
    }
}

// MARK: - Recipes

/// A shadow in a surface's stack: outer or inset, with a spread.
public struct ShadowLayer: Sendable, Hashable, Codable {
    /// Colour, blur and offset.
    public var shadow: ShadowSpec
    /// Whether it is drawn inside the surface.
    public var inset: Bool
    /// How far the shadow grows before blurring, in points.
    public var spread: Double

    /// Creates a shadow layer.
    public init(shadow: ShadowSpec, inset: Bool = false, spread: Double = 0) {
        self.shadow = shadow
        self.inset = inset
        self.spread = spread
    }
}

/// One layer of a surface, painted bottom to top.
public enum SurfaceLayer: Sendable, Hashable, Codable {
    /// A flat colour.
    case fill(ColourReference)
    /// A gradient.
    case gradient(GradientSpec)
    /// A repeating pixel pattern.
    case pattern(PatternSpec)
    /// A shadow, outer or inset.
    case shadow(ShadowLayer)
}

/// How a surface's corners are rounded.
public enum CornerRadius: Sendable, Hashable, Codable {
    /// The same radius on every corner, in points.
    case uniform(Double)
    /// Half the height: a pill.
    case capsule
}

/// How a surface behaves when the display's scale is not a whole number.
///
/// A pixel skin (System 7's one-pixel outlines and two-by-two checkerboard) is drawn on a grid of logical pixels. At 1x, 2x or 3x that grid
/// maps to whole device pixels and stays crisp. At 1.25x or 1.5x it would blur or beat against the display, so such a skin asks for the
/// nearest whole scale instead and the renderer fits the result to the window.
public enum ScalePolicy: String, Sendable, Hashable, Codable, CaseIterable {
    /// Any scale: smooth skins (Aqua, glass) and ordinary themes.
    case free
    /// Only whole scales of at least 1, drawn with nearest-neighbour sampling: pixel skins.
    case integer

    /// The scale to draw at for a requested display scale: the request for ``free``, its nearest whole number (never below 1) for
    /// ``integer``. A scale that is not a finite number is 1.
    public func effectiveScale(for requested: Double) -> Double {
        guard requested.isFinite else { return 1 }
        switch self {
        case .free: return requested
        case .integer: return max(1, requested.rounded())
        }
    }
}

/// How one control looks in one state: layers, edges, corners, blur and the ink drawn on it. Toolkit-neutral; an emitter turns it into CSS
/// (``SurfaceCSS``) or another target's syntax.
public struct SurfaceRecipe: Sendable, Hashable, Codable {
    /// The layers, bottom to top.
    public var layers: [SurfaceLayer]
    /// Per-side stripes, or `nil` for none.
    public var edges: Edges?
    /// The corner radius.
    public var radius: CornerRadius
    /// Backdrop blur as a Gaussian sigma in CSS pixels, or `nil`. A target without backdrop blur drops it and records that in the ledger.
    public var backdropBlur: Double?
    /// The colour of text drawn on this surface.
    public var ink: ColourReference
    /// How the surface is drawn at a scale that is not a whole number; see ``ScalePolicy``.
    public var scale: ScalePolicy

    /// Creates a recipe.
    public init(layers: [SurfaceLayer], edges: Edges?, radius: CornerRadius, backdropBlur: Double?, ink: ColourReference, scale: ScalePolicy) {
        self.layers = layers
        self.edges = edges
        self.radius = radius
        self.backdropBlur = backdropBlur
        self.ink = ink
        self.scale = scale
    }

    /// Throws ``SurfaceError/fractionalWidth(_:)`` when the recipe is pixel-snapped and an edge step is not a whole number of pixels.
    public func validate() throws {
        guard scale == .integer, let edges else { return }
        for step in edges.top + edges.leading + edges.bottom + edges.trailing where step.width.rounded() != step.width {
            throw SurfaceError.fractionalWidth(step.width)
        }
    }
}

/// A part of the interface that a theme may give its own surface.
public enum SurfaceRole: String, Sendable, Hashable, Codable, CaseIterable {
    /// A window or page background.
    case window
    /// A panel or card.
    case panel
    /// A push button.
    case button
    /// The default button of a dialog.
    case buttonDefault
    /// A text field.
    case field
    /// A menu or popover.
    case menu
    /// A scrollbar track.
    case scrollTrack
    /// A scrollbar thumb.
    case scrollThumb
    /// A selected row or run of text.
    case selection
}

/// A state a control can be in.
public enum ComponentState: String, Sendable, Hashable, Codable, CaseIterable {
    /// Idle.
    case rest
    /// Pointer over.
    case hover
    /// Pressed.
    case active
    /// Pressed with the pointer over.
    case activeHover
    /// Keyboard focus.
    case focus
    /// Keyboard focus with the pointer over.
    case focusHover
    /// Waiting for a result.
    case loading
    /// A disclosure that is open.
    case open
    /// A disclosure that is closed.
    case closed
    /// Not available.
    case disabled
    /// Holding a value that is refused.
    case invalid
}

/// The surfaces a theme gives its controls. A role or state a theme leaves out keeps today's output: a state inherits `rest`, and a role
/// with no recipe is drawn by the existing components stylesheet.
public struct SurfaceSet: Sendable, Hashable, Codable {
    /// Recipes by role and state.
    public var recipes: [SurfaceRole: [ComponentState: SurfaceRecipe]]

    /// Creates a set.
    public init(recipes: [SurfaceRole: [ComponentState: SurfaceRecipe]]) {
        self.recipes = recipes
    }

    /// The recipe for a role in a state, falling back to its `rest` recipe; `nil` when the role has none.
    public func recipe(for role: SurfaceRole, in state: ComponentState) -> SurfaceRecipe? {
        recipes[role]?[state] ?? recipes[role]?[.rest]
    }
}

// MARK: - CSS

/// Turns a ``SurfaceRecipe`` into CSS declarations.
public enum SurfaceCSS {
    /// A number as CSS writes it: `12` for a whole value, `12.5` otherwise. Int(exactly:) is nil for a fraction, NaN and infinity, so
    /// those fall through to the decimal form instead of trapping.
    static func number(_ value: Double) -> String {
        if let whole = Int(exactly: value) { return String(whole) }
        return String(value)
    }

    /// A number of CSS pixels: `1px`, `0.5px`, or `0` for zero.
    static func px(_ value: Double) -> String {
        if value == 0 { return "0" }
        return "\(number(value))px"
    }

    /// The CSS for a gradient; stops keep their positions, so equal positions stay a hard step.
    public static func gradient(_ spec: GradientSpec, resolve: (ColourReference) -> String) -> String {
        let stops = spec.stops.map { stop -> String in
            let percent = (stop.position * 100 * 1000).rounded() / 1000
            return "\(resolve(stop.colour)) \(number(percent))%"
        }.joined(separator: ", ")
        switch spec.kind {
        case .linear: return "linear-gradient(\(number(spec.angleDegrees))deg, \(stops))"
        case .radial: return "radial-gradient(circle, \(stops))"
        }
    }

    /// The CSS `url(...)` of a crisp SVG tile for a pattern. The resolver must return literal colours (hex), not `var(...)`.
    public static func pattern(_ spec: PatternSpec, resolve: (ColourReference) -> String) -> String {
        var rects = ""
        for (index, cell) in spec.cells.enumerated() {
            let x = index % spec.width, y = index / spec.width
            rects += "<rect x='\(x)' y='\(y)' width='1' height='1' fill='\(resolve(cell))'/>"
        }
        let svg = "<svg xmlns='http://www.w3.org/2000/svg' width='\(spec.width)' height='\(spec.height)' shape-rendering='crispEdges'>\(rects)</svg>"
        let encoded = svg.replacingOccurrences(of: "%", with: "%25").replacingOccurrences(of: "<", with: "%3C")
            .replacingOccurrences(of: ">", with: "%3E").replacingOccurrences(of: "#", with: "%23").replacingOccurrences(of: "=", with: "%3D")
        return "url(\"data:image/svg+xml,\(encoded)\")"
    }

    /// The CSS declarations for a recipe, one `property: value` string each, without the trailing semicolon.
    ///
    /// Edge stripes become a list of `inset` box-shadows with no blur: step `k` of every side is listed before step `k + 1`, so outlines
    /// cover the corners and an inner highlight never overpaints an outline. A stripe at cumulative depth `d` is `inset 0 d 0 0` on the top
    /// edge, `inset d 0 0 0` on the leading edge, `inset 0 -d 0 0` on the bottom and `inset -d 0 0 0` on the trailing edge.
    public static func declarations(for recipe: SurfaceRecipe, resolve: (ColourReference) -> String) -> [String] {
        var lines: [String] = []
        var images: [String] = []
        var sizes: [String] = []
        var shadows: [String] = []
        var hasPattern = false
        var baseFill: String?

        for (index, layer) in recipe.layers.enumerated() {
            switch layer {
            case .fill(let colour):
                if index == 0 { baseFill = resolve(colour) } else { images.append("linear-gradient(\(resolve(colour)), \(resolve(colour)))"); sizes.append("auto") }
            case .gradient(let spec):
                images.append(gradient(spec, resolve: resolve)); sizes.append("auto")
            case .pattern(let spec):
                images.append(pattern(spec, resolve: resolve)); sizes.append("\(spec.width)px \(spec.height)px"); hasPattern = true
            case .shadow(let layer):
                let spec = layer.shadow
                shadows.append("\(layer.inset ? "inset " : "")\(px(spec.x)) \(px(spec.y)) \(px(spec.radius)) \(px(layer.spread)) \(resolve(spec.colour))")
            }
        }

        if let edges = recipe.edges {
            let sides: [[EdgeStep]] = [edges.top, edges.leading, edges.bottom, edges.trailing]
            var depths = [Double](repeating: 0, count: 4)
            var edgeShadows: [String] = []
            for step in 0..<(sides.map(\.count).max() ?? 0) {
                for (side, steps) in sides.enumerated() where step < steps.count {
                    depths[side] += steps[step].width
                    let d = depths[side]
                    let offsets: [(Double, Double)] = [(0, d), (d, 0), (0, -d), (-d, 0)]
                    edgeShadows.append("inset \(px(offsets[side].0)) \(px(offsets[side].1)) 0 0 \(resolve(steps[step].colour))")
                }
            }
            shadows = edgeShadows + shadows
        }

        if let baseFill { lines.append("background-color: \(baseFill)") }
        if !images.isEmpty { lines.append("background-image: \(images.reversed().joined(separator: ", "))") }
        if hasPattern { lines.append("background-size: \(sizes.reversed().joined(separator: ", "))"); lines.append("image-rendering: pixelated") }
        if !shadows.isEmpty { lines.append("box-shadow: \(shadows.joined(separator: ", "))") }
        switch recipe.radius {
        case .uniform(let value): lines.append("border-radius: \(px(value))")
        case .capsule: lines.append("border-radius: 9999px")
        }
        if let blur = recipe.backdropBlur {
            lines.append("backdrop-filter: blur(\(px(blur)))")
            lines.append("-webkit-backdrop-filter: blur(\(px(blur)))")
        }
        lines.append("color: \(resolve(recipe.ink))")
        return lines
    }
}
