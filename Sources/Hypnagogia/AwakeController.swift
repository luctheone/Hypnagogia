import AppKit
import Combine
import Foundation

@MainActor
final class AwakeController: ObservableObject {
    static let shared = AwakeController()

    @Published private(set) var temporaryIsEnabled = false
    @Published private(set) var persistentIsEnabled = false
    @Published private(set) var persistentStateIsKnown = false
    @Published private(set) var isRefreshingPersistentState = false
    @Published private(set) var isChangingPersistentState = false
    @Published var keepDisplayAwake: Bool {
        didSet {
            UserDefaults.standard.set(keepDisplayAwake, forKey: Self.keepDisplayAwakeKey)
            if temporaryIsEnabled {
                restartCaffeinate()
            }
        }
    }
    @Published var message: UserMessage?

    private static let keepDisplayAwakeKey = "keepDisplayAwake"
    private var caffeinateProcess: Process?
    private var wakeObserver: NSObjectProtocol?

    private init() {
        keepDisplayAwake = UserDefaults.standard.bool(forKey: Self.keepDisplayAwakeKey)

        wakeObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.refreshPersistentState()
            }
        }
    }

    deinit {
        if let wakeObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(wakeObserver)
        }
    }

    var combinedState: CombinedAwakeState {
        guard persistentStateIsKnown else {
            return temporaryIsEnabled ? .temporaryUnknown : .unknown
        }

        switch (temporaryIsEnabled, persistentIsEnabled) {
        case (false, false): return .normal
        case (true, false): return .temporary
        case (false, true): return .persistent
        case (true, true): return .both
        }
    }

    var menuBarSymbol: String {
        switch combinedState {
        case .normal: return "moon.zzz"
        case .temporary: return "cup.and.saucer.fill"
        case .temporaryUnknown: return "cup.and.saucer"
        case .persistent: return "lock.shield.fill"
        case .both: return "bolt.shield.fill"
        case .unknown: return "questionmark.circle"
        }
    }

    func refreshPersistentState() {
        guard !isRefreshingPersistentState, !isChangingPersistentState else { return }
        isRefreshingPersistentState = true

        PowerSettingsClient.readSleepDisabled { [weak self] result in
            guard let self else { return }
            self.isRefreshingPersistentState = false

            switch result {
            case .success(let disabled):
                self.persistentIsEnabled = disabled
                self.persistentStateIsKnown = true
                if self.message?.source == .statusRead {
                    self.message = nil
                }
            case .failure(let error):
                self.persistentStateIsKnown = false
                if self.message?.source != .action {
                    self.message = .statusReadError(
                        "Could not read the current power setting: \(error.localizedDescription)"
                    )
                }
            }
        }
    }

    func setTemporaryEnabled(_ enabled: Bool) {
        message = nil
        enabled ? startCaffeinate() : stopCaffeinate()
    }

    func setPersistentEnabled(_ enabled: Bool) {
        guard !isChangingPersistentState else { return }
        message = nil
        isChangingPersistentState = true

        PowerSettingsClient.setSleepDisabled(enabled) { [weak self] result in
            guard let self else { return }

            switch result {
            case .changed:
                self.verifyPersistentState(expected: enabled)
            case .cancelled:
                self.isChangingPersistentState = false
                self.message = .info("No changes made — administrator approval was cancelled.")
                self.refreshPersistentState()
            case .failed(let explanation):
                self.isChangingPersistentState = false
                self.message = .error(explanation)
                self.refreshPersistentState()
            }
        }
    }

    func dismissMessage() {
        message = nil
    }

    func shutdown() {
        stopCaffeinate(showErrors: false)
    }

    private func startCaffeinate() {
        guard caffeinateProcess == nil else {
            temporaryIsEnabled = true
            return
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/caffeinate")

        var arguments = ["-i"]
        if keepDisplayAwake {
            arguments.append("-d")
        }
        // `-w` ensures the assertion cannot outlive Hypnagogia after a crash or force-quit.
        arguments.append(contentsOf: ["-w", String(ProcessInfo.processInfo.processIdentifier)])
        process.arguments = arguments
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice

        process.terminationHandler = { [weak self] terminatedProcess in
            DispatchQueue.main.async {
                guard let self,
                      self.caffeinateProcess === terminatedProcess else { return }

                self.caffeinateProcess = nil
                self.temporaryIsEnabled = false
                if terminatedProcess.terminationStatus != 0 {
                    self.message = .error("The temporary keep-awake session ended unexpectedly.")
                }
            }
        }

        do {
            try process.run()
            caffeinateProcess = process
            temporaryIsEnabled = true
        } catch {
            caffeinateProcess = nil
            temporaryIsEnabled = false
            message = .error("Could not start caffeinate: \(error.localizedDescription)")
        }
    }

    private func stopCaffeinate(showErrors: Bool = true) {
        guard let process = caffeinateProcess else {
            temporaryIsEnabled = false
            return
        }

        caffeinateProcess = nil
        temporaryIsEnabled = false
        if process.isRunning {
            process.terminate()
        } else if showErrors, process.terminationStatus != 0 {
            message = .error("The temporary keep-awake session was no longer running.")
        }
    }

    private func restartCaffeinate() {
        stopCaffeinate(showErrors: false)
        startCaffeinate()
    }

    private func verifyPersistentState(expected: Bool) {
        PowerSettingsClient.readSleepDisabled { [weak self] result in
            guard let self else { return }
            self.isChangingPersistentState = false

            switch result {
            case .success(let disabled):
                self.persistentIsEnabled = disabled
                self.persistentStateIsKnown = true
                if disabled != expected {
                    self.message = .error("macOS accepted the command, but the sleep setting did not change.")
                }
            case .failure(let error):
                self.persistentStateIsKnown = false
                self.message = .error("The command ran, but Hypnagogia could not verify it: \(error.localizedDescription)")
            }
        }
    }
}

enum CombinedAwakeState {
    case normal
    case temporary
    case temporaryUnknown
    case persistent
    case both
    case unknown

    var title: String {
        switch self {
        case .normal: return "Normal sleep is allowed"
        case .temporary: return "Kept awake temporarily"
        case .temporaryUnknown: return "Temporary session on; system status unknown"
        case .persistent: return "System sleep is disabled"
        case .both: return "Both sleep overrides are active"
        case .unknown: return "Sleep status is unavailable"
        }
    }

    var detail: String {
        switch self {
        case .normal: return "Your usual macOS sleep settings apply."
        case .temporary: return "Ends when you switch it off or quit Hypnagogia."
        case .temporaryUnknown: return "Caffeinate is on, but Hypnagogia could not read the pmset override."
        case .persistent: return "The pmset override remains on after Hypnagogia quits."
        case .both: return "Temporary caffeinate and persistent pmset are both on."
        case .unknown: return "Open this menu to try reading the setting again."
        }
    }

    var symbol: String {
        switch self {
        case .normal: return "checkmark.circle.fill"
        case .temporary: return "cup.and.saucer.fill"
        case .temporaryUnknown: return "questionmark.circle.fill"
        case .persistent: return "lock.shield.fill"
        case .both: return "bolt.shield.fill"
        case .unknown: return "questionmark.circle.fill"
        }
    }

    var color: NSColor {
        switch self {
        case .normal: return .systemGreen
        case .temporary: return .systemOrange
        case .temporaryUnknown: return .systemOrange
        case .persistent, .both: return .systemIndigo
        case .unknown: return .systemGray
        }
    }
}

struct UserMessage: Identifiable, Equatable {
    enum Kind {
        case info
        case error
    }

    enum Source {
        case statusRead
        case action
    }

    let id = UUID()
    let kind: Kind
    let source: Source
    let text: String

    static func info(_ text: String) -> UserMessage {
        UserMessage(kind: .info, source: .action, text: text)
    }

    static func error(_ text: String) -> UserMessage {
        UserMessage(kind: .error, source: .action, text: text)
    }

    static func statusReadError(_ text: String) -> UserMessage {
        UserMessage(kind: .error, source: .statusRead, text: text)
    }
}
