#if canImport(UIKit) && !os(watchOS) && !os(tvOS)
import DesignTokens
import DesignTokensSwiftUI
import SwiftUI
import SwissGalleryScenes
import Testing
import UIKit

/// Draws every gallery scene, light and dark, at an iPhone width (390 pt) and an iPad width (1024 pt) on an iOS Simulator, into the
/// folder named by `SWISS_GALLERY_OUT` (pass it to `xcodebuild test` as `TEST_RUNNER_SWISS_GALLERY_OUT`): `iphone/` and `ipad/`.
/// It does nothing when the variable is unset, so a plain test run is unaffected.
@MainActor
@Suite("Gallery on an iOS Simulator")
struct GalleryRenderTests {
    private static let folder = ProcessInfo.processInfo.environment["SWISS_GALLERY_OUT"]

    @Test("every scene renders to a PNG at the iPhone and iPad widths, light and dark", .enabled(if: GalleryRenderTests.folder != nil))
    func render() throws {
        let out = URL(fileURLWithPath: try #require(Self.folder), isDirectory: true)
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

    private static func png(_ scene: GalleryScene, width: CGFloat, dark: Bool) -> Data? {
        let root = scene.view
            .environment(\.theme, .swiss)
            .padding(16)
            .frame(width: width, alignment: .topLeading)
            .fixedSize(horizontal: false, vertical: true)
            .background(GalleryBackground())
        let host = UIHostingController(rootView: root)
        host.overrideUserInterfaceStyle = dark ? .dark : .light
        let size = host.sizeThatFits(in: CGSize(width: width, height: .greatestFiniteMagnitude))
        let window = UIWindow(frame: CGRect(origin: .zero, size: size))
        window.rootViewController = host
        window.makeKeyAndVisible()
        host.view.frame = window.bounds
        RunLoop.main.run(until: Date().addingTimeInterval(0.4))
        host.view.layoutIfNeeded()
        let image = UIGraphicsImageRenderer(size: size).image { _ in
            host.view.drawHierarchy(in: host.view.bounds, afterScreenUpdates: true)
        }
        window.isHidden = true
        return image.pngData()
    }
}
#endif
