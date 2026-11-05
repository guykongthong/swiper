import Foundation
import ServiceManagement
import SwiperCore

@MainActor
final class SettingsStore: ObservableObject {
    @Published var settings: SettingsModel {
        didSet {
            let clamped = settings.clamped()
            if clamped != settings { settings = clamped; return }
            save()
            if oldValue.launchAtLogin != settings.launchAtLogin { applyLaunchAtLogin() }
        }
    }

    private let defaults = UserDefaults.standard

    init() {
        let d = SettingsModel.defaults
        let stored = SettingsModel(
            enabled: defaults.object(forKey: "enabled") as? Bool ?? d.enabled,
            sensitivity: defaults.object(forKey: "sensitivity") as? Int ?? d.sensitivity,
            clickDelayMs: defaults.object(forKey: "clickDelayMs") as? Int ?? d.clickDelayMs,
            launchAtLogin: SMAppService.mainApp.status == .enabled
        )
        settings = stored.clamped()
    }

    private func save() {
        defaults.set(settings.enabled, forKey: "enabled")
        defaults.set(settings.sensitivity, forKey: "sensitivity")
        defaults.set(settings.clickDelayMs, forKey: "clickDelayMs")
    }

    private func applyLaunchAtLogin() {
        do {
            if settings.launchAtLogin { try SMAppService.mainApp.register() }
            else { try SMAppService.mainApp.unregister() }
        } catch {
            // Registration only works for a properly bundled app; show the real state instead.
            settings.launchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }
}
