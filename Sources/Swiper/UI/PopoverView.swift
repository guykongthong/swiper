import SwiftUI
import SwiperCore

struct PopoverView: View {
    @ObservedObject var state: AppState
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        let status = state.status
        VStack(spacing: 0) {
            header(status)
            if status == .needsPermission {
                Banner(kind: .warning,
                       title: state.tapFailed ? "macOS is still blocking Swiper" : "Accessibility permission needed",
                       message: state.tapFailed
                           ? "Swiper is switched on, but the grant is stale. Remove Swiper from the Accessibility list with the minus button, add it again, then reopen the app."
                           : "Swiper needs it to see when both mouse buttons are held.",
                       actionTitle: "Open System Settings") { state.openSystemSettingsAccessibility() }
                    .padding(.horizontal, 12).padding(.top, 12).padding(.bottom, 4)
            }
            if status == .gestureNotWorking {
                Banner(kind: .error, title: "Swipe isn't working on this macOS version",
                       message: "Clicks still work normally. Open Settings for details.")
                    .padding(.horizontal, 12).padding(.top, 12).padding(.bottom, 4)
            }
            VStack(spacing: 0) {
                toggleRow("Swiping", isOn: Binding(get: { state.store.settings.enabled }, set: { state.store.settings.enabled = $0 }))
                    .opacity(status == .needsPermission ? 0.45 : 1)
                    .disabled(status == .needsPermission)
                toggleRow("Launch at login", isOn: Binding(get: { state.store.settings.launchAtLogin }, set: { state.store.settings.launchAtLogin = $0 }))
                if status == .active || status == .paused {
                    Text(status == .paused
                         ? "Swiping is off. Your mouse buttons work as usual."
                         : "Hold both mouse buttons and move to switch desktops. Move up for Mission Control.")
                        .font(Theme.font(12)).foregroundStyle(Theme.muted)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 10).padding(.bottom, 10)
                }
                Divider().overlay(Theme.line).padding(.horizontal, 8).padding(.vertical, 2)
                menuRow("Settings…", shortcut: "⌘,") {
                    openWindow(id: "settings")
                    NSApp.activate(ignoringOtherApps: true)
                }
                menuRow("Quit Swiper", shortcut: "⌘Q") { NSApp.terminate(nil) }
            }
            .padding(.horizontal, 8).padding(.top, 6).padding(.bottom, 6)
        }
        .frame(width: 300)
        .background(Theme.paper)
        .foregroundStyle(Theme.navy)
    }

    private func header(_ status: AppStatus) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Swiper").font(Theme.font(17, .semibold))
            HStack(spacing: 8) {
                Circle().fill(Theme.dotColor(for: status)).frame(width: 8, height: 8)
                Text(Theme.label(for: status)).font(Theme.font(12.5))
            }
            .foregroundStyle(Theme.onNavy)
        }
        .foregroundStyle(Theme.paper)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 18).padding(.top, 16).padding(.bottom, 14)
        .background(Theme.navy)
    }

    private func toggleRow(_ title: String, isOn: Binding<Bool>) -> some View {
        HStack {
            Text(title).font(Theme.font(13.5))
            Spacer()
            Toggle("", isOn: isOn).labelsHidden().toggleStyle(.switch).tint(Theme.navy).controlSize(.small)
        }
        .padding(.horizontal, 10).padding(.vertical, 8)
    }

    private func menuRow(_ title: String, shortcut: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title).font(Theme.font(13.5))
                Spacer()
                Text(shortcut).font(Theme.font(12)).foregroundStyle(Theme.muted)
            }
            .padding(.horizontal, 10).padding(.vertical, 9)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
