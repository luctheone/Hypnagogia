import AppKit
import SwiftUI

final class DozeLatchAppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        AwakeController.shared.refreshPersistentState()
    }

    func applicationWillTerminate(_ notification: Notification) {
        AwakeController.shared.shutdown()
    }
}

@main
struct DozeLatchApp: App {
    @NSApplicationDelegateAdaptor(DozeLatchAppDelegate.self) private var appDelegate
    @StateObject private var controller = AwakeController.shared

    var body: some Scene {
        MenuBarExtra {
            DozeLatchView(controller: controller)
        } label: {
            Image(systemName: controller.menuBarSymbol)
                .accessibilityLabel("DozeLatch")
                .accessibilityValue(controller.combinedState.title)
        }
        .menuBarExtraStyle(.window)
    }
}
