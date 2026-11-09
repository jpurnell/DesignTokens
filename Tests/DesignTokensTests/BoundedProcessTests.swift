import Foundation
import Testing
@testable import DesignTokens

@Suite("Bounded process")
struct BoundedProcessTests {
    @Test("captures standard output and the exit code")
    func capturesOutput() throws {
        let out = try BoundedProcess.run("/bin/echo", arguments: ["hello"], timeout: 10)
        #expect(out.exitCode == 0)
        #expect(String(data: out.stdout, encoding: .utf8) == "hello\n")
    }

    @Test("a non-zero exit is reported, not thrown")
    func nonZeroExit() throws {
        let out = try BoundedProcess.run("/bin/sh", arguments: ["-c", "echo partial; exit 3"], timeout: 10)
        #expect(out.exitCode == 3)
        #expect(String(data: out.stdout, encoding: .utf8) == "partial\n")
    }

    @Test("a child that outlives the timeout is killed and reported")
    func timesOut() {
        #expect(throws: BoundedProcess.Failure.timedOut) {
            try BoundedProcess.run("/bin/sleep", arguments: ["30"], timeout: 0.3)
        }
    }

    @Test("a missing executable is reported as not started")
    func missing() {
        #expect(throws: BoundedProcess.Failure.couldNotStart) {
            try BoundedProcess.run("/nonexistent/binary", arguments: [], timeout: 5)
        }
    }

    @Test("output larger than a pipe buffer does not block the child")
    func largeOutput() throws {
        let out = try BoundedProcess.run("/bin/sh", arguments: ["-c", "yes x | head -c 400000"], timeout: 20)
        #expect(out.exitCode == 0)
        #expect(out.stdout.count == 400_000)
    }
}
