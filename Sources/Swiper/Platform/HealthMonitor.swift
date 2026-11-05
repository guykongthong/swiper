import AppKit
import SwiperCore

/// Notices when swipes stop changing the desktop (for example after a macOS update).
/// After a completed horizontal swipe it waits briefly and checks that the active desktop changed.
@MainActor
final class HealthMonitor: ObservableObject {
    @Published private(set) var isHealthy = true
    private var consecutiveMisses = 0
    private var spaceChanged = false
    private let missesBeforeWarning = 3
    private let expectedProgress = 0.25

    init() {
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.activeSpaceDidChangeNotification, object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.spaceChanged = true }
        }
    }

    func swipeBegan() { spaceChanged = false }

    /// Call when a horizontal swipe ends. Swipes too small to switch desktops are ignored.
    func swipeEnded(progress: Double) {
        guard abs(progress) >= expectedProgress else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self else { return }
            if self.spaceChanged {
                self.consecutiveMisses = 0
                self.isHealthy = true
            } else {
                self.consecutiveMisses += 1
                if self.consecutiveMisses >= self.missesBeforeWarning { self.isHealthy = false }
            }
        }
    }
}
