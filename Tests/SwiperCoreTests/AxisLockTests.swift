import Testing
@testable import SwiperCore

@Test func lockStaysNilUntilDistanceReached() {
    var lock = AxisLock(lockDistance: 6)
    #expect(lock.feed(dx: 2, dy: 1) == nil)
    #expect(lock.feed(dx: 2, dy: 0) == nil)
}

@Test func lockPicksDominantAxis() {
    var h = AxisLock(lockDistance: 6)
    #expect(h.feed(dx: 10, dy: 2) == .horizontal)
    var v = AxisLock(lockDistance: 6)
    #expect(v.feed(dx: 1, dy: -9) == .vertical)
}

@Test func lockDoesNotChangeAfterLocking() {
    var lock = AxisLock(lockDistance: 6)
    _ = lock.feed(dx: 10, dy: 0)
    #expect(lock.feed(dx: 0, dy: 50) == .horizontal)
}

@Test func resetClearsTheLock() {
    var lock = AxisLock(lockDistance: 6)
    _ = lock.feed(dx: 10, dy: 0)
    lock.reset()
    #expect(lock.feed(dx: 0, dy: 10) == .vertical)
}
