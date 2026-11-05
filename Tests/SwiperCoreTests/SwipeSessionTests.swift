import Testing
@testable import SwiperCore

private func ms(_ v: Double) -> Double { v / 1000 }

private final class FakeEffects: SwipeEffects {
    var log: [String] = []
    func replayHeldPress(_ b: MouseButton) { log.append("press:\(b)") }
    func replayRelease(_ b: MouseButton) { log.append("release:\(b)") }
    func setCursorFrozen(_ frozen: Bool) { log.append("frozen:\(frozen)") }
    func beginGesture(axis: SwipeAxis) { log.append("begin:\(axis)") }
    func updateGesture(progress: Double) { log.append("update") }
    func endGesture(progress: Double, velocity: Double) { log.append("end") }
    func cancelGesture() { log.append("cancel") }
}

private func makeSession(_ fx: FakeEffects) -> SwipeSession {
    SwipeSession(effects: fx, clickDelayMs: 40, sensitivity: 3, naturalScrolling: { true })
}

private func startChord(_ s: SwipeSession) {
    _ = s.handle(.down(.left, at: ms(0)))
    _ = s.handle(.down(.right, at: ms(10)))
}

@Test func plainClickIsSwallowedThenReplayedOnTick() {
    let fx = FakeEffects(); let s = makeSession(fx)
    let r = s.handle(.down(.left, at: ms(0)))
    #expect(r.swallow)
    #expect(r.scheduleTickAfter != nil)
    _ = s.handle(.tick(at: ms(45)))
    #expect(fx.log == ["press:left"])
}

@Test func chordFreezesCursorAndSwipeDrivesTheGesture() {
    let fx = FakeEffects(); let s = makeSession(fx)
    startChord(s)
    #expect(fx.log == ["frozen:true"])
    _ = s.handle(.moved(dx: 10, dy: 0, at: ms(20)))
    _ = s.handle(.moved(dx: 10, dy: 0, at: ms(40)))
    _ = s.handle(.up(.left, at: ms(100)))
    #expect(fx.log == ["frozen:true", "begin:horizontal", "update", "update", "end", "frozen:false"])
}

@Test func chordWithoutEnoughMovementNeverBeginsAGesture() {
    let fx = FakeEffects(); let s = makeSession(fx)
    startChord(s)
    _ = s.handle(.moved(dx: 1, dy: 1, at: ms(20)))
    _ = s.handle(.up(.right, at: ms(100)))
    #expect(fx.log == ["frozen:true", "frozen:false"])
}

@Test func abandonMidSwipeUnfreezesAndCancels() {
    let fx = FakeEffects(); let s = makeSession(fx)
    startChord(s)
    _ = s.handle(.moved(dx: 20, dy: 0, at: ms(20)))
    s.abandon()
    #expect(fx.log.suffix(2) == ["cancel", "frozen:false"])
}

@Test func abandonDuringHoldReplaysThePress() {
    let fx = FakeEffects(); let s = makeSession(fx)
    _ = s.handle(.down(.right, at: ms(0)))
    s.abandon()
    #expect(fx.log == ["press:right"])
}

@Test func abandonWhenIdleDoesNothing() {
    let fx = FakeEffects(); let s = makeSession(fx)
    s.abandon()
    #expect(fx.log == [])
}

@Test func secondChordAfterAbandonStartsClean() {
    let fx = FakeEffects(); let s = makeSession(fx)
    startChord(s)
    s.abandon()
    fx.log = []
    _ = s.handle(.up(.left, at: ms(200)))
    _ = s.handle(.up(.right, at: ms(210)))
    startChord2(s)
    #expect(fx.log == ["frozen:true"])
}

private func startChord2(_ s: SwipeSession) {
    _ = s.handle(.down(.left, at: ms(1000)))
    _ = s.handle(.down(.right, at: ms(1010)))
}

@Test func quickClickReplaysPressThenRelease() {
    let fx = FakeEffects(); let s = makeSession(fx)
    _ = s.handle(.down(.left, at: ms(0)))
    let r = s.handle(.up(.left, at: ms(10)))
    #expect(r.swallow)
    #expect(fx.log == ["press:left", "release:left"])
}

@Test func untouchedEventsPassThrough() {
    let fx = FakeEffects(); let s = makeSession(fx)
    let r = s.handle(.moved(dx: 5, dy: 5, at: ms(0)))
    #expect(!r.swallow)
    #expect(fx.log == [])
}
