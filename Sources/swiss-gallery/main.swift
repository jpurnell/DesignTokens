import Foundation

/// Writes a line to standard output (or standard error).
func say(_ message: String, error: Bool = false) {
    let handle = error ? FileHandle.standardError : FileHandle.standardOutput
    handle.write(Data((message + "\n").utf8))
}

#if canImport(SwiftUI) && canImport(AppKit)
import AppKit
import DesignTokens
import DesignTokensSwiftUI
import SwiftUI

let arguments = CommandLine.arguments
let folder = arguments.count > 1 ? arguments[1] : "swiss-gallery-output"
if #available(macOS 14.0, *) {
    MainActor.assumeIsolated {
        do {
            let written = try Gallery.run(into: URL(fileURLWithPath: folder, isDirectory: true))
            say("wrote \(written) images and index.html to \(folder)")
        } catch {
            say("gallery failed: \(error)", error: true)
            exit(1)
        }
    }
} else {
    say("swiss-gallery needs macOS 14 or later.", error: true)
    exit(1)
}
#else
say("swiss-gallery renders with AppKit and runs on macOS only.")
#endif
