import Foundation
import HypnagogiaCore

struct CommandFailure: LocalizedError {
    let command: String
    let status: Int32
    let output: String

    var errorDescription: String? {
        let details = output.trimmingCharacters(in: .whitespacesAndNewlines)
        if details.isEmpty {
            return "\(command) exited with status \(status)."
        }
        return details
    }
}

struct SleepDisabledSettingUnavailable: LocalizedError {
    var errorDescription: String? {
        "This Mac did not report support for the SleepDisabled setting."
    }
}

enum PowerSettingsClient {
    static func readSleepDisabled(completion: @escaping (Result<Bool, Error>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let result: Result<Bool, Error>

            do {
                let output = try run(
                    executable: "/usr/bin/pmset",
                    arguments: ["-g"]
                )
                guard let disabled = PowerStateParser.sleepIsDisabled(in: output) else {
                    throw SleepDisabledSettingUnavailable()
                }
                result = .success(disabled)
            } catch {
                result = .failure(error)
            }

            DispatchQueue.main.async {
                completion(result)
            }
        }
    }

    /// Executes one of two fixed commands through macOS's standard administrator prompt.
    /// No user-provided text is ever passed to the shell.
    static func setSleepDisabled(
        _ disabled: Bool,
        completion: @escaping (AuthorizationResult) -> Void
    ) {
        DispatchQueue.global(qos: .userInitiated).async {
            let value = disabled ? "1" : "0"
            let source = "do shell script \"/usr/bin/pmset -a disablesleep \(value)\" with administrator privileges"
            let result: AuthorizationResult

            do {
                let execution = try runWithStatus(
                    executable: "/usr/bin/osascript",
                    arguments: ["-e", source]
                )
                result = AuthorizationResultParser.result(
                    exitStatus: execution.status,
                    output: execution.output
                )
            } catch {
                result = .failed("Hypnagogia could not open the administrator request: \(error.localizedDescription)")
            }

            DispatchQueue.main.async {
                completion(result)
            }
        }
    }

    private static func run(executable: String, arguments: [String]) throws -> String {
        let result = try runWithStatus(executable: executable, arguments: arguments)
        guard result.status == 0 else {
            throw CommandFailure(
                command: ([executable] + arguments).joined(separator: " "),
                status: result.status,
                output: result.output
            )
        }

        return result.output
    }

    private static func runWithStatus(
        executable: String,
        arguments: [String]
    ) throws -> (status: Int32, output: String) {
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        process.standardOutput = pipe
        process.standardError = pipe

        try process.run()
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""
        return (process.terminationStatus, output)
    }
}
