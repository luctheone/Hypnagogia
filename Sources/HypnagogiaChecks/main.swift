import Darwin
import HypnagogiaCore

private struct CheckSuite {
    private(set) var failures: [String] = []
    private(set) var checksRun = 0

    mutating func expect(_ condition: @autoclosure () -> Bool, _ name: String) {
        checksRun += 1
        if !condition() {
            failures.append(name)
        }
    }
}

private var suite = CheckSuite()

suite.expect(
    PowerStateParser.sleepIsDisabled(
        in: "System-wide power settings:\n SleepDisabled        1\n"
    ) == true,
    "parses enabled state"
)
suite.expect(
    PowerStateParser.sleepIsDisabled(
        in: "System-wide power settings:\n SleepDisabled        0\n"
    ) == false,
    "parses disabled state"
)
suite.expect(
    PowerStateParser.sleepIsDisabled(in: "system-wide:\n\tSLEEPDISABLED\t1\n") == true,
    "parsing is case-insensitive and whitespace-tolerant"
)
suite.expect(
    PowerStateParser.sleepIsDisabled(in: "Currently in use:\n standby 1\n sleep 10\n") == nil,
    "missing setting is unknown"
)
suite.expect(
    PowerStateParser.sleepIsDisabled(in: "NotSleepDisabled 1\nSleepDisabledLater 1\n") == nil,
    "similar keys do not match"
)
suite.expect(
    PowerStateParser.sleepIsDisabled(in: "SleepDisabled yes\n") == nil,
    "malformed value is unknown"
)
suite.expect(
    PowerStateParser.sleepIsDisabled(in: "SleepDisabled 1 trailing\n") == nil,
    "trailing fields are rejected"
)
suite.expect(
    PowerStateParser.sleepIsDisabled(in: "SleepDisabled 1\nSleepDisabled 1\n") == nil,
    "duplicate values are unknown"
)
suite.expect(
    AuthorizationResultParser.result(
        exitStatus: 1,
        output: "execution error: User canceled. (-128)\n"
    ) == .cancelled,
    "authorization cancellation is recognized"
)
suite.expect(
    AuthorizationResultParser.result(exitStatus: 1, output: "permission denied")
        == .failed("permission denied"),
    "authorization failure keeps details"
)
suite.expect(
    AuthorizationResultParser.result(exitStatus: 0, output: "") == .changed,
    "successful authorization is recognized"
)

if suite.failures.isEmpty {
    print("Hypnagogia checks passed (\(suite.checksRun)/\(suite.checksRun)).")
} else {
    for failure in suite.failures {
        fputs("FAIL: \(failure)\n", stderr)
    }
    fputs("\(suite.failures.count) of \(suite.checksRun) checks failed.\n", stderr)
    exit(1)
}
