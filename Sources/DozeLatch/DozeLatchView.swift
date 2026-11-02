import AppKit
import SwiftUI

struct DozeLatchView: View {
    @ObservedObject var controller: AwakeController

    private var temporaryBinding: Binding<Bool> {
        Binding(
            get: { controller.temporaryIsEnabled },
            set: { controller.setTemporaryEnabled($0) }
        )
    }

    private var persistentBinding: Binding<Bool> {
        Binding(
            get: { controller.persistentIsEnabled },
            set: { controller.setPersistentEnabled($0) }
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            statusHeader
                .padding(18)

            Divider()

            VStack(spacing: 12) {
                if let message = controller.message {
                    MessageBanner(message: message) {
                        controller.dismissMessage()
                    }
                }

                temporaryCard
                persistentCard
                safetyNote
            }
            .padding(14)

            Divider()

            footer
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
        }
        .frame(width: 372)
        .background(.ultraThinMaterial)
        .onAppear {
            controller.refreshPersistentState()
        }
    }

    private var statusHeader: some View {
        let state = controller.combinedState

        return HStack(spacing: 13) {
            ZStack {
                Circle()
                    .fill(Color(nsColor: state.color).opacity(0.14))
                Image(systemName: state.symbol)
                    .font(.system(size: 21, weight: .semibold))
                    .foregroundStyle(Color(nsColor: state.color))
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 3) {
                Text("DozeLatch")
                    .font(.headline)
                Text(state.title)
                    .font(.subheadline.weight(.medium))
                Text(state.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("DozeLatch. \(state.title). \(state.detail)")
    }

    private var temporaryCard: some View {
        ControlCard(
            icon: "cup.and.saucer.fill",
            tint: .orange,
            title: "Prevent idle sleep",
            detail: "Runs caffeinate until switched off or DozeLatch quits."
        ) {
            Toggle("Temporary keep-awake", isOn: temporaryBinding)
                .labelsHidden()
                .toggleStyle(.switch)
                .accessibilityLabel("Temporary keep-awake")
                .accessibilityHint("Runs caffeinate until switched off or DozeLatch quits.")
        } content: {
            Divider()

            Toggle(isOn: $controller.keepDisplayAwake) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Keep display on too")
                        .font(.subheadline)
                    Text("Otherwise the screen may turn off normally.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .toggleStyle(.switch)
        }
    }

    private var persistentCard: some View {
        ControlCard(
            icon: "lock.shield.fill",
            tint: .indigo,
            title: "Disable all system sleep",
            detail: "Includes lid close; persists and requires administrator approval."
        ) {
            if controller.isRefreshingPersistentState || controller.isChangingPersistentState {
                ProgressView()
                    .controlSize(.small)
                    .frame(width: 28)
                    .accessibilityLabel("Updating system sleep setting")
            } else {
                Toggle("Disable all system sleep", isOn: persistentBinding)
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .disabled(!controller.persistentStateIsKnown)
                    .accessibilityLabel("Disable all system sleep persistently")
                    .accessibilityHint("Requires administrator approval and remains active after DozeLatch quits.")
            }
        } content: {
            HStack(spacing: 6) {
                Image(systemName: "person.badge.key.fill")
                Text("Uses a fixed pmset command. DozeLatch never stores your password.")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }

    private var safetyNote: some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.yellow)
                .padding(.top, 1)
            Text("Closed-lid operation varies by Mac and can build heat or drain the battery. Thermal and low-battery protections still take priority; never leave the Mac running inside a bag.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(11)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.yellow.opacity(0.08))
        )
        .accessibilityElement(children: .combine)
    }

    private var footer: some View {
        HStack {
            Button {
                controller.refreshPersistentState()
            } label: {
                Label("Refresh", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .disabled(controller.isRefreshingPersistentState || controller.isChangingPersistentState)

            Spacer()

            Button("Quit DozeLatch") {
                controller.shutdown()
                NSApp.terminate(nil)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .help(controller.persistentIsEnabled
                  ? "Quits DozeLatch. The persistent pmset setting stays on."
                  : "Quits DozeLatch and ends its temporary keep-awake session.")
        }
        .font(.caption)
    }
}

private struct ControlCard<Trailing: View, Content: View>: View {
    let icon: String
    let tint: Color
    let title: String
    let detail: String
    @ViewBuilder let trailing: () -> Trailing
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack(spacing: 11) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(tint.opacity(0.12))
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(tint)
                }
                .frame(width: 34, height: 34)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 6)
                trailing()
            }

            content()
        }
        .padding(13)
        .background(
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.72))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.07))
        )
    }
}

private struct MessageBanner: View {
    let message: UserMessage
    let dismiss: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: message.kind == .error ? "exclamationmark.circle.fill" : "info.circle.fill")
                .foregroundStyle(message.kind == .error ? Color.red : Color.accentColor)
                .padding(.top, 1)
            Text(message.text)
                .font(.caption)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 4)
            Button(action: dismiss) {
                Image(systemName: "xmark")
                    .font(.caption.weight(.bold))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Dismiss message")
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill((message.kind == .error ? Color.red : Color.accentColor).opacity(0.09))
        )
    }
}
