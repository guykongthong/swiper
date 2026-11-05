import Testing
@testable import SwiperCore

@Test func noPermissionWinsOverEverything() {
    #expect(resolveStatus(enabled: true, permissionGranted: false, gestureHealthy: false) == .needsPermission)
    #expect(resolveStatus(enabled: false, permissionGranted: false, gestureHealthy: true) == .needsPermission)
}

@Test func unhealthyGestureWithPermissionIsNotWorking() {
    #expect(resolveStatus(enabled: true, permissionGranted: true, gestureHealthy: false) == .gestureNotWorking)
}

@Test func disabledIsPaused() {
    #expect(resolveStatus(enabled: false, permissionGranted: true, gestureHealthy: true) == .paused)
}

@Test func otherwiseActive() {
    #expect(resolveStatus(enabled: true, permissionGranted: true, gestureHealthy: true) == .active)
}
