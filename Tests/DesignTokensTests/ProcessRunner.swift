import Foundation

/// Runs a child process with a deadline, for the tests that need Node.
///
/// The child is started with `posix_spawnp` and its standard output and error go to a file rather than a
/// pipe, so a child that writes more than a pipe buffer holds cannot block and nothing waits on end-of-file.
/// The wait polls with a deadline: a child that outlives it is killed. Arguments are an array, never a shell
/// string. This follows the runner in `development-guidelines/setup.swift`.
enum ProcessRunner {
    /// What a run produced.
    struct Output {
        /// The exit code, or -1 if the child died from a signal.
        var exitCode: Int32
        /// Everything the child wrote to standard output and error.
        var stdout: Data
    }

    /// Runs `executable` with `arguments`. Returns `nil` if the child could not be started or did not finish
    /// within `timeout` seconds (it is killed).
    static func run(_ executable: String, arguments: [String], timeout: TimeInterval) -> Output? {
        let sink = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("dt-\(UUID().uuidString).out")
        guard FileManager.default.createFile(atPath: sink.path, contents: nil),
              let writer = try? FileHandle(forWritingTo: sink) else { return nil }
        defer { try? FileManager.default.removeItem(at: sink) }

        var actions: posix_spawn_file_actions_t?
        guard posix_spawn_file_actions_init(&actions) == 0 else {
            try? writer.close()
            return nil
        }
        defer { posix_spawn_file_actions_destroy(&actions) }
        posix_spawn_file_actions_adddup2(&actions, writer.fileDescriptor, STDOUT_FILENO)

        var argv: [UnsafeMutablePointer<CChar>?] = ([executable] + arguments).map { strdup($0) }
        argv.append(nil)
        defer { argv.forEach { free($0) } }

        var pid: pid_t = 0
        let spawned = posix_spawnp(&pid, executable, &actions, nil, argv, environ)
        try? writer.close()
        guard spawned == 0 else { return nil }

        var status: Int32 = 0
        var reaped = waitpid(pid, &status, WNOHANG)
        let deadline = Date().addingTimeInterval(timeout)
        while reaped == 0, Date() < deadline {
            Thread.sleep(forTimeInterval: 0.01)
            reaped = waitpid(pid, &status, WNOHANG)
        }
        guard reaped == pid else {
            kill(pid, SIGKILL)
            waitpid(pid, &status, 0)
            return nil
        }
        // A normal exit stores the code in bits 8-15; a signal death leaves it in the low bits.
        let exitCode = (status & 0x7f) == 0 ? (status >> 8) & 0xff : -1
        guard let data = try? Data(contentsOf: sink) else { return nil }
        return Output(exitCode: exitCode, stdout: data)
    }
}
