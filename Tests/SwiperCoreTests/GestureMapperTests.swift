import Testing
@testable import SwiperCore

@Test func sensitivityScalesProgress() {
    var slow = GestureMapper(sensitivity: 1, naturalScrolling: true)
    var fast = GestureMapper(sensitivity: 5, naturalScrolling: true)
    let a = slow.progress(axis: .horizontal, dx: 100, dy: 0)
    let b = fast.progress(axis: .horizontal, dx: 100, dy: 0)
    #expect(abs(b) > abs(a))
}

@Test func naturalScrollingFlipsSign() {
    var natural = GestureMapper(sensitivity: 3, naturalScrolling: true)
    var classic = GestureMapper(sensitivity: 3, naturalScrolling: false)
    let a = natural.progress(axis: .horizontal, dx: 50, dy: 0)
    let b = classic.progress(axis: .horizontal, dx: 50, dy: 0)
    #expect(a == -b)
    #expect(a != 0)
}

@Test func progressAccumulatesAcrossCalls() {
    var m = GestureMapper(sensitivity: 3, naturalScrolling: true)
    let first = m.progress(axis: .horizontal, dx: 20, dy: 0)
    let second = m.progress(axis: .horizontal, dx: 20, dy: 0)
    #expect(abs(second) > abs(first))
}

@Test func otherAxisMovementIsIgnored() {
    var m = GestureMapper(sensitivity: 3, naturalScrolling: true)
    #expect(m.progress(axis: .horizontal, dx: 0, dy: 80) == 0)
}

@Test func verticalUpGivesPositiveMissionControlProgress() {
    var m = GestureMapper(sensitivity: 3, naturalScrolling: true)
    // screen coordinates: moving up means dy < 0
    #expect(m.progress(axis: .vertical, dx: 0, dy: -60) > 0)
}

@Test func sensitivityIsClamped() {
    var low = GestureMapper(sensitivity: -4, naturalScrolling: true)
    var one = GestureMapper(sensitivity: 1, naturalScrolling: true)
    #expect(low.progress(axis: .horizontal, dx: 10, dy: 0) == one.progress(axis: .horizontal, dx: 10, dy: 0))
}
