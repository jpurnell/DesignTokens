import Foundation
import Testing
@testable import DesignTokens

/// Expected placements are read off the original systems' windows (project/docs/technical/SkinMeasurements.md, title bars), not the
/// themes' own output: System 7's title bar has the close box at the left and the zoom box at the right; Mac OS 8's has the close box
/// at the left, then at the right the zoom box and the windowshade (collapse) box, the windowshade box outermost.
@Suite("Window control placement")
struct WindowControlsTests {
    @Test("System 7: close box at the left, zoom box at the right")
    func system7() throws {
        let controls = try #require(Theme.system7.windowControls)
        #expect(controls.leading == [.close])
        #expect(controls.trailing == [.zoom])
    }

    @Test("Platinum: close box at the left; zoom, then windowshade, at the right")
    func platinum() throws {
        let controls = try #require(Theme.platinum.windowControls)
        #expect(controls.leading == [.close])
        #expect(controls.trailing == [.zoom, .minimize])
    }

    @Test("a theme with no placement writes no key, and one with a placement survives the codec")
    func codec() throws {
        let swiss = String(decoding: try ThemeCodec.encode(.swiss), as: UTF8.self)
        #expect(!swiss.contains("windowControls"))
        let data = try ThemeCodec.encode(.platinum)
        #expect(String(decoding: data, as: UTF8.self).contains("\"windowControls\""))
        #expect(try ThemeCodec.decode(data) == .platinum)
    }

    @Test("GTK's decoration layout names the sides either side of a colon")
    func gtkLayout() {
        #expect(WindowControls(leading: [.close], trailing: [.zoom]).gtkDecorationLayout == "close:maximize")
        #expect(WindowControls(leading: [.close], trailing: [.zoom, .minimize]).gtkDecorationLayout == "close:maximize,minimize")
        #expect(WindowControls(leading: [], trailing: [.minimize, .zoom, .close]).gtkDecorationLayout == ":minimize,maximize,close")
    }

    @Test("the GTK settings file carries the layout; a theme with no placement has none")
    func gtkSettings() throws {
        let ini = try #require(GTKEmitter.settings(Theme.platinum))
        #expect(ini.contains("[Settings]"))
        #expect(ini.contains("gtk-decoration-layout=close:maximize,minimize\n"))
        #expect(GTKEmitter.settings(Theme.swiss) == nil)
    }

    @Test("the generator writes <id>.gtk-settings.ini only for themes that place the controls")
    func generatorFiles() throws {
        let files = try Generator.files(formats: [.gtk]).map(\.path).filter { $0.hasSuffix(".ini") }
        #expect(files == ["themes/system7.gtk-settings.ini", "themes/platinum.gtk-settings.ini"])
    }
}
