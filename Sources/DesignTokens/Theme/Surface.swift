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

    /// A step written as a literal in source, without the check: ``SurfaceRecipe/validate()`` repeats it, and every registered theme is
    /// validated by the tests, so a bad literal fails there instead of trapping here.
    init(literal colour: ColourReference, _ width: Double) {
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
    /// Which pair of sides owns a corner pixel where a light side meets a dark one, or `nil` for the default, ``EdgeStacking/topLeadingFirst``.
    /// Optional in JSON; absent means `nil`.
    public var stacking: EdgeStacking?

    /// Creates edges.
    public init(top: [EdgeStep], leading: [EdgeStep], bottom: [EdgeStep], trailing: [EdgeStep], stacking: EdgeStacking? = nil) {
        self.top = top
        self.leading = leading
        self.bottom = bottom
        self.trailing = trailing
        self.stacking = stacking
    }
}

extension Edges {
    /// The edges of the same surface turned a quarter about its diagonal: the top becomes the leading side and the bottom the trailing side,
    /// so a horizontal scroll bar's light top-left bevel is a vertical bar's light top-left bevel.
    var transposed: Edges {
        Edges(top: leading, leading: top, bottom: trailing, trailing: bottom, stacking: stacking)
    }
}

extension PatternSpec {
    /// The tile reflected about its diagonal (rows become columns).
    var transposed: PatternSpec {
        var out: [ColourReference] = []
        out.reserveCapacity(cells.count)
        for x in 0..<width { for y in 0..<height { out.append(cells[y * width + x]) } }
        return PatternSpec(literal: height, width, out)
    }
}

extension SurfaceRecipe {
    /// This recipe reflected about its diagonal: edges and pattern tiles are transposed; a fill is unchanged.
    var transposed: SurfaceRecipe {
        let layers = layers.map { layer -> SurfaceLayer in
            switch layer {
            case .pattern(let tile): return .pattern(tile.transposed)
            case .shadow(var shadow):
                shadow.shadow = ShadowSpec(colour: shadow.shadow.colour, radius: shadow.shadow.radius, x: shadow.shadow.y, y: shadow.shadow.x)
                return .shadow(shadow)
            case .fill, .gradient: return layer
            }
        }
        return SurfaceRecipe(layers: layers, edges: edges?.transposed, radius: radius, backdropBlur: backdropBlur, ink: ink, scale: scale)
    }
}

/// Which sides of a recipe's edges are painted first, and so own the pixel where two sides meet in a corner.
///
/// A stripe is a box shadow, and the first shadow listed is on top. Where a top stripe and a trailing stripe overlap at the top-right
/// corner, the side listed first shows. The Macintosh skins' corners are mitred by their own drawing and read the same either way, but
/// OPENSTEP's dark bottom and right edges own the top-right and bottom-left corners of a button.
public enum EdgeStacking: String, Sendable, Hashable, Codable {
    /// Top, leading, bottom, trailing (the default).
    case topLeadingFirst
    /// Bottom, trailing, top, leading.
    case bottomTrailingFirst
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

    /// A pattern written as a literal in source, without the checks (see ``EdgeStep/init(literal:_:)``).
    init(literal width: Int, _ height: Int, _ cells: [ColourReference]) {
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

    /// A linear gradient written as a literal in source, without the checks (see ``EdgeStep/init(literal:_:)``).
    init(literalAngle angleDegrees: Double, _ stops: [GradientStop]) {
        self.kind = .linear
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

    /// How far the edge stripes reach in from the box, in pixels: the deepest side, 0 when there are none.
    public var edgeDepth: Double {
        guard let edges else { return 0 }
        return [edges.top, edges.leading, edges.bottom, edges.trailing].map { $0.reduce(0) { $0 + $1.width } }.max() ?? 0
    }

    /// Every colour the recipe names: layers, edge steps and ink.
    var colourReferences: [ColourReference] {
        var references: [ColourReference] = [ink]
        for layer in layers {
            switch layer {
            case .fill(let colour): references.append(colour)
            case .gradient(let spec): references += spec.stops.map(\.colour)
            case .pattern(let spec): references += spec.cells
            case .shadow(let layer): references.append(layer.shadow.colour)
            }
        }
        if let edges { references += (edges.top + edges.leading + edges.bottom + edges.trailing).map(\.colour) }
        return references
    }

    /// Throws ``SurfaceError/fractionalWidth(_:)`` when the recipe is pixel-snapped and an edge step is not a whole number of pixels.
    public func validate() throws {
        for case .pattern(let spec) in layers {
            guard (1...16).contains(spec.width), (1...16).contains(spec.height) else { throw SurfaceError.cellSize(spec.width) }
            guard spec.cells.count == spec.width * spec.height else {
                throw SurfaceError.cellCount(expected: spec.width * spec.height, got: spec.cells.count)
            }
        }
        guard let edges else { return }
        let steps = edges.top + edges.leading + edges.bottom + edges.trailing
        for step in steps where !(step.width.isFinite && step.width > 0) { throw SurfaceError.width(step.width) }
        guard scale == .integer else { return }
        for step in steps where step.width.rounded() != step.width { throw SurfaceError.fractionalWidth(step.width) }
    }
}

/// A part of the interface that a theme may give its own surface.
public enum SurfaceRole: String, Sendable, Hashable, Codable, CaseIterable {
    /// The surface behind every window: System 7's checkerboard. On the web, the themed element itself.
    case desktop
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
    /// A menu or popover: the column that holds a menu's title and rows.
    case menu
    /// The bar of menu titles across the top of the screen.
    case menuBar
    /// A menu's title row (OPENSTEP's black one). The highlighted state is `hover`.
    case menuTitle
    /// A row of a menu, or a title in the menu bar. The highlighted one (`aria-selected="true"`) is the `hover` state.
    case menuItem
    /// The arrow on a menu row that opens a submenu, a small tile drawn whole (`rest` on a row at rest, `hover` on the lit row).
    case menuArrow
    /// A tile of the dock (NeXT's application icons and the trash): the frame and the ground behind an icon.
    case dockTile
    /// A scroll bar as a whole: what lies behind the arrows and the track (NeXT's outlined grey strip). Authored for a horizontal bar; a
    /// vertical one is its transpose, as are the other scroll roles.
    case scrollBar
    /// The scroll bar's track, the strip the thumb slides in.
    case scrollTrack
    /// A scrollbar thumb (authored for a horizontal bar).
    case scrollThumb
    /// The mark on a thumb's middle, a small tile drawn whole (Platinum's grooves).
    case scrollGrip
    /// The arrow button at a scrollbar's start (left, or up when vertical): a whole tile, bevel and arrow together.
    case scrollArrowStart
    /// The arrow button at a scrollbar's end (right, or down when vertical).
    case scrollArrowEnd
    /// A selected row or run of text.
    case selection
    /// A window's title bar: the bar behind the title and the window controls.
    case titleBar
    /// The stripes (or other texture) that fill a title bar between the controls and the title.
    case titleStripes
    /// A window control: the close box, at rest.
    case windowBox
    /// The zoom box, at rest.
    case windowBoxZoom
    /// The minimize (windowshade) box, at rest; it differs from the other boxes by what is drawn in it.
    case windowBoxMinimize
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

    private enum CodingKeys: String, CodingKey { case recipes }

    /// Decodes the set. On the wire the recipes are an object of objects keyed by the role's and the state's raw values, because a
    /// dictionary with enum keys would encode as a flat array whose order is not stable and would break the canonical form.
    ///
    /// - Throws: `DecodingError.dataCorrupted` for a role or a state that does not exist.
    public init(from decoder: any Decoder) throws {
        let wire = try decoder.container(keyedBy: CodingKeys.self).decode([String: [String: SurfaceRecipe]].self, forKey: .recipes)
        var recipes: [SurfaceRole: [ComponentState: SurfaceRecipe]] = [:]
        for (roleName, states) in wire {
            guard let role = SurfaceRole(rawValue: roleName) else {
                throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "unknown surface role \"\(roleName)\""))
            }
            for (stateName, recipe) in states {
                guard let state = ComponentState(rawValue: stateName) else {
                    throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "unknown component state \"\(stateName)\" in surface role \"\(roleName)\""))
                }
                recipes[role, default: [:]][state] = recipe
            }
        }
        self.recipes = recipes
    }

    /// Encodes the set as an object of objects with sorted keys; see ``init(from:)``.
    public func encode(to encoder: any Encoder) throws {
        var wire: [String: [String: SurfaceRecipe]] = [:]
        for (role, states) in recipes {
            for (state, recipe) in states { wire[role.rawValue, default: [:]][state.rawValue] = recipe }
        }
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(wire, forKey: .recipes)
    }

    /// The recipe for a role in a state, falling back to its `rest` recipe; `nil` when the role has none.
    public func recipe(for role: SurfaceRole, in state: ComponentState) -> SurfaceRecipe? {
        recipes[role]?[state] ?? recipes[role]?[.rest]
    }

    /// How much deeper the default button's edges reach than an ordinary button's: the width of its ring. The ring sits outside the
    /// measured button (System 7's is 78 x 20 inside a 3 px, 1 px, 1 px frame), so the default button's box grows by this on every side.
    public var defaultRingExtra: Double {
        guard let ring = recipes[.buttonDefault]?[.rest] else { return 0 }
        return max(0, ring.edgeDepth - (recipes[.button]?[.rest]?.edgeDepth ?? 0))
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

    /// The CSS declarations for a recipe, one `property: value` string each, without the trailing semicolon. `literal`, when given,
    /// resolves the colours of a pattern tile, which is an image and cannot read custom properties.
    ///
    /// Edge stripes become a list of `inset` box-shadows with no blur: step `k` of every side is listed before step `k + 1`, so outlines
    /// cover the corners and an inner highlight never overpaints an outline. A stripe at cumulative depth `d` is `inset 0 d 0 0` on the top
    /// edge, `inset d 0 0 0` on the leading edge, `inset 0 -d 0 0` on the bottom and `inset -d 0 0 0` on the trailing edge.
    public static func declarations(for recipe: SurfaceRecipe, resolve: (ColourReference) -> String,
                                    literal: ((ColourReference) -> String)? = nil) -> [String] {
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
                images.append(pattern(spec, resolve: { literal?($0) ?? resolve($0) })); sizes.append("\(spec.width)px \(spec.height)px"); hasPattern = true
            case .shadow(let layer):
                let spec = layer.shadow
                shadows.append("\(layer.inset ? "inset " : "")\(px(spec.x)) \(px(spec.y)) \(px(spec.radius)) \(px(layer.spread)) \(resolve(spec.colour))")
            }
        }

        if let edges = recipe.edges {
            let sides: [[EdgeStep]] = [edges.top, edges.leading, edges.bottom, edges.trailing]
            var depths = [Double](repeating: 0, count: 4)
            var edgeShadows: [String] = []
            let order = edges.stacking == .bottomTrailingFirst ? [2, 3, 0, 1] : [0, 1, 2, 3]
            for step in 0..<(sides.map(\.count).max() ?? 0) {
                for side in order where step < sides[side].count {
                    let steps = sides[side]
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
