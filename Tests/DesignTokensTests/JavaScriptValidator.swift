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

    /// The vendored copy of the script, `Tests/DesignTokensTests/Vendored/validate_palette.js`, or `nil` if it
    /// is missing. It is the only script the cross-check runs: no search of temporary directories, no
    /// environment override, so the comparison is against one pinned file (`VendoredScriptTests`).
    static func scriptPath() -> String? {
        let path = vendoredScriptURL.path
        return FileManager.default.fileExists(atPath: path) ? path : nil
    }

    static let vendoredScriptURL = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().appendingPathComponent("Vendored/validate_palette.js")

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
