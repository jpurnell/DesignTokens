import Foundation

/// Runs a child process with a deadline, so a hung browser cannot hang the tool.
///
/// The child is started with `posix_spawnp`; its standard output goes to a file rather than a pipe, so a child that writes
/// more than a pipe buffer holds cannot block and nothing waits on end-of-file, and its standard error is discarded. The
/// wait polls with a deadline and a child that outlives it is killed. Arguments are an array, never a shell string. This is
/// the shape of the runner the test target already uses for Node (`ProcessRunner`), here in the library because
/// ``ChromeBlogFetcher`` needs it at run time.
enum BoundedProcess {
    /// What a run produced.
    struct Output: Sendable, Equatable {
        /// The exit code, or -1 if the child died from a signal.
        var exitCode: Int32
        /// Everything the child wrote to standard output.
        var stdout: Data
    }

    /// Why a run produced nothing.
    enum Failure: Error, Sendable, Equatable {
        /// The child could not be started.
        case couldNotStart
        /// The child did not finish within the timeout and was killed.
        case timedOut
    }

    /// Runs `executable` (an absolute path or a name on `PATH`) with `arguments`.
    ///
    /// - Throws: ``Failure``.
    static func run(_ executable: String, arguments: [String], timeout: TimeInterval) throws -> Output {
        let sink = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("dt-\(UUID().uuidString).out")
        guard FileManager.default.createFile(atPath: sink.path, contents: nil) else { throw Failure.couldNotStart }
        let writer: FileHandle
        do {
            writer = try FileHandle(forWritingTo: sink)
        } catch {
            throw Failure.couldNotStart
        }
        defer { try? FileManager.default.removeItem(at: sink) }

        var actions: posix_spawn_file_actions_t?
        guard posix_spawn_file_actions_init(&actions) == 0 else {
            try? writer.close()
            throw Failure.couldNotStart
        }
        defer { posix_spawn_file_actions_destroy(&actions) }
        posix_spawn_file_actions_adddup2(&actions, writer.fileDescriptor, STDOUT_FILENO)
        posix_spawn_file_actions_addopen(&actions, STDERR_FILENO, "/dev/null", O_WRONLY, 0)

        var argv: [UnsafeMutablePointer<CChar>?] = ([executable] + arguments).map { strdup($0) }
        argv.append(nil)
        defer { argv.forEach { free($0) } }

        var pid: pid_t = 0
        let spawned = posix_spawnp(&pid, executable, &actions, nil, argv, environ)
        try? writer.close()
        guard spawned == 0 else { throw Failure.couldNotStart }

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
            throw Failure.timedOut
        }
        // A normal exit stores the code in bits 8-15; a signal death leaves it in the low bits.
        let exitCode = (status & 0x7f) == 0 ? (status >> 8) & 0xff : -1
        do {
            return Output(exitCode: exitCode, stdout: try Data(contentsOf: sink))
        } catch {
            throw Failure.couldNotStart
        }
    }
}
