import ApplicationServices
import Foundation

/// Tracks whether the Accessibility permission is granted, and keeps checking
/// while it is not, so granting it in System Settings takes effect without a relaunch.
@MainActor
final class PermissionMonitor: ObservableObject {
    @Published private(set) var isGranted: Bool = AXIsProcessTrusted()
    private var timer: Timer?

    func start() {
        refresh()
        guard !isGranted else { return }
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
    }

    /// Shows the system prompt (once per request) that points the user to Privacy & Security.
    func promptIfNeeded() {
        let key = "AXTrustedCheckOptionPrompt" as CFString
        let options = [key: true] as CFDictionary
        isGranted = AXIsProcessTrustedWithOptions(options)
        start()
    }

    private func refresh() {
        let trusted = AXIsProcessTrusted()
        if trusted != isGranted { isGranted = trusted }
        if trusted { timer?.invalidate(); timer = nil }
    }
}
