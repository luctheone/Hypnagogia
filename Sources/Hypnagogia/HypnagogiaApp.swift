import AppKit
import SwiftUI

final class HypnagogiaAppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        AwakeController.shared.refreshPersistentState()
    }

    func applicationWillTerminate(_ notification: Notification) {
        AwakeController.shared.shutdown()
    }
}

@main
struct HypnagogiaApp: App {
    @NSApplicationDelegateAdaptor(HypnagogiaAppDelegate.self) private var appDelegate
    @StateObject private var controller = AwakeController.shared

    var body: some Scene {
        MenuBarExtra {
            HypnagogiaView(controller: controller)
        } label: {
            Image(systemName: controller.menuBarSymbol)
                .accessibilityLabel("Hypnagogia")
                .accessibilityValue(controller.combinedState.title)
        }
        .menuBarExtraStyle(.window)
    }
}
