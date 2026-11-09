import CryptoKit
import Foundation

/// Test support: runs the dataviz skill's `validate_palette.js` under Node and parses its report.
enum JavaScriptValidator {
    /// Node failed to run the script, timed out, or exited non-zero: a failure of the test, not a skip.
    enum NodeFailure: Error { case didNotRun }

    struct Case: Encodable {
        var name: String
        var palette: [String]
        var dark: Bool
        var surface: String
        var pairs: String
    }

    struct Offender: Equatable {
        var hex: String
        var value: Double
    }

    struct Result {
        var bandOffenders: [Offender]
        var chromaOffenders: [Offender]
        var cvdWorst: Double
        var cvdKind: String
        var cvdState: String
        var normalWorst: Double
        var contrastOffenders: [Offender]
    }

    struct OrdinalResult {
        var monotone: Bool
        var thinSteps: Int
        var lightEnd: Double
        var hueSpread: Double
    }

    static func nodePath() -> String? {
        let candidates = [ProcessInfo.processInfo.environment["NODE"], "/opt/homebrew/bin/node", "/usr/local/bin/node",
                          "/opt/homebrew/opt/node@20/bin/node", "/usr/bin/node"].compactMap { $0 }
        return candidates.first { FileManager.default.isExecutableFile(atPath: $0) }
    }

    /// The reference script, located and verified by `ReferenceScript`, or `nil` (the cross-check then skips, with
    /// `ReferenceScript.skipReason`).
    static func scriptPath() -> String? { ReferenceScript.current.path }

    private static func runNode(_ node: String, source: String) throws -> Data {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("dt-js-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let file = directory.appendingPathComponent("run.mjs")
        try source.write(to: file, atomically: true, encoding: .utf8)
        guard let output = ProcessRunner.run(node, arguments: [file.path], timeout: 60), output.exitCode == 0 else {
            throw NodeFailure.didNotRun
        }
        return output.stdout
    }

    static func run(node: String, script: String, cases: [Case]) throws -> [Result] {
        let json = String(decoding: try JSONEncoder().encode(cases), as: UTF8.self)
        let source = """
        import { validate } from \(quoted(script));
        const cases = \(json);
        const out = cases.map(c => validate(c.palette, { mode: c.dark ? "dark" : "light", surface: c.surface, pairs: c.pairs }).report);
        console.log(JSON.stringify(out));
        """
        let reports = try JSONSerialization.jsonObject(with: runNode(node, source: source)) as? [[[Any]]] ?? []
        return reports.map { report in
            func detail(_ i: Int) -> String { (report[i][2] as? String) ?? "" }
            func state(_ i: Int) -> String {
                if let b = report[i][1] as? Bool { return b ? "pass" : "fail" }
                return (report[i][1] as? String) ?? ""
            }
            func offenders(_ text: String) -> [Offender] {
                guard let start = text.firstIndex(of: "["), let data = String(text[start...]).data(using: .utf8),
                      let rows = try? JSONSerialization.jsonObject(with: data) as? [[Any]] else { return [] }
                return rows.compactMap { row in
                    guard let hex = row[0] as? String, let value = (row[1] as? NSNumber)?.doubleValue else { return nil }
                    return Offender(hex: hex, value: value)
                }
            }
            func number(_ text: String) -> Double {
                guard let range = text.range(of: "ΔE ") else { return 99 }
                return Double(text[range.upperBound...].prefix { $0.isNumber || $0 == "." }) ?? 99
            }
            let cvd = detail(2)
            let kind = ["protan", "deutan"].first { cvd.contains("(\($0))") } ?? ""
            return Result(bandOffenders: report[0][1] as? Bool == false ? offenders(detail(0)) : [],
                          chromaOffenders: report[1][1] as? Bool == false ? offenders(detail(1)) : [],
                          cvdWorst: number(cvd), cvdKind: kind, cvdState: state(2), normalWorst: number(detail(3)),
                          contrastOffenders: state(4) == "relief" ? offenders(detail(4)) : [])
        }
    }

    static func runOrdinal(node: String, script: String, ramps: [(String, [String], Bool, String)]) throws -> [OrdinalResult] {
        let items = ramps.map { ["palette": $0.1, "dark": $0.2, "surface": $0.3] as [String: Any] }
        let json = String(decoding: try JSONSerialization.data(withJSONObject: items), as: UTF8.self)
        let source = """
        import { validateOrdinal } from \(quoted(script));
        const items = \(json);
        console.log(JSON.stringify(items.map(c => validateOrdinal(c.palette, { mode: c.dark ? "dark" : "light", surface: c.surface }).report)));
        """
        let reports = try JSONSerialization.jsonObject(with: runNode(node, source: source)) as? [[[Any]]] ?? []
        return reports.map { report in
            func detail(_ i: Int) -> String { (report[i][2] as? String) ?? "" }
            let thin = (try? JSONSerialization.jsonObject(with: Data(String(detail(1).drop { $0 != "[" }).utf8)) as? [Any])?.count ?? 0
            let light = Double(detail(2).split(separator: " at ").last?.prefix { $0.isNumber || $0 == "." } ?? "") ?? 0
            let spread = Double(detail(3).dropFirst("hue spread ".count).prefix { $0.isNumber || $0 == "." }) ?? 0
            return OrdinalResult(monotone: report[0][1] as? Bool ?? false, thinSteps: report[1][1] as? Bool == false ? thin : 0,
                                 lightEnd: light, hueSpread: spread)
        }
    }

    private static func quoted(_ path: String) -> String {
        let data = (try? JSONEncoder().encode(path)) ?? Data()
        return String(decoding: data, as: UTF8.self)
    }
}

/// Finds the dataviz skill's `validate_palette.js` on this machine and verifies it against a pinned SHA-256.
///
/// The script is not vendored in this repository: it has no licence of its own, so redistributing it is not
/// something this repository can confirm it may do. The pin keeps the comparison honest: a script that is absent
/// or whose hash differs is never run, and the tests that need it skip with a reason (`ReferenceScript.Resolution`).
enum ReferenceScript {
    /// SHA-256 of the script as bundled with Claude Code 2.1.311 (353 lines).
    static let pinnedSHA256 = "25df43beb77674dad34348b9fe338d5a47f568e08bcf51b38780e51386cf866e"

    /// Absolute path of the script; authoritative when set.
    static let environmentVariable = "DATAVIZ_VALIDATOR"

    /// What one candidate path turned out to be.
    enum Status: Equatable {
        case found(path: String)
        case absent(path: String)
        case mismatch(path: String, sha256: String)
    }

    /// Where the search ended.
    enum Resolution: Equatable {
        case found(String)
        case skip(String)

        var path: String? {
            if case .found(let path) = self { return path }
            return nil
        }
    }

    /// The SHA-256 of the file at `path` as lowercase hex, or `nil` if it cannot be read.
    static func sha256(ofFileAt path: String) -> String? {
        guard let data = FileManager.default.contents(atPath: path) else { return nil }
        return SHA256.hash(data: data).map { ($0 < 16 ? "0" : "") + String($0, radix: 16) }.joined()
    }

    /// Checks one candidate against `pin`.
    static func check(path: String, pin: String = pinnedSHA256) -> Status {
        guard let digest = sha256(ofFileAt: path) else { return .absent(path: path) }
        return digest == pin ? .found(path: path) : .mismatch(path: path, sha256: digest)
    }

    /// Locates the script. `DATAVIZ_VALIDATOR`, when set, is the only candidate. Otherwise the candidates are
    /// `<home>/.claude/skills/dataviz/scripts/validate_palette.js` and, two directory levels under
    /// `bundledSkillsRoot` (version, then a hash), `dataviz/scripts/validate_palette.js`: sorted by path, the first
    /// whose hash matches `pin` is used. Nothing is searched recursively.
    static func resolve(environment: [String: String], home: String, bundledSkillsRoot: String, pin: String = pinnedSHA256) -> Resolution {
        if let explicit = environment[environmentVariable], !explicit.isEmpty {
            switch check(path: explicit, pin: pin) {
            case .found(let path): return .found(path)
            case .absent(let path): return .skip("\(environmentVariable) is set to \(path), which is absent: nothing to cross-check against")
            case .mismatch(let path, let digest): return .skip("\(environmentVariable) is set to \(path), but its SHA-256 is a mismatch: \(digest), pinned \(pin)")
            }
        }
        let tail = "dataviz/scripts/validate_palette.js"
        var candidates = ["\(home)/.claude/skills/\(tail)"]
        let fileManager = FileManager.default
        for version in ((try? fileManager.contentsOfDirectory(atPath: bundledSkillsRoot)) ?? []).sorted() {
            for bundle in ((try? fileManager.contentsOfDirectory(atPath: "\(bundledSkillsRoot)/\(version)")) ?? []).sorted() {
                candidates.append("\(bundledSkillsRoot)/\(version)/\(bundle)/\(tail)")
            }
        }
        var mismatches: [String] = []
        for candidate in candidates.sorted() {
            switch check(path: candidate, pin: pin) {
            case .found(let path): return .found(path)
            case .absent: continue
            case .mismatch(let path, let digest): mismatches.append("\(path) (\(digest))")
            }
        }
        let how = "set \(environmentVariable) to the absolute path of a validate_palette.js with SHA-256 \(pin)"
        if mismatches.isEmpty {
            return .skip("reference script not found; searched \(home)/.claude/skills and \(bundledSkillsRoot): \(how)")
        }
        return .skip("reference script found but a SHA-256 mismatch against the pin: \(mismatches.joined(separator: ", ")): \(how)")
    }

    /// The resolution for this process: the real environment, home directory and Claude Code's bundled-skills directory.
    static let current: Resolution = resolve(environment: ProcessInfo.processInfo.environment,
                                             home: NSHomeDirectory(), bundledSkillsRoot: "/tmp/claude-\(getuid())/bundled-skills")

    /// Why the tests that need the script are skipped, or `nil` if they run.
    static var skipReason: String? {
        if case .skip(let reason) = current { return reason }
        return nil
    }
}
