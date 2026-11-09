import Testing
@testable import SwiperCore

final class OrderRecordingEffects: SwipeEffects {
    var calls: [String] = []
    func replayHeldPress(_ b: MouseButton) { calls.append("replayDown") }
    func replayRelease(_ b: MouseButton) { calls.append("replayUp") }
    func setCursorFrozen(_ f: Bool) {}
    func beginGesture(axis: SwipeAxis) {}
    func updateGesture(progress: Double) {}
    func endGesture(progress: Double, velocity: Double) {}
    func cancelGesture() {}
}

@Suite struct ReplayOrderingTests {
    // Release arrives after the click window but before the tick fires: press and release
    // must both be replayed, in order, and the original release swallowed.
    @Test func lateUpIsReplayedInOrder() {
        let fx = OrderRecordingEffects()
        let s = SwipeSession(effects: fx, clickDelayMs: 40, sensitivity: 50, naturalScrolling: { true })
        _ = s.handle(.down(.left, at: 0))
        let r = s.handle(.up(.left, at: 0.041))
        #expect(fx.calls == ["replayDown", "replayUp"])
        #expect(r.swallow == true)
    }

    // Release arrives inside the window: both replayed, original swallowed.
    @Test func fastUpIsReplayedInOrder() {
        let fx = OrderRecordingEffects()
        let s = SwipeSession(effects: fx, clickDelayMs: 40, sensitivity: 50, naturalScrolling: { true })
        _ = s.handle(.down(.left, at: 0))
        let r = s.handle(.up(.left, at: 0.02))
        #expect(fx.calls == ["replayDown", "replayUp"])
        #expect(r.swallow == true)
    }
}
