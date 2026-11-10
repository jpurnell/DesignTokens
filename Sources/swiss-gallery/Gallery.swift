#if canImport(SwiftUI) && canImport(AppKit)
import AppKit
import DesignTokens
import DesignTokensSwiftUI
import Foundation
import SwiftUI
import SwissGalleryScenes

/// Draws every scene in light and dark through a real window (`cacheDisplay`), so AppKit-backed views such as a native `Table`
/// are rendered as well as pure SwiftUI ones, and writes the PNGs with an index.
@MainActor
@available(macOS 14.0, iOS 17.0, visionOS 1.0, tvOS 17.0, watchOS 10.0, *)
enum Gallery {
    static func run(into folder: URL) throws -> Int {
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        NSApplication.shared.setActivationPolicy(.accessory)
        var written = 0
        var sections: [String] = []
        for scene in GalleryScenes.all {
            var figures: [String] = []
            for dark in [false, true] {
                let name = "\(scene.id)-\(dark ? "dark" : "light").png"
                let data = try render(scene, dark: dark)
                try data.write(to: folder.appendingPathComponent(name))
                written += 1
                figures.append("<figure><figcaption>\(dark ? "Dark" : "Light")</figcaption><img src=\"\(name)\" alt=\"\(scene.title), \(dark ? "dark" : "light")\"></figure>")
            }
            sections.append("<section><h2>\(scene.title)</h2><p>\(scene.note)</p><div class=\"pair\">\(figures.joined())</div></section>")
        }
        sections.append(contentsOf: try deviceSections(in: folder))
        try html(sections).write(to: folder.appendingPathComponent("index.html"), atomically: true, encoding: .utf8)
        return written
    }

    /// The iPhone and iPad renders, when the iOS Simulator test (`SWISS_GALLERY_OUT`) has written them beside this index.
    private static func deviceSections(in folder: URL) throws -> [String] {
        try [("iphone", "iPhone, 390 pt wide"), ("ipad", "iPad, 1024 pt wide")].compactMap { device, title in
            let directory = folder.appendingPathComponent(device, isDirectory: true)
            let names = try pngNames(in: directory)
            guard !names.isEmpty else { return nil }
            let figures = names.map { "<figure><figcaption>\($0.replacingOccurrences(of: ".png", with: ""))</figcaption><img src=\"\(device)/\($0)\" alt=\"\($0)\" loading=\"lazy\"></figure>" }
            return "<section><h2>\(title) (iOS Simulator)</h2><p>Drawn by <code>GalleryRenderTests</code> with <code>ImageRenderer</code> on an iOS Simulator. A <code>Menu</code> is a system control that ImageRenderer draws blank (the segmented control's menu and a stacked table's sort menu): see the Mac renders above for those.</p><div class=\"pair\">\(figures.joined())</div></section>"
        }
    }

    /// The PNG file names in a folder; none when the folder is absent (a run with no simulator renders).
    private static func pngNames(in directory: URL) throws -> [String] {
        guard FileManager.default.fileExists(atPath: directory.path) else { return [] }
        return try FileManager.default.contentsOfDirectory(atPath: directory.path).filter { $0.hasSuffix(".png") }.sorted()
    }

    private static func render(_ scene: GalleryScene, dark: Bool) throws -> Data {
        let root = scene.view
            .environment(\.theme, .swiss)
            .padding(24)
            .frame(width: scene.width + 48, alignment: .topLeading)
            .fixedSize(horizontal: false, vertical: true)
            .background(GalleryBackground())
        let host = NSHostingView(rootView: root)
        host.appearance = NSAppearance(named: dark ? .darkAqua : .aqua)
        let size = host.fittingSize
        let window = NSWindow(contentRect: NSRect(origin: .zero, size: size), styleMask: [.borderless], backing: .buffered, defer: false)
        window.appearance = host.appearance
        window.contentView = host
        host.frame = NSRect(origin: .zero, size: size)
        window.orderFrontRegardless()
        RunLoop.main.run(until: Date().addingTimeInterval(0.4))
        host.layoutSubtreeIfNeeded()
        guard let rep = host.bitmapImageRepForCachingDisplay(in: host.bounds) else { throw GalleryError.noBitmap(scene.id) }
        host.cacheDisplay(in: host.bounds, to: rep)
        guard let data = rep.representation(using: .png, properties: [:]) else { throw GalleryError.noPNG(scene.id) }
        window.orderOut(nil)
        return data
    }

    private static func html(_ sections: [String]) -> String {
        """
        <!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
        <title>DesignTokens 0.11.0 components</title>
        <style>
        :root{color-scheme:light dark;--bg:#fafafa;--fg:#111214;--muted:#6a6d72;--hair:#d6d8db}
        @media (prefers-color-scheme:dark){:root{--bg:#101112;--fg:#f2f2ef;--muted:#9a9da2;--hair:#2e3033}}
        body{margin:0 auto;max-width:1240px;padding:40px 16px;background:var(--bg);color:var(--fg);font:16px/1.5 -apple-system,"Helvetica Neue",Helvetica,sans-serif}
        h1{border-top:8px solid var(--fg);padding-top:10px;font-size:40px;letter-spacing:-.02em;margin:0 0 8px}
        section{border-top:3px solid var(--fg);margin-top:48px;padding-top:12px}
        h2{margin:0 0 4px;font-size:24px;letter-spacing:-.01em}
        p{color:var(--muted);max-width:70ch;margin:0 0 16px}
        .pair{display:grid;grid-template-columns:repeat(auto-fit,minmax(360px,1fr));gap:16px}
        figure{margin:0}figcaption{font-size:12px;font-weight:600;letter-spacing:.08em;text-transform:uppercase;color:var(--muted);margin-bottom:6px}
        img{max-width:100%;height:auto;border:1px solid var(--hair);display:block}
        </style></head><body>
        <h1>Swiss components, 0.11.0</h1>
        <p>Rendered by <code>swift run swiss-gallery</code> from the package's own components on the Swiss theme, in a real window, light and dark.</p>
        \(sections.joined(separator: "\n"))
        </body></html>
        """
    }
}

@available(macOS 14.0, iOS 17.0, visionOS 1.0, tvOS 17.0, watchOS 10.0, *)
enum GalleryError: Error {
    case noBitmap(String)
    case noPNG(String)
}
#endif
