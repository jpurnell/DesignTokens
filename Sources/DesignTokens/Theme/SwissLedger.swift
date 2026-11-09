/// What is known to fall short in the Swiss palette, kept as data so consumers can act on it.
///
/// Swiss keeps Apple's system colours (the HIG says not to re-step them), and they sit outside the dataviz
/// method's bands for some slots: see `project/docs/technical/SwissConformanceLedger.md` for the exact
/// measurements, which tests pin. A finding is recorded, not hidden, and the remedy is a rule for charts:
/// these slots must be labelled directly or have their values printed.
public enum SwissLedger {
    /// The Swiss series slots that fail the lightness band or the 3:1 mark contrast against the surface
    /// in some appearance, in series order. A chart that plots one of them labels it directly, or prints
    /// its values, and never relies on colour alone.
    public static let directLabelSlots = ["orange", "green", "yellow", "cyan"]
}
