public struct SettingsModel: Equatable, Sendable {
    public var enabled: Bool
    public var sensitivity: Int      // 1 to 5
    public var clickDelayMs: Int     // 30 to 50
    public var launchAtLogin: Bool

    public init(enabled: Bool, sensitivity: Int, clickDelayMs: Int, launchAtLogin: Bool) {
        self.enabled = enabled
        self.sensitivity = sensitivity
        self.clickDelayMs = clickDelayMs
        self.launchAtLogin = launchAtLogin
    }

    public static let defaults = SettingsModel(enabled: true, sensitivity: 3, clickDelayMs: 40, launchAtLogin: false)

    public func clamped() -> SettingsModel {
        var copy = self
        copy.sensitivity = min(max(sensitivity, 1), 5)
        copy.clickDelayMs = min(max(clickDelayMs, 30), 50)
        return copy
    }

    /// Below the default, swipes can feel jittery or register as accidental clicks.
    public var isClickDelayLow: Bool { clickDelayMs < 40 }

    public static func sensitivityLabel(_ value: Int) -> String {
        switch value {
        case ..<2: return "Slower"
        case 2: return "Slow"
        case 3: return "Default"
        case 4: return "Fast"
        default: return "Faster"
        }
    }
}
