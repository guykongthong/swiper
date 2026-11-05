public enum AppStatus: Equatable, Sendable {
    case active, paused, needsPermission, gestureNotWorking
}

public func resolveStatus(enabled: Bool, permissionGranted: Bool, gestureHealthy: Bool) -> AppStatus {
    if !permissionGranted { return .needsPermission }
    if !enabled { return .paused }
    if !gestureHealthy { return .gestureNotWorking }
    return .active
}
