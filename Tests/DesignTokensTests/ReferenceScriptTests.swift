import CryptoKit
import Foundation
import Testing
@testable import DesignTokens

/// The reference script is not in this repository (its licence is unclear), so the cross-check finds it on the
/// machine and verifies it against a pinned SHA-256. These tests are never skipped: they assert the locating and
/// skip-reason logic itself, so "the cross-check was skipped" is always visible and always explained.
@Suite("Reference script location")
struct ReferenceScriptTests {
    /// A scratch directory removed at the end of each use.
    private func scratch<T>(_ body: (URL) throws -> T) throws -> T {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("dt-ref-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        return try body(dir)
    }

    private func digest(_ text: String) -> String {
        SHA256.hash(data: Data(text.utf8)).map { ($0 < 16 ? "0" : "") + String($0, radix: 16) }.joined()
    }

    /// Writes `text` to `<root>/<relative>` and returns the path.
    @discardableResult
    private func write(_ text: String, to relative: String, in root: URL) throws -> String {
        let file = root.appendingPathComponent(relative)
        try FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
        try text.write(to: file, atomically: true, encoding: .utf8)
        return file.path
    }

    @Test("the pin is a 64-digit lowercase hex SHA-256")
    func pinIsWellFormed() {
        #expect(ReferenceScript.pinnedSHA256.count == 64)
        #expect(ReferenceScript.pinnedSHA256.allSatisfy { "0123456789abcdef".contains($0) })
    }

    @Test("a missing path is reported as absent, with the path")
    func missingPathIsAbsent() {
        #expect(ReferenceScript.check(path: "/nonexistent/dt-ref/validate_palette.js", pin: "00") == .absent(path: "/nonexistent/dt-ref/validate_palette.js"))
    }

    @Test("a file with the wrong hash is reported as a mismatch, with the hash it has")
    func wrongHashIsMismatch() throws {
        try scratch { dir in
            let path = try write("not the reference", to: "validate_palette.js", in: dir)
            #expect(ReferenceScript.check(path: path, pin: String(repeating: "0", count: 64)) == .mismatch(path: path, sha256: digest("not the reference")))
        }
    }

    @Test("a file with the pinned hash is found")
    func rightHashIsFound() throws {
        try scratch { dir in
            let path = try write("the reference", to: "validate_palette.js", in: dir)
            #expect(ReferenceScript.check(path: path, pin: digest("the reference")) == .found(path: path))
        }
    }

    @Test("DATAVIZ_VALIDATOR naming a missing file skips with a reason that names the variable and the path")
    func environmentMissingSkips() throws {
        try scratch { dir in
            // a good copy exists in the convenience directories, and still must not be used: the variable is authoritative
            try write("the reference", to: "home/.claude/skills/dataviz/scripts/validate_palette.js", in: dir)
            let resolution = ReferenceScript.resolve(environment: [ReferenceScript.environmentVariable: "/nonexistent/x.js"],
                                                     home: dir.appendingPathComponent("home").path,
                                                     bundledSkillsRoot: dir.appendingPathComponent("none").path, pin: digest("the reference"))
            guard case .skip(let reason) = resolution else { Issue.record("expected a skip, got \(resolution)"); return }
            #expect(reason.contains("DATAVIZ_VALIDATOR"))
            #expect(reason.contains("/nonexistent/x.js"))
            #expect(reason.contains("absent"))
        }
    }

    @Test("DATAVIZ_VALIDATOR naming a file with the wrong hash skips with a mismatch reason showing both hashes")
    func environmentMismatchSkips() throws {
        try scratch { dir in
            let path = try write("edited", to: "mine.js", in: dir)
            let pin = digest("the reference")
            let resolution = ReferenceScript.resolve(environment: [ReferenceScript.environmentVariable: path], home: "/nonexistent", bundledSkillsRoot: "/nonexistent", pin: pin)
            guard case .skip(let reason) = resolution else { Issue.record("expected a skip, got \(resolution)"); return }
            #expect(reason.contains("mismatch"))
            #expect(reason.contains(pin))
            #expect(reason.contains(digest("edited")))
        }
    }

    @Test("DATAVIZ_VALIDATOR naming the pinned file is used")
    func environmentGoodIsUsed() throws {
        try scratch { dir in
            let path = try write("the reference", to: "mine.js", in: dir)
            let resolution = ReferenceScript.resolve(environment: [ReferenceScript.environmentVariable: path], home: "/nonexistent",
                                                     bundledSkillsRoot: "/nonexistent", pin: digest("the reference"))
            #expect(resolution == .found(path))
        }
    }

    @Test("with no variable, the skill directory is searched")
    func skillDirectoryIsSearched() throws {
        try scratch { dir in
            let path = try write("the reference", to: "home/.claude/skills/dataviz/scripts/validate_palette.js", in: dir)
            #expect(ReferenceScript.resolve(environment: [:], home: dir.appendingPathComponent("home").path, bundledSkillsRoot: "/nonexistent", pin: digest("the reference")) == .found(path))
        }
    }

    @Test("the bundled-skills directory is searched two levels down (version, then hash), sorted, and a non-matching copy is passed over")
    func bundledDirectoryIsSearchedDeterministically() throws {
        try scratch { dir in
            let tail = "dataviz/scripts/validate_palette.js"
            try write("edited", to: "bundled/2.1.310/aaa/\(tail)", in: dir)               // sorts first, wrong hash: skipped over
            let good = try write("the reference", to: "bundled/2.1.311/bbb/\(tail)", in: dir)
            try write("the reference", to: "bundled/2.1.312/ccc/\(tail)", in: dir)          // also good, sorts later: not chosen
            let resolution = ReferenceScript.resolve(environment: [:], home: "/nonexistent", bundledSkillsRoot: dir.appendingPathComponent("bundled").path, pin: digest("the reference"))
            #expect(resolution == .found(good))
        }
    }

    @Test("nothing anywhere skips with a reason that says what was searched and how to point at the script")
    func nothingFoundSkips() throws {
        try scratch { dir in
            let resolution = ReferenceScript.resolve(environment: [:], home: dir.path, bundledSkillsRoot: dir.appendingPathComponent("bundled").path, pin: "00")
            guard case .skip(let reason) = resolution else { Issue.record("expected a skip, got \(resolution)"); return }
            #expect(reason.contains("DATAVIZ_VALIDATOR"))
            #expect(reason.contains(dir.path))
            #expect(reason.contains("not found"))
        }
    }

    @Test("a mismatching copy that is the only one found is reported as a mismatch, not as absent")
    func onlyMismatchingCopyIsReported() throws {
        try scratch { dir in
            try write("edited", to: "home/.claude/skills/dataviz/scripts/validate_palette.js", in: dir)
            let resolution = ReferenceScript.resolve(environment: [:], home: dir.appendingPathComponent("home").path, bundledSkillsRoot: "/nonexistent", pin: digest("the reference"))
            guard case .skip(let reason) = resolution else { Issue.record("expected a skip, got \(resolution)"); return }
            #expect(reason.contains("mismatch"))
        }
    }

    @Test("the README beside this suite records the pin and says why the script is not vendored")
    func readmeRecordsThePin() throws {
        let readme = URL(fileURLWithPath: #filePath).deletingLastPathComponent().appendingPathComponent("Vendored/README.md")
        let text = try String(contentsOf: readme, encoding: .utf8)
        #expect(text.contains(ReferenceScript.pinnedSHA256))
        #expect(text.contains("DATAVIZ_VALIDATOR"))
        #expect(text.contains("licence"))
    }

    @Test("no copy of the script is tracked in the repository")
    func scriptIsNotInTheRepository() {
        let vendored = URL(fileURLWithPath: #filePath).deletingLastPathComponent().appendingPathComponent("Vendored/validate_palette.js")
        #expect(!FileManager.default.fileExists(atPath: vendored.path))
    }
}
