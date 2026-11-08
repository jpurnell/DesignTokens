/// Where the system-colour values in this package were taken from.
///
/// Apple's HIG says not to hard-code system colours, so Apple resolvers defer to `Color.orange` and
/// friends. The values here exist for surfaces the system cannot reach, and they age with each OS
/// release; the release is recorded so the age is visible.
public enum Snapshot {
    /// The OS release the system-colour values were read from.
    public static let systemRelease = "macOS 27.2"
}
