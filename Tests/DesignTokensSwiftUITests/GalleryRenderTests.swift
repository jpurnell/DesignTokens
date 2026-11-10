#if canImport(UIKit) && !os(watchOS) && !os(tvOS)
import DesignTokens
import DesignTokensSwiftUI
import SwiftUI
import SwissGalleryScenes
import Testing

/// Where the gallery goes, or `nil` for a plain test run.
private let galleryFolder = ProcessInfo.processInfo.environment["SWISS_GALLERY_OUT"]

/// Draws every gallery scene, light and dark, at an iPhone width (390 pt) and an iPad width (1024 pt) on an iOS Simulator, into the
/// folder named by `SWISS_GALLERY_OUT` (pass it to `xcodebuild test` as `TEST_RUNNER_SWISS_GALLERY_OUT`): `iphone/` and `ipad/`.
/// It does nothing when the variable is unset, so a plain test run is unaffected.
@MainActor
@Suite("Gallery on an iOS Simulator")
struct GalleryRenderTests {
    @Test("every scene renders to a PNG at the iPhone and iPad widths, light and dark", .enabled(if: galleryFolder != nil))
    func render() throws {
        let out = URL(fileURLWithPath: try #require(galleryFolder), isDirectory: true)
        var written = 0
        for (device, width) in [("iphone", CGFloat(390)), ("ipad", CGFloat(1024))] {
            let directory = out.appendingPathComponent(device, isDirectory: true)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            for scene in GalleryScenes.all {
                for dark in [false, true] {
                    let sceneWidth = scene.id.hasSuffix("compact") ? min(390, width) : width
                    let data = try #require(Self.png(scene, width: sceneWidth, dark: dark))
                    try data.write(to: directory.appendingPathComponent("\(scene.id)-\(dark ? "dark" : "light").png"))
                    written += 1
                }
            }
        }
        #expect(written == 4 * GalleryScenes.all.count)
    }

    /// Drawn with `ImageRenderer`: a test process on a simulator has no window scene to host a view in, and a window drawn without one is blank.
    private static func png(_ scene: GalleryScene, width: CGFloat, dark: Bool) -> Data? {
        let root = scene.view
            .environment(\.theme, .swiss)
            .environment(\.colorScheme, dark ? .dark : .light)
            .padding(16)
            .frame(width: width, alignment: .topLeading)
            .fixedSize(horizontal: false, vertical: true)
            .background(GalleryBackground().environment(\.theme, .swiss).environment(\.colorScheme, dark ? .dark : .light))
        let renderer = ImageRenderer(content: root)
        renderer.scale = 2
        renderer.proposedSize = ProposedViewSize(width: width, height: nil)
        return renderer.uiImage?.pngData()
    }
}
#endif
