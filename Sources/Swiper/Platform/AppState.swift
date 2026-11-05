import AppKit
import Combine
import Foundation
import SwiperCore

/// Versions the owner has verified the gesture on. Add the current version here once a real swipe works.
let testedVersions: [OSVersion] = []

/// Puts the pieces together and keeps the event tap in line with settings and permission.
@MainActor
final class AppState: ObservableObject {
    let permission = PermissionMonitor()
    let health = HealthMonitor()
    let store = SettingsStore()
    private var controller: EventTapController?
    private var cancellables = Set<AnyCancellable>()

    var status: AppStatus {
        resolveStatus(enabled: store.settings.enabled, permissionGranted: permission.isGranted, gestureHealthy: health.isHealthy)
    }

    var compatibilityResult: CompatibilityResult {
        compatibility(current: SystemInfo.currentVersion(), tested: testedVersions)
    }

    init() {
        let s = store.settings
        controller = EventTapController(
            poster: HealthReportingPoster(wrapped: DockSwipePoster(), health: health),
            clickDelayMs: s.clickDelayMs, sensitivity: s.sensitivity
        )
        // Forward changes so views redraw when any part changes.
        permission.objectWillChange.sink { [weak self] _ in self?.objectWillChange.send() }.store(in: &cancellables)
        health.objectWillChange.sink { [weak self] _ in self?.objectWillChange.send() }.store(in: &cancellables)
        store.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
            DispatchQueue.main.async { self?.syncTap() }
        }.store(in: &cancellables)
        permission.objectWillChange.sink { [weak self] _ in
            DispatchQueue.main.async { self?.syncTap() }
        }.store(in: &cancellables)

        // Never leave the cursor frozen or a click held if the app quits mid-swipe.
        NotificationCenter.default.addObserver(forName: NSApplication.willTerminateNotification, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.controller?.stop() }
        }

        permission.start()
        syncTap()
    }

    func openSystemSettingsAccessibility() {
        permission.promptIfNeeded()
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspaceOpen(url)
        }
    }

    private func syncTap() {
        guard let controller else { return }
        let s = store.settings
        controller.updateSettings(clickDelayMs: s.clickDelayMs, sensitivity: s.sensitivity)
        let shouldRun = s.enabled && permission.isGranted
        if shouldRun && !controller.isRunning { try? controller.start() }
        if !shouldRun && controller.isRunning { controller.stop() }
    }
}

import AppKit
private func NSWorkspaceOpen(_ url: URL) { NSWorkspace.shared.open(url) }

/// Passes gesture calls on and tells the health monitor how each swipe went.
final class HealthReportingPoster: GesturePosting {
    private let wrapped: GesturePosting
    private let health: HealthMonitor
    private var axis: SwipeAxis = .horizontal

    init(wrapped: GesturePosting, health: HealthMonitor) {
        self.wrapped = wrapped
        self.health = health
    }

    func begin(axis: SwipeAxis) {
        self.axis = axis
        if axis == .horizontal { MainActor.assumeIsolated { health.swipeBegan() } }
        wrapped.begin(axis: axis)
    }
    func update(progress: Double) { wrapped.update(progress: progress) }
    func end(progress: Double, velocity: Double) {
        if axis == .horizontal { MainActor.assumeIsolated { health.swipeEnded(progress: progress) } }
        wrapped.end(progress: progress, velocity: velocity)
    }
    func cancel() { wrapped.cancel() }
}
