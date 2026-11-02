import Foundation

public enum PowerStateParser {
    /// Parses the system-wide `SleepDisabled` value printed by `pmset -g`.
    /// A missing key is left as unknown because older hardware may not support it.
    public static func sleepIsDisabled(in output: String) -> Bool? {
        var parsedValue: Bool?

        for line in output.split(whereSeparator: \.isNewline) {
            let fields = line.split(whereSeparator: \.isWhitespace)
            guard fields.count >= 2,
                  fields[0].caseInsensitiveCompare("SleepDisabled") == .orderedSame else {
                continue
            }

            guard fields.count == 2 else { return nil }

            let value: Bool
            switch fields[1] {
            case "0": value = false
            case "1": value = true
            default: return nil
            }

            // More than one matching line is ambiguous, even if the values agree.
            guard parsedValue == nil else { return nil }
            parsedValue = value
        }

        return parsedValue
    }
}

public enum AuthorizationResult: Equatable {
    case changed
    case cancelled
    case failed(String)
}

public enum AuthorizationResultParser {
    public static func result(exitStatus: Int32, output: String) -> AuthorizationResult {
        if exitStatus == 0 {
            return .changed
        }

        let details = output.trimmingCharacters(in: .whitespacesAndNewlines)
        if details.contains("(-128)") {
            return .cancelled
        }

        return .failed(details.isEmpty ? "macOS could not change the sleep setting." : details)
    }
}
